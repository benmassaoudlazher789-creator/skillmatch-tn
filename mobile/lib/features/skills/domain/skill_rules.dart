/// Règles d'une compétence saisie à la main.
///
/// Comme cv_file_rules.dart : du Dart pur, sans Flutter, donc testable très
/// vite et sans écran. L'écran ne fait qu'appeler ces fonctions.
abstract final class SkillRules {
  /// Longueur maximale d'une compétence, en caractères. 40 suffit pour
  /// « Gestion de projet agile » ou « Microsoft Power BI ».
  static const maxLength = 40;

  static const emptyError = 'Saisissez une compétence.';
  static const tooLongError = '$maxLength caractères maximum.';
  static const duplicateError = 'Cette compétence est déjà dans la liste.';

  /// Nettoie la saisie : retire les espaces au début et à la fin, et
  /// remplace plusieurs espaces de suite par un seul
  /// (« Power   BI » devient « Power BI »).
  static String clean(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Clé de comparaison entre deux compétences : la saisie nettoyée, en
  /// minuscules. « flutter » et « Flutter » ont la même clé.
  ///
  /// Une seule fonction, partagée par la recherche de doublons (ici), le
  /// score des offres et la recherche de formations : les trois comparent
  /// donc les compétences exactement de la même façon.
  /// Limites assumées : les accents comptent (« Ecoute » n'est pas
  /// « Écoute »), et les synonymes ne sont pas reconnus (« JS » n'est pas
  /// « JavaScript »).
  static String key(String raw) => clean(raw).toLowerCase();

  /// Renvoie un message d'erreur, ou null si la compétence peut être
  /// ajoutée à [existing].
  ///
  /// Le doublon est cherché sans tenir compte des majuscules : « flutter »
  /// est refusé si « Flutter » est déjà là. Limite assumée : les accents
  /// comptent (« Ecoute » et « Écoute » sont deux saisies différentes).
  static String? validate(String raw, List<String> existing) {
    final skill = clean(raw);
    if (skill.isEmpty) return emptyError;
    if (skill.length > maxLength) return tooLongError;
    final newKey = key(skill);
    if (existing.any((s) => key(s) == newKey)) {
      return duplicateError;
    }
    return null;
  }
}
