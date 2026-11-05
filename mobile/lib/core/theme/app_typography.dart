import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typographie de DESIGN.md : Merriweather pour les titres,
/// Plus Jakarta Sans pour le reste de l'interface.
///
/// Pourquoi google_fonts ? Ce paquet télécharge les polices au premier
/// lancement puis les garde en cache : rien à copier dans le projet.
/// Limite : il faut Internet la première fois. Plus tard, on pourra placer
/// les fichiers .ttf dans assets/fonts/ pour un fonctionnement hors ligne.
///
/// La hauteur de ligne en Flutter est un multiplicateur (height = ligne /
/// taille), d'où les divisions ci-dessous (ex. 38 px / 30 px).
abstract final class AppTypography {
  static TextStyle _serif(double size, double lineHeight) =>
      GoogleFonts.merriweather(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: lineHeight / size,
      );

  static TextStyle _sans(double size, double lineHeight, FontWeight weight) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: lineHeight / size,
      );

  /// Associe chaque style de DESIGN.md à un emplacement du TextTheme de
  /// Flutter. Les écrans utilisent ensuite Theme.of(context).textTheme,
  /// ce qui garde le code des écrans indépendant des polices.
  static TextTheme textTheme() => TextTheme(
        // headline-xl : grand titre d'écran
        displaySmall: _serif(30, 38),
        // headline-lg
        headlineMedium: _serif(24, 32),
        // headline-md
        headlineSmall: _serif(20, 28),
        // headline-sm : titre de poste dans une carte
        titleLarge: _serif(18, 24),
        // title-md
        titleMedium: _sans(16, 22, FontWeight.w600),
        // body-lg / body-md / body-sm
        bodyLarge: _sans(16, 24, FontWeight.w400),
        bodyMedium: _sans(14, 20, FontWeight.w400),
        bodySmall: _sans(13, 18, FontWeight.w400),
        // label-lg / label-md / label-sm
        labelLarge: _sans(14, 18, FontWeight.w600),
        labelMedium: _sans(12, 16, FontWeight.w600),
        labelSmall: _sans(11, 14, FontWeight.w600),
      );
}
