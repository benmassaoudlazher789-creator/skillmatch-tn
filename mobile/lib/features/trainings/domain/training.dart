/// Niveau d'une formation, avec le code envoyé par l'API (« debutant »…).
enum TrainingLevel {
  debutant('debutant', 'Débutant'),
  intermediaire('intermediaire', 'Intermédiaire'),
  avance('avance', 'Avancé');

  const TrainingLevel(this.code, this.label);

  /// Code de l'API.
  final String code;

  /// Libellé affiché sur la carte.
  final String label;

  /// Niveau correspondant au code de l'API, ou null s'il est inconnu (une
  /// future version de l'API pourrait en ajouter un).
  static TrainingLevel? fromCode(String code) {
    for (final level in values) {
      if (level.code == code) return level;
    }
    return null;
  }
}

/// Forme de la formation, avec le code envoyé par l'API.
enum TrainingType {
  coursEnLigne('cours_en_ligne', 'Cours en ligne'),
  tutoriel('tutoriel', 'Tutoriel'),
  projetPratique('projet_pratique', 'Projet pratique');

  const TrainingType(this.code, this.label);

  final String code;
  final String label;

  /// Type correspondant au code de l'API, ou null s'il est inconnu.
  static TrainingType? fromCode(String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// Une formation suggérée pour apprendre une compétence, telle que le
/// serveur la renvoie (GET /trainings).
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
    required this.isSample,
    this.url,
  });

  /// Identifiant donné par le serveur : sert de clé aux cartes (et aux tests).
  final String id;

  /// Compétence que cette formation aide à apprendre.
  final String skill;

  final String title;
  final TrainingLevel level;

  /// Durée indicative, en heures.
  final int hours;

  final TrainingType type;

  /// Vrai pour une formation inventée : la carte porte alors le badge
  /// « Formation d'exemple ».
  final bool isSample;

  /// Lien vers la formation, ou null. Gardé pour une vraie source plus
  /// tard, mais jamais affiché pour l'instant (choix validé : pas de bouton
  /// de lien, donc pas de dépendance url_launcher).
  final String? url;

  /// Durée affichée. « environ » rappelle qu'elle n'est qu'indicative.
  String get durationLabel => 'environ $hours h';
}
