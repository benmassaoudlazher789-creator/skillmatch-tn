import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/cv_picker.dart';
import '../../domain/cv_file_rules.dart';

/// Bloc du fichier choisi : icône, nom, taille, et deux actions
/// (« Changer » et « Retirer »).
class CvFileTile extends StatelessWidget {
  const CvFileTile({
    super.key,
    required this.file,
    required this.onChange,
    required this.onRemove,
  });

  final PickedCvFile file;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.border),
      ),
      // LayoutBuilder donne la largeur disponible, pour limiter le bouton
      // « Changer » ci-dessous.
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: AppColors.emerald,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Expanded : le nom prend la place restante et se coupe avec
            // « … » s'il est trop long, au lieu de déborder.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge?.copyWith(color: AppColors.navy),
                  ),
                  Text(
                    CvFileRules.formatSize(file.sizeInBytes),
                    style: text.bodySmall?.copyWith(color: AppColors.carbon),
                  ),
                ],
              ),
            ),
            // Avec un texte très agrandi, « Changer » pourrait prendre toute
            // la largeur et faire déborder la ligne. On le limite à 40 % de
            // la place : en temps normal il est bien plus petit (aucun
            // effet), dans le cas extrême il se coupe avec « … ». Le lecteur
            // d'écran lit toujours « Changer » en entier.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
              child: TextButton(
                onPressed: onChange,
                child: const Text(
                  'Changer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              tooltip: 'Retirer le fichier',
              color: AppColors.carbon,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
