namespace SkillMatch.Core.Skills;

/// <summary>
/// Clé de comparaison d'une compétence : deux écritures qui désignent le même
/// outil ont la même clé.
///
/// Règles, dans l'ordre :
/// 1. minuscules et accents retirés, mots découpés (voir <see cref="TextNormalizer"/>) :
///    « Réseaux », « reseaux » et « RÉSEAUX » se valent ;
/// 2. si le résultat est le nom ou une variante d'une entrée du
///    <see cref="SkillDictionary"/>, la clé est celle du nom de l'entrée :
///    « JS » et « JavaScript » se valent, « k8s » et « Kubernetes » aussi ;
/// 3. sinon, la clé est simplement le texte normalisé : une compétence absente
///    du dictionnaire (« Odoo ») se compare quand même à elle-même.
///
/// Fonction pure : même texte, même clé, sans base ni réseau.
/// </summary>
public static class SkillKey
{
    // Table « forme normalisée → clé du nom », construite une seule fois.
    // Lazy : thread-safe, et rien n'est calculé si personne ne s'en sert.
    private static readonly Lazy<Dictionary<string, string>> Aliases = new(BuildAliases);

    /// <summary>Clé de <paramref name="skill"/>, ou chaîne vide s'il ne contient aucun mot.</summary>
    public static string For(string skill)
    {
        ArgumentNullException.ThrowIfNull(skill);

        var normalized = Words(skill);
        return Aliases.Value.TryGetValue(normalized, out var canonical) ? canonical : normalized;
    }

    // Les mots séparés par une seule espace : « Power-BI » et « power  bi »
    // donnent tous deux « power bi ».
    private static string Words(string text) =>
        string.Join(' ', TextNormalizer.Tokenize(TextNormalizer.Normalize(text)));

    private static Dictionary<string, string> BuildAliases()
    {
        var aliases = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var entry in SkillDictionary.Default)
        {
            var canonical = Words(entry.Name);
            // TryAdd : si deux entrées partageaient une forme, la première
            // garderait la sienne. Un test vérifie que ce cas n'existe pas.
            aliases.TryAdd(canonical, canonical);
            foreach (var variant in entry.Variants)
            {
                aliases.TryAdd(Words(variant), canonical);
            }
        }

        return aliases;
    }
}
