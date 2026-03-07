import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/student.dart';

class AppError implements Exception {
  const AppError(this.message);

  final String message;
}

class IntraApiService {
  static const _apiBase = 'https://api.intra.42.fr';
  static const _oauthTokenPath = '/oauth/token';
  static const _usersPath = '/v2/users';
  static const _tokenSafetyMarginSeconds = 30;
  static const int _debugTokenTtlOverrideSeconds = 60;

  final http.Client _client;
  String? _accessToken;
  DateTime? _tokenExpiresAt;

  IntraApiService({http.Client? client}) : _client = client ?? http.Client();

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[IntraApiService] $message');
    }
  }

  static String _networkErrorMessage(String action) {
    if (kIsWeb) {
      return 'Network error while $action. In web mode, this can be caused by '
          'browser CORS restrictions. Use Android/iOS run for full API test.';
    }
    return 'Network error while $action.';
  }

  Future<Student> fetchStudentByLogin(String login) async {
    if (!Env.isConfigured) {
      throw const AppError(
        'Missing INTRA_UID or INTRA_SECRET in .env file.',
      );
    }

    final normalizedLogin = login.trim();
    if (normalizedLogin.isEmpty) {
      throw const AppError('Please enter a login.');
    }

    final token = await _getValidToken();
    final uri = Uri.parse('$_apiBase$_usersPath/$normalizedLogin');
    late http.Response response;
    try {
      _debugLog('GET $uri');
      response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      _debugLog('GET /v2/users/$normalizedLogin -> ${response.statusCode}');
    } catch (_) {
      throw AppError(_networkErrorMessage('requesting user data'));
    }

    if (response.statusCode == 404) {
      throw AppError('Login "$normalizedLogin" not found.');
    }

    if (response.statusCode == 401) {
      // Token can be revoked before its expiration; force refresh once.
      _debugLog('401 received, forcing token refresh and retry.');
      _accessToken = null;
      _tokenExpiresAt = null;
      return _fetchWithFreshToken(normalizedLogin);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppError(
        '42 API error: ${response.statusCode} ${response.reasonPhrase ?? ''}'
            .trim(),
      );
    }

    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Student.fromJson(jsonBody);
  }

  Future<Student> _fetchWithFreshToken(String login) async {
    final token = await _requestNewToken();
    _accessToken = token;

    final uri = Uri.parse('$_apiBase$_usersPath/$login');
    late http.Response response;
    try {
      _debugLog('GET (retry) $uri');
      response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      _debugLog('GET /v2/users/$login (retry) -> ${response.statusCode}');
    } catch (_) {
      throw AppError(_networkErrorMessage('requesting user data'));
    }

    if (response.statusCode == 404) {
      throw AppError('Login "$login" not found.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppError(
        '42 API error: ${response.statusCode} ${response.reasonPhrase ?? ''}'
            .trim(),
      );
    }

    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Student.fromJson(jsonBody);
  }

  Future<String> _getValidToken() async {
    final now = DateTime.now();
    final token = _accessToken;
    final expiresAt = _tokenExpiresAt;

    if (token != null && expiresAt != null && now.isBefore(expiresAt)) {
      _debugLog('Using cached OAuth token (expires at $expiresAt).');
      return token;
    }

    _debugLog('Requesting new OAuth token (missing or expired cache).');
    final newToken = await _requestNewToken();
    _accessToken = newToken;
    return newToken;
  }

  Future<String> _requestNewToken() async {
    final uri = Uri.parse('$_apiBase$_oauthTokenPath');
    late http.Response response;

    try {
      _debugLog('POST $uri');
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'client_credentials',
          'client_id': Env.uid,
          'client_secret': Env.secret,
        },
      );
      _debugLog('POST /oauth/token -> ${response.statusCode}');
    } catch (_) {
      throw AppError(_networkErrorMessage('requesting access token'));
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppError(
        'OAuth error: ${response.statusCode} ${response.reasonPhrase ?? ''}'
            .trim(),
      );
    }

    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = (jsonBody['access_token'] ?? '').toString();
    final expiresIn = (jsonBody['expires_in'] as num?)?.toInt() ?? 0;

    if (accessToken.isEmpty || expiresIn <= 0) {
      throw const AppError('Received invalid OAuth token response.');
    }

    // In debug builds, allow a short fixed TTL for easy defense/demo.
    final now = DateTime.now();
    final serverExpiresAt = now.add(Duration(seconds: expiresIn));
    final effectiveTtlSeconds =
        kDebugMode
            ? _debugTokenTtlOverrideSeconds
            : (expiresIn - _tokenSafetyMarginSeconds).clamp(1, expiresIn).toInt();
    final cachedExpiresAt = now.add(Duration(seconds: effectiveTtlSeconds));
    _debugLog(
      'OAuth TTL: expires_in=$expiresIn sec, '
      'safety_margin=$_tokenSafetyMarginSeconds sec, '
      'effective_ttl=$effectiveTtlSeconds sec'
      '${kDebugMode ? ' (debug override)' : ''}.',
    );
    _debugLog('Server token expires at $serverExpiresAt.');
    _debugLog('Cached token expires at $cachedExpiresAt.');
    _tokenExpiresAt = cachedExpiresAt;
    _debugLog('Cached OAuth token until $_tokenExpiresAt.');
    return accessToken;
  }
}
