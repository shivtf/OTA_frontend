import '../network/api_client.dart';

class AuthService {
  final _client = ApiClient.instance;

  // ── POST /auth/register ─────────────────────────────────────────
  Future<RegisterResult> register(Map<String, dynamic> body) async {
    final res = await _client.post('/auth/register', body);
    // Response: { success, message, data: { user: {...} } }
    final data = res['data'] as Map<String, dynamic>;
    return RegisterResult.fromJson(data);
  }

  // ── POST /auth/login ────────────────────────────────────────────
  Future<AuthResult> login(String email, String password) async {
    final res = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    });
    // Response: { success, message, data: { user: {...}, accessToken, refreshToken } }
    final data = AuthResult.fromJson(res['data'] as Map<String, dynamic>);
    await _client.saveTokens(data.accessToken, data.refreshToken);
    return data;
  }

  // ── POST /auth/logout ───────────────────────────────────────────
  Future<void> logout() async {
    final refresh = await _client.getRefreshToken();
    if (refresh != null) {
      try {
        await _client.post('/auth/logout', {'refreshToken': refresh},
            auth: true);
      } catch (_) {}
    }
    await _client.clearTokens();
  }

  // ── POST /auth/refresh ──────────────────────────────────────────
  Future<String> refreshToken() async {
    final refresh = await _client.getRefreshToken();
    if (refresh == null) throw ApiException('No refresh token', 401);
    final res = await _client.post('/auth/refresh', {'refreshToken': refresh});
    // Backend refresh returns 'token', not 'accessToken'
    final access =
        res['data']['token'] as String? ?? res['data']['accessToken'] as String;
    final newRefresh = res['data']['refreshToken'] as String? ?? refresh;
    await _client.saveTokens(access, newRefresh);
    return access;
  }

  // ── GET /auth/me ────────────────────────────────────────────────
  // Response: { success, message, data: { user: {...} } }
  Future<UserProfile> getMe() async {
    final res = await _client.get('/auth/me', auth: true);
    final data = res['data'] as Map<String, dynamic>;
    // Backend returns data.user or data directly
    final userMap = data['user'] as Map<String, dynamic>? ?? data;
    return UserProfile.fromJson(userMap);
  }

  // ── PATCH /auth/me ──────────────────────────────────────────────
  Future<UserProfile> updateMe(Map<String, dynamic> body) async {
    final res = await _client.patch('/auth/me', body, auth: true);
    final data = res['data'] as Map<String, dynamic>;
    return UserProfile.fromJson(data);
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

  // ── POST /auth/change-password ──────────────────────────────────
  // Authenticated endpoint: verifies currentPassword on the backend
  // before updating. All other sessions are invalidated on success.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await _client.post(
      '/auth/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
      auth: true,
    );
  }

  // ── Token helpers ───────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final token = await _client.getAccessToken();
    return token != null;
  }
}

// ── Models ──────────────────────────────────────────────────────────

/// Returned from /auth/register — no tokens yet (email verification required)
class RegisterResult {
  final UserProfile user;
  final String message;

  RegisterResult({required this.user, required this.message});

  factory RegisterResult.fromJson(Map<String, dynamic> j) => RegisterResult(
        user: UserProfile.fromJson(j['user'] as Map<String, dynamic>? ?? j),
        message: j['message'] as String? ?? '',
      );
}

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
        // Backend login/register returns 'token', not 'accessToken'
        accessToken: j['token'] as String? ?? j['accessToken'] as String? ?? '',
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
  final String? dateOfBirth;
  final String? nationality;
  final String? passportNumber;
  final bool isVerified;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.dateOfBirth,
    this.nationality,
    this.passportNumber,
    required this.isVerified,
  });

  String get fullName => '$firstName $lastName';

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String? ?? '',
        email: j['email'] as String? ?? '',
        // Backend returns snake_case from register, camelCase elsewhere
        firstName:
            j['firstName'] as String? ?? j['first_name'] as String? ?? '',
        lastName: j['lastName'] as String? ?? j['last_name'] as String? ?? '',
        phone: j['phone'] as String?,
        dateOfBirth:
            j['dateOfBirth'] as String? ?? j['date_of_birth'] as String?,
        nationality: j['nationality'] as String?,
        passportNumber:
            j['passportNumber'] as String? ?? j['passport_number'] as String?,
        isVerified:
            j['isVerified'] as bool? ?? j['is_verified'] as bool? ?? false,
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
