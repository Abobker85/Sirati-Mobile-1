import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import 'analytics_service.dart';
import 'api_client.dart';
import 'auth_token_store.dart';
import 'mobile_content_service.dart';
import 'notification_service.dart';
import 'session_cache.dart';

/// Handles mid-session auth expiry (401/403) with a single redirect.
class AuthSessionGuard {
  AuthSessionGuard._();

  static bool _handling = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void install({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;
    ApiClient.onAuthExpired = handleAuthExpired;
  }

  /// Clear local session and push Login once (parallel 401s debounce).
  static Future<void> handleAuthExpired({bool showMessage = true}) async {
    if (_handling) return;
    _handling = true;
    try {
      try {
        await NotificationService.instance.unregisterToken();
      } catch (_) {}
      await const AuthTokenStore().clearToken();
      SessionCache.instance.clear();
      // Drop offline content so the next account never sees prior user data.
      await MobileContentService.clearAllCaches();
      await AnalyticsService.clearUser();

      final nav = _navigatorKey?.currentState;
      if (nav == null) return;

      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            sessionExpiredNotice: showMessage,
          ),
        ),
        (route) => false,
      );
    } finally {
      // Allow a future expiry after the user logs in again.
      Future<void>.delayed(const Duration(seconds: 2), () {
        _handling = false;
      });
    }
  }
}
