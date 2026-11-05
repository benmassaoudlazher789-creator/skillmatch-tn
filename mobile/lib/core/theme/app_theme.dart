import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Le thème global de l'application.
///
/// Flutter applique automatiquement ce ThemeData à tous les widgets
/// Material (boutons, champs, puces…). On décrit donc le style une seule
/// fois ici, et chaque écran en hérite sans répéter les couleurs.
abstract final class AppTheme {
  static ThemeData get light {
    final textTheme = AppTypography.textTheme().apply(
      bodyColor: AppColors.navy,
      displayColor: AppColors.navy,
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: AppColors.white,
      secondary: AppColors.emerald,
      onSecondary: AppColors.white,
      tertiary: AppColors.amber,
      onTertiary: AppColors.onAmberSoft,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.cream,
      onSurface: AppColors.navy,
      onSurfaceVariant: AppColors.carbon,
      outline: AppColors.border,
    );

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme,

      // Bouton principal (vert) : FilledButton.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(160, AppSpacing.controlHeight),
          ),
          shape: WidgetStatePropertyAll(controlShape),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          foregroundColor: const WidgetStatePropertyAll(AppColors.white),
          // Le vert s'assombrit quand on appuie (DESIGN.md).
          // Désactivé (onPressed: null) : vert à 50 %, comme la maquette.
          // Sans ce cas, un bouton inactif aurait l'air actif.
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.emerald.withValues(alpha: 0.5);
            }
            return states.contains(WidgetState.pressed)
                ? AppColors.emeraldPressed
                : AppColors.emerald;
          }),
        ),
      ),

      // Bouton secondaire : contour bleu nuit.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(160, AppSpacing.controlHeight),
          shape: controlShape,
          foregroundColor: AppColors.navy,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Bouton utilitaire discret.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
          foregroundColor: AppColors.carbon,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
      ),

      // Champs de saisie : fond blanc, bordure beige, vert quand actif.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gutter,
          vertical: 14,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.carbon),
        labelStyle: textTheme.labelMedium,
        // Texte d'aide (ex. « 8 caractères minimum ») et messages d'erreur
        // sous les champs. Deux lignes maximum pour ne rien couper.
        helperStyle: textTheme.bodySmall?.copyWith(color: AppColors.carbon),
        helperMaxLines: 2,
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
        errorMaxLines: 2,
        border: _inputBorder(AppColors.border, 1),
        enabledBorder: _inputBorder(AppColors.border, 1),
        focusedBorder: _inputBorder(AppColors.emerald, 1.5),
        errorBorder: _inputBorder(AppColors.error, 1),
        focusedErrorBorder: _inputBorder(AppColors.error, 1.5),
      ),

      // Puces de filtre neutres (les puces de compétences ont leur
      // propre widget : voir widgets/skill_chip.dart).
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.white,
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.carbon),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),

      // Cartes : blanc, bordure fine, coins de 20 px, ombre quasi nulle.
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),

      // Barre du haut des écrans clairs (Inscription, puis les suivants) :
      // fond crème, texte bleu nuit, titre en Merriweather 18 (headline-sm).
      // Pas d'ombre, mais un trait fin en bas (DESIGN.md, niveau 2).
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.navy,
        elevation: 0,
        // Pas de changement de teinte quand le contenu défile dessous.
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        // Fond clair : icônes sombres dans la barre d'état. On remet aussi
        // la barre de navigation Android en crème (Bienvenue l'a mise en nuit).
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.cream,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      // Cases à cocher (DESIGN.md) : bord gris carbone de 1,5 px, coins de
      // 6 px, vert une fois cochée, rouge en cas d'erreur.
      checkboxTheme: CheckboxThemeData(
        // Zone tactile de 48 px partout, y compris sur le web et l'ordinateur.
        materialTapTargetSize: MaterialTapTargetSize.padded,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.checkbox),
        ),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.emerald
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: AppColors.emerald, width: 1.5);
          }
          if (states.contains(WidgetState.error)) {
            return const BorderSide(color: AppColors.error, width: 1.5);
          }
          return const BorderSide(color: AppColors.carbon, width: 1.5);
        }),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: color, width: width),
      );
}
