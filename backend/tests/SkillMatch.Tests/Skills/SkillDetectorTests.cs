using SkillMatch.Core.Skills;

namespace SkillMatch.Tests.Skills;

/// <summary>
/// Détection des compétences : fonction pure. Les textes sont des exemples
/// écrits pour les tests, pas des extraits de vrais CV.
/// </summary>
public sealed class SkillDetectorTests
{
    [Theory]
    [InlineData("Flutter")]
    [InlineData("flutter")]
    [InlineData("FLUTTER")]
    [InlineData("Développement avec FlUtTeR.")]
    public void MajusculesSansImportance(string text) =>
        Assert.Equal(new[] { "Flutter" }, SkillDetector.Detect(text));

    [Theory]
    [InlineData("Réseaux informatiques")]
    [InlineData("reseaux informatiques")]
    [InlineData("RÉSEAUX INFORMATIQUES")]
    [InlineData("Administration réseaux")]
    public void AccentsSansImportance(string text) =>
        Assert.Equal(new[] { "Réseaux" }, SkillDetector.Detect(text));

    [Theory]
    [InlineData("JS", "JavaScript")]
    [InlineData("NodeJS", "Node.js")]
    [InlineData("Node.js", "Node.js")]
    [InlineData("PowerBI", "Power BI")]
    [InlineData("Power-BI", "Power BI")]
    [InlineData("power bi", "Power BI")]
    [InlineData("ASP.NET Core", ".NET")]
    [InlineData("dotnet", ".NET")]
    [InlineData("scikit-learn", "Scikit-learn")]
    [InlineData("GitLab", "Git")]
    [InlineData("GitHub", "GitHub")]
    [InlineData("REST API", "API REST")]
    [InlineData("Tests unitaires", "Tests unitaires")]
    public void VariantesReconnues(string text, string expected) =>
        Assert.Equal(new[] { expected }, SkillDetector.Detect(text));

    [Fact]
    public void Java_NestPasTrouveDansJavaScript()
    {
        Assert.Equal(new[] { "JavaScript" }, SkillDetector.Detect("JavaScript"));
        Assert.Equal(new[] { "Java", "JavaScript" }, SkillDetector.Detect("Java et JavaScript"));
    }

    [Theory]
    [InlineData("C#", "C#")]
    [InlineData("C++", "C++")]
    [InlineData("Langage C", "C")]
    public void C_CSharp_CPlusPlus_Distincts(string text, string expected) =>
        Assert.Equal(new[] { expected }, SkillDetector.Detect(text));

    [Fact]
    public void CSharpEtCPlusPlus_SansC() =>
        Assert.Equal(new[] { "C#", "C++" }, SkillDetector.Detect("C# et C++"));

    [Theory]
    // Lettres seules et mots courants : aucune compétence.
    [InlineData("Permis B, niveau C1, note : C")]
    [InlineData("Ordinateur 16 Go de RAM")]
    [InlineData("Vue d'ensemble du projet")]
    [InlineData("Tableau de bord et réseaux sociaux")]
    [InlineData("Word of mouth")]
    public void MotsAmbigus_NonDetectes(string text) =>
        Assert.Empty(SkillDetector.Detect(text));

    [Theory]
    [InlineData("Golang", "Go")]
    [InlineData("Vue.js", "Vue.js")]
    [InlineData("Microsoft Word", "Word")]
    public void MotsAmbigus_FormeExplicite_Detectes(string text, string expected) =>
        Assert.Equal(new[] { expected }, SkillDetector.Detect(text));

    [Fact]
    public void ReactNative_DonneAussiReact() =>
        Assert.Equal(new[] { "React", "React Native" }, SkillDetector.Detect("React Native"));

    [Fact]
    public void ChaqueCompetenceUneSeuleFois_DansLOrdreDuDictionnaire()
    {
        var skills = SkillDetector.Detect("git, Flutter, SQL ; flutter ; DART ; Git ; dart");

        Assert.Equal(new[] { "Dart", "SQL", "Flutter", "Git" }, skills);
    }

    [Fact]
    public void PonctuationAutourDesMots()
    {
        var skills = SkillDetector.Detect("(Docker), Python. Linux;Excel!");

        Assert.Equal(new[] { "Python", "Docker", "Linux", "Excel" }, skills);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   \n\t ")]
    [InlineData("Curriculum vitae sans outil connu.")]
    public void RienATrouver_ListeVide(string text) =>
        Assert.Empty(SkillDetector.Detect(text));

    [Fact]
    public void DictionnairePersonnalise()
    {
        SkillEntry[] dictionary = [new("Outil Exemple", ["outil exemple", "oe-2"])];

        Assert.Equal(new[] { "Outil Exemple" }, SkillDetector.Detect("j'utilise OE-2", dictionary));
    }

    [Fact]
    public void Dictionnaire_NomsUniques()
    {
        var names = SkillDictionary.Default.Select(e => e.Name).ToList();

        Assert.Equal(names.Count, names.Distinct(StringComparer.OrdinalIgnoreCase).Count());
    }

    [Fact]
    public void Dictionnaire_VariantesValidesEtSansDoublon()
    {
        // Chaque variante doit donner au moins un mot, et deux compétences ne
        // doivent pas partager la même variante (sinon le résultat serait flou).
        var seen = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (var entry in SkillDictionary.Default)
        {
            Assert.NotEmpty(entry.Variants);
            foreach (var variant in entry.Variants)
            {
                var words = TextNormalizer.Tokenize(TextNormalizer.Normalize(variant));
                Assert.NotEmpty(words);

                var key = string.Join(' ', words);
                Assert.False(
                    seen.TryGetValue(key, out var other),
                    $"La variante « {variant} » est à la fois dans {other} et {entry.Name}.");
                seen[key] = entry.Name;
            }
        }
    }

    [Fact]
    public void ChaqueNomEstDetecteParSesPropresVariantes()
    {
        foreach (var entry in SkillDictionary.Default)
        {
            foreach (var variant in entry.Variants)
            {
                Assert.Contains(entry.Name, SkillDetector.Detect(variant));
            }
        }
    }
}
