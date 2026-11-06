import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/widgets/info_banner.dart';
import '../../../core/theme/widgets/skill_chip.dart';
// Mise en page partagée avec les écrans précédents (voir offers_screen.dart
// pour la remarque sur son nom).
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../data/sample_trainings.dart';
import '../domain/training.dart';
import '../domain/training_finder.dart';
import 'widgets/training_card.dart';

/// Écran 7 : Formations.
///
/// S'ouvre quand on touche une compétence manquante (puce rouge) sur
/// l'écran Offres, et suggère des formations pour l'apprendre. Pour
/// l'instant ce sont des exemples en mémoire : aucun appel réseau.
///
/// StatelessWidget : rien ne change sur cet écran une fois ouvert (pas de
/// filtre), donc pas besoin d'état.
class TrainingsScreen extends StatelessWidget {
  const TrainingsScreen({
    super.key,
    required this.skill,
    this.trainings = sampleTrainings,
  });

  /// Compétence manquante touchée sur l'écran Offres.
  final String skill;

  /// Catalogue dans lequel chercher. Les tests passent leur propre liste.
  final List<Training> trainings;

  static String heading(String skill) => 'Formations pour $skill';
  static const subtitle =
      "Suggestions d'exemple pour apprendre cette compétence.";
  static const disclaimer =
      'Ces formations sont des exemples inventés pour la démonstration. Ce '
      'sont des suggestions : aucune formation ne garantit un emploi ni un '
      'meilleur score. Les durées sont indicatives.';
  static String emptyMessage(String skill) =>
      "Aucune formation d'exemple pour $skill pour le moment.";
  static const backToOffers = 'Retour aux offres';

  /// « 1 formation d'exemple », « 2 formations d'exemple ».
  static String countLabel(int count) =>
      count <= 1 ? "$count formation d'exemple" : "$count formations d'exemple";

  /// Clé de la carte d'une formation, pour les tests.
  static Key cardKey(String trainingId) => Key('training_$trainingId');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final found = TrainingFinder.forSkill(skill, trainings);

    return AuthScaffold(
      appBarTitle: 'Formations',
      heading: heading(skill),
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rappel de la compétence en rouge, comme sur l'écran Offres,
          // suivi du nombre de formations. Wrap : le compteur passe sous
          // la puce si la place manque.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SkillChip.missing(skill),
              if (found.isNotEmpty)
                Text(
                  countLabel(found.length),
                  style: text.labelMedium?.copyWith(color: AppColors.carbon),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner.example(disclaimer),
          const SizedBox(height: AppSpacing.lg),
          if (found.isEmpty) ...[
            Text(
              emptyMessage(skill),
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.carbon),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => Navigator.maybePop(context),
              // Flexible : le texte passe à la ligne au lieu de déborder.
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_rounded, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(backToOffers, textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
          ] else
            for (final training in found) ...[
              TrainingCard(key: cardKey(training.id), training: training),
              const SizedBox(height: AppSpacing.gutter),
            ],
        ],
      ),
    );
  }
}
