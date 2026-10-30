import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/shared/services/session_cache.dart';

class AuthApiService {
  AuthApiService({
    ApiClient? apiClient,
    ApiClient? publicApiClient,
    AuthTokenStore tokenStore = const AuthTokenStore(),
    LocalSessionCleanup? localSessionCleanup,
  })  : _tokenStore = tokenStore,
        _localSessionCleanup = localSessionCleanup ??
            LocalSessionCleanup(clearToken: tokenStore.clearToken),
        _apiClient =
            apiClient ?? ApiClient(tokenProvider: tokenStore.readToken),
        _publicClient = publicApiClient ?? apiClient ?? ApiClient();

  final ApiClient _apiClient;
  final ApiClient _publicClient;
  final AuthTokenStore _tokenStore;
  final LocalSessionCleanup _localSessionCleanup;

  Future<AuthSession> login(
      {required String email, required String password}) async {
    final response = await _publicClient.postJson('/auth/login', {
      'email': email,
      'password': password,
      'device_name': 'sirati-mobile',
    });

    final session = AuthSession.fromJson(response);
    await _saveSession(session);
    return session;
  }

  /// Exchanges a provider ID token (`google`, `apple`) for a Sirati session.
  /// The server verifies the token; the answer is the same as [login]'s.
  Future<AuthSession> socialSignIn({
    required String provider,
    required String idToken,
    String? nonce,
    String? authorizationCode,
    String? name,
  }) async {
    final response = await _publicClient.postJson('/auth/social/$provider', {
      'id_token': idToken,
      if (nonce != null) 'nonce': nonce,
      if (authorizationCode != null) 'authorization_code': authorizationCode,
      if (name != null) 'name': name,
      'device_name': 'sirati-mobile',
    });

    final session = AuthSession.fromJson(response);
    await _saveSession(session);
    return session;
  }

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? location,
    int? jobTitleId,
    String? jobTitleOther,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'device_name': 'sirati-mobile',
    };
    if (phone != null && phone.trim().isNotEmpty) {
      body['phone'] = phone.trim();
    }
    if (location != null && location.trim().isNotEmpty) {
      body['location'] = location.trim();
    }
    if (jobTitleId != null) {
      body['job_title_id'] = jobTitleId;
    }
    if (jobTitleOther != null && jobTitleOther.trim().isNotEmpty) {
      body['job_title_other'] = jobTitleOther.trim();
    }

    final response = await _publicClient.postJson('/auth/register', body);

    final session = AuthSession.fromJson(response);
    await _saveSession(session);
    return session;
  }

  Future<void> _saveSession(AuthSession session) async {
    await _tokenStore.saveToken(session.token);
    SessionCache.instance.setUser(session.user);
    await _bindAnalyticsUser(session.user);
  }

  /// Opaque backend id only — never email/name.
  Future<void> _bindAnalyticsUser(AuthUser user) async {
    if (user.id > 0) {
      await AnalyticsService.setUserId(user.id.toString());
    }
  }

  Future<AuthUser> verifyEmail({required String code}) async {
    final response = await _apiClient.postJson('/auth/email/verify', {
      'code': code.trim(),
    });
    final data = response['data'];
    final user = AuthUser.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
    SessionCache.instance.setUser(user);
    await _bindAnalyticsUser(user);
    return user;
  }

  // Success calls return nothing: screens confirm with catalog text, as the
  // server's message is not in the user's language.
  Future<void> resendVerification() async {
    await _apiClient.postJson('/auth/email/resend', const {});
  }

  Future<void> forgotPassword({required String email}) async {
    await _publicClient.postJson('/auth/forgot-password', {
      'email': email,
    });
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _publicClient.postJson('/auth/reset-password', {
      'email': email.trim(),
      'code': code.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
  }

  Future<void> logout() async {
    final token = await _tokenStore.readToken();
    // Read the device token before the local wipe rotates it, so the server
    // cleanup removes the row that actually belongs to this account.
    final fcmToken = await NotificationService.instance.getToken();
    try {
      await _clearLocalSession();
    } finally {
      // Local failures must not leave the captured bearer valid on the server.
      if (token != null && token.isNotEmpty) {
        unawaited(_remoteLogoutCleanup(token, fcmToken));
      }
    }
  }

  Future<void> _remoteLogoutCleanup(String token, String? fcmToken) async {
    final remote = ApiClient(tokenProvider: () async => token);
    try {
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await remote.deleteJson('/fcm-tokens', body: {'token': fcmToken});
      }
    } catch (_) {}
    try {
      await remote.postJson('/auth/logout', const {});
    } catch (_) {}
  }

  Future<AuthUser?> me() async {
    final response = await _apiClient.getJson('/auth/me');
    final data = response['data'];
    if (data is! Map<String, dynamic>) return null;
    final user = AuthUser.fromJson(data);
    SessionCache.instance.setUser(user);
    await _bindAnalyticsUser(user);
    return user;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    await _apiClient.postJson('/auth/change-password', {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmation,
    });
  }

  /// Deletes the account after the server verifies [password].
  ///
  /// Nothing local is touched until the server confirms: a wrong password
  /// must leave the session — including push delivery — exactly as it was.
  /// Once the account is gone, every local cleanup step is attempted; any
  /// failures are reported separately from server deletion errors.
  ///
  /// Accounts with a password confirm with it; Google/Apple-only accounts
  /// confirm with a fresh provider ID token ([provider], [idToken], and
  /// Apple's raw [nonce]).
  Future<void> deleteAccount({
    String? password,
    String? provider,
    String? idToken,
    String? nonce,
  }) async {
    assert((password != null) != (provider != null && idToken != null),
        'confirm with a password or with a provider token, not both');
    await _apiClient.deleteJson('/auth/account', body: {
      if (password != null) 'password': password,
      if (provider != null) 'provider': provider,
      if (idToken != null) 'id_token': idToken,
      if (nonce != null) 'nonce': nonce,
    });
    // No FCM unregister call here: the server already deleted this account's
    // tokens, and calling the API with the now-revoked bearer would 401 and
    // trigger the session-expired flow on top of this one.
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() => _localSessionCleanup.run();

  /// Retries device cleanup without repeating confirmed server deletion.
  Future<void> retryLocalSessionCleanup() => _clearLocalSession();

  Future<AuthUser> updateProfile({
    required String name,
    int? jobTitleId,
    String? jobTitleOther,
    bool clearJobTitle = false,
    String? location,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
    };
    if (location != null) {
      body['location'] = location.trim().isEmpty ? null : location.trim();
    }
    if (clearJobTitle) {
      body['job_title_id'] = null;
      body['job_title_other'] = null;
    } else {
      if (jobTitleId != null) {
        body['job_title_id'] = jobTitleId;
      }
      if (jobTitleOther != null) {
        body['job_title_other'] =
            jobTitleOther.trim().isEmpty ? null : jobTitleOther.trim();
      }
    }

    return _userFrom(await _apiClient.putJson('/auth/profile', body));
  }

  /// Uploads a square PNG profile photo (see `AvatarCropScreen`).
  Future<AuthUser> uploadAvatar(List<int> pngBytes) async =>
      _userFrom(await _apiClient.postMultipart(
        '/auth/avatar',
        fields: const {},
        // The server checks the image by its content, not the declared type.
        file: http.MultipartFile.fromBytes(
          'avatar',
          pngBytes,
          filename: 'avatar.png',
        ),
      ));

  Future<AuthUser> deleteAvatar() async =>
      _userFrom(await _apiClient.deleteJson('/auth/avatar'));

  /// The `data` user of a profile response, also made the cached session user.
  AuthUser _userFrom(Map<String, dynamic> response) {
    final data = response['data'];
    final user = AuthUser.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
    SessionCache.instance.setUser(user);
    return user;
  }
}
