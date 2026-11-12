namespace SkillMatch.Core.Trainings;

/// <summary>
/// Une formation telle qu'une source la fournit, avant contrôle et
/// enregistrement. Simples données, sans lien avec la base, comme JobPosting.
/// </summary>
/// <param name="ExternalId">Identifiant de la formation chez la source : sert à la retrouver lors d'un nouvel import.</param>
/// <param name="Skill">Compétence que la formation aide à apprendre (« Docker »).</param>
/// <param name="Hours">Durée indicative, en heures entières.</param>
/// <param name="Url">Lien vers la formation, ou null (cas des formations d'exemple).</param>
public sealed record TrainingPosting(
    string ExternalId,
    string Skill,
    string Title,
    TrainingLevel Level,
    int Hours,
    TrainingType Type,
    string? Url);
