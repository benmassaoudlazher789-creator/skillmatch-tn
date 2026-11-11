namespace SkillMatch.Core.Jobs;

/// <summary>Les trois sortes d'offres de SkillMatch TN.</summary>
public enum JobType
{
    Stage,
    Pfe,
    Emploi,
}

/// <summary>Importance d'une compétence dans une offre.</summary>
public enum SkillImportance
{
    /// <summary>Demandée : pèse 70 % du score.</summary>
    Required,

    /// <summary>Appréciée (un plus) : pèse 30 % du score.</summary>
    Preferred,
}

/// <summary>
/// Codes texte stables, utilisés en base et dans le JSON (« stage », « pfe »,
/// « emploi », « required », « preferred »).
///
/// Pourquoi du texte plutôt que le numéro de l'enum ? Une ligne SQL se lit
/// sans tableau de correspondance, et réordonner l'enum un jour ne change
/// pas le sens des données déjà enregistrées.
/// </summary>
public static class JobCodes
{
    public const int MaxCodeLength = 10;

    public static string ToCode(JobType type) => type switch
    {
        JobType.Stage => "stage",
        JobType.Pfe => "pfe",
        JobType.Emploi => "emploi",
        _ => throw new ArgumentOutOfRangeException(nameof(type), type, "Type d'offre inconnu."),
    };

    public static JobType ToJobType(string code) => code switch
    {
        "stage" => JobType.Stage,
        "pfe" => JobType.Pfe,
        "emploi" => JobType.Emploi,
        _ => throw new ArgumentOutOfRangeException(nameof(code), code, "Code de type d'offre inconnu."),
    };

    public static string ToCode(SkillImportance importance) => importance switch
    {
        SkillImportance.Required => "required",
        SkillImportance.Preferred => "preferred",
        _ => throw new ArgumentOutOfRangeException(nameof(importance), importance, "Importance inconnue."),
    };

    public static SkillImportance ToImportance(string code) => code switch
    {
        "required" => SkillImportance.Required,
        "preferred" => SkillImportance.Preferred,
        _ => throw new ArgumentOutOfRangeException(nameof(code), code, "Code d'importance inconnu."),
    };
}
