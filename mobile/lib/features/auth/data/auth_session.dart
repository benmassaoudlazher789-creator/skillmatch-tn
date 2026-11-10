import '../domain/auth_failure.dart';
import 'auth_api.dart';
import 'token_store.dart';

/// Regroupe les deux étapes d'une connexion : demander le jeton à l'API,
/// puis le ranger sur l'appareil. Inscription et Connexion s'en servent
/// toutes les deux, sans répéter ce code.
class AuthSession {
  const AuthSession({required this.api, required this.tokenStore});

  final AuthApi api;
  final TokenStore tokenStore;

  /// Crée le compte. Pas de jeton ici : l'API n'en donne qu'à la connexion.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) => api.register(fullName: fullName, email: email, password: password);

  /// Connecte le candidat et garde le jeton. Lève une AuthException.
  Future<void> login({required String email, required String password}) async {
    final token = await api.login(email: email, password: password);
    try {
      await tokenStore.save(token.accessToken);
    } catch (_) {
      // L'erreur d'origine est volontairement jetée : on ne veut aucun
      // détail technique à l'écran, et rien qui puisse citer le jeton.
      throw const AuthException(AuthFailure.storage);
    }
  }
}

/// Session utilisée quand un écran n'en reçoit pas (donc hors tests).
///
/// Une variable globale « final » n'est créée qu'à sa première lecture :
/// le client http n'existe donc que si le candidat envoie un formulaire,
/// et il est partagé par tous les écrans au lieu d'en créer un par écran.
final AuthSession defaultAuthSession = AuthSession(
  api: HttpAuthApi(),
  tokenStore: const SecureTokenStore(),
);
