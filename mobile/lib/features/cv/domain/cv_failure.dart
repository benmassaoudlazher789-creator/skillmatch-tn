import '../../auth/domain/auth_failure.dart';

/// Les raisons possibles d'un échec de l'analyse du CV, chacune avec le
/// message montré au candidat.
///
/// Comme pour AuthFailure : nos propres textes, toujours en français, plutôt
/// que ceux de l'API. L'API renvoie un « code » stable (« no_text »…) qui
/// nous sert seulement à choisir le bon message.
enum CvFailure {
  /// 401, ou aucun jeton sur l'appareil : il faut se reconnecter.
  sessionExpired(sessionExpiredMessage),

  /// 400 « empty » (ou fichier vide lu sur le téléphone).
  empty('Ce fichier est vide. Choisissez un autre fichier.'),

  /// 400 d'une autre sorte : la requête elle-même était mal formée. Ce n'est
  /// pas la faute du candidat ; un nouvel essai peut suffire.
  invalidRequest("L'envoi du CV n'a pas abouti. Réessayez."),

  /// 413 : plus de 5 Mo (le fichier a pu changer depuis qu'il a été choisi).
  tooLarge('Fichier trop volumineux : la taille maximale est de 5 Mo.'),

  /// 415 : le contenu n'est ni un PDF ni un DOCX, même si le nom le dit.
  unsupportedType(
    "Ce fichier n'est pas un vrai PDF ou DOCX. Enregistrez votre CV en PDF "
    'ou en DOCX, puis réessayez.',
  ),

  /// 422 « password_protected ».
  passwordProtected(
    'Ce fichier est protégé par un mot de passe. Envoyez une version sans '
    'protection.',
  ),

  /// 422 « no_text » : souvent un CV scanné (une simple image).
  noText(
    "Aucun texte trouvé dans ce fichier. S'il s'agit d'un CV scanné (une "
    'image), envoyez une version texte en PDF ou en DOCX.',
  ),

  /// 422 « unreadable » ou autre 422 : fichier abîmé ou mal enregistré.
  unreadable(
    'Impossible de lire ce fichier. Enregistrez-le de nouveau en PDF ou en '
    'DOCX, puis réessayez.',
  ),

  /// 429 : l'API limite le nombre d'analyses par minute.
  tooManyRequests(
    "Trop d'analyses en peu de temps. Patientez une minute avant de "
    'réessayer.',
  ),

  /// Pas de réponse : pas d'Internet, API arrêtée ou délai dépassé.
  network(
    "Impossible de joindre le serveur. Assurez-vous d'être connecté à "
    'Internet, puis réessayez.',
  ),

  /// Le téléphone n'a pas pu relire le fichier choisi (déplacé, supprimé…).
  fileRead(
    "Impossible de relire ce fichier sur votre téléphone. Choisissez-le de "
    'nouveau.',
  ),

  /// Tout le reste (500, réponse illisible…).
  unknown('Une erreur inattendue est survenue. Réessayez dans un instant.');

  const CvFailure(this.message);

  final String message;
}

/// Erreur levée par CvApi et CvAnalysisService.
///
/// Elle ne contient JAMAIS le jeton, le contenu du CV, le corps de la
/// réponse ni l'erreur d'origine : un message d'erreur peut finir dans un
/// log ou à l'écran.
class CvException implements Exception {
  const CvException(this.failure);

  final CvFailure failure;

  String get message => failure.message;

  // Seulement le nom de la raison : rien qui vienne de la requête ou de la
  // réponse.
  @override
  String toString() => 'CvException(${failure.name})';
}
