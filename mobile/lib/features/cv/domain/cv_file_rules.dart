/// Règles d'un fichier CV acceptable : type et taille.
///
/// Pourquoi un fichier à part, sans Flutter ? Ces règles sont de simples
/// calculs sur un nom et une taille. Isolées ici, elles se testent très
/// vite (sans écran) et l'écran ne fait que les appeler.
///
/// Limite assumée : on regarde l'extension du nom (« .pdf », « .docx »),
/// pas le contenu du fichier, car l'application ne lit pas le fichier.
/// Le vrai contrôle du contenu sera fait plus tard par le serveur.
abstract final class CvFileRules {
  /// Extensions acceptées, en minuscules.
  static const allowedExtensions = ['pdf', 'doc', 'docx'];

  /// 5 Mo, en octets (1 Mo = 1024 × 1024 octets).
  static const maxSizeInBytes = 5 * 1024 * 1024;

  /// Texte d'aide affiché sous le titre de la carte.
  static const formatsHint = 'PDF, DOC ou DOCX (5 Mo maximum)';

  // Messages d'erreur, en français clair.
  static const formatError =
      'Format non accepté : choisissez un fichier PDF, DOC ou DOCX.';
  static const emptyError = 'Ce fichier est vide.';
  static const pickerError =
      "Impossible d'ouvrir le sélecteur de fichiers. Réessayez.";

  static String tooLargeError(int sizeInBytes) =>
      'Fichier trop volumineux (${formatSize(sizeInBytes)}) : '
      'la taille maximale est de 5 Mo.';

  /// Renvoie un message d'erreur, ou null si le fichier est accepté.
  static String? validate({
    required String fileName,
    required int sizeInBytes,
  }) {
    final extension = extensionOf(fileName);
    if (extension == null || !allowedExtensions.contains(extension)) {
      return formatError;
    }
    if (sizeInBytes <= 0) return emptyError;
    if (sizeInBytes > maxSizeInBytes) return tooLargeError(sizeInBytes);
    return null;
  }

  /// Extension en minuscules (« CV.PDF » → « pdf »), ou null s'il n'y en a
  /// pas (« cv », « cv. » ou « .pdf » sans nom avant le point).
  static String? extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return null;
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Taille lisible, à la française : « 512 octets », « 350 Ko »,
  /// « 1,2 Mo », « 6 Mo ».
  static String formatSize(int sizeInBytes) {
    const kilo = 1024;
    const mega = 1024 * 1024;
    if (sizeInBytes < kilo) return '$sizeInBytes octets';
    if (sizeInBytes < mega) return '${(sizeInBytes / kilo).round()} Ko';
    // Une décimale, virgule française, et « ,0 » retiré (« 6 Mo »).
    final value = (sizeInBytes / mega).toStringAsFixed(1).replaceAll('.', ',');
    final trimmed = value.endsWith(',0')
        ? value.substring(0, value.length - 2)
        : value;
    return '$trimmed Mo';
  }
}
