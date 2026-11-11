import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../domain/cv_failure.dart';

/// Appel de l'API pour l'analyse du CV : POST /cv.
///
/// Pourquoi une interface ? Comme pour AuthApi : le reste de l'application
/// ne dépend pas du paquet http. Les tests donnent un faux CvApi, ou un
/// HttpCvApi branché sur un MockClient : aucun appel réseau réel.
abstract interface class CvApi {
  /// Envoie le CV et renvoie les compétences reconnues (liste parfois vide).
  ///
  /// [extension] (« pdf » ou « docx ») sert à nommer le fichier envoyé.
  /// Lève une CvException en cas d'échec.
  Future<List<String>> analyze({
    required String token,
    required Uint8List bytes,
    required String extension,
  });
}

/// Vraie version, basée sur le paquet http.
///
/// Rien n'est jamais écrit dans un log ici : ni le jeton, ni le contenu du
/// CV, ni la réponse (qui décrit le profil du candidat).
class HttpCvApi implements CvApi {
  HttpCvApi({
    http.Client? client,
    String baseUrl = apiBaseUrl,
    // 30 s au lieu des 15 s de la connexion : envoyer 5 Mo sur un réseau
    // mobile lent, puis laisser le serveur lire le fichier, prend du temps.
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       // On retire un éventuel « / » final pour ne pas obtenir « //cv ».
       _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  /// Au-delà, on abandonne : sans limite, l'écran resterait sur
  /// « Analyse en cours… » indéfiniment si le serveur ne répond pas.
  final Duration timeout;

  /// Nom du champ du formulaire attendu par l'API (CvEndpoints.FileFieldName).
  static const fileField = 'file';

  @override
  Future<List<String>> analyze({
    required String token,
    required Uint8List bytes,
    required String extension,
  }) async {
    // multipart/form-data : la façon standard d'envoyer un fichier en HTTP.
    // Le jeton voyage dans l'en-tête Authorization, jamais dans l'adresse
    // (une adresse peut être enregistrée dans les journaux d'un serveur).
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/cv'))
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          fileField,
          bytes,
          // Nom neutre, et non le vrai nom du fichier : celui-ci contient
          // souvent le nom du candidat, et l'API ne le lit de toute façon
          // pas. Un nom est quand même nécessaire pour que le serveur
          // reconnaisse la partie comme un fichier.
          filename: 'cv.$extension',
        ),
      );

    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw const CvException(CvFailure.network);
    } on http.ClientException {
      // Pas d'Internet, serveur arrêté, ou dans Chrome une réponse bloquée
      // par CORS.
      throw const CvException(CvFailure.network);
    }

    if (response.statusCode == 200) return _parseSkills(response);
    throw CvException(_failureFor(response));
  }

  /// Traduit un code HTTP d'erreur (et le « code » de l'API) en raison connue.
  static CvFailure _failureFor(http.Response response) {
    final code = _errorCode(response);
    return switch (response.statusCode) {
      400 when code == 'empty' => CvFailure.empty,
      400 => CvFailure.invalidRequest,
      401 => CvFailure.sessionExpired,
      413 => CvFailure.tooLarge,
      415 => CvFailure.unsupportedType,
      422 when code == 'password_protected' => CvFailure.passwordProtected,
      422 when code == 'no_text' => CvFailure.noText,
      422 => CvFailure.unreadable,
      429 => CvFailure.tooManyRequests,
      _ => CvFailure.unknown,
    };
  }

  /// Les erreurs de l'API ressemblent à { "code": "no_text", "title": "…" }.
  /// Le 401 et le 429 arrivent sans corps : on renvoie alors null.
  static String? _errorCode(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json case {'code': final String code}) return code;
    } on FormatException {
      // Corps vide ou illisible : le code HTTP suffit.
    }
    return null;
  }

  /// Lit { "skills": ["Flutter", "SQL"] }.
  ///
  /// L'erreur d'origine est volontairement jetée : le message d'une
  /// FormatException recopie le texte analysé, donc les compétences.
  static List<String> _parseSkills(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json case {'skills': final List<dynamic> skills}) {
        return skills.whereType<String>().toList();
      }
    } on FormatException {
      // On tombe sur le throw ci-dessous.
    }
    throw const CvException(CvFailure.unknown);
  }
}
