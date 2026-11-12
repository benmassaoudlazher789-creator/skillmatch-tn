using SkillMatch.Core.Trainings;

namespace SkillMatch.Infrastructure.Trainings;

/// <summary>
/// Jeu de formations d'EXEMPLE, pour développer et faire une démonstration
/// avant qu'une vraie source soit branchée.
///
/// Tout y est fictif et marqué comme tel :
/// - la source s'appelle « exemple » et chaque formation a IsSample = true ;
///   l'application l'affiche donc comme exemple ;
/// - titres inventés, sans nom de plateforme ni de société, sans prix ;
/// - aucun lien (choix validé) : l'application n'affiche pas de bouton
///   « ouvrir » pour une formation qui n'existe pas.
///
/// Ce sont les mêmes formations que l'ancien jeu en mémoire de l'application
/// (sample_trainings.dart), avec les mêmes identifiants. Windows, Linux et
/// Réseaux n'ont volontairement aucune formation : on peut ainsi voir le cas
/// « aucune formation » dans l'application.
///
/// Les compétences reprennent exactement les noms du SkillDictionary (un
/// test le vérifie).
///
/// Cette classe n'est volontairement PAS enregistrée comme ITrainingSource :
/// seul l'import de démarrage en développement s'en sert. Une future vraie
/// source ne risque donc pas d'importer ces exemples en production.
/// </summary>
public sealed class SampleTrainingSource : ITrainingSource
{
    public const string SourceName = "exemple";

    public string Name => SourceName;

    public bool IsSample => true;

    public Task<IReadOnlyList<TrainingPosting>> FetchAsync(CancellationToken cancellationToken) =>
        Task.FromResult(Postings);

    /// <summary>Les formations d'exemple, toujours les mêmes.</summary>
    public static IReadOnlyList<TrainingPosting> Postings { get; } =
    [
        // --- Docker ---
        Posting("docker-1", "Docker", "Premiers pas avec les conteneurs", TrainingLevel.Debutant, 3, TrainingType.CoursEnLigne),
        Posting("docker-2", "Docker", "Conteneuriser une petite API", TrainingLevel.Intermediaire, 6, TrainingType.ProjetPratique),

        // --- Firebase ---
        Posting("firebase-1", "Firebase", "Connecter une application mobile à une base en ligne", TrainingLevel.Debutant, 2, TrainingType.Tutoriel),
        Posting("firebase-2", "Firebase", "Authentification et stockage : un projet d'entraînement", TrainingLevel.Intermediaire, 8, TrainingType.ProjetPratique),

        // --- Tests unitaires ---
        Posting("tests-1", "Tests unitaires", "Écrire ses premiers tests unitaires", TrainingLevel.Debutant, 2, TrainingType.Tutoriel),
        Posting("tests-2", "Tests unitaires", "Tester une application de bout en bout", TrainingLevel.Intermediaire, 5, TrainingType.CoursEnLigne),

        // --- Figma ---
        Posting("figma-1", "Figma", "Maquetter un écran d'application", TrainingLevel.Debutant, 3, TrainingType.ProjetPratique),

        // --- API REST ---
        Posting("api-1", "API REST", "Comprendre les API REST en partant d'exemples", TrainingLevel.Debutant, 2, TrainingType.CoursEnLigne),
        Posting("api-2", "API REST", "Concevoir une API pour une application de stock", TrainingLevel.Intermediaire, 10, TrainingType.ProjetPratique),

        // --- JavaScript ---
        Posting("js-1", "JavaScript", "Les bases de JavaScript", TrainingLevel.Debutant, 6, TrainingType.CoursEnLigne),
        Posting("js-2", "JavaScript", "Manipuler une page web pas à pas", TrainingLevel.Debutant, 3, TrainingType.Tutoriel),

        // --- React ---
        Posting("react-1", "React", "Construire une interface avec des composants", TrainingLevel.Debutant, 5, TrainingType.CoursEnLigne),
        Posting("react-2", "React", "Une liste de tâches en React", TrainingLevel.Intermediaire, 4, TrainingType.ProjetPratique),

        // --- Node.js ---
        Posting("node-1", "Node.js", "Un petit serveur web avec Node.js", TrainingLevel.Debutant, 3, TrainingType.Tutoriel),

        // --- Python ---
        Posting("python-1", "Python", "Python pour débuter", TrainingLevel.Debutant, 8, TrainingType.CoursEnLigne),
        Posting("python-2", "Python", "Analyser un fichier de données avec Python", TrainingLevel.Intermediaire, 4, TrainingType.ProjetPratique),

        // --- Power BI ---
        Posting("powerbi-1", "Power BI", "Créer un premier tableau de bord", TrainingLevel.Debutant, 3, TrainingType.Tutoriel),
    ];

    // Url toujours null : voir le commentaire de la classe.
    private static TrainingPosting Posting(
        string externalId,
        string skill,
        string title,
        TrainingLevel level,
        int hours,
        TrainingType type) =>
        new(externalId, skill, title, level, hours, type, Url: null);
}
