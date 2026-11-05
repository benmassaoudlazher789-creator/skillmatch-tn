import 'package:file_picker/file_picker.dart';

import '../domain/cv_file_rules.dart';

/// Ce que l'application garde du fichier choisi : son nom et sa taille.
/// Rien d'autre : le contenu du CV n'est jamais lu.
class PickedCvFile {
  const PickedCvFile({required this.name, required this.sizeInBytes});

  final String name;
  final int sizeInBytes;
}

/// Petite interface pour choisir un fichier CV.
///
/// Pourquoi une interface ? L'écran ne dépend pas directement du paquet
/// file_picker. Dans les tests, on lui donne un faux sélecteur qui renvoie
/// le fichier voulu, sans ouvrir de vraie fenêtre système.
abstract interface class CvPicker {
  /// Ouvre le sélecteur. Renvoie null si l'utilisateur annule.
  Future<PickedCvFile?> pick();
}

/// Vraie version, basée sur le paquet file_picker.
/// C'est le seul fichier du projet qui importe file_picker.
class FilePickerCvPicker implements CvPicker {
  const FilePickerCvPicker();

  @override
  Future<PickedCvFile?> pick() async {
    // Depuis file_picker 13, on appelle directement FilePicker.pickFile
    // (méthode statique, plus de « .platform »). Elle ne choisit qu'un seul
    // fichier et renvoie null si l'utilisateur annule.
    // Le contenu n'est plus chargé en mémoire d'office : on ne lit que ce
    // qu'on demande (ici le nom et la taille).
    final file = await FilePicker.pickFile(
      // Filtre dès l'ouverture. On revérifie quand même dans l'écran, car
      // certains téléphones ignorent ce filtre.
      type: FileType.custom,
      allowedExtensions: CvFileRules.allowedExtensions,
    );
    if (file == null) return null;

    // length() donne la taille en octets, ou null si elle est inconnue.
    // Sans taille, on ne peut pas vérifier la limite de 5 Mo : on refuse
    // le fichier plutôt que de l'accepter sans contrôle. L'écran attrape
    // cette erreur et affiche son message d'échec.
    final size = await file.length();
    if (size == null) {
      throw StateError('Taille du fichier inconnue : ${file.name}');
    }
    return PickedCvFile(name: file.name, sizeInBytes: size);
  }
}
