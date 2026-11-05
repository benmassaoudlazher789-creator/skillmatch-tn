import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Ligne « question + lien » en bas des écrans de compte, par exemple
/// « Déjà inscrit ? Se connecter » ou « Pas de compte ? Créer un compte ».
///
/// Wrap passe à la ligne si l'écran est très étroit ou si le texte est
/// agrandi dans les réglages du téléphone.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: text.bodyMedium?.copyWith(color: AppColors.carbon),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.emerald,
            // 48 px de zone tactile (le thème met 40 pour les boutons
            // utilitaires).
            minimumSize: const Size(
              kMinInteractiveDimension,
              kMinInteractiveDimension,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
