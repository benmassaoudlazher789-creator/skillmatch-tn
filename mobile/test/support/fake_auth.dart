import 'dart:async';

import 'package:skillmatch_tn/features/auth/data/auth_api.dart';
import 'package:skillmatch_tn/features/auth/data/auth_session.dart';
import 'package:skillmatch_tn/features/auth/data/token_store.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_token.dart';

// Faux objets partagés par les tests d'écrans : aucun appel réseau, aucun
// accès au stockage du téléphone. Valeurs fictives, propres aux tests.

/// Jeton d'exemple renvoyé par le faux AuthApi.
const fakeToken = AuthToken(
  accessToken: 'jeton-exemple-123',
  expiresIn: Duration(minutes: 60),
);

/// Faux AuthApi : retient les appels et répond ce que le test demande.
class FakeAuthApi implements AuthApi {
  /// Réponse de register. Par défaut : succès immédiat.
  Future<void> Function() onRegister = () async {};

  /// Réponse de login. Par défaut : le jeton d'exemple.
  Future<AuthToken> Function() onLogin = () async => fakeToken;

  final registerCalls = <({String fullName, String email, String password})>[];
  final loginCalls = <({String email, String password})>[];

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    registerCalls.add((fullName: fullName, email: email, password: password));
    return onRegister();
  }

  @override
  Future<AuthToken> login({required String email, required String password}) {
    loginCalls.add((email: email, password: password));
    return onLogin();
  }
}

/// Rangement en mémoire, à la place de flutter_secure_storage.
class MemoryTokenStore implements TokenStore {
  String? token;

  /// Vrai pour simuler un stockage indisponible.
  bool failOnSave = false;

  @override
  Future<void> save(String token) async {
    if (failOnSave) throw StateError('stockage indisponible (test)');
    this.token = token;
  }

  @override
  Future<String?> read() async => token;

  @override
  Future<void> clear() async => token = null;
}

/// Session prête pour un test d'écran.
({AuthSession session, FakeAuthApi api, MemoryTokenStore store}) fakeSession() {
  final api = FakeAuthApi();
  final store = MemoryTokenStore();
  return (
    session: AuthSession(api: api, tokenStore: store),
    api: api,
    store: store,
  );
}
