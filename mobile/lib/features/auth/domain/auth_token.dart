/// Jeton de connexion reçu de l'API (POST /auth/login).
///
/// Le jeton prouve à l'API que le candidat est connecté : quiconque le
/// possède peut agir à sa place jusqu'à son expiration. On ne l'affiche
/// donc jamais et on ne l'écrit jamais dans un log.
class AuthToken {
  const AuthToken({required this.accessToken, required this.expiresIn});

  final String accessToken;

  /// Durée de validité annoncée par l'API (60 minutes au plus).
  final Duration expiresIn;

  // Par défaut, Dart afficherait « Instance of 'AuthToken' », mais un
  // toString écrit à la main un jour pourrait inclure le jeton. On fixe
  // donc ici un texte qui le masque : un print(token) ne révèle rien.
  @override
  String toString() =>
      'AuthToken(jeton masqué, valable ${expiresIn.inMinutes} min)';
}
