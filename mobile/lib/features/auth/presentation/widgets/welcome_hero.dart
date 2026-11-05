import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'welcome_illustration.dart';

/// Photo de l'écran Bienvenue, dans une carte aux coins arrondis,
/// avec un dégradé sombre en bas comme dans la maquette.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key, this.height = 144}); // h-36

  static const _asset = 'assets/images/welcome_hero.png';

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Photo de personnes qui travaillent ensemble',
      image: true,
      child: DecoratedBox(
        // shadow-md, comme l'illustration.
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.media), // 12
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 4),
              blurRadius: 6,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.media),
          child: SizedBox(
            height: height,
            width: double.infinity,
            // LayoutBuilder donne la largeur réelle de la carte, pour
            // calculer cacheWidth.
            child: LayoutBuilder(
              builder: (context, constraints) {
                // cacheWidth : Flutter décode l'image directement à la
                // taille affichée (largeur × densité de l'écran) au lieu de
                // garder l'original en mémoire. Il ne l'agrandit jamais.
                final dpr = MediaQuery.devicePixelRatioOf(context);
                final cacheWidth = (constraints.maxWidth * dpr).round();
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      cacheWidth: cacheWidth,
                      // Le Semantics du dessus décrit déjà l'image.
                      excludeFromSemantics: true,
                      // Si la photo ne se charge pas, on revient à
                      // l'illustration géométrique.
                      errorBuilder: (_, _, _) =>
                          WelcomeIllustration(height: height),
                    ),
                    // Dégradé de la maquette : bg-gradient-to-t
                    // from-primary-container via-primary-container/40
                    // to-transparent.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.navy,
                            AppColors.navy.withValues(alpha: 0.40),
                            AppColors.navy.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
