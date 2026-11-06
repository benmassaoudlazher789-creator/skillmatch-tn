import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/widgets/info_banner.dart';
// Mise en page partagée avec Inscription, Connexion et Vos compétences.
// Son nom ne convient plus (« auth ») : à renommer et déplacer dans core/
// lors d'un prochain nettoyage.
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../trainings/presentation/trainings_screen.dart';
import '../data/sample_offers.dart';
import '../domain/match_score.dart';
import '../domain/offer.dart';
import 'widgets/offer_card.dart';

/// Écran 6 : Offres pour votre CV.
///
/// Reçoit les compétences de l'écran Vos compétences, calcule un score pour
/// chaque offre (voir MatchScore) et les affiche de la meilleure à la plus
/// faible. Pour l'instant les offres sont des exemples en mémoire : aucun
/// appel réseau tant que l'API n'existe pas.
class OffersScreen extends StatefulWidget {
  const OffersScreen({
    super.key,
    required this.skills,
    this.offers = sampleOffers,
  });

  /// Compétences déclarées par le candidat à l'écran précédent.
  final List<String> skills;

  /// Offres à comparer. Les tests passent leur propre liste.
  final List<Offer> offers;

  static const heading = 'Offres pour votre CV';
  static const exampleBanner =
      "Offres d'exemple, inventées pour la démonstration : les vraies "
      'offres arriveront dans une prochaine version.';
  static const scoreInfo =
      "Le pourcentage compare les compétences demandées par l'offre à "
      "celles que vous avez déclarées. C'est une aide pour choisir, pas une "
      "garantie d'être retenu. Les compétences en rouge sont celles qui "
      "vous manquent : touchez-en une pour voir comment l'apprendre.";
  static const emptyFilter = "Aucune offre d'exemple de ce type.";

  /// Clé d'un filtre, pour les tests (null = « Tout »).
  static Key filterKey(OfferType? type) =>
      Key('offers_filter_${type?.name ?? 'all'}');

  /// Clé de la carte d'une offre, pour les tests.
  static Key cardKey(String offerId) => Key('offer_$offerId');

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  /// Calculé une seule fois à l'ouverture : les compétences et les offres
  /// ne changent pas pendant qu'on est sur cet écran.
  late final List<MatchResult> _ranked = MatchScore.rank(
    widget.offers,
    widget.skills,
  );

  /// Filtre choisi ; null veut dire « Tout ».
  OfferType? _filter;

  /// Ouvre l'écran Formations pour la compétence manquante touchée.
  /// push garde cet écran en dessous : « Retour » y revient avec le même
  /// filtre (l'état de cet écran n'est pas détruit).
  void _openTrainings(String skill) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TrainingsScreen(skill: skill)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // where() garde l'ordre du tri : le filtre ne change pas le classement.
    final visible = _ranked
        .where((r) => _filter == null || r.offer.type == _filter)
        .toList();

    return AuthScaffold(
      appBarTitle: 'Offres',
      heading: OffersScreen.heading,
      subtitle: 'Classées selon vos compétences déclarées.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilters(text),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner.example(OffersScreen.exampleBanner),
          const SizedBox(height: AppSpacing.sm),
          const InfoBanner.neutral(OffersScreen.scoreInfo),
          const SizedBox(height: AppSpacing.lg),
          if (visible.isEmpty)
            Text(
              OffersScreen.emptyFilter,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.carbon),
            )
          else
            for (final result in visible) ...[
              OfferCard(
                key: OffersScreen.cardKey(result.offer.id),
                result: result,
                onMissingTap: _openTrainings,
              ),
              const SizedBox(height: AppSpacing.gutter),
            ],
        ],
      ),
    );
  }

  /// Filtres Tout / Emplois / Stages / PFE. Wrap : ils passent à la ligne
  /// sur un petit écran au lieu de déborder.
  Widget _buildFilters(TextTheme text) {
    Widget filter(OfferType? type, String label) {
      final selected = _filter == type;
      return ChoiceChip(
        key: OffersScreen.filterKey(type),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        // Bleu nuit quand le filtre est choisi, comme dans la maquette ;
        // le reste vient de chipTheme (app_theme.dart).
        selectedColor: AppColors.navy,
        labelStyle: text.labelMedium?.copyWith(
          color: selected ? AppColors.white : AppColors.carbon,
        ),
        onSelected: (_) => setState(() => _filter = type),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        filter(null, 'Tout'),
        for (final type in OfferType.values) filter(type, type.pluralLabel),
      ],
    );
  }
}
