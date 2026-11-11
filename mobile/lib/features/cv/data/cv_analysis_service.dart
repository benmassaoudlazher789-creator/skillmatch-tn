import 'dart:typed_data';

import '../../auth/data/token_store.dart';
import '../../skills/domain/skill_rules.dart';
import '../domain/cv_failure.dart';
import '../domain/cv_file_rules.dart';
import 'cv_api.dart';
import 'cv_picker.dart';

/// Regroupe les étapes d'une analyse : lire le jeton, lire le fichier,
/// l'envoyer à l'API, puis ranger la liste reçue.
///
/// Pourquoi une classe à part, et pas tout dans l'écran ? L'écran ne fait
/// qu'afficher « en cours », le résultat ou l'erreur. Les règles (jeton
/// absent, 401, doublons) se testent ici sans écran.
class CvAnalysisService {
  const CvAnalysisService({required this.api, required this.tokenStore});

  final CvApi api;
  final TokenStore tokenStore;

  /// Renvoie les compétences reconnues dans [file]. Lève une CvException.
  Future<List<String>> analyze(PickedCvFile file) async {
    final token = await _readToken();
    if (token == null || token.isEmpty) {
      await _forgetToken();
      throw const CvException(CvFailure.sessionExpired);
    }

    final Uint8List bytes;
    try {
      bytes = await file.readBytes();
    } catch (_) {
      // L'erreur d'origine est jetée : elle peut citer le chemin du fichier.
      throw const CvException(CvFailure.fileRead);
    }
    // Le fichier a pu changer depuis qu'il a été choisi : on revérifie
    // avant d'envoyer, pour ne pas transférer 50 Mo pour rien.
    if (bytes.isEmpty) throw const CvException(CvFailure.empty);
    if (bytes.length > CvFileRules.maxSizeInBytes) {
      throw const CvException(CvFailure.tooLarge);
    }

    final List<String> skills;
    try {
      skills = await api.analyze(
        token: token,
        bytes: bytes,
        // L'écran n'accepte que des noms valides : l'extension existe.
        extension: CvFileRules.extensionOf(file.name) ?? 'pdf',
      );
    } on CvException catch (e) {
      // 401 : le jeton a expiré (60 minutes au plus) ou n'est plus valable.
      // On l'efface pour ne plus l'envoyer, puis l'écran renvoie vers la
      // Connexion.
      if (e.failure == CvFailure.sessionExpired) await _forgetToken();
      rethrow;
    }
    return tidy(skills);
  }

  /// Nettoie la liste reçue avec les mêmes règles qu'une saisie à la main :
  /// espaces retirés, entrées vides et doublons (« flutter » et « Flutter »)
  /// écartés. L'ordre de l'API est gardé.
  static List<String> tidy(List<String> skills) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in skills) {
      final skill = SkillRules.clean(raw);
      // add renvoie false si la clé était déjà dans l'ensemble.
      if (skill.isNotEmpty && seen.add(SkillRules.key(skill))) {
        result.add(skill);
      }
    }
    return result;
  }

  /// Stockage illisible = comme s'il n'y avait pas de jeton : le candidat
  /// devra se reconnecter, ce qui le réécrira.
  Future<String?> _readToken() async {
    try {
      return await tokenStore.read();
    } catch (_) {
      return null;
    }
  }

  /// Un échec de l'effacement ne doit pas masquer le vrai message (session
  /// expirée) : on l'ignore.
  Future<void> _forgetToken() async {
    try {
      await tokenStore.clear();
    } catch (_) {}
  }
}

/// Service utilisé quand un écran n'en reçoit pas (donc hors tests).
/// Créé seulement à sa première lecture, comme defaultAuthSession.
final CvAnalysisService defaultCvAnalysisService = CvAnalysisService(
  api: HttpCvApi(),
  tokenStore: const SecureTokenStore(),
);
