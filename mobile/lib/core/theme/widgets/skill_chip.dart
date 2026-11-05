import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_spacing.dart';

/// Les trois sortes de puces décrites dans DESIGN.md.
enum SkillChipKind { acquired, missing, neutral }

/// Puce de compétence : verte si l'outil est acquis, rouge s'il manque.
///
/// On écrit notre propre widget plutôt que d'utiliser Chip, car les puces
/// "acquis" et "manquant" ont chacune leurs couleurs, leur bordure et leur
/// icône. Un seul widget avec trois constructeurs garde les écrans simples :
///   SkillChip.acquired('Flutter')
///   SkillChip.missing('Docker')
class SkillChip extends StatelessWidget {
  const SkillChip.acquired(this.label, {super.key})
      : kind = SkillChipKind.acquired;
  const SkillChip.missing(this.label, {super.key})
      : kind = SkillChipKind.missing;
  const SkillChip.neutral(this.label, {super.key})
      : kind = SkillChipKind.neutral;

  final String label;
  final SkillChipKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, icon) = switch (kind) {
      SkillChipKind.acquired => (
          AppColors.skillAcquiredBg,
          AppColors.skillAcquiredText,
          null,
          Icons.check_rounded,
        ),
      SkillChipKind.missing => (
          AppColors.skillMissingBg,
          AppColors.skillMissingText,
          AppColors.skillMissingBorder,
          Icons.add_rounded,
        ),
      SkillChipKind.neutral => (
          AppColors.white,
          AppColors.carbon,
          AppColors.border,
          null,
        ),
    };

    final radius = kind == SkillChipKind.neutral
        ? AppRadius.small
        : AppRadius.chip;

    return Semantics(
      label: switch (kind) {
        SkillChipKind.acquired => 'Compétence acquise : $label',
        SkillChipKind.missing => 'Compétence manquante : $label',
        SkillChipKind.neutral => label,
      },
      excludeSemantics: true,
      child: Container(
        constraints: kind == SkillChipKind.neutral
            ? const BoxConstraints(minHeight: 36)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
