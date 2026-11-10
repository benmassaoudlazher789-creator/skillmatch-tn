import 'package:flutter/material.dart';

import '../../cv/presentation/cv_upload_screen.dart';

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

/// Affiche un message en bas de l'écran, en remplaçant le précédent.
void showAuthMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
