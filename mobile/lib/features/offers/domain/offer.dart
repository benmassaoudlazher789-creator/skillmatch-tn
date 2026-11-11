/// Les trois sortes d'offres de l'application.
///
/// Un enum « amélioré » (avec des champs) garde le libellé à côté de la
/// valeur : on n'a pas besoin d'un switch dans chaque écran pour l'afficher.
enum OfferType {
  emploi('emploi', 'Emploi', 'Emplois'),
  stage('stage', 'Stage', 'Stages'),
  pfe('pfe', 'PFE', 'PFE');

  const OfferType(this.code, this.label, this.pluralLabel);

  /// Code envoyé par l'API (« stage », « pfe », « emploi »).
  final String code;

  /// Libellé sur la carte (« Stage »).
  final String label;

  /// Libellé du filtre (« Stages »).
  final String pluralLabel;

  /// Type correspondant au code de l'API, ou null s'il est inconnu (une
  /// future version de l'API pourrait en ajouter un).
  static OfferType? fromCode(String code) {
    for (final type in values) {
      if (type.code == code) return type;
    }
    return null;
  }
}

/// Une offre d'emploi, de stage ou de PFE, avec son score pour le candidat.
///
/// Tout vient du serveur (GET /offers), score compris : l'application ne
/// calcule plus rien, elle affiche. Ainsi le calcul n'existe qu'à un seul
/// endroit, testé côté API (MatchScorer).
///
/// Classe immuable (tous les champs sont final) : une offre ne change pas
/// pendant qu'on l'affiche.
class Offer {
  const Offer({
    required this.id,
    required this.title,
    required this.company,
    required this.city,
    required this.type,
    required this.isSample,
    required this.score,
    required this.explanation,
    this.url,
    this.requiredAcquired = const [],
    this.requiredMissing = const [],
    this.preferredAcquired = const [],
    this.preferredMissing = const [],
  });

  /// Identifiant unique : sert de clé aux cartes (et aux tests).
  final String id;
  final String title;
  final String company;
  final String city;
  final OfferType type;

  /// Lien vers l'annonce d'origine, ou null.
  final String? url;

  /// Vrai pour une offre fictive : la carte affiche « Offre d'exemple ».
  final bool isSample;

  /// Score de 0 à 100, calculé par le serveur (arrondi vers le bas).
  final int score;

  /// Phrase du serveur qui dit d'où vient le score, par exemple
  /// « Requises : 2 sur 3 (70 % du score) · Souhaitées : 1 sur 2 (30 %) ».
  final String explanation;

  final List<String> requiredAcquired;
  final List<String> requiredMissing;
  final List<String> preferredAcquired;
  final List<String> preferredMissing;

  /// Compétences présentes : les requises d'abord.
  List<String> get acquired => [...requiredAcquired, ...preferredAcquired];

  /// Compétences manquantes : les requises d'abord, car ce sont elles qui
  /// font le plus monter le score.
  List<String> get missing => [...requiredMissing, ...preferredMissing];
}
