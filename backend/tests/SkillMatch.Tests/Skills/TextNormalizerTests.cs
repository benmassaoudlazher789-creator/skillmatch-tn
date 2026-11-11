using SkillMatch.Core.Skills;

namespace SkillMatch.Tests.Skills;

/// <summary>Normalisation et découpage en mots : fonctions pures, sans serveur.</summary>
public sealed class TextNormalizerTests
{
    [Theory]
    [InlineData("Développement", "developpement")]
    [InlineData("RÉSEAUX ÉLÈVE", "reseaux eleve")]
    [InlineData("Ça, où, maïs", "ca, ou, mais")]
    [InlineData("C++ et C#", "c++ et c#")]
    public void Normalize_RetireAccentsEtMajuscules(string input, string expected) =>
        Assert.Equal(expected, TextNormalizer.Normalize(input));

    [Fact]
    public void Tokenize_GardeLesSignesDesNomsTechniques()
    {
        var words = TextNormalizer.Tokenize("c++, c#; .net. node.js/react (docker)");

        Assert.Equal(new[] { "c++", "c#", ".net", "node.js", "react", "docker" }, words);
    }

    [Fact]
    public void Tokenize_LeTiretEtLApostropheSeparent()
    {
        var words = TextNormalizer.Tokenize("scikit-learn d'excel");

        Assert.Equal(new[] { "scikit", "learn", "d", "excel" }, words);
    }

    [Theory]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData(" . , ; ... ")]
    public void Tokenize_SansMot_ListeVide(string input) =>
        Assert.Empty(TextNormalizer.Tokenize(input));
}
