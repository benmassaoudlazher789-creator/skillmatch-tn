import '../../skills/domain/skill_rules.dart';
import 'offer.dart';

/// Résultat de la comparaison entre une offre et les compétences du
/// candidat. Tout est calculé une seule fois par [computeMatch] ; l'écran ne
/// fait qu'afficher ces valeurs.
class MatchResult {
  const MatchResult({
    required this.offer,
    required this.percent,
    required this.requiredAcquired,
    required this.requiredMissing,
    required this.preferredAcquired,
    required this.preferredMissing,
  });

  final Offer offer;

  /// Score entre 0 et 100, arrondi vers le bas.
  final int percent;

  final List<String> requiredAcquired;
  final List<String> requiredMissing;
  final List<String> preferredAcquired;
  final List<String> preferredMissing;

  /// Compétences présentes : les requises d'abord.
  List<String> get acquired => [...requiredAcquired, ...preferredAcquired];

  /// Compétences manquantes : les requises d'abord, car ce sont elles qui
  /// font le plus monter le score.
  List<String> get missing => [...requiredMissing, ...preferredMissing];

  /// Phrase qui explique d'où vient le pourcentage, par exemple :
  /// « Requises : 2 sur 3 (70 % du score) · Souhaitées : 1 sur 2 (30 %) ».
  String get explanation {
    final requiredTotal = offer.requiredSkills.length;
    final preferredTotal = offer.preferredSkills.length;
    final requiredText =
        'Requises : ${requiredAcquired.length} sur $requiredTotal';
    final preferredText =
        'Souhaitées : ${preferredAcquired.length} sur $preferredTotal';

    if (requiredTotal > 0 && preferredTotal > 0) {
      return '$requiredText (${MatchScore.requiredWeight} % du score) · '
          '$preferredText (${MatchScore.preferredWeight} %)';
    }
    if (requiredTotal > 0) return '$requiredText (100 % du score)';
    if (preferredTotal > 0) return '$preferredText (100 % du score)';
    return 'Aucune compétence indiquée pour cette offre.';
  }
}

/// Calcul du score de correspondance.
///
/// Du Dart pur, sans Flutter (comme SkillRules) : on le teste en quelques
/// millisecondes, sans écran.
///
/// Règle, écrite en clair pour pouvoir l'expliquer au candidat :
///   score = 70 % × (requises présentes / requises)
///         + 30 % × (souhaitées présentes / souhaitées)
/// Les poids sont fixes : les compétences requises comptent toujours plus
/// que les souhaitées, quel que soit leur nombre. Si l'offre n'a qu'une
/// seule des deux listes, celle-ci compte pour 100 %.
///
/// Le score est une aide pour choisir, pas une garantie d'être retenu.
abstract final class MatchScore {
  static const requiredWeight = 70;
  static const preferredWeight = 30;

  /// Clé de comparaison : sans espaces en trop et sans majuscules, donc
  /// « flutter » correspond à « Flutter ». Limites assumées (comme à
  /// l'écran Vos compétences) : les accents comptent, et les synonymes ne
  /// sont pas reconnus (« JS » n'est pas « JavaScript »).
  static String _key(String skill) => SkillRules.clean(skill).toLowerCase();

  /// Compare [offer] aux compétences [skills] du candidat.
  static MatchResult compute(Offer offer, List<String> skills) {
    // Un Set rend la recherche immédiate, même avec une longue liste.
    final owned = {for (final s in skills) _key(s)};
    bool has(String skill) => owned.contains(_key(skill));

    final requiredAcquired = offer.requiredSkills.where(has).toList();
    final requiredMissing = offer.requiredSkills.where((s) => !has(s)).toList();
    final preferredAcquired = offer.preferredSkills.where(has).toList();
    final preferredMissing = offer.preferredSkills
        .where((s) => !has(s))
        .toList();

    return MatchResult(
      offer: offer,
      percent: _percent(
        requiredHave: requiredAcquired.length,
        requiredTotal: offer.requiredSkills.length,
        preferredHave: preferredAcquired.length,
        preferredTotal: offer.preferredSkills.length,
      ),
      requiredAcquired: requiredAcquired,
      requiredMissing: requiredMissing,
      preferredAcquired: preferredAcquired,
      preferredMissing: preferredMissing,
    );
  }

  /// Calcul en nombres entiers (division entière ~/) plutôt qu'en nombres
  /// à virgule : 0,7 × 100 donne parfois 70,00000000000001 en machine.
  /// La division entière arrondit vers le bas : on n'affiche jamais 100 %
  /// s'il manque une compétence.
  static int _percent({
    required int requiredHave,
    required int requiredTotal,
    required int preferredHave,
    required int preferredTotal,
  }) {
    if (requiredTotal == 0 && preferredTotal == 0) return 0;
    if (preferredTotal == 0) return 100 * requiredHave ~/ requiredTotal;
    if (requiredTotal == 0) return 100 * preferredHave ~/ preferredTotal;

    // 70 × a/b + 30 × c/d, mis au même dénominateur b × d.
    final numerator =
        requiredWeight * requiredHave * preferredTotal +
        preferredWeight * preferredHave * requiredTotal;
    return numerator ~/ (requiredTotal * preferredTotal);
  }

  /// Calcule le score de chaque offre, puis les trie du meilleur score au
  /// plus faible. À score égal, l'ordre alphabétique du titre départage :
  /// l'ordre reste ainsi le même à chaque ouverture de l'écran.
  static List<MatchResult> rank(List<Offer> offers, List<String> skills) {
    final results = [for (final o in offers) compute(o, skills)];
    results.sort((a, b) {
      final byScore = b.percent.compareTo(a.percent);
      if (byScore != 0) return byScore;
      return a.offer.title.toLowerCase().compareTo(b.offer.title.toLowerCase());
    });
    return results;
  }
}
