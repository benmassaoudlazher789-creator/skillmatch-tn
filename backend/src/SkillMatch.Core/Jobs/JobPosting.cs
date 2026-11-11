namespace SkillMatch.Core.Jobs;

/// <summary>
/// Une offre telle qu'une source la fournit, avant contrôle et enregistrement.
/// Simples données, sans lien avec la base : une source n'a rien à savoir
/// d'EF Core.
/// </summary>
/// <param name="ExternalId">Identifiant de l'offre chez la source : sert à la retrouver lors d'un nouvel import.</param>
/// <param name="Url">Lien vers l'annonce d'origine, ou null.</param>
public sealed record JobPosting(
    string ExternalId,
    string Title,
    string Company,
    JobType Type,
    string City,
    string? Url,
    DateTimeOffset PublishedAt,
    IReadOnlyList<string> RequiredSkills,
    IReadOnlyList<string> PreferredSkills);
