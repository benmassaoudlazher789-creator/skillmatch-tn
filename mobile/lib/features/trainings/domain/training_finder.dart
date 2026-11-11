import '../../skills/domain/skill_rules.dart';
import 'training.dart';

/// Recherche des formations d'une compétence.
///
/// Du Dart pur, sans Flutter (comme SkillRules) : testable sans écran.
abstract final class TrainingFinder {
  /// Formations de [catalog] qui correspondent à [skill], de la plus
  /// accessible à la plus avancée.
  ///
  /// La compétence est comparée avec SkillRules.key, comme pour le score :
  /// « docker » trouve les formations « Docker ».
  ///
  /// Ordre : niveau (Débutant d'abord), puis durée (la plus courte
  /// d'abord), puis titre. Un ordre complet garantit le même affichage à
  /// chaque ouverture.
  static List<Training> forSkill(String skill, List<Training> catalog) {
    final key = SkillRules.key(skill);
    final found = catalog.where((t) => SkillRules.key(t.skill) == key).toList()
      ..sort((a, b) {
        final byLevel = a.level.index.compareTo(b.level.index);
        if (byLevel != 0) return byLevel;
        final byHours = a.hours.compareTo(b.hours);
        if (byHours != 0) return byHours;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return found;
  }
}
