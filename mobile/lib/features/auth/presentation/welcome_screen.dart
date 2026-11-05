import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'register_screen.dart';
import 'widgets/feature_tile.dart';
import 'widgets/welcome_illustration.dart';

/// Écran 1 : Bienvenue.
///
/// Premier écran vu par le candidat. Il présente l'application et propose
/// de créer un compte ou de se connecter. Aucun appel API ici : le contenu
/// est entièrement statique.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.onCreateAccount, this.onSignIn});

  /// Actions des deux boutons. On peut les remplacer (utile pour les tests
  /// ou une future navigation centrale). Sans valeur fournie :
  /// - « Créer un compte » ouvre l'écran Inscription ;
  /// - « Se connecter » affiche un message temporaire (écran Connexion à venir).
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSignIn;

  /// Ouvre l'écran Inscription par-dessus Bienvenue. Navigator.push garde
  /// Bienvenue en dessous : le bouton retour y ramène tout seul.
  void _openRegister(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  void _comingSoon(BuildContext context, String screen) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Écran « $screen » à venir.')));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Icônes de la barre d'état en clair, puisque le fond est sombre.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.navy,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          children: [
            // Halos lumineux décoratifs, aux positions de la maquette.
            // -top-16 -right-16, w-64, secondary/15, blur-3xl (64 px)
            const Positioned(
              top: -64,
              right: -64,
              child: _Glow(
                color: AppColors.glowEmerald,
                size: 256,
                opacity: 0.15,
                blur: 64,
              ),
            ),
            // top-1/2 -left-20, w-56, tertiary-fixed-dim/10, blur-2xl (40 px)
            Positioned(
              top: MediaQuery.sizeOf(context).height / 2,
              left: -80,
              child: const _Glow(
                color: AppColors.amberLight,
                size: 224,
                opacity: 0.10,
                blur: 40,
              ),
            ),
            SafeArea(
              // Défilement : LayoutBuilder donne la hauteur disponible.
              // Le ConstrainedBox impose au contenu au moins cette hauteur :
              // s'il y a de la place, la Column (spaceBetween) pousse les
              // boutons en bas ; sinon, le contenu dépasse et on fait
              // défiler pour atteindre les boutons. Aucun débordement.
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        // Contenu centré, limité à 480 px (voir AppSpacing).
                        // Le fond bleu nuit, lui, couvre toute la fenêtre.
                        maxWidth: AppSpacing.maxContentWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenMargin,
                          vertical: AppSpacing.xl, // py-7 = 28
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIntro(text),
                            _buildActions(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Partie haute : badge, illustration, titre, sous-titre, tuiles.
  Widget _buildIntro(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Header(),
        const SizedBox(height: 24), // mb-6
        // Illustration géométrique à la place de la photo (welcome_hero.png).
        // La photo reste dans assets/images/, mais on ne l'affiche pas pour
        // l'instant. Une photo de meilleure qualité, avec des droits d'usage
        // clairs (licence connue, autorisation des personnes visibles),
        // pourra la remplacer plus tard : il suffira de réutiliser le widget
        // WelcomeHero (widgets/welcome_hero.dart) avec la nouvelle image.
        const WelcomeIllustration(),
        const SizedBox(height: 24), // mb-6
        Text(
          'Prouve ce que tu sais faire.',
          style: text.displaySmall?.copyWith(
            color: AppColors.onNavy,
            letterSpacing: -0.75, // tracking-tight = -0,025 em
          ),
        ),
        const SizedBox(height: AppSpacing.md), // space-y-3
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              'Le recrutement tunisien fondé sur les '
              'compétences démontrées.',
              style: text.bodyMedium?.copyWith(color: AppColors.onNavyMuted),
            ),
          ),
        ),
        const SizedBox(height: 32), // mb-8
        const FeatureTile(
          title: 'Valorisez vos compétences',
          description: 'Un profil clair pour les recruteurs.',
        ),
        const SizedBox(height: 14), // space-y-3.5
        const FeatureTile(
          title: 'Comprenez votre score',
          // Règle du projet : le score est une aide, pas une garantie.
          // On le dit dès l'accueil.
          description: "Chaque correspondance d'offre est expliquée, sans "
              'boîte noire. Le score est une aide pour vous orienter, pas '
              'une garantie.',
        ),
        const SizedBox(height: 14),
        const FeatureTile(
          title: 'Progressez vers le poste',
          description:
              "Un plan d'action personnalisé et réalisable pour chaque annonce.",
        ),
      ],
    );
  }

  /// Partie basse : les deux boutons.
  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Écart minimal entre les tuiles et les boutons : mb-8 + pt-2 = 40.
        const SizedBox(height: 40),
        DecoratedBox(
          // shadow-lg de la maquette.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.control),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 10),
                blurRadius: 15,
                spreadRadius: -3,
              ),
              BoxShadow(
                color: Color(0x1A000000),
                offset: Offset(0, 4),
                blurRadius: 6,
                spreadRadius: -4,
              ),
            ],
          ),
          child: FilledButton(
            onPressed: onCreateAccount ?? () => _openRegister(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Créer un compte'),
                SizedBox(width: AppSpacing.sm),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: onSignIn ?? () => _comingSoon(context, 'Connexion'),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
            foregroundColor: AppColors.onNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
          ),
          child: const Text('Se connecter'),
        ),
        // La phrase sur l'hébergement et la conformité des données a été
        // retirée volontairement.
      ],
    );
  }
}

/// En-tête : badge de marque.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    // Sélecteur de langue Français / العربية : volontairement masqué pour
    // l'instant. L'application n'est traduite qu'en français ; afficher un
    // bouton "العربية" qui ne fait rien tromperait l'utilisateur. On
    // l'ajoutera ici (à droite du badge, dans une Row) quand la traduction
    // arabe et la mise en page de droite à gauche seront prêtes.
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.amberSoft,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            // shadow-sm
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hub_outlined,
              size: 16,
              color: AppColors.onAmberSoft,
            ),
            const SizedBox(width: 6),
            Text(
              'SKILLMATCH TN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onAmberSoft,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.55, // tracking-wider = 0,05 em
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un halo de couleur flou, purement décoratif.
class _Glow extends StatelessWidget {
  const _Glow({
    required this.color,
    required this.size,
    required this.opacity,
    required this.blur,
  });

  final Color color;
  final double size;
  final double opacity;
  final double blur;

  @override
  Widget build(BuildContext context) {
    // ImageFiltered applique le même flou que "blur-3xl" en CSS
    // (sigma = rayon du flou). TileMode.decal : le bord s'efface en douceur.
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: opacity),
          ),
        ),
      ),
    );
  }
}
