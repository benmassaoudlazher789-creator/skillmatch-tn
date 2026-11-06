import '../domain/training.dart';

/// Formations d'exemple, en mémoire, affichées tant que l'API n'existe pas.
///
/// Titres inventés, sans nom de plateforme ni de société, sans prix ni
/// lien : l'écran marque chaque carte « Formation d'exemple ».
///
/// Elles couvrent une partie des compétences manquantes des offres
/// d'exemple. Windows, Linux et Réseaux n'ont volontairement aucune
/// formation : on peut ainsi voir le cas « aucune formation » dans
/// l'application.
const sampleTrainings = [
  // --- Docker ---
  Training(
    id: 'docker-1',
    skill: 'Docker',
    title: 'Premiers pas avec les conteneurs',
    level: TrainingLevel.debutant,
    hours: 3,
    type: TrainingType.coursEnLigne,
  ),
  Training(
    id: 'docker-2',
    skill: 'Docker',
    title: 'Conteneuriser une petite API',
    level: TrainingLevel.intermediaire,
    hours: 6,
    type: TrainingType.projetPratique,
  ),
  // --- Firebase ---
  Training(
    id: 'firebase-1',
    skill: 'Firebase',
    title: 'Connecter une application mobile à une base en ligne',
    level: TrainingLevel.debutant,
    hours: 2,
    type: TrainingType.tutoriel,
  ),
  Training(
    id: 'firebase-2',
    skill: 'Firebase',
    title: "Authentification et stockage : un projet d'entraînement",
    level: TrainingLevel.intermediaire,
    hours: 8,
    type: TrainingType.projetPratique,
  ),
  // --- Tests unitaires ---
  Training(
    id: 'tests-1',
    skill: 'Tests unitaires',
    title: 'Écrire ses premiers tests unitaires',
    level: TrainingLevel.debutant,
    hours: 2,
    type: TrainingType.tutoriel,
  ),
  Training(
    id: 'tests-2',
    skill: 'Tests unitaires',
    title: 'Tester une application de bout en bout',
    level: TrainingLevel.intermediaire,
    hours: 5,
    type: TrainingType.coursEnLigne,
  ),
  // --- Figma ---
  Training(
    id: 'figma-1',
    skill: 'Figma',
    title: "Maquetter un écran d'application",
    level: TrainingLevel.debutant,
    hours: 3,
    type: TrainingType.projetPratique,
  ),
  // --- API REST ---
  Training(
    id: 'api-1',
    skill: 'API REST',
    title: "Comprendre les API REST en partant d'exemples",
    level: TrainingLevel.debutant,
    hours: 2,
    type: TrainingType.coursEnLigne,
  ),
  Training(
    id: 'api-2',
    skill: 'API REST',
    title: 'Concevoir une API pour une application de stock',
    level: TrainingLevel.intermediaire,
    hours: 10,
    type: TrainingType.projetPratique,
  ),
  // --- JavaScript ---
  Training(
    id: 'js-1',
    skill: 'JavaScript',
    title: 'Les bases de JavaScript',
    level: TrainingLevel.debutant,
    hours: 6,
    type: TrainingType.coursEnLigne,
  ),
  Training(
    id: 'js-2',
    skill: 'JavaScript',
    title: 'Manipuler une page web pas à pas',
    level: TrainingLevel.debutant,
    hours: 3,
    type: TrainingType.tutoriel,
  ),
  // --- React ---
  Training(
    id: 'react-1',
    skill: 'React',
    title: 'Construire une interface avec des composants',
    level: TrainingLevel.debutant,
    hours: 5,
    type: TrainingType.coursEnLigne,
  ),
  Training(
    id: 'react-2',
    skill: 'React',
    title: 'Une liste de tâches en React',
    level: TrainingLevel.intermediaire,
    hours: 4,
    type: TrainingType.projetPratique,
  ),
  // --- Node.js ---
  Training(
    id: 'node-1',
    skill: 'Node.js',
    title: 'Un petit serveur web avec Node.js',
    level: TrainingLevel.debutant,
    hours: 3,
    type: TrainingType.tutoriel,
  ),
  // --- Python ---
  Training(
    id: 'python-1',
    skill: 'Python',
    title: 'Python pour débuter',
    level: TrainingLevel.debutant,
    hours: 8,
    type: TrainingType.coursEnLigne,
  ),
  Training(
    id: 'python-2',
    skill: 'Python',
    title: 'Analyser un fichier de données avec Python',
    level: TrainingLevel.intermediaire,
    hours: 4,
    type: TrainingType.projetPratique,
  ),
  // --- Power BI ---
  Training(
    id: 'powerbi-1',
    skill: 'Power BI',
    title: 'Créer un premier tableau de bord',
    level: TrainingLevel.debutant,
    hours: 3,
    type: TrainingType.tutoriel,
  ),
];
