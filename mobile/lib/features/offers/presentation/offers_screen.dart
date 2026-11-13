import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/widgets/info_banner.dart';
import '../../auth/presentation/auth_navigation.dart';
// Mise en page partagée avec Inscription, Connexion et Vos compétences.
// Son nom ne convient plus (« auth ») : à renommer et déplacer dans core/
// lors d'un prochain nettoyage.
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../trainings/data/trainings_service.dart';
import '../../trainings/presentation/trainings_screen.dart';
import '../data/offers_service.dart';
import '../domain/offer.dart';
import '../domain/offers_failure.dart';
import 'widgets/offer_card.dart';

/// Les trois états de l'écran.
enum _Status { loading, failed, ready }

/// Écran 6 : Offres pour votre CV.
///
/// Envoie les compétences de l'écran Vos compétences au serveur
/// (GET /offers), qui renvoie les offres déjà classées avec leur score.
/// L'écran n'en calcule aucun : il affiche, dans l'ordre reçu.
/// Les filtres (Emplois, Stages, PFE) ne font que masquer des cartes de
/// cette liste, sans rien recalculer.
class OffersScreen extends StatefulWidget {
  const OffersScreen({
    super.key,
    required this.skills,
    this.service,
    this.trainingsService,
  });

  /// Compétences déclarées par le candidat à l'écran précédent.
  final List<String> skills;

  /// Chargement des offres. Les tests en donnent un faux ; sinon, le vrai.
  final OffersService? service;

  /// Transmis à l'écran Formations : les tests y passent un faux, pour
  /// qu'ouvrir une formation n'appelle jamais le réseau. Null = le vrai.
  final TrainingsService? trainingsService;

  static const heading = 'Offres pour votre CV';
  static const loadingText = 'Chargement des offres…';
  static const sampleBanner =
      'Certaines offres sont des exemples inventés pour la démonstration : '
      "elles portent la mention « Offre d'exemple ».";
  // Pas le nom de l'application ici : la maquette et les tests excluent le
  // mot « Match » de cet écran.
  static const scoreInfo =
      'Le pourcentage, calculé par notre serveur, compare les compétences '
      "demandées par l'offre à celles que vous avez déclarées. C'est une aide "
      "pour choisir, pas une garantie d'être retenu. Les compétences en rouge "
      'sont celles qui vous manquent : touchez-en une pour voir comment '
      "l'apprendre.";
  static const emptyFilter = 'Aucune offre de ce type.';
  static const noOffers = 'Aucune offre disponible pour le moment.';

  /// Clé d'un filtre, pour les tests (null = « Tout »).
  static Key filterKey(OfferType? type) =>
      Key('offers_filter_${type?.name ?? 'all'}');

  /// Clé de la carte d'une offre, pour les tests.
  static Key cardKey(String offerId) => Key('offer_$offerId');

  static const retryButtonKey = Key('offers_retry');

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  _Status _status = _Status.loading;

  /// Message de l'échec, affiché quand _status vaut failed.
  String _error = '';

  /// Offres reçues, dans l'ordre du serveur.
  List<Offer> _offers = const [];

  /// Filtre choisi ; null veut dire « Tout ».
  OfferType? _filter;

  /// Vrai pendant un chargement : un double appui sur « Réessayer » ne
  /// lance qu'une requête.
  bool _isRunning = false;

  OffersService get _service => widget.service ?? defaultOffersService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Demande les offres. Appelée à l'ouverture et par « Réessayer ».
  Future<void> _load() async {
    if (_isRunning) return;
    _isRunning = true;
    // Au premier appel (depuis initState), l'état vaut déjà loading.
    if (_status != _Status.loading) {
      setState(() => _status = _Status.loading);
    }

    List<Offer>? offers;
    OffersFailure? failure;
    try {
      offers = await _service.fetch(widget.skills);
    } on OffersException catch (e) {
      failure = e.failure;
    } catch (_) {
      // Erreur imprévue : message générique, jamais le détail technique.
      failure = OffersFailure.unknown;
    }
    _isRunning = false;

    // Le candidat a pu revenir en arrière pendant l'attente.
    if (!mounted) return;

    if (failure == OffersFailure.sessionExpired) {
      openLoginAfterSessionExpired(context);
      return;
    }
    setState(() {
      if (offers != null) {
        _status = _Status.ready;
        _offers = List.unmodifiable(offers);
      } else {
        _status = _Status.failed;
        _error = (failure ?? OffersFailure.unknown).message;
      }
    });
  }

  /// Ouvre l'écran Formations pour la compétence manquante touchée.
  /// push garde cet écran en dessous : « Retour » y revient avec le même
  /// filtre (l'état de cet écran n'est pas détruit).
  void _openTrainings(String skill) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TrainingsScreen(skill: skill, service: widget.trainingsService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      appBarTitle: 'Offres',
      heading: OffersScreen.heading,
      subtitle: 'Classées selon vos compétences déclarées.',
      child: switch (_status) {
        _Status.loading => _buildLoading(text),
        _Status.failed => _buildError(text),
        _Status.ready => _buildOffers(text),
      },
    );
  }

  Widget _buildLoading(TextTheme text) {
    // liveRegion : le lecteur d'écran annonce le chargement.
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Center(
            child: CircularProgressIndicator(color: AppColors.emerald),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            OffersScreen.loadingText,
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(color: AppColors.navy),
          ),
        ],
      ),
    );
  }

  Widget _buildError(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              // Expanded : le message passe à la ligne au lieu de déborder.
              Expanded(
                child: Text(
                  _error,
                  style: text.bodyMedium?.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: OffersScreen.retryButtonKey,
          onPressed: _load,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, size: 20),
              SizedBox(width: AppSpacing.sm),
              Flexible(child: Text('Réessayer', textAlign: TextAlign.center)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOffers(TextTheme text) {
    // where() garde l'ordre du serveur : le filtre ne change pas le classement.
    final visible = _offers
        .where((o) => _filter == null || o.type == _filter)
        .toList();
    final hasSample = _offers.any((o) => o.isSample);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFilters(text),
        const SizedBox(height: AppSpacing.md),
        // Bandeau ambre seulement si au moins une offre est un exemple.
        if (hasSample) ...[
          const InfoBanner.example(OffersScreen.sampleBanner),
          const SizedBox(height: AppSpacing.sm),
        ],
        const InfoBanner.neutral(OffersScreen.scoreInfo),
        const SizedBox(height: AppSpacing.lg),
        if (visible.isEmpty)
          Text(
            _offers.isEmpty ? OffersScreen.noOffers : OffersScreen.emptyFilter,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.carbon),
          )
        else
          for (final offer in visible) ...[
            OfferCard(
              key: OffersScreen.cardKey(offer.id),
              offer: offer,
              onMissingTap: _openTrainings,
            ),
            const SizedBox(height: AppSpacing.gutter),
          ],
      ],
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
