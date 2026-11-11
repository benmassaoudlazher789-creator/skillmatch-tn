using SkillMatch.Core.Skills;

namespace SkillMatch.Core.Cv;

/// <summary>Raisons pour lesquelles un CV ne peut pas être analysé.</summary>
public enum CvError
{
    /// <summary>Fichier de 0 octet.</summary>
    Empty,

    /// <summary>Plus de 5 Mo.</summary>
    TooLarge,

    /// <summary>Ni PDF ni DOCX (d'après le contenu), ou DOCX avec macros.</summary>
    UnsupportedType,

    /// <summary>PDF protégé par un mot de passe.</summary>
    PasswordProtected,

    /// <summary>Fichier abîmé, piégé ou trop complexe.</summary>
    Unreadable,

    /// <summary>Aucun texte : souvent un CV scanné (une image).</summary>
    NoText,
}

/// <summary>Texte lu dans un CV, ou la raison de l'échec.</summary>
public sealed record CvTextExtraction(string? Text, CvError? Error)
{
    public static CvTextExtraction Success(string text) => new(text, null);

    public static CvTextExtraction Failure(CvError error) => new(null, error);

    // Le ToString généré afficherait tout le texte du CV. On le remplace pour
    // qu'un log écrit par erreur ne contienne jamais le contenu.
    public override string ToString() =>
        Error is { } error ? $"CvTextExtraction {{ Error = {error} }}" : "CvTextExtraction { Text = (masqué) }";
}

/// <summary>Lit le texte d'un CV. Interface : l'analyse se teste avec un faux extracteur.</summary>
public interface ICvTextExtractor
{
    CvTextExtraction Extract(byte[] content, CvFileKind kind, CancellationToken cancellationToken);
}

/// <summary>Résultat d'une analyse : compétences détectées, ou la raison de l'échec.</summary>
public sealed record CvAnalysisResult(IReadOnlyList<string> Skills, CvError? Error)
{
    public static CvAnalysisResult Success(IReadOnlyList<string> skills) => new(skills, null);

    public static CvAnalysisResult Failure(CvError error) => new([], error);
}

/// <summary>
/// Enchaîne les étapes : taille, type par signature, texte, compétences.
///
/// Confidentialité (choix validé) : le CV est lu en mémoire puis oublié.
/// Cette classe ne garde rien, n'écrit rien sur le disque ni en base, et ne
/// journalise rien.
/// </summary>
public sealed class CvAnalyzer(ICvTextExtractor extractor)
{
    public CvAnalysisResult Analyze(byte[] content, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(content);

        if (content.Length == 0)
        {
            return CvAnalysisResult.Failure(CvError.Empty);
        }

        if (content.Length > CvLimits.MaxFileBytes)
        {
            return CvAnalysisResult.Failure(CvError.TooLarge);
        }

        if (CvFileType.Detect(content) is not { } kind)
        {
            return CvAnalysisResult.Failure(CvError.UnsupportedType);
        }

        var extraction = extractor.Extract(content, kind, cancellationToken);
        if (extraction.Error is { } error)
        {
            return CvAnalysisResult.Failure(error);
        }

        if (string.IsNullOrWhiteSpace(extraction.Text))
        {
            return CvAnalysisResult.Failure(CvError.NoText);
        }

        return CvAnalysisResult.Success(SkillDetector.Detect(extraction.Text));
    }
}
