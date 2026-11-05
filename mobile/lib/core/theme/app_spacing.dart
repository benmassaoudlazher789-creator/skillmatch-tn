/// Espacements et arrondis, repris de DESIGN.md.
///
/// Tout est un multiple de 4 : cela donne un rythme régulier à l'écran.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double gutter = 16;
  static const double lg = 20;
  static const double xl = 28;

  /// Marge gauche/droite des écrans (20 px selon DESIGN.md).
  static const double screenMargin = 20;

  /// Hauteur des boutons principaux et des champs de saisie.
  static const double controlHeight = 52;

  /// Largeur maximale du contenu. Sur un grand écran (Chrome, tablette),
  /// le contenu reste lisible au centre au lieu de s'étirer sur toute la
  /// largeur. Partagée par Bienvenue, Inscription et les écrans suivants.
  static const double maxContentWidth = 480;
}

/// Rayons d'arrondi des coins.
abstract final class AppRadius {
  /// Cartes et grands blocs.
  static const double card = 20;

  /// Boutons et champs de saisie.
  static const double control = 14;

  /// Petits boutons utilitaires et puces de filtre.
  static const double small = 10;

  /// Puces de compétences (jamais complètement rondes, voir DESIGN.md).
  static const double chip = 8;

  /// Petites tuiles sur fond nuit (écran Bienvenue) : rounded-lg = 8.
  static const double tile = 8;

  /// Illustration en haut d'écran : rounded-xl de la maquette = 12.
  static const double media = 12;

  /// Cases à cocher (DESIGN.md : 6 px).
  static const double checkbox = 6;
}
