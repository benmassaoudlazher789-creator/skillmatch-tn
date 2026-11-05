import 'package:flutter/material.dart';

/// Toutes les couleurs de l'application, reprises de DESIGN.md.
///
/// Pourquoi une classe à part ? Si on écrit les codes couleur directement
/// dans chaque écran, changer une teinte oblige à modifier des dizaines de
/// fichiers. Ici, on la change une seule fois.
abstract final class AppColors {
  // --- Couleurs de marque ---
  /// Bleu nuit : en-têtes, titres, fond de l'écran Bienvenue.
  static const navy = Color(0xFF10243A);

  /// Bleu nuit plus profond, pour les zones posées sur le fond nuit.
  static const navyDeep = Color(0xFF0A1A2C);

  /// Crème : fond de base des écrans clairs.
  static const cream = Color(0xFFF7F5EF);

  /// Vert : boutons d'action principaux, scores élevés.
  static const emerald = Color(0xFF0F7F6B);

  /// Vert foncé : bouton vert quand on appuie dessus.
  static const emeraldPressed = Color(0xFF0A5C4D);

  /// Ambre : points d'attention, dates limites, favoris.
  static const amber = Color(0xFFE8A33D);

  /// Ambre très clair : fond du badge de marque.
  static const amberSoft = Color(0xFFFFDDB5);

  /// Brun foncé lisible sur l'ambre clair.
  static const onAmberSoft = Color(0xFF2A1800);

  // --- Neutres ---
  /// Gris carbone : textes secondaires, métadonnées.
  static const carbon = Color(0xFF5B6670);

  /// Bordures et séparateurs sur fond crème.
  static const border = Color(0xFFE0DDD2);

  static const white = Color(0xFFFFFFFF);

  // --- Textes sur fond bleu nuit ---
  /// Texte principal sur fond nuit (presque blanc, légèrement bleuté).
  static const onNavy = Color(0xFFF6F9FF);

  /// Texte secondaire sur fond nuit.
  /// Valeur de la maquette (surface-dim).
  static const onNavyMuted = Color(0xFFD0DBE7);

  /// Fond des tuiles de l'écran Bienvenue (#000E1F, utilisé à 40 %).
  static const tileOnNavy = Color(0xFF000E1F);

  /// Ambre clair des points des tuiles (tertiary-fixed-dim de la maquette).
  static const amberLight = Color(0xFFFFB956);

  /// Vert du halo décoratif de l'écran Bienvenue (secondary de la maquette).
  static const glowEmerald = Color(0xFF006B59);

  // --- Puces de compétences ---
  static const skillAcquiredBg = Color(0xFFDFF3EE);
  static const skillAcquiredText = Color(0xFF0A5C4D);

  static const skillMissingBg = Color(0xFFFDE7E5);
  static const skillMissingText = Color(0xFF8A1C14);
  static const skillMissingBorder = Color(0xFFF0B2AF);

  // --- Erreurs (formulaires) ---
  static const error = Color(0xFFBA1A1A);
}
