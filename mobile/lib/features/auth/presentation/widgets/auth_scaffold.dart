import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Mise en page commune aux écrans de compte (Inscription, Connexion).
///
/// Pourquoi un widget partagé ? Les deux écrans ont exactement la même
/// structure : barre du haut avec bouton retour, grand titre, sous-titre,
/// puis le formulaire. On l'écrit une seule fois ici ; chaque écran ne
/// fournit que ses textes et son contenu (child).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.appBarTitle,
    required this.heading,
    required this.subtitle,
    required this.child,
  });

  /// Titre court de la barre du haut (ex. « Connexion »).
  final String appBarTitle;

  /// Grand titre de l'écran (ex. « Bon retour »).
  final String heading;

  /// Phrase sous le grand titre.
  final String subtitle;

  /// Contenu de l'écran, en général un Form.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      // Couleurs, titre et barre d'état viennent de appBarTheme (app_theme.dart).
      appBar: AppBar(
        // Bouton retour personnalisé : IconButton fait au moins 48 × 48 px
        // (taille tactile recommandée) et son infobulle est en français.
        // Le BackButton par défaut afficherait « Back ».
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(appBarTitle),
      ),
      body: SafeArea(
        top: false, // l'AppBar s'occupe déjà du haut de l'écran
        child: SingleChildScrollView(
          // Faire défiler ferme le clavier : pratique sur un petit écran.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.lg,
                  AppSpacing.screenMargin,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // header: true : le lecteur d'écran annonce ce texte
                    // comme un titre.
                    Semantics(
                      header: true,
                      child: Text(heading, style: text.displaySmall),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: text.bodyMedium?.copyWith(color: AppColors.carbon),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
