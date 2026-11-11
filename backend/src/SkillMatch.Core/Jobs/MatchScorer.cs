using SkillMatch.Core.Skills;

namespace SkillMatch.Core.Jobs;

/// <summary>
/// Résultat de la comparaison entre une offre et les compétences du candidat.
/// Les listes gardent les noms tels que l'offre les écrit.
/// </summary>
public sealed record JobMatch(
    int Score,
    IReadOnlyList<string> RequiredAcquired,
    IReadOnlyList<string> RequiredMissing,
    IReadOnlyList<string> PreferredAcquired,
    IReadOnlyList<string> PreferredMissing,
    string Explanation);

/// <summary>
/// Calcul du score de correspondance. Même règle que l'application mobile
/// (match_score.dart), écrite en clair pour pouvoir l'expliquer au candidat :
///
///   score = 70 % × (requises présentes / requises)
///         + 30 % × (souhaitées présentes / souhaitées)
///
/// Si l'offre n'a qu'une des deux listes, celle-ci compte pour 100 %.
/// Le calcul se fait en nombres entiers et arrondit vers le bas : on n'affiche
/// jamais 100 % s'il manque une compétence.
///
/// Les compétences sont comparées avec <see cref="SkillKey"/> (majuscules,
/// accents et variantes du dictionnaire ne comptent pas).
///
/// Le score est une aide pour choisir, pas une garantie d'être retenu.
/// </summary>
public static class MatchScorer
{
    public const int RequiredWeight = 70;
    public const int PreferredWeight = 30;

    /// <summary>
    /// Clés des compétences du candidat. Calculées une fois par requête, puis
    /// réutilisées pour chaque offre. Un HashSet rend chaque recherche immédiate.
    /// </summary>
    public static HashSet<string> CandidateKeys(IEnumerable<string> skills)
    {
        ArgumentNullException.ThrowIfNull(skills);

        var keys = new HashSet<string>(StringComparer.Ordinal);
        foreach (var skill in skills)
        {
            var key = SkillKey.For(skill);
            if (key.Length > 0)
            {
                keys.Add(key);
            }
        }

        return keys;
    }

    public static JobMatch Score(
        IReadOnlyList<string> required,
        IReadOnlyList<string> preferred,
        IReadOnlySet<string> candidateKeys)
    {
        ArgumentNullException.ThrowIfNull(required);
        ArgumentNullException.ThrowIfNull(preferred);
        ArgumentNullException.ThrowIfNull(candidateKeys);

        bool Has(string skill) => candidateKeys.Contains(SkillKey.For(skill));

        var requiredAcquired = required.Where(Has).ToList();
        var requiredMissing = required.Where(s => !Has(s)).ToList();
        var preferredAcquired = preferred.Where(Has).ToList();
        var preferredMissing = preferred.Where(s => !Has(s)).ToList();

        var score = Percent(requiredAcquired.Count, required.Count, preferredAcquired.Count, preferred.Count);
        var explanation = Explain(requiredAcquired.Count, required.Count, preferredAcquired.Count, preferred.Count);

        return new JobMatch(score, requiredAcquired, requiredMissing, preferredAcquired, preferredMissing, explanation);
    }

    /// <summary>
    /// Compare une offre enregistrée aux compétences du candidat.
    ///
    /// Les compétences relues en base arrivent dans un ordre quelconque (SQL ne
    /// promet aucun ordre sans ORDER BY) : on les trie par ordre alphabétique,
    /// pour que la réponse soit toujours la même.
    /// </summary>
    public static JobMatch Score(Job job, IReadOnlySet<string> candidateKeys)
    {
        ArgumentNullException.ThrowIfNull(job);

        List<string> Names(SkillImportance importance) => job.Skills
            .Where(s => s.Importance == importance)
            .Select(s => s.Name)
            .Order(NameOrder)
            .ToList();

        return Score(Names(SkillImportance.Required), Names(SkillImportance.Preferred), candidateKeys);
    }

    // Sans tenir compte des majuscules, et indépendant de la langue du serveur.
    private static readonly StringComparer NameOrder =
        StringComparer.Create(System.Globalization.CultureInfo.InvariantCulture, ignoreCase: true);

    /// <summary>
    /// Division entière plutôt que nombres à virgule : 0,7 × 100 donne parfois
    /// 70,00000000000001 en machine. La division entière arrondit vers le bas.
    /// </summary>
    public static int Percent(int requiredHave, int requiredTotal, int preferredHave, int preferredTotal)
    {
        if (requiredTotal == 0 && preferredTotal == 0)
        {
            return 0;
        }

        if (preferredTotal == 0)
        {
            return 100 * requiredHave / requiredTotal;
        }

        if (requiredTotal == 0)
        {
            return 100 * preferredHave / preferredTotal;
        }

        // 70 × a/b + 30 × c/d, mis au même dénominateur b × d.
        var numerator = (RequiredWeight * requiredHave * preferredTotal)
            + (PreferredWeight * preferredHave * requiredTotal);
        return numerator / (requiredTotal * preferredTotal);
    }

    /// <summary>
    /// Phrase qui dit d'où vient le pourcentage, par exemple
    /// « Requises : 2 sur 3 (70 % du score) · Souhaitées : 1 sur 2 (30 %) ».
    /// Même texte que l'application mobile.
    /// </summary>
    public static string Explain(int requiredHave, int requiredTotal, int preferredHave, int preferredTotal)
    {
        var requiredText = $"Requises : {requiredHave} sur {requiredTotal}";
        var preferredText = $"Souhaitées : {preferredHave} sur {preferredTotal}";

        if (requiredTotal > 0 && preferredTotal > 0)
        {
            return $"{requiredText} ({RequiredWeight} % du score) · {preferredText} ({PreferredWeight} %)";
        }

        if (requiredTotal > 0)
        {
            return $"{requiredText} (100 % du score)";
        }

        if (preferredTotal > 0)
        {
            return $"{preferredText} (100 % du score)";
        }

        return "Aucune compétence indiquée pour cette offre.";
    }
}
