import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../domain/training.dart';
import '../domain/trainings_failure.dart';

/// Appel de l'API pour les formations : GET /trainings.
///
/// Interface, comme OffersApi : le reste de l'application ne dépend pas du
/// paquet http, et les tests n'appellent jamais le réseau.
abstract interface class TrainingsApi {
  /// Formations pour [skill], dans l'ordre du serveur.
  /// Lève une TrainingsException en cas d'échec.
  Future<List<Training>> fetch({required String token, required String skill});
}

/// Vraie version, basée sur le paquet http.
///
/// Rien n'est jamais écrit dans un log ici : ni le jeton, ni la compétence.
class HttpTrainingsApi implements TrainingsApi {
  HttpTrainingsApi({
    http.Client? client,
    String baseUrl = apiBaseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  /// Au-delà, on abandonne : l'écran ne reste pas en chargement sans fin.
  final Duration timeout;

  @override
  Future<List<Training>> fetch({
    required String token,
    required String skill,
  }) async {
    // Uri encode la compétence (« C# » devient « C%23 ») : on ne construit
    // jamais l'adresse à la main. Une seule compétence par appel (choix validé).
    final uri = Uri.parse('$_baseUrl/trainings')
        .replace(queryParameters: {'skill': skill});

    final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            // Le jeton voyage dans l'en-tête, jamais dans l'adresse.
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const TrainingsException(TrainingsFailure.network);
    } on http.ClientException {
      throw const TrainingsException(TrainingsFailure.network);
    }

    if (response.statusCode == 200) return _parseTrainings(response);
    throw TrainingsException(_failureFor(response));
  }

  static TrainingsFailure _failureFor(http.Response response) {
    final code = _errorCode(response);
    return switch (response.statusCode) {
      400 when code == 'skill_too_long' => TrainingsFailure.skillTooLong,
      401 => TrainingsFailure.sessionExpired,
      _ => TrainingsFailure.unknown,
    };
  }

  /// Les erreurs de l'API ressemblent à { "code": "…", "title": "…" }.
  static String? _errorCode(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json case {'code': final String code}) return code;
    } on FormatException {
      // Corps vide ou illisible : le code HTTP suffit.
    }
    return null;
  }

  /// Lit { "skill": …, "trainings": [ … ] }. L'ordre du serveur (niveau,
  /// durée, titre) est gardé tel quel : l'écran ne retrie rien.
  ///
  /// Une formation incomplète, ou d'un niveau ou d'un type inconnu, est
  /// écartée sans faire échouer tout l'écran.
  static List<Training> _parseTrainings(http.Response response) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const TrainingsException(TrainingsFailure.unknown);
    }
    if (json case {'trainings': final List<dynamic> items}) {
      return [for (final item in items) ?_parseTraining(item)];
    }
    throw const TrainingsException(TrainingsFailure.unknown);
  }

  static Training? _parseTraining(Object? item) {
    if (item is! Map<String, dynamic>) return null;
    if (item case {
      'id': final String id,
      'skill': final String skill,
      'title': final String title,
      'level': final String levelCode,
      'hours': final int hours,
      'type': final String typeCode,
      'isSample': final bool isSample,
    }) {
      final level = TrainingLevel.fromCode(levelCode);
      final type = TrainingType.fromCode(typeCode);
      if (level == null || type == null) return null;
      final url = item['url'];
      return Training(
        id: id,
        skill: skill,
        title: title,
        level: level,
        hours: hours,
        type: type,
        isSample: isSample,
        url: url is String ? url : null,
      );
    }
    return null;
  }
}
