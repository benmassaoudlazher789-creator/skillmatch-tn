namespace SkillMatch.Core.Cv;

/// <summary>Types de CV acceptés.</summary>
public enum CvFileKind
{
    Pdf,

    /// <summary>
    /// Archive ZIP, candidate pour un DOCX. Sa structure (fichiers Word
    /// attendus, absence de macros) est contrôlée à l'ouverture, par l'extracteur.
    /// </summary>
    Docx,
}

/// <summary>
/// Reconnaît le type d'un fichier à ses premiers octets (sa « signature »),
/// jamais à son nom ni au type annoncé par le téléphone : ces deux-là se
/// changent en une seconde, alors qu'un faux contenu est vite repéré.
/// Fonction pure, testée sans serveur.
/// </summary>
public static class CvFileType
{
    // « %PDF- » : tout PDF commence ainsi. La norme tolère quelques octets
    // avant, mais les logiciels courants l'écrivent tout au début : on reste
    // strict, c'est plus simple et plus sûr.
    private static ReadOnlySpan<byte> PdfSignature => "%PDF-"u8;

    // « PK » 03 04 : début d'une archive ZIP. Un DOCX est une archive ZIP.
    private static ReadOnlySpan<byte> ZipSignature => [0x50, 0x4B, 0x03, 0x04];

    /// <summary>Renvoie le type reconnu, ou null si le fichier n'est ni PDF ni ZIP.</summary>
    public static CvFileKind? Detect(ReadOnlySpan<byte> content)
    {
        if (content.StartsWith(PdfSignature))
        {
            return CvFileKind.Pdf;
        }

        if (content.StartsWith(ZipSignature))
        {
            return CvFileKind.Docx;
        }

        return null;
    }
}
