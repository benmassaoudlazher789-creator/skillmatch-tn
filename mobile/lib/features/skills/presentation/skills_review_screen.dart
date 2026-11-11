import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/widgets/skill_chip.dart';
import '../../auth/presentation/auth_navigation.dart';
// Widgets partagés avec Inscription et Connexion. Ils pourront être
// déplacés dans core/ plus tard, maintenant que plusieurs écrans s'en
// servent.
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../auth/presentation/widgets/labeled_text_field.dart';
import '../../cv/data/cv_analysis_service.dart';
import '../../cv/data/cv_picker.dart';
import '../../cv/domain/cv_failure.dart';
import '../../offers/data/offers_service.dart';
import '../../offers/presentation/offers_screen.dart';
import '../domain/skill_rules.dart';

/// Les trois états de l'écran.
enum _Status { loading, failed, ready }

/// Écran 5 : Vos compétences.
///
/// À l'ouverture, l'écran envoie le CV au serveur et affiche « Analyse en
/// cours… ». Ensuite :
/// - succès : la liste des compétences repérées, que le candidat relit,
///   complète ou corrige à la main ;
/// - échec : un message clair et un bouton « Réessayer » ;
/// - session expirée (401) : retour à la Connexion.
/// Les compétences retenues sont celles que le candidat garde : la
/// détection automatique n'est qu'un point de départ.
class SkillsReviewScreen extends StatefulWidget {
  const SkillsReviewScreen({
    super.key,
    required this.file,
    this.service,
    this.offersService,
  });

  /// Fichier choisi sur l'écran Ajout du CV.
  final PickedCvFile file;

  /// Analyse du CV. Les tests en donnent une fausse ; sinon, la vraie.
  final CvAnalysisService? service;

  /// Transmis à l'écran Offres. Les tests en donnent un faux ; sinon, le
  /// vrai (defaultOffersService).
  final OffersService? offersService;

  // Clés qui permettent aux tests de retrouver le champ et les boutons.
  static const skillFieldKey = Key('skills_field');
  static const addButtonKey = Key('skills_add');
  static const offersButtonKey = Key('skills_offers');
  static const retryButtonKey = Key('skills_retry');

  static const loadingText = 'Analyse en cours…';
  static const atLeastOneHint =
      'Ajoutez au moins une compétence pour voir les offres.';
  static const noSkillFoundHint =
      "Aucune compétence n'a été reconnue dans votre CV. Ajoutez-les "
      'ci-dessous.';

  @override
  State<SkillsReviewScreen> createState() => _SkillsReviewScreenState();
}

class _SkillsReviewScreenState extends State<SkillsReviewScreen> {
  _Status _status = _Status.loading;

  /// Message de l'échec, affiché quand _status vaut failed.
  String _error = '';

  /// Liste modifiable, remplie par la réponse du serveur.
  List<String> _skills = [];

  /// Vrai si le serveur n'a reconnu aucune compétence : on l'explique au
  /// lieu d'afficher seulement « Aucune compétence ».
  bool _noneFound = false;

  /// Vrai pendant un envoi.
  bool _isRunning = false;

  /// Le Form sert à afficher l'erreur sous le champ, comme dans
  /// Inscription et Connexion.
  final _formKey = GlobalKey<FormState>();

  /// Le contrôleur permet de vider le champ après un ajout réussi.
  final _controller = TextEditingController();

  CvAnalysisService get _service => widget.service ?? defaultCvAnalysisService;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  @override
  void dispose() {
    // Un contrôleur doit être libéré quand l'écran disparaît.
    _controller.dispose();
    super.dispose();
  }

  /// Envoie le CV. Appelée à l'ouverture et par « Réessayer ».
  Future<void> _analyze() async {
    // Un double appui rapide sur « Réessayer » n'envoie le CV qu'une fois.
    if (_isRunning) return;
    _isRunning = true;
    // Au premier appel (depuis initState), l'état vaut déjà loading : pas
    // besoin de setState, qui n'a pas sa place dans initState.
    if (_status != _Status.loading) {
      setState(() => _status = _Status.loading);
    }

    List<String>? skills;
    CvFailure? failure;
    try {
      skills = await _service.analyze(widget.file);
    } on CvException catch (e) {
      failure = e.failure;
    } catch (_) {
      // Erreur imprévue : message générique, jamais le détail technique
      // (il pourrait citer le fichier ou la réponse).
      failure = CvFailure.unknown;
    }
    _isRunning = false;

    // Le candidat a pu revenir en arrière pendant l'attente : on ne touche
    // plus à un écran fermé.
    if (!mounted) return;

    if (failure == CvFailure.sessionExpired) {
      openLoginAfterSessionExpired(context);
      return;
    }
    setState(() {
      if (skills != null) {
        _status = _Status.ready;
        _skills = List.of(skills);
        _noneFound = skills.isEmpty;
      } else {
        _status = _Status.failed;
        _error = (failure ?? CvFailure.unknown).message;
      }
    });
  }

  void _add() {
    // validate() appelle le validator du champ : s'il renvoie un message,
    // celui-ci s'affiche sous le champ et on s'arrête là.
    if (!_formKey.currentState!.validate()) return;
    setState(() => _skills.add(SkillRules.clean(_controller.text)));
    _controller.clear();
  }

