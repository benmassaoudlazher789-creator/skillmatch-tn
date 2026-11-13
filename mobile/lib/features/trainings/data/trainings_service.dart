import '../../auth/data/token_store.dart';
import '../domain/training.dart';
import '../domain/trainings_failure.dart';
import 'trainings_api.dart';

/// Lit le jeton, puis demande les formations à l'API.
///
/// Même règle que OffersService : sans jeton, ou si l'API répond 401 (jeton
/// expiré), le jeton stocké est effacé et l'écran renvoie vers la Connexion.
class TrainingsService {
  const TrainingsService({required this.api, required this.tokenStore});

  final TrainingsApi api;
  final TokenStore tokenStore;

  /// Formations pour [skill]. Lève une TrainingsException.
  Future<List<Training>> fetch(String skill) async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      await _forgetToken();
      throw const TrainingsException(TrainingsFailure.sessionExpired);
    }

    try {
      return await api.fetch(token: token, skill: skill);
    } on TrainingsException catch (e) {
      if (e.failure == TrainingsFailure.sessionExpired) await _forgetToken();
      rethrow;
    }
  }

  /// Stockage illisible = comme s'il n'y avait pas de jeton.
  Future<String?> _readToken() async {
    try {
      return await tokenStore.read();
    } catch (_) {
      return null;
    }
  }

  /// Un échec de l'effacement ne doit pas masquer « session expirée ».
  Future<void> _forgetToken() async {
    try {
      await tokenStore.clear();
    } catch (_) {}
  }
}

/// Service utilisé quand un écran n'en reçoit pas (donc hors tests).
/// Créé seulement à sa première lecture.
final TrainingsService defaultTrainingsService = TrainingsService(
  api: HttpTrainingsApi(),
  tokenStore: const SecureTokenStore(),
);
