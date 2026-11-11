namespace SkillMatch.Core.Skills;

/// <summary>
/// Trouve les compétences du dictionnaire dans un texte. Fonction pure :
/// même texte, même résultat, sans base ni réseau.
///
/// Méthode : texte et variantes sont normalisés (minuscules, sans accents),
/// puis découpés en mots. Une variante est trouvée si ses mots apparaissent
/// à la suite dans le texte, en entier. Ainsi « Java » n'est pas trouvé dans
/// « JavaScript » (un seul mot, différent) et « React » est trouvé dans
/// « React Native ».
/// </summary>
public static class SkillDetector
{
    /// <summary>
    /// Compétences trouvées, chacune une seule fois, dans l'ordre du
    /// dictionnaire (un ordre stable, donc des tests simples).
    /// </summary>
    public static IReadOnlyList<string> Detect(string text) => Detect(text, SkillDictionary.Default);

    public static IReadOnlyList<string> Detect(string text, IReadOnlyList<SkillEntry> dictionary)
    {
        ArgumentNullException.ThrowIfNull(text);
        ArgumentNullException.ThrowIfNull(dictionary);

        var words = TextNormalizer.Tokenize(TextNormalizer.Normalize(text));
        if (words.Count == 0)
        {
            return [];
        }

        // Index « mot → positions » : on ne teste une variante qu'aux endroits
        // où son premier mot apparaît, au lieu de parcourir tout le texte.
        var positions = new Dictionary<string, List<int>>(StringComparer.Ordinal);
        for (var i = 0; i < words.Count; i++)
        {
            if (!positions.TryGetValue(words[i], out var list))
            {
                list = [];
                positions[words[i]] = list;
            }

            list.Add(i);
        }

        var found = new List<string>();
        foreach (var entry in dictionary)
        {
            if (entry.Variants.Any(variant => ContainsSequence(words, positions, Words(variant))))
            {
                found.Add(entry.Name);
            }
        }

        return found;
    }

    // La variante passe par les mêmes règles que le texte : « Power-BI »,
    // « power bi » et « POWER BI » donnent les mêmes mots.
    private static List<string> Words(string variant) =>
        TextNormalizer.Tokenize(TextNormalizer.Normalize(variant));

    private static bool ContainsSequence(
        List<string> words,
        Dictionary<string, List<int>> positions,
        List<string> sequence)
    {
        if (sequence.Count == 0 || !positions.TryGetValue(sequence[0], out var starts))
        {
            return false;
        }

        foreach (var start in starts)
        {
            if (start + sequence.Count > words.Count)
            {
                continue;
            }

            var match = true;
            for (var k = 1; k < sequence.Count; k++)
            {
                if (!string.Equals(words[start + k], sequence[k], StringComparison.Ordinal))
                {
                    match = false;
                    break;
                }
            }

            if (match)
            {
                return true;
            }
        }

        return false;
    }
}
