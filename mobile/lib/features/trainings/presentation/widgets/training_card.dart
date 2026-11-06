import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/training.dart';

/// Carte d'une formation : badge d'exemple, titre, puis durée, niveau et
/// type. Pas de bouton « Voir la formation » : il n'y a pas encore de vraie
/// formation à ouvrir, et aucun appel réseau tant que l'API n'existe pas.
class TrainingCard extends StatelessWidget {
  const TrainingCard({super.key, required this.training});

  final Training training;

  static const sampleBadge = "Formation d'exemple";

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      // Même carte blanche que les écrans précédents.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSampleBadge(text),
          const SizedBox(height: AppSpacing.sm),
          Text(
            training.title,
            style: text.titleMedium?.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Wrap et non Row : les informations passent à la ligne sur un
          // petit écran ou avec un texte agrandi, sans déborder.
          Wrap(
            spacing: AppSpacing.gutter,
            runSpacing: AppSpacing.xs,
            children: [
              _Meta(
                icon: Icons.schedule_rounded,
                text: training.durationLabel,
                semanticLabel: 'Durée indicative : ${training.durationLabel}',
              ),
              _Meta(
                icon: Icons.signal_cellular_alt_rounded,
                text: training.level.label,
                semanticLabel: 'Niveau : ${training.level.label}',
              ),
              _Meta(
                icon: _iconFor(training.type),
                text: training.type.label,
                semanticLabel: 'Type : ${training.type.label}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge ambre, même forme que « Offre d'exemple » sur l'écran Offres.
  /// Il reste ici (et non dans core/) car seul le bandeau devait être
  /// partagé à cette étape ; à regrouper si un troisième écran en a besoin.
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

  static IconData _iconFor(TrainingType type) => switch (type) {
    TrainingType.coursEnLigne => Icons.laptop_outlined,
    TrainingType.tutoriel => Icons.menu_book_outlined,
    TrainingType.projetPratique => Icons.build_outlined,
  };
}

/// Une information de la carte : petite icône suivie d'un texte.
///
/// Text.rich avec un WidgetSpan plutôt qu'une Row : l'icône fait partie du
/// texte, qui peut passer à la ligne sans jamais déborder.
class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
    required this.semanticLabel,
  });

  final IconData icon;
  final String text;

  /// Phrase lue par le lecteur d'écran (« Niveau : Débutant ») : l'icône
  /// seule ne dirait rien.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(icon, size: 16, color: AppColors.carbon),
            ),
            TextSpan(text: ' $text'),
          ],
        ),
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.carbon),
      ),
    );
  }
}
