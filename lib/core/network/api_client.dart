// lib/core/network/api_client.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Central HTTP client for all Wanderly API calls.
/// Base URL: https://ota-jnuy.onrender.com/api/v1
class ApiClient {
  static const String baseUrl = 'https://ota-jnuy.onrender.com/api/v1';
  static const Duration _timeout = Duration(seconds: 30);

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // FIX: Cache SharedPreferences so _headers() never does a disk read
  // mid-gesture. Initialised once on first use via _prefs getter.
  SharedPreferences? _prefsCache;
  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  // FIX: Cache the access token in memory so _headers() is fully synchronous
  // after the first call. Cleared on logout / 401.
  String? _cachedAccessToken;

  // ── Refresh deduplication ────────────────────────────────────────
  Future<void>? _refreshFuture;

  // ── Token helpers ────────────────────────────────────────────────
  Future<void> saveTokens(String access, String refresh) async {
    _cachedAccessToken = access; // update memory cache immediately
    final p = await _prefs;
    await p.setString(_kAccessToken, access);
    await p.setString(_kRefreshToken, refresh);
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    final p = await _prefs;
    _cachedAccessToken = p.getString(_kAccessToken);
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    final p = await _prefs;
    return p.getString(_kRefreshToken);
  }

  Future<void> clearTokens() async {
    _cachedAccessToken = null; // clear memory cache
    final p = await _prefs;
    await p.remove(_kAccessToken);
    await p.remove(_kRefreshToken);
  }

  // ── Header builder ───────────────────────────────────────────────
  // FIX: After the first getAccessToken() call this is effectively
  // synchronous (memory read only), so it never blocks during a gesture.
  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Token refresh (deduplicated) ─────────────────────────────────
  Future<void> _refreshAccessToken() async {
    if (_refreshFuture != null) {
      await _refreshFuture;
      return;
    }
    _refreshFuture = _doRefresh();
    try {
      await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _doRefresh() async {
    final refresh = await getRefreshToken();
    if (refresh == null) throw ApiException('No refresh token', 401);

    final uri = Uri.parse('$baseUrl/auth/refresh');
    final res = await http
        .post(
          uri,
          headers: await _headers(),
          body: jsonEncode({'refreshToken': refresh}),
        )
        .timeout(_timeout);

    if (res.statusCode == 401) {
      await clearTokens();
      throw ApiException('Session expired. Please log in again.', 401);
    }

    // FIX: parse in background isolate even during refresh
    final body = await compute(_decodeJson, res.body);
    final newAccess = body['data']?['token'] as String? ??
        body['data']?['accessToken'] as String?;
    if (newAccess == null) throw ApiException('Refresh failed', 401);

    final newRefresh = body['data']?['refreshToken'] as String?;
    if (newRefresh != null) {
      await saveTokens(newAccess, newRefresh);
    } else {
      _cachedAccessToken = newAccess;
      final p = await _prefs;
      await p.setString(_kAccessToken, newAccess);
    }
  }

  // ── 401 retry wrapper ────────────────────────────────────────────
  Future<Map<String, dynamic>> _withRefresh(
    Future<http.Response> Function() request,
    Future<http.Response> Function() retry,
    bool auth,
  ) async {
    final response = await request().timeout(_timeout);
    if (response.statusCode == 401 && auth) {
      try {
        await _refreshAccessToken();
        final retried = await retry().timeout(_timeout);
        return _parseInBackground(retried);
      } on ApiException {
        rethrow;
      } catch (_) {
        throw ApiException('Session expired. Please log in again.', 401);
      }
    }
    return _parseInBackground(response);
  }

  // ── Core request methods ─────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    return _withRefresh(
      () async => http.get(uri, headers: await _headers(auth: auth)),
      () async => http.get(uri, headers: await _headers(auth: auth)),
      auth,
    );
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final encoded = jsonEncode(body);
    return _withRefresh(
      () async =>
          http.post(uri, headers: await _headers(auth: auth), body: encoded),
      () async =>
          http.post(uri, headers: await _headers(auth: auth), body: encoded),
      auth,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final encoded = jsonEncode(body);
    return _withRefresh(
      () async =>
          http.patch(uri, headers: await _headers(auth: auth), body: encoded),
      () async =>
          http.patch(uri, headers: await _headers(auth: auth), body: encoded),
      auth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _withRefresh(
      () async => http.delete(uri, headers: await _headers(auth: auth)),
      () async => http.delete(uri, headers: await _headers(auth: auth)),
      auth,
    );
  }

  // ── Response parser ──────────────────────────────────────────────
  // FIX: jsonDecode is moved off the main thread via compute().
  // Previously this ran synchronously on the UI isolate — on a large
  // booking payload mid-gesture that was enough to freeze the animator.
  Future<Map<String, dynamic>> _parseInBackground(
      http.Response response) async {
    Map<String, dynamic> body;
    try {
      body = await compute(_decodeJson, response.body);
    } catch (_) {
      throw ApiException('Invalid JSON response', response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['message'] as String? ?? 'Unknown error';
    throw ApiException(message, response.statusCode, body);
  }
}

// ── Top-level function required by compute() ─────────────────────────
// Must be a top-level or static function — closures are not allowed.
Map<String, dynamic> _decodeJson(String body) {
  return jsonDecode(body) as Map<String, dynamic>;
}

// ── Exception ────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? body;

  ApiException(this.message, this.statusCode, [this.body]);

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
