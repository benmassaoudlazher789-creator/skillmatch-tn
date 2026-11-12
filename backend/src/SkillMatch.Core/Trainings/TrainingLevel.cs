namespace SkillMatch.Core.Trainings;

/// <summary>
/// Niveau d'une formation. L'ordre de déclaration compte : il sert au tri
/// (Débutant d'abord), comme dans l'application mobile.
/// </summary>
public enum TrainingLevel
{
    Debutant,
    Intermediaire,
    Avance,
}

/// <summary>Forme de la formation.</summary>
public enum TrainingType
{
    CoursEnLigne,
    Tutoriel,
    ProjetPratique,
}

/// <summary>
/// Codes texte stables, utilisés en base et dans le JSON (« debutant »,
/// « cours_en_ligne »…). Même raison que pour JobCodes : une ligne SQL se lit
/// sans tableau de correspondance, et réordonner un enum ne change pas le
/// sens des données déjà enregistrées.
/// </summary>
public static class TrainingCodes
{
    /// <summary>« projet_pratique » (15 caractères) est le plus long code.</summary>
    public const int MaxCodeLength = 20;

    public static string ToCode(TrainingLevel level) => level switch
    {
        TrainingLevel.Debutant => "debutant",
        TrainingLevel.Intermediaire => "intermediaire",
        TrainingLevel.Avance => "avance",
        _ => throw new ArgumentOutOfRangeException(nameof(level), level, "Niveau de formation inconnu."),
    };

    public static TrainingLevel ToLevel(string code) => code switch
    {
        "debutant" => TrainingLevel.Debutant,
        "intermediaire" => TrainingLevel.Intermediaire,
        "avance" => TrainingLevel.Avance,
        _ => throw new ArgumentOutOfRangeException(nameof(code), code, "Code de niveau inconnu."),
    };

    public static string ToCode(TrainingType type) => type switch
    {
        TrainingType.CoursEnLigne => "cours_en_ligne",
        TrainingType.Tutoriel => "tutoriel",
        TrainingType.ProjetPratique => "projet_pratique",
        _ => throw new ArgumentOutOfRangeException(nameof(type), type, "Type de formation inconnu."),
    };

    public static TrainingType ToType(string code) => code switch
    {
        "cours_en_ligne" => TrainingType.CoursEnLigne,
        "tutoriel" => TrainingType.Tutoriel,
        "projet_pratique" => TrainingType.ProjetPratique,
        _ => throw new ArgumentOutOfRangeException(nameof(code), code, "Code de type de formation inconnu."),
    };
}
