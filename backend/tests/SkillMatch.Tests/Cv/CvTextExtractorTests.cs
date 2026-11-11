using System.Text;
using DocumentFormat.OpenXml;
using SkillMatch.Core.Cv;
using SkillMatch.Infrastructure.Cv;

namespace SkillMatch.Tests.Cv;

/// <summary>Lecture réelle de PDF et DOCX générés pendant le test.</summary>
public sealed class CvTextExtractorTests
{
    private readonly CvTextExtractor _extractor = new();

    private CvTextExtraction Extract(byte[] content, CvFileKind kind) =>
        _extractor.Extract(content, kind, TestContext.Current.CancellationToken);

    [Fact]
    public void Pdf_TexteLu()
    {
        var result = Extract(CvTestFiles.Pdf("Competences : Flutter et Docker"), CvFileKind.Pdf);

        Assert.Null(result.Error);
        Assert.NotNull(result.Text);
        Assert.Contains("Flutter", result.Text, StringComparison.Ordinal);
        Assert.Contains("Docker", result.Text, StringComparison.Ordinal);
    }

    [Fact]
    public void Pdf_SansTexte_NoText() =>
        Assert.Equal(CvError.NoText, Extract(CvTestFiles.PdfWithoutText(), CvFileKind.Pdf).Error);

    [Fact]
    public void Pdf_Abime_Refuse()
    {
        // Bonne signature, mais le reste n'est pas un PDF. Selon la façon dont
        // PdfPig s'en sort, c'est « illisible » ou « sans texte » : jamais un succès.
        var result = Extract(Encoding.ASCII.GetBytes("%PDF-1.7\nceci n'est pas un vrai PDF"), CvFileKind.Pdf);

        Assert.Contains(result.Error, new CvError?[] { CvError.Unreadable, CvError.NoText });
    }

    [Fact]
    public void Docx_TexteLuAvecAccents()
    {
        var result = Extract(CvTestFiles.Docx("Développement mobile\nRéseaux informatiques"), CvFileKind.Docx);

        Assert.Null(result.Error);
        Assert.NotNull(result.Text);
        Assert.Contains("Développement mobile", result.Text, StringComparison.Ordinal);
        Assert.Contains("Réseaux informatiques", result.Text, StringComparison.Ordinal);
    }

    [Fact]
    public void Docx_AMacros_UnsupportedType()
    {
        var docm = CvTestFiles.Docx("Flutter", WordprocessingDocumentType.MacroEnabledDocument);

        Assert.Equal(CvError.UnsupportedType, Extract(docm, CvFileKind.Docx).Error);
    }

    [Fact]
    public void ZipOrdinaire_UnsupportedType() =>
        Assert.Equal(CvError.UnsupportedType, Extract(CvTestFiles.PlainZip(), CvFileKind.Docx).Error);

    [Fact]
    public void ZipAbime_Unreadable()
    {
        // Signature ZIP suivie de n'importe quoi.
        byte[] content = [0x50, 0x4B, 0x03, 0x04, 0x01, 0x02, 0x03];

        Assert.Equal(CvError.Unreadable, Extract(content, CvFileKind.Docx).Error);
    }
}
