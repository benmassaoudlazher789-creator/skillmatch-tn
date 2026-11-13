import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/widgets/info_banner.dart';
import '../../../core/theme/widgets/skill_chip.dart';
import '../../auth/presentation/auth_navigation.dart';
// Mise en page partagée avec les écrans précédents (voir offers_screen.dart
// pour la remarque sur son nom).
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../data/trainings_service.dart';
import '../domain/training.dart';
import '../domain/trainings_failure.dart';
import 'widgets/training_card.dart';

/// Les trois états de l'écran (la liste vide est un cas de « ready »).
enum _Status { loading, failed, ready }

/// Écran 7 : Formations.
///
/// S'ouvre quand on touche une compétence manquante (puce rouge) sur
/// l'écran Offres. Demande au serveur les formations de cette compétence
/// (GET /trainings) et les affiche dans l'ordre reçu : le serveur filtre et
/// trie déjà, l'écran ne recalcule rien.
class TrainingsScreen extends StatefulWidget {
  const TrainingsScreen({super.key, required this.skill, this.service});

  /// Compétence manquante touchée sur l'écran Offres.
  final String skill;

  /// Chargement des formations. Les tests en donnent un faux ; sinon, le vrai.
  final TrainingsService? service;

  static String heading(String skill) => 'Formations pour $skill';
  static const subtitle = 'Suggestions pour apprendre cette compétence.';
  static const loadingText = 'Chargement des formations…';

  /// Bandeau ambre, seulement si au moins une formation est un exemple.
  static const sampleBanner =
      'Certaines formations sont des exemples inventés pour la démonstration : '
      "elles portent la mention « Formation d'exemple ».";

  /// Bandeau neutre, toujours affiché avec la liste.
  static const disclaimer =
      'Ce sont des suggestions : aucune formation ne garantit un emploi ni un '
      'meilleur score. Les durées sont indicatives.';

  static String emptyMessage(String skill) =>
      'Aucune formation pour $skill pour le moment.';
  static const backToOffers = 'Retour aux offres';

  /// « 1 formation », « 2 formations ».
  static String countLabel(int count) =>
      count <= 1 ? '$count formation' : '$count formations';

  /// Clé de la carte d'une formation, pour les tests.
  static Key cardKey(String trainingId) => Key('training_$trainingId');

  static const retryButtonKey = Key('trainings_retry');

  @override
  State<TrainingsScreen> createState() => _TrainingsScreenState();
}

class _TrainingsScreenState extends State<TrainingsScreen> {
  _Status _status = _Status.loading;

  /// Message de l'échec, affiché quand _status vaut failed.
  String _error = '';

  /// Formations reçues, dans l'ordre du serveur.
  List<Training> _trainings = const [];

  /// Vrai pendant un chargement : un double appui sur « Réessayer » ne
  /// lance qu'une requête.
  bool _isRunning = false;

  TrainingsService get _service => widget.service ?? defaultTrainingsService;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Demande les formations. Appelée à l'ouverture et par « Réessayer ».
  /// Même déroulé que sur l'écran Offres.
  Future<void> _load() async {
    if (_isRunning) return;
    _isRunning = true;
    // Au premier appel (depuis initState), l'état vaut déjà loading.
    if (_status != _Status.loading) {
      setState(() => _status = _Status.loading);
    }

    List<Training>? trainings;
    TrainingsFailure? failure;
    try {
      trainings = await _service.fetch(widget.skill);
    } on TrainingsException catch (e) {
      failure = e.failure;
    } catch (_) {
      // Erreur imprévue : message générique, jamais le détail technique.
      failure = TrainingsFailure.unknown;
    }
    _isRunning = false;

    // Le candidat a pu revenir en arrière pendant l'attente.
    if (!mounted) return;

    if (failure == TrainingsFailure.sessionExpired) {
      openLoginAfterSessionExpired(context);
      return;
    }
    setState(() {
      if (trainings != null) {
        _status = _Status.ready;
        _trainings = List.unmodifiable(trainings);
      } else {
        _status = _Status.failed;
        _error = (failure ?? TrainingsFailure.unknown).message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      appBarTitle: 'Formations',
      heading: TrainingsScreen.heading(widget.skill),
      subtitle: TrainingsScreen.subtitle,
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
              SkillChip.missing(widget.skill),
              if (_status == _Status.ready && _trainings.isNotEmpty)
                Text(
                  TrainingsScreen.countLabel(_trainings.length),
                  style: text.labelMedium?.copyWith(color: AppColors.carbon),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          switch (_status) {
            _Status.loading => _buildLoading(text),
            _Status.failed => _buildError(text),
            _Status.ready =>
              _trainings.isEmpty ? _buildEmpty(text) : _buildList(),
          },
        ],
      ),
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
            TrainingsScreen.loadingText,
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
          key: TrainingsScreen.retryButtonKey,
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

  Widget _buildEmpty(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          TrainingsScreen.emptyMessage(widget.skill),
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
                child: Text(
                  TrainingsScreen.backToOffers,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final hasSample = _trainings.any((t) => t.isSample);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bandeau ambre seulement si au moins une formation est un exemple,
        // comme sur l'écran Offres.
        if (hasSample) ...[
          const InfoBanner.example(TrainingsScreen.sampleBanner),
          const SizedBox(height: AppSpacing.sm),
        ],
        const InfoBanner.neutral(TrainingsScreen.disclaimer),
        const SizedBox(height: AppSpacing.lg),
        for (final training in _trainings) ...[
          TrainingCard(
            key: TrainingsScreen.cardKey(training.id),
            training: training,
          ),
          const SizedBox(height: AppSpacing.gutter),
        ],
      ],
    );
  }
}
