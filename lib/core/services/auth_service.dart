// lib/core/services/auth_service.dart
import '../network/api_client.dart';

class AuthService {
  final _client = ApiClient.instance;

  // ── POST /auth/register ─────────────────────────────────────────
  /// [body]: { firstName, lastName, email, password, phone? }
  Future<AuthResult> register(Map<String, dynamic> body) async {
    final res = await _client.post('/auth/register', body);
    return AuthResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── POST /auth/login ────────────────────────────────────────────
  /// [body]: { email, password }
  Future<AuthResult> login(String email, String password) async {
    final res = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });
    final data = AuthResult.fromJson(res['data'] as Map<String, dynamic>);
    await _client.saveTokens(data.accessToken, data.refreshToken);
    return data;
  }

  // ── POST /auth/logout ───────────────────────────────────────────
  Future<void> logout() async {
    final refresh = await _client.getRefreshToken();
    if (refresh != null) {
      await _client.post('/auth/logout', {'refreshToken': refresh}, auth: true);
    }
    await _client.clearTokens();
  }

  // ── POST /auth/refresh ──────────────────────────────────────────
  Future<String> refreshToken() async {
    final refresh = await _client.getRefreshToken();
    if (refresh == null) throw ApiException('No refresh token', 401);
    final res = await _client.post('/auth/refresh', {'refreshToken': refresh});
    final access = res['data']['accessToken'] as String;
    final newRefresh = res['data']['refreshToken'] as String? ?? refresh;
    await _client.saveTokens(access, newRefresh);
    return access;
  }

  // ── GET /auth/me ────────────────────────────────────────────────
  Future<UserProfile> getMe() async {
    final res = await _client.get('/auth/me', auth: true);
    return UserProfile.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── PATCH /auth/me ──────────────────────────────────────────────
  Future<UserProfile> updateMe(Map<String, dynamic> body) async {
    final res = await _client.patch('/auth/me', body, auth: true);
    return UserProfile.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── POST /auth/forgot-password ──────────────────────────────────
  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', {'email': email});
  }

  // ── POST /auth/reset-password ───────────────────────────────────
  Future<void> resetPassword(String token, String newPassword) async {
    await _client.post('/auth/reset-password', {
      'token': token,
      'newPassword': newPassword,
    });
  }

  // ── Token helpers ───────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await _client.getAccessToken();
    return token != null;
  }
}

// ── Models ──────────────────────────────────────────────────────────
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final UserProfile user;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
    accessToken: j['accessToken'] as String? ?? '',
    refreshToken: j['refreshToken'] as String? ?? '',
    user: UserProfile.fromJson(j['user'] as Map<String, dynamic>? ?? j),
  );
}

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.isVerified,
  });

  String get fullName => '$firstName $lastName';

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: j['id'] as String? ?? '',
    email: j['email'] as String? ?? '',
    firstName: j['firstName'] as String? ?? j['first_name'] as String? ?? '',
    lastName: j['lastName'] as String? ?? j['last_name'] as String? ?? '',
    phone: j['phone'] as String?,
    isVerified: j['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'isVerified': isVerified,
  };
}
