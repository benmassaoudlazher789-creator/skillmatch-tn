import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_token.dart';

/// Appels de l'API pour les comptes.
///
/// Pourquoi une interface ? Comme pour CvPicker : les écrans ne dépendent
/// pas du paquet http. Dans les tests, on donne un faux AuthApi, et aucun
/// appel réseau réel n'est fait.
abstract interface class AuthApi {
  /// POST /auth/register. Ne renvoie rien : l'API répond 201 sans jeton.
  /// Lève une AuthException en cas d'échec.
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// POST /auth/login. Lève une AuthException en cas d'échec.
  Future<AuthToken> login({required String email, required String password});
}

/// Vraie version, basée sur le paquet http.
/// C'est le seul fichier de l'application qui importe http.
class HttpAuthApi implements AuthApi {
  HttpAuthApi({
    http.Client? client,
    String baseUrl = apiBaseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       // On retire un éventuel « / » final pour ne pas obtenir « //auth ».
       _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  /// Les tests y mettent un MockClient (fourni par le paquet http) qui
  /// répond sans réseau. Sinon, un vrai client.
  final http.Client _client;
  final String _baseUrl;

  /// Au-delà, on abandonne : sans limite, le bouton resterait bloqué
  /// indéfiniment si le serveur ne répond pas.
  final Duration timeout;

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
    if (response.statusCode != 201) throw _failureFor(response);
  }

  @override
  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (response.statusCode != 200) throw _failureFor(response);
    return _parseToken(response);
  }

  /// Envoie le corps en JSON. Toute absence de réponse devient « réseau ».
  Future<http.Response> _post(String path, Map<String, String> body) async {
    try {
      return await _client
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AuthException(AuthFailure.network);
    } on http.ClientException {
      // ClientException couvre : pas d'Internet, serveur arrêté, et dans
      // Chrome une réponse bloquée par CORS.
      throw const AuthException(AuthFailure.network);
    }
  }

  /// Traduit un code HTTP d'erreur en raison connue.
  static AuthException _failureFor(http.Response response) =>
      switch (response.statusCode) {
        400 => AuthException(
          AuthFailure.invalidInput,
          serverMessage: _firstValidationMessage(response),
        ),
        401 => const AuthException(AuthFailure.invalidCredentials),
        409 => const AuthException(AuthFailure.emailAlreadyUsed),
        429 => const AuthException(AuthFailure.tooManyAttempts),
        _ => const AuthException(AuthFailure.unknown),
      };

  /// Le 400 de l'API ressemble à { "errors": { "password": ["…"] } }.
  /// On garde le premier message : il dit quel champ corriger.
  static String? _firstValidationMessage(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json case {'errors': final Map<String, dynamic> errors}) {
        for (final messages in errors.values) {
          if (messages case [final String first, ...]) return first;
        }
      }
    } on FormatException {
      // Corps illisible : on se rabat sur le message générique.
    }
    return null;
  }

  /// Lit { "accessToken": "…", "expiresIn": 3600 }.
  ///
  /// ATTENTION : ce corps contient le jeton. En cas de problème, on lève une
  /// AuthException neutre et on jette l'erreur d'origine : le message d'une
  /// FormatException recopie le texte analysé, donc le jeton.
  static AuthToken _parseToken(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json
          case {
            'accessToken': final String token,
            'expiresIn': final int seconds,
          }
          when token.isNotEmpty) {
        return AuthToken(
          accessToken: token,
          expiresIn: Duration(seconds: seconds),
        );
      }
    } on FormatException {
      // Volontairement ignorée (voir plus haut) : on tombe sur le throw.
    }
    throw const AuthException(AuthFailure.unknown);
  }
}
