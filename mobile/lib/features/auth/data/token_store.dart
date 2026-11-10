import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Rangement du jeton de connexion sur l'appareil.
///
/// Interface pour la même raison que AuthApi : les tests utilisent un
/// rangement en mémoire, sans toucher au vrai stockage du téléphone.
abstract interface class TokenStore {
  Future<void> save(String token);

  /// Renvoie null si aucun jeton n'est enregistré.
  Future<String?> read();

  Future<void> clear();
}

/// Vraie version, basée sur flutter_secure_storage.
/// C'est le seul fichier de l'application qui importe ce paquet.
///
/// Pourquoi ce paquet plutôt que shared_preferences ? Sur Android et iOS,
/// il range la valeur dans le coffre du système (Keystore, Trousseau), que
/// les autres applications ne peuvent pas lire. Dans Chrome, il n'existe
/// pas de tel coffre : la protection y est plus faible (stockage du
/// navigateur). C'est acceptable pour le développement.
class SecureTokenStore implements TokenStore {
  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _key = 'skillmatch_access_token';

  @override
  Future<void> save(String token) => _storage.write(key: _key, value: token);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
