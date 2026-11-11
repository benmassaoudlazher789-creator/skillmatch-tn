using System.IO.Compression;
using System.Text;
using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using UglyToad.PdfPig.Core;
using UglyToad.PdfPig.Fonts.Standard14Fonts;
using UglyToad.PdfPig.Writer;
// Alias : PdfPig et Open XML ont tous deux une classe « PageSize ». Le nom
// PdfPageSize lève l'ambiguïté (erreur CS0104) et dit clairement laquelle on utilise.
using PdfPageSize = UglyToad.PdfPig.Content.PageSize;

namespace SkillMatch.Tests.Cv;

/// <summary>
/// Faux CV fabriqués pendant les tests, avec un texte fictif.
/// Aucun vrai CV n'est rangé dans le dépôt : il contiendrait des données
/// personnelles.
/// </summary>
internal static class CvTestFiles
{
    /// <summary>PDF d'une page, une ligne de texte par élément de <paramref name="lines"/>.</summary>
    /// <remarks>
    /// Texte en ASCII seulement : la police standard Helvetica de PdfPig ne
    /// sait pas écrire toutes les lettres accentuées. Les accents sont testés
    /// avec le DOCX et dans SkillDetectorTests.
    /// </remarks>
    public static byte[] Pdf(params string[] lines)
    {
        var builder = new PdfDocumentBuilder();
        var font = builder.AddStandard14Font(Standard14Font.Helvetica);
        var page = builder.AddPage(PdfPageSize.A4);

        var y = 780.0;
        foreach (var line in lines)
        {
            page.AddText(line, 12, new PdfPoint(40, y), font);
            y -= 20;
        }

        return builder.Build();
    }

    /// <summary>PDF valide mais sans aucun texte, comme un CV scanné.</summary>
    public static byte[] PdfWithoutText()
    {
        var builder = new PdfDocumentBuilder();
        builder.AddPage(PdfPageSize.A4);
        return builder.Build();
    }

    /// <summary>DOCX avec un paragraphe par ligne.</summary>
    public static byte[] Docx(
        string text,
        WordprocessingDocumentType type = WordprocessingDocumentType.Document)
    {
        using var stream = new MemoryStream();
        using (var document = WordprocessingDocument.Create(stream, type))
        {
            var main = document.AddMainDocumentPart();
            main.Document = new Document(new Body(
                text.Split('\n').Select(line => new Paragraph(new Run(new Text(line))))));
        }

        return stream.ToArray();
    }

    /// <summary>Archive ZIP ordinaire (pas un DOCX), à renommer en .docx.</summary>
    public static byte[] PlainZip()
    {
        using var stream = new MemoryStream();
        using (var archive = new ZipArchive(stream, ZipArchiveMode.Create, leaveOpen: true))
        {
            var entry = archive.CreateEntry("note.txt");
            using var writer = new StreamWriter(entry.Open());
            writer.Write("Fichier texte d'exemple.");
        }

        return stream.ToArray();
    }

    /// <summary>Texte brut, à renommer en .pdf.</summary>
    public static byte[] PlainText() => Encoding.UTF8.GetBytes("Ceci n'est pas un PDF. Flutter, Dart.");
}
