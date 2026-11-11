import 'dart:convert';
import 'dart:typed_data';

import 'package:skillmatch_tn/features/cv/data/cv_analysis_service.dart';
import 'package:skillmatch_tn/features/cv/data/cv_api.dart';
import 'package:skillmatch_tn/features/cv/data/cv_picker.dart';

import 'fake_auth.dart';

// Faux objets partagés par les tests du CV : aucun appel réseau, aucun
// accès au stockage du téléphone. Valeurs fictives, propres aux tests.

/// Jeton d'exemple rangé dans le faux stockage.
const fakeCvToken = 'jeton-exemple-cv-456';

/// Contenu d'exemple : un faux début de PDF, sans aucune donnée réelle.
Future<Uint8List> fakePdfBytes() async =>
    Uint8List.fromList(utf8.encode('%PDF-contenu-exemple'));

/// Lecture qui échoue, comme un fichier supprimé entre le choix et l'envoi.
Future<Uint8List> failingBytes() async =>
    throw StateError('fichier introuvable (test)');

/// Faux CvApi : retient les appels et répond ce que le test demande.
class FakeCvApi implements CvApi {
  /// Réponse de analyze. Par défaut : une liste d'exemple.
  Future<List<String>> Function() onAnalyze = () async => const [
    'Dart',
    'Flutter',
    'SQL',
    'Git',
  ];

  final calls = <({String token, Uint8List bytes, String extension})>[];

  @override
  Future<List<String>> analyze({
    required String token,
    required Uint8List bytes,
    required String extension,
  }) {
    calls.add((token: token, bytes: bytes, extension: extension));
    return onAnalyze();
  }
}

/// Service prêt pour un test, avec un jeton déjà rangé (sauf si
/// [token] vaut null).
({CvAnalysisService service, FakeCvApi api, MemoryTokenStore store})
fakeCvService({String? token = fakeCvToken}) {
  final api = FakeCvApi();
  final store = MemoryTokenStore()..token = token;
  return (
    service: CvAnalysisService(api: api, tokenStore: store),
    api: api,
    store: store,
  );
}

/// Fichier d'exemple déjà choisi.
const fakeCvFile = PickedCvFile(
  name: 'cv_exemple.pdf',
  sizeInBytes: 20,
  readBytes: fakePdfBytes,
);
