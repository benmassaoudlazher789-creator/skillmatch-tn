namespace SkillMatch.Core.Cv;

/// <summary>
/// Limites appliquées à un CV reçu. Elles protègent le serveur : un fichier
/// piégé (PDF de milliers de pages, archive qui « explose » une fois
/// décompressée) ne doit pas pouvoir l'occuper longtemps.
/// </summary>
public static class CvLimits
{
    /// <summary>5 Mo, comme la limite affichée dans l'application mobile.</summary>
    public const int MaxFileBytes = 5 * 1024 * 1024;

    /// <summary>
    /// Pages lues dans un PDF. Un CV en compte rarement plus de 3 ; au-delà
    /// de 10, la suite est ignorée au lieu de faire travailler le serveur.
    /// </summary>
    public const int MaxPdfPages = 10;

    /// <summary>Texte gardé pour la détection : largement assez pour un CV.</summary>
    public const int MaxTextChars = 100_000;

    /// <summary>
    /// Taille totale une fois décompressée d'un DOCX (une archive ZIP).
    /// Un DOCX de 5 Mo contenant 2 Go une fois ouvert est une « bombe ZIP » :
    /// on le refuse avant de l'ouvrir.
    /// </summary>
    public const long MaxDocxUncompressedBytes = 20 * 1024 * 1024;

    /// <summary>Nombre de fichiers dans l'archive DOCX (un CV normal en a une vingtaine).</summary>
    public const int MaxDocxEntries = 1_000;
}
