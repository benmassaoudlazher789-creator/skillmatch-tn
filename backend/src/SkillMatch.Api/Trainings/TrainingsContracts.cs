namespace SkillMatch.Api.Trainings;

// Corps JSON renvoyés par GET /trainings.

/// <summary>
/// Réponse 200 : la compétence demandée (nettoyée) et ses formations, de la
/// plus accessible à la plus avancée. Une liste vide n'est pas une erreur.
/// </summary>
public sealed record TrainingsResponse(string Skill, IReadOnlyList<TrainingResponse> Trainings);

/// <summary>
/// Une formation. Level : « debutant », « intermediaire » ou « avance ».
/// Type : « cours_en_ligne », « tutoriel » ou « projet_pratique ».
/// Url : null pour les formations d'exemple. IsSample : vrai pour une
/// formation fictive, que l'application doit présenter comme un exemple.
/// </summary>
public sealed record TrainingResponse(
    Guid Id,
    string Skill,
    string Title,
    string Level,
    int Hours,
    string Type,
    string? Url,
    string Source,
    bool IsSample);

/// <summary>Erreur de GET /trainings, même forme que celles de /offers et /cv.</summary>
public sealed record TrainingsErrorResponse(string Code, string Title);

/// <summary>Codes d'erreur de GET /trainings, partagés avec les tests.</summary>
public static class TrainingsErrorCodes
{
    public const string MissingSkill = "missing_skill";
    public const string TooManySkills = "too_many_skills";
    public const string SkillTooLong = "skill_too_long";
}
