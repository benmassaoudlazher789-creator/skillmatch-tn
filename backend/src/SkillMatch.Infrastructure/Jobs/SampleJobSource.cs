using SkillMatch.Core.Jobs;

namespace SkillMatch.Infrastructure.Jobs;

/// <summary>
/// Jeu d'offres d'EXEMPLE, pour développer et faire une démonstration avant
/// qu'une vraie source soit branchée.
///
/// Tout y est fictif et marqué comme tel :
/// - la source s'appelle « exemple » et chaque offre a IsSample = true ;
///   l'application l'affiche donc comme exemple ;
/// - les entreprises sont des noms inventés (« Société Exemple Alpha »…) ;
/// - les liens pointent vers example.com, un domaine réservé par l'IANA
///   justement pour les exemples : il n'appartient à personne ;
/// - aucune donnée des maquettes (noms, entreprises, salaires, chiffres).
///
/// Les compétences reprennent exactement les noms du SkillDictionary, pour
/// que la comparaison avec un CV analysé fonctionne (un test le vérifie).
///
/// Cette classe n'est volontairement PAS enregistrée comme IJobSource : seul
/// l'import de démarrage en développement s'en sert. Une future vraie source
/// ne risque donc pas d'importer ces exemples en production.
/// </summary>
public sealed class SampleJobSource : IJobSource
{
    public const string SourceName = "exemple";

    public string Name => SourceName;

    public bool IsSample => true;

    public Task<IReadOnlyList<JobPosting>> FetchAsync(CancellationToken cancellationToken) =>
        Task.FromResult(Postings);

    /// <summary>Les offres d'exemple, toujours les mêmes (dates fixes : des tests simples).</summary>
    public static IReadOnlyList<JobPosting> Postings { get; } =
    [
        Posting(1, "Stage développeur mobile Flutter", "Alpha", JobType.Stage, "Tunis", 2026, 10, 28,
            ["Flutter", "Dart", "Git"], ["Firebase", "API REST"]),
        Posting(2, "PFE application web de gestion de stock", "Bêta", JobType.Pfe, "Sfax", 2026, 10, 25,
            ["Angular", "TypeScript", "Spring Boot"], ["PostgreSQL", "Docker"]),
        Posting(3, "Développeur back-end .NET junior", "Gamma", JobType.Emploi, "Tunis", 2026, 10, 22,
            ["C#", ".NET", "SQL"], ["Azure", "Docker", "Tests unitaires"]),
        Posting(4, "Stage analyse de données", "Delta", JobType.Stage, "Sousse", 2026, 10, 20,
            ["Python", "Pandas", "SQL"], ["Power BI", "Excel"]),
        Posting(5, "PFE détection d'anomalies par machine learning", "Epsilon", JobType.Pfe, "Ariana", 2026, 10, 18,
            ["Python", "Machine learning", "Scikit-learn"], ["TensorFlow", "Git"]),
        Posting(6, "Développeur front-end React", "Zêta", JobType.Emploi, "Tunis", 2026, 10, 15,
            ["React", "JavaScript", "HTML", "CSS"], ["TypeScript", "Tailwind CSS"]),
        Posting(7, "Stage administration systèmes et réseaux", "Êta", JobType.Stage, "Monastir", 2026, 10, 12,
            ["Linux", "Réseaux"], ["Docker", "Windows"]),
        Posting(8, "Ingénieur DevOps junior", "Thêta", JobType.Emploi, "Tunis", 2026, 10, 10,
            ["Docker", "Kubernetes", "CI/CD", "Linux"], ["AWS", "Jenkins"]),
        Posting(9, "PFE application mobile de suivi de livraisons", "Iota", JobType.Pfe, "Sfax", 2026, 10, 8,
            ["Flutter", "Firebase"], ["Google Cloud", "API REST"]),
        Posting(10, "Stage design d'interfaces", "Kappa", JobType.Stage, "Nabeul", 2026, 10, 5,
            ["Figma"], ["Adobe XD", "Illustrator", "Photoshop"]),
        Posting(11, "Développeur PHP Laravel", "Lambda", JobType.Emploi, "Sousse", 2026, 10, 3,
            ["PHP", "Laravel", "MySQL"], ["Vue.js", "Git"]),
        Posting(12, "PFE conception mécanique assistée par ordinateur", "Mu", JobType.Pfe, "Bizerte", 2026, 10, 1,
            ["SolidWorks", "AutoCAD"], ["MATLAB"]),
    ];

    private static JobPosting Posting(
        int number,
        string title,
        string companySuffix,
        JobType type,
        string city,
        int year,
        int month,
        int day,
        string[] required,
        string[] preferred) =>
        new(
            ExternalId: $"exemple-{number:000}",
            Title: title,
            Company: $"Société Exemple {companySuffix}",
            Type: type,
            City: city,
            Url: $"https://example.com/offres-exemple/{number:000}",
            PublishedAt: new DateTimeOffset(year, month, day, 9, 0, 0, TimeSpan.Zero),
            RequiredSkills: required,
            PreferredSkills: preferred);
}
