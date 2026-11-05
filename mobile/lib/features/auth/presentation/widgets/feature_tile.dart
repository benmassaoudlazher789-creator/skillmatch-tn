import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Une tuile "avantage" de l'écran Bienvenue : point ambre, titre, texte.
///
/// Extraite dans son propre widget car elle est répétée trois fois :
/// on écrit le style une fois, on change seulement le texte.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md), // p-3 = 12
      decoration: BoxDecoration(
        color: AppColors.tileOnNavy.withValues(alpha: 0.40), // bg-primary/40
        borderRadius: BorderRadius.circular(AppRadius.tile), // 8
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4), // mt-1
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.amberLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.titleMedium?.copyWith(color: AppColors.onNavy),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: text.bodySmall?.copyWith(color: AppColors.onNavyMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
