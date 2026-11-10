namespace SkillMatch.Api.Auth;

/// <summary>
/// Réglages du jeton JWT, lus dans la section « Jwt » de la configuration.
/// Issuer, Audience et durée sont dans appsettings.json (ce ne sont pas des secrets) ;
/// SigningKey vient UNIQUEMENT de dotnet user-secrets (ou d'une variable
/// d'environnement en production), jamais d'un fichier du dépôt.
/// </summary>
public sealed class JwtOptions
{
    public const string SectionName = "Jwt";

    /// <summary>
    /// HMAC-SHA256 demande une clé d'au moins 256 bits, soit 32 octets.
    /// Une clé plus courte se casserait par essais successifs.
    /// </summary>
    public const int MinSigningKeyBytes = 32;

    // Valeurs par défaut identiques à appsettings.json : l'API reste
    // cohérente même si ce fichier n'est pas trouvé (par exemple en test).

    /// <summary>Qui émet le jeton : notre API.</summary>
    public string Issuer { get; set; } = "skillmatch-api";

    /// <summary>À qui le jeton est destiné : l'application mobile.</summary>
    public string Audience { get; set; } = "skillmatch-mobile";

    /// <summary>Clé secrète de signature. Ses octets UTF-8 servent de clé HMAC.</summary>
    public string SigningKey { get; set; } = string.Empty;

    /// <summary>
    /// 30 minutes : un jeton volé ne sert que peu de temps. Sans jeton de
    /// renouvellement, l'utilisateur se reconnecte ensuite.
    /// </summary>
    public int LifetimeMinutes { get; set; } = 30;
}
