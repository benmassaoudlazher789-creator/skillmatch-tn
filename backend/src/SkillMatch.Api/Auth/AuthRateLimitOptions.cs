namespace SkillMatch.Api.Auth;

/// <summary>
/// Limite d'essais sur /auth/*, lue dans la section « RateLimiting:Auth ».
/// Configurable pour que les tests puissent la relever sans la désactiver.
/// </summary>
public sealed class AuthRateLimitOptions
{
    public const string SectionName = "RateLimiting:Auth";

    /// <summary>
    /// 5 requêtes par minute et par adresse IP : assez pour un humain qui se
    /// trompe, beaucoup trop peu pour essayer une liste de mots de passe.
    /// </summary>
    public const int DefaultPermitLimit = 5;

    /// <summary>Fenêtre fixe d'une minute (non configurable, pour rester simple).</summary>
    public static readonly TimeSpan Window = TimeSpan.FromMinutes(1);

    public int PermitLimit { get; set; } = DefaultPermitLimit;
}
