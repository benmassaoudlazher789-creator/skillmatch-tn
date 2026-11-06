/// Les trois sortes d'offres de l'application.
///
/// Un enum « amélioré » (avec des champs) garde le libellé à côté de la
/// valeur : on n'a pas besoin d'un switch dans chaque écran pour l'afficher.
enum OfferType {
  emploi('Emploi', 'Emplois'),
  stage('Stage', 'Stages'),
  pfe('PFE', 'PFE');

  const OfferType(this.label, this.pluralLabel);

  /// Libellé sur la carte (« Stage »).
  final String label;

  /// Libellé du filtre (« Stages »).
  final String pluralLabel;
}

/// Une offre d'emploi, de stage ou de PFE.
///
/// Classe immuable (tous les champs sont final) : une offre ne change pas
/// pendant qu'on l'affiche, ce qui évite des erreurs difficiles à suivre.
class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.type,
    required this.requiredSkills,
    this.preferredSkills = const [],
  });

  /// Identifiant unique : sert de clé aux cartes (et aux tests).
  final String id;
  final String title;
  final String company;
  final String city;
  final OfferType type;

  /// Compétences demandées : elles pèsent le plus dans le score.
  final List<String> requiredSkills;

  /// Compétences « appréciées » : un plus, qui pèse moins dans le score.
  final List<String> preferredSkills;
}
