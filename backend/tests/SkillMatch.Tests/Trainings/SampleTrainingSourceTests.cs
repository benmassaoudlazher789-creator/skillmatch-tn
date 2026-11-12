using SkillMatch.Core.Skills;
using SkillMatch.Core.Trainings;
using SkillMatch.Infrastructure.Trainings;

namespace SkillMatch.Tests.Trainings;

/// <summary>Le jeu d'exemple doit rester fictif, marqué comme tel, et utilisable.</summary>
public sealed class SampleTrainingSourceTests
{
    private static IReadOnlyList<TrainingPosting> Postings => SampleTrainingSource.Postings;

    [Fact]
    public void SourceMarqueeCommeExemple()
    {
        var source = new SampleTrainingSource();

        Assert.Equal("exemple", source.Name);
        Assert.True(source.IsSample);
    }

    [Fact]
    public void ChaqueFormationEstValide() =>
        Assert.All(Postings, p => Training.FromPosting(SampleTrainingSource.SourceName, isSample: true, p));

    [Fact]
    public void IdentifiantsUniques() =>
        Assert.Equal(Postings.Count, Postings.Select(p => p.ExternalId).Distinct().Count());

    [Fact]
    public void AucunLien() =>
        // Choix validé : pas de bouton « ouvrir » pour une formation inventée.
        Assert.All(Postings, p => Assert.Null(p.Url));

    [Fact]
    public void CompetencesEcritesCommeDansLeDictionnaire()
    {
        // Sinon, une compétence manquante d'une offre ne retrouverait pas ses formations.
        var names = SkillDictionary.Default.Select(e => e.Name).ToHashSet(StringComparer.Ordinal);

        Assert.All(
            Postings,
            p => Assert.True(names.Contains(p.Skill), $"« {p.Skill} » n'est pas un nom du dictionnaire."));
    }

    [Theory]
    [InlineData("Windows")]
    [InlineData("Linux")]
    [InlineData("Réseaux")]
    public void CompetencesSansFormation_PourLEtatVide(string skill)
    {
        var key = SkillKey.For(skill);

        Assert.DoesNotContain(Postings, p => SkillKey.For(p.Skill) == key);
    }

    [Fact]
    public void AucunMotInterdit()
    {
        string[] forbidden = ["vérifi", "certifi", "prouv", "passeport", "défi", "chiffré", "robot"];

        foreach (var posting in Postings)
        {
            var text = $"{posting.Title} {posting.Skill}";
            foreach (var word in forbidden)
            {
                Assert.DoesNotContain(word, text, StringComparison.OrdinalIgnoreCase);
            }
        }
    }
}
