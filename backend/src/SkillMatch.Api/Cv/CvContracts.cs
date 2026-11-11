namespace SkillMatch.Api.Cv;

// Corps JSON renvoyés par POST /cv.

/// <summary>Réponse 200 : les compétences détectées (la liste peut être vide).</summary>
public sealed record CvAnalysisResponse(IReadOnlyList<string> Skills);

/// <summary>
/// Erreur de POST /cv. « Code » est stable et sert à l'application pour
/// choisir son message ; « Title » est un message en français lisible.
/// </summary>
public sealed record CvErrorResponse(string Code, string Title);

/// <summary>Codes d'erreur de POST /cv, partagés avec les tests.</summary>
public static class CvErrorCodes
{
    public const string InvalidRequest = "invalid_request";
    public const string NoFile = "no_file";
    public const string TooManyFiles = "too_many_files";
    public const string Empty = "empty";
    public const string TooLarge = "too_large";
    public const string UnsupportedType = "unsupported_type";
    public const string PasswordProtected = "password_protected";
    public const string Unreadable = "unreadable";
    public const string NoText = "no_text";
}
