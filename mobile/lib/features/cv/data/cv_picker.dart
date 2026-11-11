import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../domain/cv_file_rules.dart';

/// Le fichier CV choisi : son nom, sa taille, et une fonction pour lire son
/// contenu.
///
/// Pourquoi une fonction (readBytes) plutôt que les octets eux-mêmes ? Le
/// contenu n'est lu qu'au moment de l'envoi, une fois le nom et la taille
/// acceptés : un fichier de 2 Go choisi par erreur n'est jamais chargé en
/// mémoire. Et l'écran ne garde pas le contenu du CV dans son état.
class PickedCvFile {
  const PickedCvFile({
    required this.name,
    required this.sizeInBytes,
    required this.readBytes,
  });

  final String name;
  final int sizeInBytes;

  /// Lit le contenu du fichier. Peut échouer (fichier déplacé, supprimé…).
  final Future<Uint8List> Function() readBytes;

  // Le nom d'un CV contient souvent le nom du candidat : un print(file)
  // n'affiche que la taille.
  @override
  String toString() => 'PickedCvFile(nom masqué, $sizeInBytes octets)';
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
    // Le contenu n'est pas chargé en mémoire d'office : on ne lit que ce
    // qu'on demande (le nom et la taille ici, le contenu à l'envoi).
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
    // cette erreur et affiche son message d'échec. Le message ne cite pas
    // le nom du fichier, qui peut contenir celui du candidat.
    final size = await file.length();
    if (size == null) {
      throw StateError('Taille du fichier inconnue.');
    }
    // file.readAsBytes est passé tel quel : rien n'est lu maintenant.
    return PickedCvFile(
      name: file.name,
      sizeInBytes: size,
      readBytes: file.readAsBytes,
    );
  }
}
