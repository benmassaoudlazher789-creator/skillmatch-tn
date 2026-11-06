import '../domain/offer.dart';

/// Offres d'exemple, en mémoire, affichées tant que l'API n'existe pas.
///
/// Les entreprises sont inventées (leur nom contient « Exemple ») et
/// l'écran marque chaque carte « Offre d'exemple ». Pas de salaire ni de
/// source : on ne veut rien faire passer pour une vraie annonce.
/// Elles seront remplacées par les offres de l'API dans une prochaine
/// version.
const sampleOffers = [
  Offer(
    id: 'exemple-1',
    title: 'Développeur Flutter junior',
    company: 'Atelier Exemple Mobile',
    city: 'Tunis',
    type: OfferType.emploi,
    requiredSkills: ['Dart', 'Flutter', 'Git'],
    preferredSkills: ['Firebase', 'Tests unitaires'],
  ),
  Offer(
    id: 'exemple-2',
    title: 'Stage développement mobile',
    company: 'Studio Exemple Web',
    city: 'Sousse',
    type: OfferType.stage,
    requiredSkills: ['Flutter', 'Dart'],
    preferredSkills: ['Git', 'Figma'],
  ),
  Offer(
    id: 'exemple-3',
    title: 'PFE application de gestion de stock',
    company: 'Exemple Logiciels',
    city: 'Sfax',
    type: OfferType.pfe,
    requiredSkills: ['Flutter', 'SQL', 'API REST'],
    preferredSkills: ['Docker'],
  ),
  Offer(
    id: 'exemple-4',
    title: 'Développeur web junior',
    company: 'Exemple Systèmes',
    city: 'Ariana',
    type: OfferType.emploi,
    requiredSkills: ['JavaScript', 'React', 'SQL'],
    preferredSkills: ['Git', 'Node.js'],
  ),
  Offer(
    id: 'exemple-5',
    title: 'PFE tableau de bord de données',
    company: 'Exemple Data Lab',
    city: 'Monastir',
    type: OfferType.pfe,
    requiredSkills: ['Python', 'SQL', 'Power BI'],
    preferredSkills: ['Git'],
  ),
  Offer(
    id: 'exemple-6',
    title: 'Stage support informatique',
    company: 'Exemple Conseil IT',
    city: 'Bizerte',
    type: OfferType.stage,
    requiredSkills: ['Windows', 'Réseaux'],
    preferredSkills: ['Linux'],
  ),
];
