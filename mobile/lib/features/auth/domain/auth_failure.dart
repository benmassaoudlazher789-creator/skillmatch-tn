/// Les raisons possibles d'un échec d'inscription ou de connexion, chacune
/// avec le message montré au candidat.
///
/// Pourquoi nos propres textes plutôt que ceux envoyés par l'API ? Ils sont
/// toujours en français, toujours compréhensibles, et les tests peuvent les
/// retrouver. Seule exception : les erreurs de formulaire (400), où l'API
/// précise le champ en cause (voir AuthException.serverMessage).
enum AuthFailure {
  /// 401 : l'API ne dit pas si c'est l'e-mail ou le mot de passe qui est faux,
  /// et nous non plus (sinon on aiderait à deviner les adresses inscrites).
  invalidCredentials('E-mail ou mot de passe incorrect.'),

  /// 409 : l'adresse est déjà utilisée par un compte.
  emailAlreadyUsed(
    'Un compte existe déjà avec cette adresse. '
    'Connectez-vous ou utilisez une autre adresse.',
  ),

  /// 429 : l'API limite le nombre d'essais par minute.
  tooManyAttempts(
    'Trop de tentatives. Patientez une minute avant de réessayer.',
  ),

  /// Pas de réponse : pas d'Internet, API arrêtée ou délai dépassé.
  network(
    "Impossible de joindre le serveur. Assurez-vous d'être connecté à "
    'Internet, puis réessayez.',
  ),

  /// 400 sans message exploitable.
  invalidInput(
    'Certaines informations ne sont pas valides. Corrigez le formulaire.',
  ),

  /// Connexion acceptée, mais le jeton n'a pas pu être rangé sur l'appareil.
  storage(
    "Connexion réussie, mais la session n'a pas pu être enregistrée sur "
    'cet appareil. Réessayez.',
  ),

  /// Tout le reste (500, réponse illisible…).
  unknown('Une erreur inattendue est survenue. Réessayez dans un instant.');

  const AuthFailure(this.message);

  final String message;
}

/// Erreur levée par AuthApi et AuthSession.
///
/// Elle ne contient JAMAIS le corps de la réponse ni l'erreur d'origine :
/// la réponse de connexion contient le jeton, et un message d'erreur peut
/// finir dans un log ou à l'écran.
class AuthException implements Exception {
  const AuthException(this.failure, {this.serverMessage});

  final AuthFailure failure;

  /// Message de validation renvoyé par l'API (400 seulement), ou null.
  final String? serverMessage;

  /// Texte à afficher au candidat.
  String get message => serverMessage ?? failure.message;

  // Seulement le nom de la raison : rien qui vienne de la réponse.
  @override
  String toString() => 'AuthException(${failure.name})';
}
