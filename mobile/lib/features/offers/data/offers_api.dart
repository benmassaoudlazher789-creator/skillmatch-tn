import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../domain/offer.dart';
import '../domain/offers_failure.dart';

/// Appel de l'API pour les offres : GET /offers.
///
/// Pourquoi une interface ? Comme pour CvApi : le reste de l'application ne
/// dépend pas du paquet http, et les tests n'appellent jamais le réseau.
abstract interface class OffersApi {
  /// Offres classées par le serveur pour ces compétences, dans l'ordre reçu.
  /// Lève une OffersException en cas d'échec.
  Future<List<Offer>> fetch({
    required String token,
    required List<String> skills,
  });
}

/// Vraie version, basée sur le paquet http.
///
/// Rien n'est jamais écrit dans un log ici : ni le jeton, ni les
/// compétences (qui décrivent le profil du candidat).
class HttpOffersApi implements OffersApi {
  HttpOffersApi({
    http.Client? client,
    String baseUrl = apiBaseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  final http.Client _client;
  final String _baseUrl;

  /// Au-delà, on abandonne : l'écran ne reste pas en chargement sans fin.
  final Duration timeout;

  /// 50 : le maximum accepté par l'API. On demande tout d'un coup pour que
  /// les filtres (Emplois, Stages, PFE) travaillent sur la liste complète.
  static const limit = 50;

  @override
  Future<List<Offer>> fetch({
    required String token,
    required List<String> skills,
  }) async {
    // Uri encode chaque compétence (« C# » devient « C%23 », « Power BI »
    // devient « Power+BI ») : on ne construit jamais l'adresse à la main.
    // Une liste donne un paramètre répété : ?skill=Dart&skill=SQL.
    final uri = Uri.parse('$_baseUrl/offers')
        .replace(queryParameters: {'skill': skills, 'limit': '$limit'});

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
      throw const OffersException(OffersFailure.network);
    } on http.ClientException {
      throw const OffersException(OffersFailure.network);
    }

    if (response.statusCode == 200) return _parseOffers(response);
    throw OffersException(_failureFor(response));
  }

  static OffersFailure _failureFor(http.Response response) {
    final code = _errorCode(response);
    return switch (response.statusCode) {
      400 when code == 'too_many_skills' => OffersFailure.tooManySkills,
      400 when code == 'skill_too_long' => OffersFailure.skillTooLong,
      401 => OffersFailure.sessionExpired,
      _ => OffersFailure.unknown,
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

  /// Lit { "offers": [ … ] }. L'ordre du serveur est gardé tel quel.
  ///
  /// Une offre incomplète ou d'un type inconnu est écartée, sans faire
  /// échouer tout l'écran. Si le corps entier est illisible : erreur
  /// inattendue (l'erreur d'origine, qui recopie le texte, est jetée).
  static List<Offer> _parseOffers(http.Response response) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const OffersException(OffersFailure.unknown);
    }
    if (json case {'offers': final List<dynamic> items}) {
      // « ? » devant l'élément : il n'est ajouté que s'il n'est pas null.
      return [for (final item in items) ?_parseOffer(item)];
    }
    throw const OffersException(OffersFailure.unknown);
  }

  static Offer? _parseOffer(Object? item) {
    // D'abord vérifier que c'est un objet JSON : ensuite, item['url'] est
    // permis (Dart sait que item est une Map).
    if (item is! Map<String, dynamic>) return null;
    if (item case {
      'id': final String id,
      'title': final String title,
      'company': final String company,
      'type': final String typeCode,
      'city': final String city,
      'isSample': final bool isSample,
      'score': final int score,
      'explanation': final String explanation,
    }) {
      final type = OfferType.fromCode(typeCode);
      if (type == null) return null;
      final url = item['url'];
      return Offer(
        id: id,
        title: title,
        company: company,
        city: city,
        type: type,
        url: url is String ? url : null,
        isSample: isSample,
        // Par prudence : la barre de progression attend 0 à 100.
        score: score.clamp(0, 100),
        explanation: explanation,
        requiredAcquired: _strings(item['requiredAcquired']),
        requiredMissing: _strings(item['requiredMissing']),
        preferredAcquired: _strings(item['preferredAcquired']),
        preferredMissing: _strings(item['preferredMissing']),
      );
    }
    return null;
  }

  /// Liste de textes ; tout ce qui n'est pas un texte est ignoré.
  static List<String> _strings(Object? value) =>
      value is List ? List.unmodifiable(value.whereType<String>()) : const [];
}
