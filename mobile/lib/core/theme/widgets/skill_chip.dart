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
///   SkillChip.acquired('Git', onRemove: () => ...) // avec un bouton ×
///   SkillChip.missing('Docker', onTap: () => ...)  // toute la puce se touche
class SkillChip extends StatelessWidget {
  const SkillChip.acquired(this.label, {super.key, this.onRemove, this.onTap})
    : kind = SkillChipKind.acquired;
  const SkillChip.missing(this.label, {super.key, this.onRemove, this.onTap})
    : kind = SkillChipKind.missing;
  const SkillChip.neutral(this.label, {super.key, this.onRemove, this.onTap})
    : kind = SkillChipKind.neutral;

  final String label;
  final SkillChipKind kind;

  /// Si fourni, la puce affiche un petit bouton × (infobulle
  /// « Retirer <label> ») qui appelle cette fonction.
  final VoidCallback? onRemove;

  /// Si fourni, toute la puce réagit au toucher (avec l'effet d'encre de
  /// Material) et le lecteur d'écran l'annonce comme un bouton.
  final VoidCallback? onTap;

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
    final remove = onRemove;
    final tap = onTap;
    final borderRadius = BorderRadius.circular(radius);

    // Le contenu (icône, texte, bouton ×) est le même dans les deux cas ;
    // seul l'« emballage » change selon que la puce se touche ou non.
    final content = Container(
      // Une puce qui se touche fait au moins 36 px de haut : plus facile à
      // viser du doigt.
      constraints:
          kind == SkillChipKind.neutral || remove != null || tap != null
          ? const BoxConstraints(minHeight: 36)
          : null,
      // Avec le bouton ×, on réduit la marge de droite et en hauteur : le
      // bouton a déjà sa propre zone de toucher de 32 px.
      padding: remove == null
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.fromLTRB(12, 2, 2, 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          // Flexible : un nom long passe à la ligne au lieu de déborder
          // sur un écran étroit.
          Flexible(
            // Le lecteur d'écran lit « Compétence acquise : Flutter » au
            // lieu du seul texte. Seul le texte est concerné : le bouton ×
            // garde sa propre annonce (« Retirer Flutter »).
            child: Semantics(
              label: switch (kind) {
                SkillChipKind.acquired => 'Compétence acquise : $label',
                SkillChipKind.missing => 'Compétence manquante : $label',
                SkillChipKind.neutral => label,
              },
              excludeSemantics: true,
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: fg),
              ),
            ),
          ),
          if (remove != null)
            IconButton(
              onPressed: remove,
              tooltip: 'Retirer $label',
              icon: const Icon(Icons.close_rounded),
              iconSize: 16,
              color: fg,
              padding: EdgeInsets.zero,
              // 32 × 32 px : assez grand pour le doigt, sans rendre la
              // puce beaucoup plus haute que la maquette.
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );

    if (tap == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: borderRadius,
          border: border == null ? null : Border.all(color: border),
        ),
        child: content,
      );
    }

    // Puce qui se touche : le fond est peint par Material (et non par une
    // BoxDecoration) pour que l'effet d'encre de l'InkWell reste visible
    // par-dessus.
    return Semantics(
      button: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: border == null ? BorderSide.none : BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: tap, child: content),
      ),
    );
  }
}
