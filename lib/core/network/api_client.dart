// lib/core/network/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Central HTTP client for all Wanderly API calls.
/// Base URL: https://ota-jnuy.onrender.com/api/v1
class ApiClient {
  static const String baseUrl = 'https://ota-jnuy.onrender.com/api/v1';
  static const Duration _timeout = Duration(seconds: 30);

  // ── Token storage keys ───────────────────────────────────────────
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  // ── Singleton ────────────────────────────────────────────────────
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // ── Token helpers ────────────────────────────────────────────────
  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, access);
    await prefs.setString(_kRefreshToken, refresh);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kRefreshToken);
  }

  // ── Header builder ───────────────────────────────────────────────
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

  // ── Core request methods ─────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await http
        .get(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);
    return _parse(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .post(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .patch(
          uri,
          headers: await _headers(auth: auth),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parse(response);
  }

  Future<Map<String, dynamic>> delete(String path, {bool auth = false}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http
        .delete(uri, headers: await _headers(auth: auth))
        .timeout(_timeout);
    return _parse(response);
  }

  // ── Response parser ──────────────────────────────────────────────
  Map<String, dynamic> _parse(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
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

// ── Exception ──────────────────────────────────────────────────────
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
