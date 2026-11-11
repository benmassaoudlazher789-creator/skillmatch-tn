import 'package:flutter/material.dart';

import '../../cv/presentation/cv_upload_screen.dart';
import '../domain/auth_failure.dart';
import 'login_screen.dart';

/// Après une connexion réussie, ouvre l'écran Ajout du CV.
///
/// pushAndRemoveUntil retire tous les écrans précédents (Bienvenue,
/// Connexion…) : le bouton retour ne ramène donc pas à un formulaire de
/// connexion alors que le candidat est déjà connecté.
void openHomeAfterSignIn(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const CvUploadScreen()),
    (_) => false,
  );
}

/// Quand l'API refuse le jeton (401), ouvre la Connexion avec le message
/// « Session expirée, reconnectez-vous ».
///
/// Là aussi, tous les écrans précédents sont retirés : sans jeton valable,
/// le bouton retour ne doit pas ramener à des écrans qui en ont besoin.
/// Le jeton a déjà été effacé par CvAnalysisService.
void openLoginAfterSessionExpired(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => const LoginScreen(initialMessage: sessionExpiredMessage),
    ),
    (_) => false,
  );
}

/// Affiche un message en bas de l'écran, en remplaçant le précédent.
void showAuthMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
