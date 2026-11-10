import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:skillmatch_tn/features/auth/data/auth_api.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_failure.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_token.dart';

import 'support/fake_auth.dart';

// Tests de HttpAuthApi sans réseau : MockClient (fourni par le paquet http)
// joue le rôle du serveur et répond ce que chaque test demande.

/// Adresse fictive, avec un « / » final pour vérifier qu'il est retiré.
const _baseUrl = 'http://api.exemple.test/';

/// Valeur fictive qui joue le rôle d'un jeton secret.
const _secretToken = 'jeton-secret-exemple-XYZ';

HttpAuthApi _api(
  MockClientHandler handler, {
  Duration timeout = const Duration(seconds: 15),
}) => HttpAuthApi(
  client: MockClient(handler),
  baseUrl: _baseUrl,
  timeout: timeout,
);

/// Réponse JSON encodée en UTF-8, comme celle de l'API.
http.Response _json(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Exécute l'appel et renvoie l'AuthException levée (échec si aucune).
Future<AuthException> _failureOf(Future<Object?> Function() call) async {
  try {
    await call();
  } on AuthException catch (e) {
    return e;
  }
  fail('Une AuthException était attendue.');
}

Future<AuthToken> _login(HttpAuthApi api) =>
    api.login(email: 'candidat@exemple.com', password: 'Exemple-123');

Future<void> _register(HttpAuthApi api) => api.register(
  fullName: 'Candidat Test',
  email: 'candidat@exemple.com',
  password: 'Exemple-123',
);

void main() {
  group('login', () {
    test('200 : envoie un POST JSON et renvoie le jeton', () async {
      late http.Request sent;
      final api = _api((request) async {
        sent = request;
        return _json({
          'accessToken': _secretToken,
          'tokenType': 'Bearer',
          'expiresIn': 3600,
        }, 200);
      });

      final token = await _login(api);

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'http://api.exemple.test/auth/login');
      expect(sent.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(sent.body), {
        'email': 'candidat@exemple.com',
        'password': 'Exemple-123',
      });
      expect(token.accessToken, _secretToken);
      expect(token.expiresIn, const Duration(hours: 1));
    });

    test('401 : identifiants incorrects', () async {
      final api = _api(
        (_) async => _json({'title': 'E-mail ou mot de passe incorrect.'}, 401),
      );
      final e = await _failureOf(() => _login(api));
      expect(e.failure, AuthFailure.invalidCredentials);
    });

    test('429 : trop de tentatives', () async {
      final api = _api((_) async => _json({'title': 'Trop.'}, 429));
      final e = await _failureOf(() => _login(api));
      expect(e.failure, AuthFailure.tooManyAttempts);
    });

    test('500 : erreur inconnue', () async {
      final api = _api((_) async => http.Response('', 500));
      final e = await _failureOf(() => _login(api));
      expect(e.failure, AuthFailure.unknown);
    });

    test('200 sans jeton : erreur inconnue', () async {
      final api = _api((_) async => _json({'tokenType': 'Bearer'}, 200));
      final e = await _failureOf(() => _login(api));
      expect(e.failure, AuthFailure.unknown);
    });

    test("200 illisible : l'erreur ne recopie jamais le jeton", () async {
      // JSON coupé en plein milieu : jsonDecode échoue, et le message de sa
      // FormatException contiendrait ce texte, donc le jeton.
      final api = _api(
        (_) async => http.Response('{"accessToken": "$_secretToken"', 200),
      );
      final e = await _failureOf(() => _login(api));

      expect(e.failure, AuthFailure.unknown);
      expect(e.toString(), isNot(contains(_secretToken)));
      expect(e.message, isNot(contains(_secretToken)));
    });
  });

  group('register', () {
    test('201 : envoie fullName, email et password', () async {
      late http.Request sent;
      final api = _api((request) async {
        sent = request;
        return _json({'id': 'x', 'fullName': 'x', 'email': 'x'}, 201);
      });

      await _register(api);

      expect(sent.method, 'POST');
      expect(sent.url.toString(), 'http://api.exemple.test/auth/register');
      expect(jsonDecode(sent.body), {
        'fullName': 'Candidat Test',
        'email': 'candidat@exemple.com',
        'password': 'Exemple-123',
      });
    });

    test('409 : adresse déjà utilisée', () async {
      final api = _api((_) async => _json({'title': 'Déjà.'}, 409));
      final e = await _failureOf(() => _register(api));
      expect(e.failure, AuthFailure.emailAlreadyUsed);
    });

    test("400 : reprend le message de validation de l'API", () async {
      final api = _api(
        (_) async => _json({
          'errors': {
            'password': ['Le mot de passe est trop long.'],
          },
        }, 400),
      );
      final e = await _failureOf(() => _register(api));

      expect(e.failure, AuthFailure.invalidInput);
      expect(e.message, 'Le mot de passe est trop long.');
    });

    test('400 sans détail : message générique', () async {
      final api = _api((_) async => http.Response('', 400));
      final e = await _failureOf(() => _register(api));

      expect(e.failure, AuthFailure.invalidInput);
      expect(e.message, AuthFailure.invalidInput.message);
    });
  });

  group('réseau', () {
    test('serveur injoignable : erreur réseau', () async {
      final api = _api((_) async => throw http.ClientException('injoignable'));
      final e = await _failureOf(() => _login(api));
      expect(e.failure, AuthFailure.network);
    });

    test('délai dépassé : erreur réseau', () async {
      // Le faux serveur ne répond jamais ; délai très court pour le test.
      final api = _api(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 10),
      );
      final e = await _failureOf(() => _login(api));
      expect(e.failure, AuthFailure.network);
    });
  });

  group('messages et confidentialité', () {
    test('401, 409, 429 et réseau ont des messages distincts', () {
      final messages = {
        AuthFailure.invalidCredentials.message,
        AuthFailure.emailAlreadyUsed.message,
        AuthFailure.tooManyAttempts.message,
        AuthFailure.network.message,
      };
      expect(messages, hasLength(4));
    });

    test('aucun message ne contient de mot interdit', () {
      const forbidden = [
        'vérifié',
        'certifié',
        'prouvé',
        'passeport',
        'défi',
        'chiffré',
        'robot',
      ];
      for (final failure in AuthFailure.values) {
        for (final word in forbidden) {
          expect(
            failure.message.toLowerCase(),
            isNot(contains(word)),
            reason: '${failure.name} : $word',
          );
        }
      }
    });

    test('AuthToken.toString masque le jeton', () {
      const token = AuthToken(
        accessToken: _secretToken,
        expiresIn: Duration(minutes: 60),
      );
      expect(token.toString(), isNot(contains(_secretToken)));
    });
  });

  group('AuthSession', () {
    test('login range le jeton reçu', () async {
      final (:session, :api, :store) = fakeSession();

      await session.login(email: 'candidat@exemple.com', password: 'abc');

      expect(api.loginCalls, hasLength(1));
      expect(store.token, fakeToken.accessToken);
    });

    test('stockage en échec : erreur « storage », sans le jeton', () async {
      final (:session, api: _, :store) = fakeSession();
      store.failOnSave = true;

      final e = await _failureOf(
        () => session.login(email: 'candidat@exemple.com', password: 'abc'),
      );

      expect(e.failure, AuthFailure.storage);
      expect(e.toString(), isNot(contains(fakeToken.accessToken)));
      expect(store.token, isNull);
    });

    test("l'API en échec : rien n'est rangé", () async {
      final (:session, :api, :store) = fakeSession();
      api.onLogin = () async =>
          throw const AuthException(AuthFailure.invalidCredentials);

      final e = await _failureOf(
        () => session.login(email: 'candidat@exemple.com', password: 'abc'),
      );

      expect(e.failure, AuthFailure.invalidCredentials);
      expect(store.token, isNull);
    });
  });
}
