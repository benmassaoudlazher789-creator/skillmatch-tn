import '../../auth/data/token_store.dart';
import '../domain/offer.dart';
import '../domain/offers_failure.dart';
import 'offers_api.dart';

/// Lit le jeton, puis demande les offres à l'API.
///
/// Même règle que CvAnalysisService : sans jeton, ou si l'API répond 401
/// (jeton expiré), le jeton stocké est effacé et l'écran renvoie vers la
/// Connexion.
class OffersService {
  const OffersService({required this.api, required this.tokenStore});

  final OffersApi api;
  final TokenStore tokenStore;

  /// Offres classées pour [skills]. Lève une OffersException.
  Future<List<Offer>> fetch(List<String> skills) async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      await _forgetToken();
      throw const OffersException(OffersFailure.sessionExpired);
    }

    try {
      return await api.fetch(token: token, skills: skills);
    } on OffersException catch (e) {
      if (e.failure == OffersFailure.sessionExpired) await _forgetToken();
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
final OffersService defaultOffersService = OffersService(
  api: HttpOffersApi(),
  tokenStore: const SecureTokenStore(),
);
