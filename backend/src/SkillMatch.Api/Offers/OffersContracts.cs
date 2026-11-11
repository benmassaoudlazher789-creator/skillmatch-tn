namespace SkillMatch.Api.Offers;

// Corps JSON renvoyés par GET /offers.

/// <summary>Réponse 200 : les offres, du meilleur score au plus faible.</summary>
public sealed record OffersResponse(IReadOnlyList<OfferResponse> Offers);

/// <summary>
/// Une offre et son score pour le candidat.
/// Type : « stage », « pfe » ou « emploi ». Score : 0 à 100, arrondi vers le bas.
/// IsSample : vrai pour une offre fictive, que l'application doit présenter
/// comme un exemple.
/// </summary>
public sealed record OfferResponse(
    Guid Id,
    string Title,
    string Company,
    string Type,
    string City,
    string? Url,
    string Source,
    bool IsSample,
    DateTimeOffset PublishedAt,
    int Score,
    IReadOnlyList<string> RequiredAcquired,
    IReadOnlyList<string> RequiredMissing,
    IReadOnlyList<string> PreferredAcquired,
    IReadOnlyList<string> PreferredMissing,
    string Explanation);

/// <summary>Erreur de GET /offers, même forme que celles de POST /cv.</summary>
public sealed record OffersErrorResponse(string Code, string Title);

/// <summary>Codes d'erreur de GET /offers, partagés avec les tests.</summary>
public static class OffersErrorCodes
{
    public const string TooManySkills = "too_many_skills";
    public const string SkillTooLong = "skill_too_long";
    public const string InvalidLimit = "invalid_limit";
}
