// lib/features/auth/providers/auth_provider.dart
//
// Drop-in replacement for the dummy auth used in login_screen.dart.
// Wrap your MaterialApp with ChangeNotifierProvider<AuthProvider>.

import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserProfile? _user;
  bool _isLoading = false;
  String? _error;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  // ── Load saved session ──────────────────────────────────────────
  Future<void> tryAutoLogin() async {
    final loggedIn = await _service.isLoggedIn();
    if (!loggedIn) return;
    try {
      _user = await _service.getMe();
      notifyListeners();
    } catch (_) {
      await _service.logout();
    }
  }

  // ── Register ────────────────────────────────────────────────────
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
  }) async {
    _setLoading(true);
    try {
      final result = await _service.register({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        if (phone != null) 'phone': phone,
      });
      _user = result.user;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Login ───────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _service.login(email, password);
      _user = result.user;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ──────────────────────────────────────────────────────
  Future<void> logout() async {
    await _service.logout();
    _user = null;
    notifyListeners();
  }

  // ── Update profile ──────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> body) async {
    _setLoading(true);
    try {
      _user = await _service.updateMe(body);
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Forgot / reset password ─────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    try {
      await _service.forgotPassword(email);
      _error = null;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Private ─────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
