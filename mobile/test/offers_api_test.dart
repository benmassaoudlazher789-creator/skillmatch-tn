import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:skillmatch_tn/features/offers/data/offers_api.dart';
import 'package:skillmatch_tn/features/offers/domain/offer.dart';
import 'package:skillmatch_tn/features/offers/domain/offers_failure.dart';

// Tests de HttpOffersApi avec MockClient (fourni par le paquet http) : il
// répond à la place du serveur, sans aucun appel réseau réel.
void main() {
  // Valeurs fictives, propres aux tests.
  const token = 'jeton-test-offres';
  const skills = ['Flutter', 'C#', 'Power BI'];

  http.Response json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Une offre comme l'API la renvoie.
  Map<String, Object?> offerJson({
    String id = 'o1',
    String type = 'stage',
    bool isSample = true,
    String? url = 'https://example.com/offre',
  }) => {
    'id': id,
    'title': 'Stage exemple',
    'company': 'Société Exemple Test',
    'type': type,
    'city': 'Tunis',
    'url': url,
    'source': 'exemple',
    'isSample': isSample,
    'publishedAt': '2026-10-01T09:00:00+00:00',
    'score': 65,
    'requiredAcquired': ['Flutter'],
    'requiredMissing': ['Dart'],
    'preferredAcquired': ['Git'],
    'preferredMissing': <String>[],
    'explanation':
        'Requises : 1 sur 2 (70 % du score) · Souhaitées : 1 sur 1 (30 %)',
  };

  HttpOffersApi apiWith(MockClientHandler handler) =>
      HttpOffersApi(client: MockClient(handler), baseUrl: 'http://api.test/');

  Future<List<Offer>> fetch(HttpOffersApi api) =>
      api.fetch(token: token, skills: skills);

  Future<OffersFailure> failureOf(HttpOffersApi api) async {
    try {
      await fetch(api);
    } on OffersException catch (e) {
      return e.failure;
    }
    fail('Une OffersException était attendue.');
  }

  test('GET /offers avec le jeton, les compétences et limit=50', () async {
    late http.Request sent;
    final api = apiWith((request) async {
      sent = request;
      return json(200, {'offers': <Object>[]});
    });

    await fetch(api);

    expect(sent.method, 'GET');
    expect(sent.url.path, '/offers');
    expect(sent.headers['Authorization'], 'Bearer $token');
    // Paramètre répété, une valeur par compétence, décodée telle quelle.
    expect(sent.url.queryParametersAll['skill'], skills);
    expect(sent.url.queryParameters['limit'], '50');
    // « C# » est bien encodé : le « # » ne coupe pas l'adresse.
    expect(sent.url.toString(), contains('C%23'));
    // Le jeton ne voyage jamais dans l'adresse.
    expect(sent.url.toString(), isNot(contains(token)));
  });

  test('Lit les offres dans l\'ordre du serveur', () async {
    final api = apiWith(
      (_) async => json(200, {
        'offers': [
          offerJson(id: 'b', type: 'emploi', isSample: false, url: null),
          offerJson(id: 'a', type: 'pfe'),
        ],
      }),
    );

    final offers = await fetch(api);

    expect(offers.map((o) => o.id), ['b', 'a']);
    final first = offers.first;
    expect(first.type, OfferType.emploi);
    expect(first.isSample, isFalse);
    expect(first.url, isNull);
    expect(first.score, 65);
    expect(first.acquired, ['Flutter', 'Git']);
    expect(first.missing, ['Dart']);
    expect(first.explanation, startsWith('Requises : 1 sur 2'));
    expect(offers.last.isSample, isTrue);
    expect(offers.last.url, 'https://example.com/offre');
  });

  test(
    'Offre de type inconnu ou incomplète : écartée, les autres restent',
    () async {
      final api = apiWith(
        (_) async => json(200, {
          'offers': [
            offerJson(id: 'inconnu', type: 'freelance'),
            {'id': 'incomplete'},
            'pas un objet',
            offerJson(id: 'ok'),
          ],
        }),
      );

      expect((await fetch(api)).map((o) => o.id), ['ok']);
    },
  );

  test('Corps illisible : erreur inattendue', () async {
    final api = apiWith((_) async => http.Response('pas du json', 200));
    expect(await failureOf(api), OffersFailure.unknown);
  });

  group('Codes d\'erreur traduits en messages français', () {
    final cases = <(int, String?, OffersFailure)>[
      (400, 'too_many_skills', OffersFailure.tooManySkills),
      (400, 'skill_too_long', OffersFailure.skillTooLong),
      (400, 'invalid_limit', OffersFailure.unknown),
      (401, null, OffersFailure.sessionExpired),
      (500, null, OffersFailure.unknown),
    ];
    for (final (status, code, expected) in cases) {
      test('$status ${code ?? '(sans corps)'} → ${expected.name}', () async {
        final api = apiWith(
          (_) async => code == null
              ? http.Response('', status)
              : json(status, {'code': code, 'title': 'Message du serveur'}),
        );
        expect(await failureOf(api), expected);
      });
    }
  });

  test('Serveur injoignable : erreur réseau', () async {
    final api = apiWith(
      (_) async => throw http.ClientException('Connection refused'),
    );
    expect(await failureOf(api), OffersFailure.network);
  });

  test('Délai dépassé : erreur réseau', () async {
    final api = HttpOffersApi(
      client: MockClient((_) => Completer<http.Response>().future),
      baseUrl: 'http://api.test',
      timeout: const Duration(milliseconds: 20),
    );
    expect(await failureOf(api), OffersFailure.network);
  });

  test('L\'erreur ne contient ni le jeton ni les compétences', () async {
    // Réponse piégée qui recopie le jeton et une compétence.
    final api = apiWith((_) async => http.Response('$token Power BI', 500));
    try {
      await fetch(api);
      fail('Une OffersException était attendue.');
    } on OffersException catch (e) {
      for (final text in [e.toString(), e.message]) {
        expect(text, isNot(contains(token)));
        expect(text, isNot(contains('Power BI')));
      }
    }
  });

  test('Messages en français, sans mot interdit', () {
    for (final failure in OffersFailure.values) {
      expect(failure.message, isNotEmpty);
      for (final word in [
        'vérifi',
        'certifi',
        'prouv',
        'passeport',
        'défi',
        'chiffr',
        'robot',
      ]) {
        expect(failure.message, isNot(contains(word)), reason: failure.name);
      }
    }
  });
}
