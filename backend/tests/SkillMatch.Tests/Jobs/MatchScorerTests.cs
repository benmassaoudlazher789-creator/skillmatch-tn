using SkillMatch.Core.Jobs;

namespace SkillMatch.Tests.Jobs;

public sealed class MatchScorerTests
{
    private static JobMatch Score(string[] required, string[] preferred, params string[] candidate) =>
        MatchScorer.Score(required, preferred, MatchScorer.CandidateKeys(candidate));

    // ---- Règle 70 / 30, arrondi vers le bas ----

    [Theory]
    // 70 × 2/3 + 30 × 1/2 = 46,67 + 15 = 61,67 → 61
    [InlineData(2, 3, 1, 2, 61)]
    // 70 × 1 + 30 × 1/2 = 85
    [InlineData(1, 1, 1, 2, 85)]
    [InlineData(3, 3, 2, 2, 100)]
    [InlineData(0, 3, 2, 2, 30)]
    [InlineData(3, 3, 0, 2, 70)]
    [InlineData(0, 2, 0, 2, 0)]
    // Seulement des requises : elles comptent pour 100 %. 2/3 = 66,67 → 66
    [InlineData(2, 3, 0, 0, 66)]
    // Seulement des souhaitées : 1/3 = 33,33 → 33
    [InlineData(0, 0, 1, 3, 33)]
    [InlineData(0, 0, 0, 0, 0)]
    // Cas repris du test mobile (match_score_test.dart), avant sa suppression :
    // seulement des requises, 1 sur 2 = 50.
    [InlineData(1, 2, 0, 0, 50)]
    // 70 × 1 + 30 × 99/100 = 99,7 → 99 : jamais 100 s'il manque une compétence.
    [InlineData(1, 1, 99, 100, 99)]
    public void Percent(int requiredHave, int requiredTotal, int preferredHave, int preferredTotal, int expected) =>
        Assert.Equal(expected, MatchScorer.Percent(requiredHave, requiredTotal, preferredHave, preferredTotal));

    [Fact]
    public void JamaisCentPourCentSIlManqueUneCompetence()
    {
        // 70 × 29/30 + 30 = 97,67 : arrondi vers le bas, donc 97 et non 98.
        Assert.Equal(97, MatchScorer.Percent(29, 30, 1, 1));
        Assert.True(MatchScorer.Percent(9, 10, 10, 10) < 100);
    }

    // ---- Listes acquises / manquantes ----

    [Fact]
    public void ListesAcquisesEtManquantes_DansLOrdreDeLOffre()
    {
        var match = Score(["Flutter", "Dart", "Firebase"], ["Git", "Docker"], "dart", "Flutter", "Git");

        Assert.Equal(new[] { "Flutter", "Dart" }, match.RequiredAcquired);
        Assert.Equal(new[] { "Firebase" }, match.RequiredMissing);
        Assert.Equal(new[] { "Git" }, match.PreferredAcquired);
        Assert.Equal(new[] { "Docker" }, match.PreferredMissing);
        Assert.Equal(61, match.Score);
    }

    [Fact]
    public void ComparaisonSouple_AccentsEtVariantes()
    {
        var match = Score(["Réseaux", "JavaScript"], ["Kubernetes"], "reseaux", "JS", "k8s");

        Assert.Equal(100, match.Score);
        Assert.Empty(match.RequiredMissing);
        Assert.Empty(match.PreferredMissing);
    }

    [Fact]
    public void SansCompetenceDuCandidat_ToutManque()
    {
        var match = Score(["Python"], ["SQL"]);

        Assert.Equal(0, match.Score);
        Assert.Equal(new[] { "Python" }, match.RequiredMissing);
        Assert.Equal(new[] { "SQL" }, match.PreferredMissing);
    }

    // ---- Cas repris du test mobile (match_score_test.dart) ----

    [Fact]
    public void CentSouhaitees_UneManque_99()
    {
        var preferred = Enumerable.Range(0, 100).Select(i => $"S{i}").ToArray();
        var candidate = Enumerable.Range(0, 99).Select(i => $"S{i}").Append("A").ToArray();

        var match = Score(["A"], preferred, candidate);

        Assert.Equal(99, match.Score);
        Assert.Equal(new[] { "S99" }, match.PreferredMissing);
    }

    [Fact]
    public void MajusculesEtEspacesEnTropIgnores_PucesALEcritureDeLOffre()
    {
        // « fig  ma » (espace au milieu) n'est pas « Figma » : deux mots.
        var match = Score(["Dart", "Flutter", "Git"], ["Docker", "Figma"], "dart", "FLUTTER", "  git  ", "fig  ma");

        Assert.Equal(70, match.Score);
        Assert.Equal(new[] { "Dart", "Flutter", "Git" }, match.RequiredAcquired);
        Assert.Equal(new[] { "Docker", "Figma" }, match.PreferredMissing);
    }

    [Fact]
    public void OffreSansCompetence_0_SansErreur()
    {
        var match = Score([], [], "Dart");

        Assert.Equal(0, match.Score);
        Assert.Equal("Aucune compétence indiquée pour cette offre.", match.Explanation);
    }

    // ---- Explication ----

    [Fact]
    public void Explication_DeuxListes() =>
        Assert.Equal(
            "Requises : 2 sur 3 (70 % du score) · Souhaitées : 1 sur 2 (30 %)",
            MatchScorer.Explain(2, 3, 1, 2));

    [Fact]
    public void Explication_UneSeuleListe()
    {
        Assert.Equal("Requises : 1 sur 2 (100 % du score)", MatchScorer.Explain(1, 2, 0, 0));
        Assert.Equal("Souhaitées : 0 sur 1 (100 % du score)", MatchScorer.Explain(0, 0, 0, 1));
    }

    // ---- Score d'une offre enregistrée ----

    [Fact]
    public void ScoreDUneOffre_ListesTrieesParOrdreAlphabetique()
    {
        var job = JobTestData.Job(required: ["SQL", "Dart", "flutter"], preferred: ["Git"]);

        var match = MatchScorer.Score(job, MatchScorer.CandidateKeys(["Dart"]));

        Assert.Equal(new[] { "Dart" }, match.RequiredAcquired);
        Assert.Equal(new[] { "flutter", "SQL" }, match.RequiredMissing);
        Assert.Equal(new[] { "Git" }, match.PreferredMissing);
    }
}
