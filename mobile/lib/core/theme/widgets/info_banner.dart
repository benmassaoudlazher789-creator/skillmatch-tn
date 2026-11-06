import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

/// Bandeau d'information : icône « i » et texte.
///
/// Partagé par les écrans Offres et Formations (auparavant privé dans
/// l'écran Offres). Deux constructeurs pour deux usages :
///   InfoBanner.example('…') // ambre : « ce sont des données d'exemple »
///   InfoBanner.neutral('…') // blanc : simple explication
class InfoBanner extends StatelessWidget {
  const InfoBanner.example(this.text, {super.key})
    : background = AppColors.amberSoft,
      foreground = AppColors.onAmberSoft,
      border = AppColors.amber;

  const InfoBanner.neutral(this.text, {super.key})
    : background = AppColors.white,
      foreground = AppColors.carbon,
      border = AppColors.border;

  final String text;
  final Color background;
  final Color foreground;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          // Expanded : le texte passe à la ligne au lieu de déborder.
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
