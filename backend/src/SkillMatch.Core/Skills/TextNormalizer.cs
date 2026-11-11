using System.Globalization;
using System.Text;

namespace SkillMatch.Core.Skills;

/// <summary>
/// Met un texte sous une forme comparable : minuscules, sans accents, puis
/// découpé en mots. « Développement Web » et « developpement web » donnent
/// exactement les mêmes mots. Fonctions pures, testées sans serveur.
/// </summary>
public static class TextNormalizer
{
    /// <summary>Minuscules et accents retirés (« Réseaux » devient « reseaux »).</summary>
    public static string Normalize(string text)
    {
        ArgumentNullException.ThrowIfNull(text);

        // FormD sépare chaque lettre de son accent (« é » = « e » + accent) ;
        // on garde la lettre et on jette l'accent (catégorie NonSpacingMark).
        var decomposed = text.Normalize(NormalizationForm.FormD);
        var builder = new StringBuilder(decomposed.Length);
        foreach (var c in decomposed)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
            {
                builder.Append(c);
            }
        }

        // ToLowerInvariant : même résultat quelle que soit la langue du serveur.
        return builder.ToString().Normalize(NormalizationForm.FormC).ToLowerInvariant();
    }

    /// <summary>
    /// Découpe un texte normalisé en mots.
    ///
    /// Un mot est fait de lettres, de chiffres et des signes « + », « # » et
    /// « . », pour garder entiers « c++ », « c# », « .net » et « node.js ».
    /// Tout le reste sépare (espace, virgule, tiret, barre, apostrophe…) :
    /// « scikit-learn » et « scikit learn » donnent les mêmes mots.
    /// Le point final d'une phrase (« … et Python. ») est retiré.
    /// </summary>
    public static List<string> Tokenize(string normalizedText)
    {
        ArgumentNullException.ThrowIfNull(normalizedText);

        var tokens = new List<string>();
        var current = new StringBuilder();

        foreach (var c in normalizedText)
        {
            if (char.IsLetterOrDigit(c) || c is '+' or '#' or '.')
            {
                current.Append(c);
            }
            else
            {
                AddToken(tokens, current);
            }
        }

        AddToken(tokens, current);
        return tokens;
    }

    private static void AddToken(List<string> tokens, StringBuilder current)
    {
        // Points en fin de mot retirés : « python. » devient « python ».
        // Le point au début est gardé, pour « .net ».
        var token = current.ToString().TrimEnd('.');
        current.Clear();

        if (token.Length > 0 && token != ".")
        {
            tokens.Add(token);
        }
    }
}
