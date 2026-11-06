import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
// Mise en page partagée avec Inscription et Connexion (barre du haut,
// titre, sous-titre). Elle pourra être déplacée dans core/ plus tard.
import '../../auth/presentation/widgets/auth_scaffold.dart';
import '../../skills/presentation/skills_review_screen.dart';
import '../data/cv_picker.dart';
import '../domain/cv_file_rules.dart';
import 'widgets/cv_file_tile.dart';

/// Écran 4 : Ajout du CV.
///
/// Le candidat choisit son CV (PDF, DOC ou DOCX, 5 Mo maximum). On vérifie
/// seulement le nom et la taille sur le téléphone. Rien n'est envoyé, le
/// contenu du fichier n'est pas lu, et aucune compétence n'est déduite.
class CvUploadScreen extends StatefulWidget {
  const CvUploadScreen({super.key, this.picker = const FilePickerCvPicker()});

  /// Sélecteur de fichier. Les tests le remplacent par un faux.
  final CvPicker picker;

  // Clés qui permettent aux tests de retrouver les boutons.
  static const pickButtonKey = Key('cv_pick');
  static const analyzeButtonKey = Key('cv_analyze');

  @override
  State<CvUploadScreen> createState() => _CvUploadScreenState();
}

class _CvUploadScreenState extends State<CvUploadScreen> {
  /// Fichier valide choisi, ou null.
  PickedCvFile? _file;

  /// Message d'erreur affiché sous la carte, ou null.
  String? _error;

  /// Vrai pendant que le sélecteur est ouvert : évite de l'ouvrir deux fois.
  bool _isPicking = false;

  Future<void> _pick() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    final PickedCvFile? picked;
    try {
      picked = await widget.picker.pick();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPicking = false;
        _error = CvFileRules.pickerError;
      });
      return;
    }
    // L'écran a pu être fermé pendant que le sélecteur était ouvert.
    if (!mounted) return;

    // Annulation : rien ne change.
    if (picked == null) {
      setState(() => _isPicking = false);
      return;
    }

    final error = CvFileRules.validate(
      fileName: picked.name,
      sizeInBytes: picked.sizeInBytes,
    );
    setState(() {
      _isPicking = false;
      _error = error;
      // Le dernier choix compte : un fichier refusé retire aussi le
      // précédent, et le bouton d'analyse redevient inactif.
      _file = error == null ? picked : null;
    });
  }

  void _remove() {
    setState(() {
      _file = null;
      _error = null;
    });
  }

  void _analyze() {
    // Ouvre l'écran Vos compétences. Rien n'est envoyé : cet écran montre
    // une liste d'exemple, avec un bandeau qui le dit. push (et non
    // pushReplacement) : Retour ramène ici, avec le fichier toujours choisi.
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SkillsReviewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      appBarTitle: 'Ajout du CV',
      heading: 'Ajoutez votre CV',
      subtitle:
          "Choisissez le fichier de votre CV. L'analyse des compétences "
          'arrivera dans une prochaine version.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPickCard(text),
          const SizedBox(height: AppSpacing.lg),
          // Texte sur la vie privée : seulement ce que l'application fait
          // réellement aujourd'hui.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.carbon,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  "Votre CV reste sur votre téléphone. L'application lit "
                  "seulement son nom et sa taille. Rien n'est envoyé pour "
                  "l'instant.",
                  style: text.bodySmall?.copyWith(color: AppColors.carbon),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // onPressed: null désactive le bouton tant qu'aucun fichier
          // valide n'est choisi.
          FilledButton(
            key: CvUploadScreen.analyzeButtonKey,
            onPressed: _file == null ? null : _analyze,
            // Même protection que le bouton « Choisir un fichier » : le
            // texte passe à la ligne au lieu de déborder.
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text('Analyser mon CV', textAlign: TextAlign.center),
                ),
                SizedBox(width: AppSpacing.sm),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Grande carte blanche : icône, consignes, bouton ou fichier choisi,
  /// et message d'erreur éventuel.
  Widget _buildPickCard(TextTheme text) {
    final file = _file;
    final error = _error;

    return Container(
      padding: const EdgeInsets.all(24), // p-6 de la maquette
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          // shadow-sm
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
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file_outlined,
                size: 32,
                color: AppColors.emerald,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choisissez votre CV',
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(color: AppColors.navy),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CvFileRules.formatsHint,
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.carbon),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (file == null)
            FilledButton(
              key: CvUploadScreen.pickButtonKey,
              onPressed: _isPicking ? null : _pick,
              // Flexible : si la place manque (petit écran, texte agrandi),
              // le texte passe à la ligne et le bouton grandit en hauteur,
              // au lieu de déborder à droite. mainAxisSize.min garde
              // l'icône collée au texte, le tout centré par le bouton.
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'Choisir un fichier',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          else
            CvFileTile(
              file: file,
              // _pick ignore déjà un second appui pendant l'ouverture.
              onChange: _pick,
              onRemove: _remove,
            ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.md),
            // liveRegion : le lecteur d'écran lit l'erreur dès qu'elle
            // apparaît.
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      error,
                      style: text.bodySmall?.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
