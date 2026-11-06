import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/widgets/skill_chip.dart';
// Widgets partagés avec Inscription et Connexion. Ils pourront être
// déplacés dans core/ plus tard, maintenant que plusieurs écrans s'en
// servent.
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../auth/presentation/widgets/labeled_text_field.dart';
import '../data/sample_skills.dart';
import '../domain/skill_rules.dart';

/// Écran 5 : Vos compétences.
///
/// Le candidat relit la liste de ses compétences, en retire et en ajoute à
/// la main. Pour l'instant, la liste de départ est un exemple en mémoire
/// (aucune analyse réelle du CV), et un bandeau le dit clairement.
/// Les compétences sont « déclarées » par le candidat : rien n'est contrôlé.
class SkillsReviewScreen extends StatefulWidget {
  const SkillsReviewScreen({super.key, this.initialSkills = sampleSkills});

  /// Liste de départ. Les tests passent leur propre liste.
  final List<String> initialSkills;

  // Clés qui permettent aux tests de retrouver le champ et les boutons.
  static const skillFieldKey = Key('skills_field');
  static const addButtonKey = Key('skills_add');
  static const offersButtonKey = Key('skills_offers');

  static const exampleBanner =
      "Exemple de résultat : l'analyse réelle arrivera dans une prochaine "
      'version.';
  static const offersSoonMessage = 'Offres bientôt disponibles.';
  static const atLeastOneHint =
      'Ajoutez au moins une compétence pour voir les offres.';

  @override
  State<SkillsReviewScreen> createState() => _SkillsReviewScreenState();
}

class _SkillsReviewScreenState extends State<SkillsReviewScreen> {
  /// Copie modifiable de la liste de départ (List.of crée une nouvelle
  /// liste : on ne touche jamais à la constante sampleSkills).
  late final List<String> _skills = List.of(widget.initialSkills);

  /// Le Form sert à afficher l'erreur sous le champ, comme dans
  /// Inscription et Connexion.
  final _formKey = GlobalKey<FormState>();

  /// Le contrôleur permet de vider le champ après un ajout réussi.
  final _controller = TextEditingController();

  @override
  void dispose() {
    // Un contrôleur doit être libéré quand l'écran disparaît.
    _controller.dispose();
    super.dispose();
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
    // Message temporaire : l'écran des offres (écran 6) viendra ensuite.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(SkillsReviewScreen.offersSoonMessage)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      appBarTitle: 'Compétences',
      heading: 'Vos compétences',
      subtitle: 'Retirez ou ajoutez des compétences.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildExampleBanner(text),
          const SizedBox(height: AppSpacing.lg),
          _buildSkillsCard(text),
          const SizedBox(height: AppSpacing.xl),
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
          // Revient à l'écran Ajout du CV, qui est juste en dessous.
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

  /// Bandeau ambre : la liste n'est qu'un exemple, pas une vraie analyse.
  Widget _buildExampleBanner(TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.amber),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.onAmberSoft,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              SkillsReviewScreen.exampleBanner,
              style: text.bodySmall?.copyWith(color: AppColors.onAmberSoft),
            ),
          ),
        ],
      ),
    );
  }

  /// Carte blanche : titre et compteur, puces, champ d'ajout, information.
  Widget _buildSkillsCard(TextTheme text) {
    final count = _skills.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      // Même carte que sur l'écran Ajout du CV.
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
              'Aucune compétence pour le moment.',
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
                  'Ces compétences sont déclarées par vous. Elles serviront '
                  'à comparer votre profil aux offres ; le résultat sera '
                  'une aide, pas une garantie.',
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
