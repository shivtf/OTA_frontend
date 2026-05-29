import 'package:flutter/foundation.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final _service = AuthService();

  UserProfile? _user;
  bool _isLoading = false;
  String? _error;
  // Set after registration — prompts "check your email" UI
  bool _awaitingVerification = false;
  String? _pendingEmail;

  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  bool get awaitingVerification => _awaitingVerification;
  String? get pendingEmail => _pendingEmail;

  // Called by ProfileScreen after refreshing /auth/me
  void setUser(UserProfile profile) {
    _user = profile;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

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
  /// Returns true on success. After success, user must verify email.
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? dateOfBirth,
    String? nationality,
    String? passportNumber,
  }) async {
    _setLoading(true);
    try {
      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
        if (nationality != null) 'nationality': nationality,
        if (passportNumber != null && passportNumber.isNotEmpty)
          'passportNumber': passportNumber,
      };
      await _service.register(body);
      _awaitingVerification = true;
      _pendingEmail = email;
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
      _awaitingVerification = false;
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

  // ── Forgot password ─────────────────────────────────────────────
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
