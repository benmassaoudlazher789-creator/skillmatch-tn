import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:skillmatch_tn/features/cv/data/cv_api.dart';
import 'package:skillmatch_tn/features/cv/domain/cv_failure.dart';

// Tests de HttpCvApi avec MockClient (fourni par le paquet http) : il
// répond à la place du serveur, sans aucun appel réseau réel.
void main() {
  // Valeurs fictives, propres aux tests.
  const token = 'jeton-test-789';
  final bytes = Uint8List.fromList(utf8.encode('%PDF-contenu-secret-test'));

  http.Response json(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  HttpCvApi apiWith(
    MockClientHandler handler, {
    String baseUrl = 'http://api.test',
  }) => HttpCvApi(client: MockClient(handler), baseUrl: baseUrl);

  Future<List<String>> analyze(HttpCvApi api) =>
      api.analyze(token: token, bytes: bytes, extension: 'pdf');

  /// Lance l'analyse et renvoie la raison de l'échec.
  Future<CvFailure> failureOf(HttpCvApi api) async {
    try {
      await analyze(api);
    } on CvException catch (e) {
      return e.failure;
    }
    fail('Une CvException était attendue.');
  }

  test('Envoie un formulaire multipart avec le jeton et le fichier', () async {
    late http.Request sent;
    final api = apiWith((request) async {
      sent = request;
      return json(200, {
        'skills': ['Flutter', 'SQL'],
      });
    });

    final skills = await analyze(api);

    expect(skills, ['Flutter', 'SQL']);
    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'http://api.test/cv');
    expect(sent.headers['Authorization'], 'Bearer $token');
    expect(sent.headers['content-type'], startsWith('multipart/form-data'));
    // latin1 : lit le corps octet par octet, sans erreur d'encodage.
    final body = latin1.decode(sent.bodyBytes);
    expect(body, contains('name="file"'));
    // Nom neutre : le vrai nom du fichier n'est jamais envoyé.
    expect(body, contains('filename="cv.pdf"'));
    expect(body, contains('%PDF-contenu-secret-test'));
  });

  test('Le « / » final de l\'adresse est retiré', () async {
    late Uri url;
    final api = apiWith((request) async {
      url = request.url;
      return json(200, {'skills': <String>[]});
    }, baseUrl: 'http://api.test/');

    expect(await analyze(api), isEmpty);
    expect(url.toString(), 'http://api.test/cv');
  });

  test('Réponse 200 sans liste lisible : erreur inattendue', () async {
    final api = apiWith((_) async => http.Response('pas du json', 200));
    expect(await failureOf(api), CvFailure.unknown);
  });

  group('Codes d\'erreur traduits en messages français', () {
    final cases = <(int, String?, CvFailure)>[
      (400, 'empty', CvFailure.empty),
      (400, 'no_file', CvFailure.invalidRequest),
      (400, null, CvFailure.invalidRequest),
      (401, null, CvFailure.sessionExpired),
      (413, 'too_large', CvFailure.tooLarge),
      (415, 'unsupported_type', CvFailure.unsupportedType),
      (422, 'password_protected', CvFailure.passwordProtected),
      (422, 'no_text', CvFailure.noText),
      (422, 'unreadable', CvFailure.unreadable),
      (422, null, CvFailure.unreadable),
      (429, null, CvFailure.tooManyRequests),
      (500, null, CvFailure.unknown),
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
    expect(await failureOf(api), CvFailure.network);
  });

  test('Délai dépassé : erreur réseau', () async {
    // Le serveur ne répond jamais ; la limite est réduite pour le test.
    final api = HttpCvApi(
      client: MockClient((_) => Completer<http.Response>().future),
      baseUrl: 'http://api.test',
      timeout: const Duration(milliseconds: 20),
    );
    expect(await failureOf(api), CvFailure.network);
  });

  test('L\'erreur ne contient ni le jeton ni le contenu du CV', () async {
    // Réponse piégée qui recopie le jeton et le contenu : rien ne doit
    // en ressortir dans l'erreur.
    final api = apiWith(
      (_) async => http.Response('$token %PDF-contenu-secret-test', 500),
    );
    try {
      await analyze(api);
      fail('Une CvException était attendue.');
    } on CvException catch (e) {
      for (final text in [e.toString(), e.message]) {
        expect(text, isNot(contains(token)));
        expect(text, isNot(contains('contenu-secret')));
      }
    }
  });

  test('Tous les messages sont en français et sans mot interdit', () {
    for (final failure in CvFailure.values) {
      expect(failure.message, isNotEmpty);
      for (final word in [
        'vérifi',
        'certifi',
        'prouv',
        'passeport',
        'défi',
        'chiffré',
        'robot',
      ]) {
        expect(failure.message, isNot(contains(word)), reason: failure.name);
      }
    }
  });
}
