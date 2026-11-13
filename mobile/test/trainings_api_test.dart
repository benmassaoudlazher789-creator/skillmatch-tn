import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:skillmatch_tn/features/trainings/data/trainings_api.dart';
import 'package:skillmatch_tn/features/trainings/domain/training.dart';
import 'package:skillmatch_tn/features/trainings/domain/trainings_failure.dart';

// Tests de HttpTrainingsApi avec MockClient (fourni par le paquet http) :
// il répond à la place du serveur, sans aucun appel réseau réel.
void main() {
  // Valeurs fictives, propres aux tests.
  const token = 'jeton-test-formations';
  const skill = 'C#';

  http.Response json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Une formation comme l'API la renvoie.
  Map<String, Object?> trainingJson({
    String id = 't1',
    String level = 'debutant',
    String type = 'tutoriel',
    bool isSample = true,
    Object? url,
  }) => {
    'id': id,
    'skill': 'C#',
    'title': 'Formation exemple $id',
    'level': level,
    'hours': 3,
    'type': type,
    'url': url,
    'source': 'exemple',
    'isSample': isSample,
  };

  HttpTrainingsApi apiWith(MockClientHandler handler) => HttpTrainingsApi(
    client: MockClient(handler),
    baseUrl: 'http://api.test/',
  );

  Future<List<Training>> fetch(HttpTrainingsApi api) =>
      api.fetch(token: token, skill: skill);

  Future<TrainingsFailure> failureOf(HttpTrainingsApi api) async {
    try {
      await fetch(api);
    } on TrainingsException catch (e) {
      return e.failure;
    }
    fail('Une TrainingsException était attendue.');
  }

  test('GET /trainings avec le jeton et une seule compétence', () async {
    late http.Request sent;
    final api = apiWith((request) async {
      sent = request;
      return json(200, {'skill': skill, 'trainings': <Object>[]});
    });

    await fetch(api);

    expect(sent.method, 'GET');
    expect(sent.url.path, '/trainings');
    expect(sent.headers['Authorization'], 'Bearer $token');
    expect(sent.url.queryParametersAll['skill'], [skill]);
    // « C# » est bien encodé : le « # » ne coupe pas l'adresse.
    expect(sent.url.toString(), contains('C%23'));
    // Le jeton ne voyage jamais dans l'adresse.
    expect(sent.url.toString(), isNot(contains(token)));
  });

  test('Lit les formations dans l\'ordre du serveur', () async {
    final api = apiWith(
      (_) async => json(200, {
        'skill': skill,
        'trainings': [
          trainingJson(
            id: 'b',
            level: 'avance',
            type: 'projet_pratique',
            isSample: false,
            url: 'https://example.com/formation',
          ),
          trainingJson(id: 'a', level: 'intermediaire', type: 'cours_en_ligne'),
        ],
      }),
    );

    final trainings = await fetch(api);

    expect(trainings.map((t) => t.id), ['b', 'a']);
    final first = trainings.first;
    expect(first.skill, 'C#');
    expect(first.level, TrainingLevel.avance);
    expect(first.type, TrainingType.projetPratique);
    expect(first.hours, 3);
    expect(first.isSample, isFalse);
    expect(first.url, 'https://example.com/formation');
    final last = trainings.last;
    expect(last.level, TrainingLevel.intermediaire);
    expect(last.type, TrainingType.coursEnLigne);
    expect(last.isSample, isTrue);
    expect(last.url, isNull);
  });

  test('Lien d\'un mauvais type : lu comme absent', () async {
    final api = apiWith(
      (_) async => json(200, {
        'trainings': [trainingJson(url: 42)],
      }),
    );

    expect((await fetch(api)).single.url, isNull);
  });

  test('Liste vide : aucune formation, sans erreur', () async {
    final api = apiWith(
      (_) async => json(200, {'skill': skill, 'trainings': <Object>[]}),
    );

    expect(await fetch(api), isEmpty);
  });

  test(
    'Formation de niveau ou type inconnu, ou incomplète : écartée',
    () async {
      final api = apiWith(
        (_) async => json(200, {
          'trainings': [
            trainingJson(id: 'niveau', level: 'expert'),
            trainingJson(id: 'type', type: 'atelier'),
            {'id': 'incomplete'},
            'pas un objet',
            trainingJson(id: 'ok'),
          ],
        }),
      );

      expect((await fetch(api)).map((t) => t.id), ['ok']);
    },
  );

  test('Corps illisible : erreur inattendue', () async {
    final api = apiWith((_) async => http.Response('pas du json', 200));
    expect(await failureOf(api), TrainingsFailure.unknown);
  });

  test('Corps sans liste de formations : erreur inattendue', () async {
    final api = apiWith((_) async => json(200, {'autre': 1}));
    expect(await failureOf(api), TrainingsFailure.unknown);
  });

  group('Codes d\'erreur traduits en messages français', () {
    final cases = <(int, String?, TrainingsFailure)>[
      (400, 'skill_too_long', TrainingsFailure.skillTooLong),
      (400, 'missing_skill', TrainingsFailure.unknown),
      (400, 'too_many_skills', TrainingsFailure.unknown),
      (401, null, TrainingsFailure.sessionExpired),
      (500, null, TrainingsFailure.unknown),
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
    expect(await failureOf(api), TrainingsFailure.network);
  });

  test('Délai dépassé : erreur réseau', () async {
    final api = HttpTrainingsApi(
      client: MockClient((_) => Completer<http.Response>().future),
      baseUrl: 'http://api.test',
      timeout: const Duration(milliseconds: 20),
    );
    expect(await failureOf(api), TrainingsFailure.network);
  });

  test('L\'erreur ne contient ni le jeton ni la compétence', () async {
    // Réponse piégée qui recopie le jeton et une compétence.
    final api = HttpTrainingsApi(
      client: MockClient((_) async => http.Response('$token Power BI', 500)),
      baseUrl: 'http://api.test',
    );
    try {
      await api.fetch(token: token, skill: 'Power BI');
      fail('Une TrainingsException était attendue.');
    } on TrainingsException catch (e) {
      for (final text in [e.toString(), e.message]) {
        expect(text, isNot(contains(token)));
        expect(text, isNot(contains('Power BI')));
      }
    }
  });

  test('Messages en français, sans mot interdit', () {
    for (final failure in TrainingsFailure.values) {
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
