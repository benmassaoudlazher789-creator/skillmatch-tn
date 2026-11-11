using System.IO.Compression;
using System.Text;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;
using SkillMatch.Core.Cv;
using UglyToad.PdfPig;
using UglyToad.PdfPig.Exceptions;

namespace SkillMatch.Infrastructure.Cv;

/// <summary>
/// Lit le texte d'un CV PDF (PdfPig) ou DOCX (Open XML SDK), en mémoire.
///
/// Règles de confidentialité et de sécurité :
/// - rien n'est écrit sur le disque, rien n'est gardé après l'appel ;
/// - rien n'est journalisé ;
/// - les erreurs des bibliothèques sont attrapées et remplacées par une
///   raison neutre (CvError). Leur message peut recopier un morceau du
///   fichier : il ne doit jamais sortir d'ici.
/// </summary>
public sealed class CvTextExtractor : ICvTextExtractor
{
    public CvTextExtraction Extract(byte[] content, CvFileKind kind, CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(content);

        try
        {
            return kind switch
            {
                CvFileKind.Pdf => ExtractPdf(content, cancellationToken),
                CvFileKind.Docx => ExtractDocx(content, cancellationToken),
                _ => CvTextExtraction.Failure(CvError.UnsupportedType),
            };
        }
        catch (PdfDocumentEncryptedException)
        {
            return CvTextExtraction.Failure(CvError.PasswordProtected);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            // Fichier abîmé ou piégé : on ne garde que la conclusion, jamais
            // l'exception (voir plus haut). L'annulation (le téléphone a coupé
            // la connexion), elle, continue son chemin normalement.
            return CvTextExtraction.Failure(CvError.Unreadable);
        }
    }

    private static CvTextExtraction ExtractPdf(byte[] content, CancellationToken cancellationToken)
    {
        using var document = PdfDocument.Open(content);
        var text = new StringBuilder();

        var pageCount = Math.Min(document.NumberOfPages, CvLimits.MaxPdfPages);
        for (var number = 1; number <= pageCount && text.Length < CvLimits.MaxTextChars; number++)
        {
            cancellationToken.ThrowIfCancellationRequested();

            // GetWords plutôt que page.Text : page.Text colle parfois les mots
            // entre eux (« JavaPython »), ce qui empêcherait de les reconnaître.
            foreach (var word in document.GetPage(number).GetWords())
            {
                text.Append(word.Text).Append(' ');
            }

            text.AppendLine();
        }

        return Finish(text);
    }

    private static CvTextExtraction ExtractDocx(byte[] content, CancellationToken cancellationToken)
    {
        // 1. Contrôle de l'archive AVANT de laisser Open XML la décompresser.
        if (CheckDocxArchive(content) is { } archiveError)
        {
            return CvTextExtraction.Failure(archiveError);
        }

        cancellationToken.ThrowIfCancellationRequested();

        // 2. Lecture seule (isEditable: false) depuis la mémoire.
        using var stream = new MemoryStream(content, writable: false);
        using var document = WordprocessingDocument.Open(stream, isEditable: false);

        // Un modèle (.dotx) ou un document à macros (.docm) renommé en .docx
        // est refusé : seul un document Word ordinaire est accepté.
        if (document.DocumentType != DocumentFormat.OpenXml.WordprocessingDocumentType.Document)
        {
            return CvTextExtraction.Failure(CvError.UnsupportedType);
        }

        var body = document.MainDocumentPart?.Document?.Body;
        if (body is null)
        {
            return CvTextExtraction.Failure(CvError.NoText);
        }

        var text = new StringBuilder();
        // Descendants<Paragraph> trouve aussi les paragraphes des tableaux et
        // des zones de texte, fréquents dans les modèles de CV.
        foreach (var paragraph in body.Descendants<Paragraph>())
        {
            if (text.Length >= CvLimits.MaxTextChars)
            {
                break;
            }

            text.AppendLine(paragraph.InnerText);
        }

        return Finish(text);
    }

    /// <summary>
    /// Renvoie une erreur si l'archive n'est pas un DOCX ordinaire, ou si elle
    /// deviendrait trop grosse une fois décompressée (bombe ZIP).
    /// </summary>
    private static CvError? CheckDocxArchive(byte[] content)
    {
        using var stream = new MemoryStream(content, writable: false);
        using var archive = new ZipArchive(stream, ZipArchiveMode.Read);

        if (archive.Entries.Count > CvLimits.MaxDocxEntries)
        {
            return CvError.Unreadable;
        }

        long totalUncompressed = 0;
        var hasContentTypes = false;
        var hasDocument = false;

        foreach (var entry in archive.Entries)
        {
            // Tailles annoncées par l'archive elle-même, lues sans rien
            // décompresser : un premier contrôle simple et rapide.
            totalUncompressed += entry.Length;
            if (totalUncompressed > CvLimits.MaxDocxUncompressedBytes)
            {
                return CvError.Unreadable;
            }

            hasContentTypes |= entry.FullName == "[Content_Types].xml";
            hasDocument |= entry.FullName == "word/document.xml";

            // Macros VBA : refusées, même si le fichier s'appelle .docx.
            if (entry.FullName.EndsWith("vbaProject.bin", StringComparison.OrdinalIgnoreCase))
            {
                return CvError.UnsupportedType;
            }
        }

        // Une archive ZIP quelconque renommée en .docx n'a pas ces deux fichiers.
        return hasContentTypes && hasDocument ? null : CvError.UnsupportedType;
    }

    private static CvTextExtraction Finish(StringBuilder text)
    {
        if (text.Length > CvLimits.MaxTextChars)
        {
            text.Length = CvLimits.MaxTextChars;
        }

        var result = text.ToString();
        return string.IsNullOrWhiteSpace(result)
            ? CvTextExtraction.Failure(CvError.NoText)
            : CvTextExtraction.Success(result);
    }
}
