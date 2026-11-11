import '../../auth/domain/auth_failure.dart';

/// Les raisons possibles d'un échec du chargement des offres, chacune avec
/// le message montré au candidat (même principe que CvFailure).
enum OffersFailure {
  /// 401, ou aucun jeton sur l'appareil : il faut se reconnecter.
  sessionExpired(sessionExpiredMessage),

  /// 400 « too_many_skills » : l'API accepte 50 compétences au plus.
  tooManySkills(
    'Trop de compétences pour la recherche : gardez-en 50 au plus, puis '
    'réessayez.',
  ),

  /// 400 « skill_too_long » : 40 caractères au plus par compétence.
  skillTooLong(
    'Une compétence est trop longue (40 caractères au plus). Corrigez-la, '
    'puis réessayez.',
  ),

  /// Pas de réponse : pas d'Internet, API arrêtée ou délai dépassé.
  network(
    "Impossible de joindre le serveur. Assurez-vous d'être connecté à "
    'Internet, puis réessayez.',
  ),

  /// Tout le reste (500, réponse illisible…).
  unknown('Une erreur inattendue est survenue. Réessayez dans un instant.');

  const OffersFailure(this.message);

  final String message;
}

/// Erreur levée par OffersApi et OffersService.
///
/// Elle ne contient JAMAIS le jeton, les compétences envoyées, le corps de
/// la réponse ni l'erreur d'origine.
class OffersException implements Exception {
  const OffersException(this.failure);

  final OffersFailure failure;

  String get message => failure.message;

  @override
  String toString() => 'OffersException(${failure.name})';
}
