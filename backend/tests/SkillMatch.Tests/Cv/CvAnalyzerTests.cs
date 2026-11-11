using SkillMatch.Core.Cv;

namespace SkillMatch.Tests.Cv;

/// <summary>
/// Enchaînement des étapes, avec un faux extracteur : on teste l'ordre des
/// contrôles sans dépendre de PdfPig ni d'Open XML.
/// </summary>
public sealed class CvAnalyzerTests
{
    private sealed class FakeExtractor(CvTextExtraction result) : ICvTextExtractor
    {
        public int Calls { get; private set; }

        public CvTextExtraction Extract(byte[] content, CvFileKind kind, CancellationToken cancellationToken)
        {
            Calls++;
            return result;
        }
    }

    private static readonly byte[] PdfHeader = "%PDF-1.7 exemple"u8.ToArray();

    [Fact]
    public void FichierVide_Empty_SansLecture()
    {
        var extractor = new FakeExtractor(CvTextExtraction.Success("Flutter"));

        var result = new CvAnalyzer(extractor).Analyze([], TestContext.Current.CancellationToken);

        Assert.Equal(CvError.Empty, result.Error);
        Assert.Equal(0, extractor.Calls);
    }

    [Fact]
    public void PlusDe5Mo_TooLarge_SansLecture()
    {
        var extractor = new FakeExtractor(CvTextExtraction.Success("Flutter"));
        var content = new byte[CvLimits.MaxFileBytes + 1];
        PdfHeader.CopyTo(content, 0);

        var result = new CvAnalyzer(extractor).Analyze(content, TestContext.Current.CancellationToken);

        Assert.Equal(CvError.TooLarge, result.Error);
        Assert.Equal(0, extractor.Calls);
    }

    [Fact]
    public void SignatureInconnue_UnsupportedType_SansLecture()
    {
        var extractor = new FakeExtractor(CvTextExtraction.Success("Flutter"));

        var result = new CvAnalyzer(extractor).Analyze(CvTestFiles.PlainText(), TestContext.Current.CancellationToken);

        Assert.Equal(CvError.UnsupportedType, result.Error);
        Assert.Equal(0, extractor.Calls);
    }

    [Theory]
    [InlineData(CvError.PasswordProtected)]
    [InlineData(CvError.Unreadable)]
    [InlineData(CvError.UnsupportedType)]
    public void ErreurDeLecture_EstTransmise(CvError error)
    {
        var extractor = new FakeExtractor(CvTextExtraction.Failure(error));

        var result = new CvAnalyzer(extractor).Analyze(PdfHeader, TestContext.Current.CancellationToken);

        Assert.Equal(error, result.Error);
        Assert.Empty(result.Skills);
    }

    [Fact]
    public void TexteBlanc_NoText()
    {
        var extractor = new FakeExtractor(CvTextExtraction.Success("  \n "));

        var result = new CvAnalyzer(extractor).Analyze(PdfHeader, TestContext.Current.CancellationToken);

        Assert.Equal(CvError.NoText, result.Error);
    }

    [Fact]
    public void TexteLu_CompetencesDetectees()
    {
        var extractor = new FakeExtractor(CvTextExtraction.Success("Projets en Flutter et SQL."));

        var result = new CvAnalyzer(extractor).Analyze(PdfHeader, TestContext.Current.CancellationToken);

        Assert.Null(result.Error);
        Assert.Equal(new[] { "SQL", "Flutter" }, result.Skills);
    }

    [Fact]
    public void ToString_NeMontreJamaisLeTexte()
    {
        var extraction = CvTextExtraction.Success("Texte confidentiel d'exemple");

        Assert.DoesNotContain("confidentiel", extraction.ToString(), StringComparison.Ordinal);
    }
}
