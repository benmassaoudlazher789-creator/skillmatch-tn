using SkillMatch.Core.Skills;

namespace SkillMatch.Tests.Jobs;

public sealed class SkillKeyTests
{
    [Theory]
    [InlineData("Flutter", "flutter")]
    [InlineData("  FLUTTER  ", "flutter")]
    [InlineData("Réseaux", "reseaux")]
    [InlineData("Power   BI", "Power BI")]
    [InlineData("power-bi", "Power BI")]
    public void MajusculesAccentsEtEspacesNeComptentPas(string a, string b) =>
        Assert.Equal(SkillKey.For(a), SkillKey.For(b));

    [Theory]
    [InlineData("JS", "JavaScript")]
    [InlineData("k8s", "Kubernetes")]
    [InlineData("postgres", "PostgreSQL")]
    [InlineData("dotnet", ".NET")]
    [InlineData("csharp", "C#")]
    [InlineData("integration continue", "CI/CD")]
    public void LesVariantesDuDictionnaireSeValent(string variant, string name) =>
        Assert.Equal(SkillKey.For(name), SkillKey.For(variant));

    [Theory]
    [InlineData("Java", "JavaScript")]
    [InlineData("React", "React Native")]
    [InlineData("C", "C++")]
    public void DesOutilsDifferentsRestentDifferents(string a, string b) =>
        Assert.NotEqual(SkillKey.For(a), SkillKey.For(b));

    [Fact]
    public void CompetenceHorsDictionnaire_ComparéeAElleMeme() =>
        Assert.Equal(SkillKey.For("Odoo"), SkillKey.For("ODOO"));

    [Fact]
    public void SansAucunMot_CleVide() =>
        Assert.Equal(string.Empty, SkillKey.For(" - / "));

    [Fact]
    public void AucuneFormeNeDesigneDeuxEntreesDuDictionnaire()
    {
        // Sinon, une même écriture pourrait désigner deux outils, et la
        // comparaison dépendrait de l'ordre du dictionnaire.
        var owner = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var entry in SkillDictionary.Default)
        {
            foreach (var form in entry.Variants.Append(entry.Name))
            {
                var words = string.Join(' ', TextNormalizer.Tokenize(TextNormalizer.Normalize(form)));
                if (owner.TryGetValue(words, out var other))
                {
                    Assert.Equal(other, entry.Name);
                }
                else
                {
                    owner[words] = entry.Name;
                }
            }
        }
    }
}
