import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Bouton principal d'Inscription et de Connexion.
///
/// Pendant l'envoi, il est désactivé (onPressed à null) et la flèche est
/// remplacée par un petit indicateur de chargement. Deux raisons :
/// le candidat voit que sa demande part, et un double appui n'envoie pas
/// deux requêtes (ce qui consommerait deux essais sur la limite de l'API).
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  /// Clé de l'indicateur, pour les tests.
  static const loadingKey = Key('auth_submit_loading');

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flexible : sur un écran étroit, le texte passe à la ligne au lieu
          // de faire déborder la ligne.
          Flexible(child: Text(label, textAlign: TextAlign.center)),
          const SizedBox(width: AppSpacing.sm),
          if (isLoading)
            const SizedBox.square(
              key: loadingKey,
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                semanticsLabel: 'Envoi en cours',
              ),
            )
          else
            const Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }
}
