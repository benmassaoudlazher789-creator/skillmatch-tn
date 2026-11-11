import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/widgets/skill_chip.dart';
import '../../domain/offer.dart';

/// Carte d'une offre : en-tête, score et son explication, puis les
/// compétences présentes (vert) et manquantes (rouge).
///
/// Widget sans état (StatelessWidget) : il affiche une [Offer] dont le score
/// a été calculé par le serveur, et prévient l'écran quand on touche une
/// compétence manquante.
class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer, required this.onMissingTap});

  final Offer offer;

  /// Appelée avec le nom de la compétence manquante touchée.
  final ValueChanged<String> onMissingTap;

  static const sampleBadge = "Offre d'exemple";

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      // Même carte blanche que les écrans Ajout du CV et Vos compétences.
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(text),
          const SizedBox(height: AppSpacing.md),
          // Le score a sa propre ligne, et non une place à droite du titre
          // comme dans la maquette : dans une Row, sa largeur (qui grandit
          // avec le texte agrandi) ne laissait plus de place au titre et
          // faisait déborder la carte. Align le colle à gauche sans
          // l'étirer sur toute la largeur.
          Align(alignment: Alignment.centerLeft, child: _buildScore(text)),
          const SizedBox(height: AppSpacing.sm),
          // La barre répète le pourcentage pour l'œil ; le lecteur d'écran
          // l'a déjà entendu dans la boîte du score, d'où ExcludeSemantics.
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: offer.score / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              color: AppColors.emerald,
              backgroundColor: AppColors.skillAcquiredBg,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            offer.explanation,
            style: text.bodySmall?.copyWith(color: AppColors.carbon),
          ),
          const SizedBox(height: AppSpacing.md),
          _SkillLine(
            label: 'Acquises :',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.emerald,
            emptyText: 'aucune pour le moment',
            chips: [
              for (final skill in offer.acquired) SkillChip.acquired(skill),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SkillLine(
            label: 'À apprendre :',
            icon: Icons.add_circle_outline_rounded,
            color: AppColors.skillMissingText,
            emptyText: 'aucune compétence manquante',
            chips: [
              for (final skill in offer.missing)
                SkillChip.missing(skill, onTap: () => onMissingTap(skill)),
            ],
          ),
        ],
      ),
    );
  }

  /// Icône du type, puis titre et infos. Seule l'icône a une largeur fixe
  /// (44 + 12 px) : tout le reste est dans l'Expanded et passe à la ligne.
  Widget _buildHeader(TextTheme text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Une icône selon le type, à la place des photos de la maquette
        // (on n'a pas de vraies photos d'entreprises).
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(AppRadius.media),
          ),
          child: Icon(_iconFor(offer.type), color: AppColors.navy, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        // Expanded : le texte prend la place restante et passe à la ligne
        // au lieu de déborder.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.title,
                style: text.titleMedium?.copyWith(color: AppColors.navy),
              ),
              const SizedBox(height: 2),
              Text(
                '${offer.company} · ${offer.city} · ${offer.type.label}',
                style: text.bodySmall?.copyWith(color: AppColors.carbon),
              ),
              // Badge seulement pour une offre fictive (isSample envoyé par
              // le serveur) : une vraie offre n'en porte pas.
              if (offer.isSample) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildSampleBadge(text),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Badge ambre, mêmes couleurs que le bandeau d'exemple.
  Widget _buildSampleBadge(TextTheme text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        sampleBadge,
        style: text.labelSmall?.copyWith(color: AppColors.onAmberSoft),
      ),
    );
  }

  /// Boîte du score. Le lecteur d'écran lit une phrase complète
  /// (« Correspondance : 78 % ») plutôt que « 78 % score ».
  Widget _buildScore(TextTheme text) {
    return Semantics(
      label: 'Correspondance : ${offer.score} %',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.skillAcquiredBg,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        // mainAxisSize.min : la boîte prend la hauteur de son contenu. Si le
        // chiffre est trop large (texte très agrandi), le Text passe à la
        // ligne au lieu de déborder.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${offer.score} %',
              style: text.headlineSmall?.copyWith(color: AppColors.emerald),
            ),
            Text(
              'score',
              style: text.labelSmall?.copyWith(color: AppColors.carbon),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(OfferType type) => switch (type) {
    OfferType.emploi => Icons.work_outline_rounded,
    OfferType.stage => Icons.school_outlined,
    OfferType.pfe => Icons.menu_book_outlined,
  };
}

/// Une ligne « Acquises : » ou « À apprendre : » suivie de ses puces.
///
/// Tout est dans un Wrap (et non une Row) : le libellé et les puces
/// passent à la ligne quand la place manque, rien ne peut déborder.
class _SkillLine extends StatelessWidget {
  const _SkillLine({
    required this.label,
    required this.icon,
    required this.color,
    required this.emptyText,
    required this.chips,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String emptyText;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Text.rich avec un WidgetSpan : l'icône fait partie du texte et
        // passe à la ligne avec lui (une Row pourrait déborder).
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(icon, size: 14, color: color),
              ),
              TextSpan(text: ' $label'),
            ],
          ),
          style: text.labelSmall?.copyWith(color: color),
        ),
        if (chips.isEmpty)
          Text(
            emptyText,
            style: text.bodySmall?.copyWith(color: AppColors.carbon),
          )
        else
          ...chips,
      ],
    );
  }
}