  void _remove(String skill) {
    setState(() => _skills.remove(skill));
  }

  void _showOffers() {
    // On passe une copie figée (List.unmodifiable) de la liste courante :
    // l'écran Offres ne peut pas la modifier, et un changement fait ici
    // après le retour ne touche pas une liste déjà affichée là-bas.
    // push garde cet écran en dessous : « Retour » y revient avec la liste
    // intacte.
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OffersScreen(
          skills: List.unmodifiable(_skills),
          service: widget.offersService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ready = _status == _Status.ready;

    return AuthScaffold(
      appBarTitle: 'Compétences',
      heading: 'Vos compétences',
      subtitle:
          'Relisez les compétences repérées dans votre CV, retirez-en ou '
          'ajoutez-en.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (_status) {
            _Status.loading => _buildLoadingCard(text),
            _Status.failed => _buildErrorCard(text),
            _Status.ready => _buildSkillsCard(text),
          },
          const SizedBox(height: AppSpacing.xl),
          if (ready) ...[
            if (_skills.isEmpty) ...[
              Text(
                SkillsReviewScreen.atLeastOneHint,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: AppColors.carbon),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            // onPressed: null désactive le bouton quand la liste est vide.
            FilledButton(
              key: SkillsReviewScreen.offersButtonKey,
              onPressed: _skills.isEmpty ? null : _showOffers,
              // Flexible : le texte passe à la ligne au lieu de déborder
              // (petit écran ou texte agrandi).
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text('Voir les offres', textAlign: TextAlign.center),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Revient à l'écran Ajout du CV, qui est juste en dessous. Visible
          // dans les trois états : pendant l'analyse, le candidat peut
          // changer d'avis ; après un échec, choisir un autre fichier.
          OutlinedButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.upload_file_outlined, size: 20),
                SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Importer un autre CV',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Carte blanche commune aux trois états (même carte que sur l'écran
  /// Ajout du CV).
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: child,
    );
  }

  /// Pendant l'envoi et la lecture du CV par le serveur.
  Widget _buildLoadingCard(TextTheme text) {
    // liveRegion : le lecteur d'écran annonce « Analyse en cours… ».
    return _card(
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sm),
            const Center(
              child: CircularProgressIndicator(color: AppColors.emerald),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              SkillsReviewScreen.loadingText,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Le serveur SkillMatch lit votre CV. Cela prend en général '
              'quelques secondes.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: AppColors.carbon),
            ),
          ],
        ),
      ),
    );
  }

  /// Après un échec : message et bouton « Réessayer ».
  Widget _buildErrorCard(TextTheme text) {
    return _card(
      child: Column(
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
            key: SkillsReviewScreen.retryButtonKey,
            onPressed: _analyze,
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
      ),
    );
  }

  /// Carte du résultat : titre et compteur, puces, champ d'ajout,
  /// information.
  Widget _buildSkillsCard(TextTheme text) {
    final count = _skills.length;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wrap plutôt que Row : avec un texte agrandi, le compteur passe
          // sous le titre au lieu de déborder.
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Compétences déclarées',
                style: text.titleMedium?.copyWith(color: AppColors.navy),
              ),
              Semantics(
                label: count <= 1 ? '$count compétence' : '$count compétences',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    '$count',
                    style: text.labelSmall?.copyWith(color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_skills.isEmpty)
            Text(
              // Liste vide dès la réponse : on dit pourquoi. Liste vidée à
              // la main : simple constat.
              _noneFound
                  ? SkillsReviewScreen.noSkillFoundHint
                  : 'Aucune compétence pour le moment.',
              style: text.bodySmall?.copyWith(color: AppColors.carbon),
            )
          else
            // Wrap : les puces passent à la ligne suivante quand la place
            // manque (DESIGN.md : « flex wrap », espace de 6 px).
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final skill in _skills)
                  SkillChip.acquired(
                    skill,
                    // La clé aide Flutter à savoir quelle puce a disparu.
                    key: ValueKey(skill),
                    onRemove: () => _remove(skill),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          Form(
            key: _formKey,
            child: LabeledTextField(
              fieldKey: SkillsReviewScreen.skillFieldKey,
              label: 'Ajouter une compétence',
              hintText: 'Ex. : Docker, Figma, Excel',
              controller: _controller,
              maxLength: SkillRules.maxLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              validator: (value) => SkillRules.validate(value ?? '', _skills),
              // La touche « OK » du clavier ajoute aussi la compétence.
              onFieldSubmitted: (_) => _add(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Sous le champ, pas à côté : rien ne peut déborder en largeur.
          OutlinedButton(
            key: SkillsReviewScreen.addButtonKey,
            onPressed: _add,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 20),
                SizedBox(width: AppSpacing.xs),
                Flexible(child: Text('Ajouter', textAlign: TextAlign.center)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.carbon,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Cette liste est repérée automatiquement dans votre CV et '
                  'peut être incomplète : relisez-la. Elle servira à '
                  'comparer votre profil aux offres ; le résultat sera une '
                  'aide, pas une garantie.',
                  style: text.bodySmall?.copyWith(color: AppColors.carbon),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
