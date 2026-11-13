import '../../auth/domain/auth_failure.dart';

/// Les raisons possibles d'un échec du chargement des formations, chacune
/// avec le message montré au candidat (même principe que OffersFailure).
enum TrainingsFailure {
  /// 401, ou aucun jeton sur l'appareil : il faut se reconnecter.
  sessionExpired(sessionExpiredMessage),

  /// 400 « skill_too_long » : 40 caractères au plus.
  skillTooLong(
    'Cette compétence est trop longue (40 caractères au plus) pour chercher '
    'des formations.',
  ),

  /// Pas de réponse : pas d'Internet, API arrêtée ou délai dépassé.
  network(
    "Impossible de joindre le serveur. Assurez-vous d'être connecté à "
    'Internet, puis réessayez.',
  ),

  /// Tout le reste (500, réponse illisible, et les erreurs 400 que
  /// l'application n'envoie jamais : compétence absente ou répétée).
  unknown('Une erreur inattendue est survenue. Réessayez dans un instant.');

  const TrainingsFailure(this.message);

  final String message;
}

/// Erreur levée par TrainingsApi et TrainingsService.
///
/// Elle ne contient JAMAIS le jeton, la compétence envoyée, le corps de la
/// réponse ni l'erreur d'origine.
class TrainingsException implements Exception {
  const TrainingsException(this.failure);

  final TrainingsFailure failure;

  String get message => failure.message;

  @override
  String toString() => 'TrainingsException(${failure.name})';
}
