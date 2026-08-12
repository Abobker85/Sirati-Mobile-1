import '../models/auth_session.dart';
import 'analytics_service.dart';
import 'api_client.dart';
import 'auth_token_store.dart';
import 'mobile_content_service.dart';
import 'notification_service.dart';
import 'session_cache.dart';

class AuthApiService {
  AuthApiService(
      {ApiClient? apiClient,
      AuthTokenStore tokenStore = const AuthTokenStore()})
      : _apiClient =
            apiClient ?? ApiClient(tokenProvider: tokenStore.readToken),
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  Future<AuthSession> login(
      {required String email, required String password}) async {
    final response = await _apiClient.postJson('/auth/login', {
      'email': email,
      'password': password,
      'device_name': 'sirati-mobile',
    });

    final session = AuthSession.fromJson(response);
    await _tokenStore.saveToken(session.token);
    SessionCache.instance.setUser(session.user);
    await _bindAnalyticsUser(session.user);

    if (session.user.emailVerified) {
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.registerToken();
    }

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

    final response = await _apiClient.postJson('/auth/register', body);

    final session = AuthSession.fromJson(response);
    await _tokenStore.saveToken(session.token);
    SessionCache.instance.setUser(session.user);
    await _bindAnalyticsUser(session.user);

    // FCM requires a verified email — deferred until after OTP success.
    return session;
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

    if (user.emailVerified) {
      await NotificationService.instance.requestPermission();
      await NotificationService.instance.registerToken();
    }

    return user;
  }

  Future<String> resendVerification() async {
    final response = await _apiClient.postJson('/auth/email/resend', const {});
    return response['message']?.toString() ??
        'تم إرسال رمز التحقق إلى بريدك الإلكتروني.';
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _apiClient.postJson('/auth/forgot-password', {
      'email': email,
    });

    return response['message']?.toString() ??
        'تم إرسال رمز استعادة كلمة المرور إذا كان البريد مسجلاً لدينا.';
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _apiClient.postJson('/auth/reset-password', {
      'email': email.trim(),
      'code': code.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
    });

    return response['message']?.toString() ??
        'تم تعيين كلمة المرور الجديدة بنجاح. يمكنك تسجيل الدخول الآن.';
  }

  Future<void> logout() async {
    try {
      // Unregister FCM token before logout
      await NotificationService.instance.unregisterToken();
      await _apiClient.postJson('/auth/logout', const {});
    } finally {
      await _tokenStore.clearToken();
      SessionCache.instance.clear();
      await MobileContentService.clearAllCaches();
      await AnalyticsService.clearUser();
    }
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

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final response = await _apiClient.postJson('/auth/change-password', {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': confirmation,
    });
    return response['message']?.toString() ?? 'تم تغيير كلمة المرور بنجاح.';
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      await NotificationService.instance.unregisterToken();
      await _apiClient.deleteJson('/auth/account', body: {
        'password': password,
      });
    } finally {
      await _tokenStore.clearToken();
      SessionCache.instance.clear();
      await MobileContentService.clearAllCaches();
      await AnalyticsService.clearUser();
    }
  }

  Future<AuthUser> updateProfile({
    required String name,
    int? jobTitleId,
    String? jobTitleOther,
    bool clearJobTitle = false,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
    };
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

    final response = await _apiClient.putJson('/auth/profile', body);
    final data = response['data'];
    final user = AuthUser.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
    SessionCache.instance.setUser(user);
    return user;
  }
}
