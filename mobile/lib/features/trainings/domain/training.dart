/// Niveau d'une formation. L'ordre de déclaration compte : il sert au tri
/// (Débutant d'abord), grâce à l'index de chaque valeur.
enum TrainingLevel {
  debutant('Débutant'),
  intermediaire('Intermédiaire'),
  avance('Avancé');

  const TrainingLevel(this.label);
  final String label;
}

/// Forme de la formation.
enum TrainingType {
  coursEnLigne('Cours en ligne'),
  tutoriel('Tutoriel'),
  projetPratique('Projet pratique');

  const TrainingType(this.label);
  final String label;
}

/// Une formation suggérée pour apprendre une compétence.
///
/// Classe immuable, comme Offer : elle ne change pas pendant l'affichage.
class Training {
  const Training({
    required this.id,
    required this.skill,
    required this.title,
    required this.level,
    required this.hours,
    required this.type,
  });

  /// Identifiant unique : sert de clé aux cartes (et aux tests).
  final String id;

  /// Compétence que cette formation aide à apprendre.
  final String skill;

  final String title;
  final TrainingLevel level;

  /// Durée indicative, en heures. On stocke un nombre (et non un texte)
  /// pour pouvoir trier les formations par durée.
  final int hours;

  final TrainingType type;

  /// Durée affichée. « environ » rappelle qu'elle n'est qu'indicative.
  String get durationLabel => 'environ $hours h';
}
