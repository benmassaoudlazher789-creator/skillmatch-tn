namespace SkillMatch.Api.Cv;

/// <summary>
/// Limite d'analyses sur POST /cv, lue dans la section « RateLimiting:Cv ».
/// Lire un PDF demande du calcul : sans limite, quelques comptes pourraient
/// occuper le serveur en envoyant des fichiers en boucle.
/// </summary>
public sealed class CvRateLimitOptions
{
    public const string SectionName = "RateLimiting:Cv";

    /// <summary>10 analyses par minute et par compte : largement assez pour un humain.</summary>
    public const int DefaultPermitLimit = 10;

    /// <summary>Fenêtre fixe d'une minute, comme pour /auth.</summary>
    public static readonly TimeSpan Window = TimeSpan.FromMinutes(1);

    public int PermitLimit { get; set; } = DefaultPermitLimit;
}
