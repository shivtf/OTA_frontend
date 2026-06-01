// lib/core/utils/reset_password_token_cache.dart
//
// Simple in-memory + SharedPreferences cache for the reset password token.
// The token arrives via deep link (otaapp://auth/reset-password?token=xxx)
// and must survive until the user fills the form and hits Reset Password.
//
// Usage:
//   Save:  ResetPasswordTokenCache.save(token);
//   Read:  final token = await ResetPasswordTokenCache.read();
//   Clear: ResetPasswordTokenCache.clear();

import 'package:shared_preferences/shared_preferences.dart';

class ResetPasswordTokenCache {
  ResetPasswordTokenCache._();

  static const _key = 'reset_password_token';

  // In-memory copy so reads are synchronous after the first save.
  static String? _memoryToken;

  /// Save the token from the deep link.
  static Future<void> save(String token) async {
    _memoryToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  /// Read the cached token. Returns null if none is saved.
  static Future<String?> read() async {
    if (_memoryToken != null) return _memoryToken;
    final prefs = await SharedPreferences.getInstance();
    _memoryToken = prefs.getString(_key);
    return _memoryToken;
  }

  /// Clear after successful reset or when the screen is disposed.
  static Future<void> clear() async {
    _memoryToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
