using SkillMatch.Core.Jobs;
using SkillMatch.Core.Skills;
using SkillMatch.Infrastructure.Jobs;

namespace SkillMatch.Tests.Jobs;

/// <summary>Le jeu d'exemple doit rester fictif, marqué comme tel, et utilisable.</summary>
public sealed class SampleJobSourceTests
{
    private static IReadOnlyList<JobPosting> Postings => SampleJobSource.Postings;

    [Fact]
    public void SourceMarqueeCommeExemple()
    {
        var source = new SampleJobSource();

        Assert.Equal("exemple", source.Name);
        Assert.True(source.IsSample);
    }

    [Fact]
    public void ChaqueOffreEstValide() =>
        Assert.All(Postings, p => Job.FromPosting(SampleJobSource.SourceName, isSample: true, p));

    [Fact]
    public void IdentifiantsUniques() =>
        Assert.Equal(Postings.Count, Postings.Select(p => p.ExternalId).Distinct().Count());

    [Fact]
    public void LesTroisTypesSontPresents()
    {
        foreach (var type in Enum.GetValues<JobType>())
        {
            Assert.Contains(Postings, p => p.Type == type);
        }
    }

    [Fact]
    public void EntreprisesFictivesEtLiensReserves()
    {
        Assert.All(Postings, p =>
        {
            Assert.StartsWith("Société Exemple ", p.Company, StringComparison.Ordinal);
            // example.com est réservé aux exemples (IANA) : il n'appartient à personne.
            Assert.NotNull(p.Url);
            Assert.Equal("example.com", new Uri(p.Url).Host);
        });
    }

    [Fact]
    public void CompetencesEcritesCommeDansLeDictionnaire()
    {
        // Sinon, une compétence détectée dans un CV ne correspondrait pas à
        // celle de l'offre.
        var names = SkillDictionary.Default.Select(e => e.Name).ToHashSet(StringComparer.Ordinal);

        Assert.All(
            Postings.SelectMany(p => p.RequiredSkills.Concat(p.PreferredSkills)),
            skill => Assert.True(names.Contains(skill), $"« {skill} » n'est pas un nom du dictionnaire."));
    }

    [Fact]
    public void AucunMotInterdit()
    {
        string[] forbidden = ["vérifi", "certifi", "prouv", "passeport", "défi", "chiffré", "robot"];

        foreach (var posting in Postings)
        {
            var text = $"{posting.Title} {posting.Company} {posting.City}";
            foreach (var word in forbidden)
            {
                Assert.DoesNotContain(word, text, StringComparison.OrdinalIgnoreCase);
            }
        }
    }
}
