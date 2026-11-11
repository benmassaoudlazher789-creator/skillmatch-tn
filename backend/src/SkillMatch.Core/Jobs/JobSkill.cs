namespace SkillMatch.Core.Jobs;

/// <summary>
/// Une compétence demandée par une offre, requise ou souhaitée.
/// Créée et modifiée seulement par <see cref="Job"/>, qui contrôle les règles
/// (longueur, pas de doublon).
/// </summary>
public sealed class JobSkill
{
    /// <summary>40 caractères, comme une compétence saisie dans l'application mobile.</summary>
    public const int MaxNameLength = 40;

    /// <summary>Offre à laquelle la compétence appartient (rempli par EF Core).</summary>
    public Guid JobId { get; private set; }

    /// <summary>Nom affiché, tel que l'offre l'écrit (« Power BI »).</summary>
    public string Name { get; private set; } = string.Empty;

    public SkillImportance Importance { get; internal set; }

    // Constructeur vide réservé à EF Core.
    private JobSkill()
    {
    }

    internal JobSkill(string name, SkillImportance importance)
    {
        Name = name;
        Importance = importance;
    }
}
