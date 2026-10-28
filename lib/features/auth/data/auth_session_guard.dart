import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/session_expired_screen.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/services/notification_service.dart';

/// Handles mid-session auth expiry (401) with a single redirect.
class AuthSessionGuard {
  AuthSessionGuard._();

  static bool _handling = false;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static AuthTokenStore tokenStore = const AuthTokenStore();
  static LocalSessionCleanup? _localSessionCleanup;

  static void install({
    required GlobalKey<NavigatorState> navigatorKey,
    AuthTokenStore? store,
  }) {
    _navigatorKey = navigatorKey;
    if (store != null) tokenStore = store;
    // ApiClient invokes this callback without awaiting it. Report cleanup
    // failures through Flutter rather than leaving an unhandled future.
    ApiClient.onAuthExpired = ({String? requestToken}) async {
      try {
        await handleAuthExpired(requestToken: requestToken);
      } on LocalSessionCleanupException catch (error, stackTrace) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'auth',
          context: ErrorDescription('while clearing an expired local session'),
        ));
      }
    };
  }

  /// Test hook — restores debounce and the default token store.
  static void resetForTest({
    AuthTokenStore? store,
    LocalSessionCleanup? localSessionCleanup,
  }) {
    _handling = false;
    _navigatorKey = null;
    tokenStore = store ?? const AuthTokenStore();
    _localSessionCleanup = localSessionCleanup;
    ApiClient.onAuthExpired = null;
  }

  /// Clear local session and leave authenticated screens once (parallel 401s
  /// debounce): to [SessionExpiredScreen] when [showMessage], else to Login.
  ///
  /// [requestToken] is the bearer token that received the 401. A delayed
  /// 401 for an older token is ignored when a newer session is already saved.
  static Future<void> handleAuthExpired({
    String? requestToken,
    bool showMessage = true,
  }) async {
    final current = await tokenStore.readToken();
    if (_isStaleRequest(requestToken, current)) return;
    if (_handling) return;
    _handling = true;
    try {
      try {
        await NotificationService.instance.unregisterToken();
      } catch (_) {}
      try {
        await (_localSessionCleanup ??
                LocalSessionCleanup(clearToken: tokenStore.clearToken))
            .run();
      } finally {
        // An expired session must leave authenticated screens even when a
        // local store fails. Preserve the cleanup error for the caller.
        final nav = _navigatorKey?.currentState;
        if (nav != null) {
          unawaited(nav.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => showMessage
                  ? const SessionExpiredScreen()
                  : const LoginScreen(),
            ),
            (route) => false,
          ));
        }
      }
    } finally {
      // Allow a future expiry after the user logs in again.
      Future<void>.delayed(const Duration(seconds: 2), () {
        _handling = false;
      });
    }
  }

  static bool _isStaleRequest(String? requestToken, String? currentToken) {
    final request = _bareToken(requestToken);
    final current = _bareToken(currentToken);

    if (request == null || request.isEmpty) {
      // No snapshot of the failing request. Do not kill a token that was
      // saved after this call started (login racing a startup 401).
      return current != null && current.isNotEmpty;
    }
    if (current == null || current.isEmpty) return false;
    return request != current;
  }

  static String? _bareToken(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    const prefix = 'Bearer ';
    if (trimmed.startsWith(prefix)) {
      return trimmed.substring(prefix.length).trim();
    }
    return trimmed;
  }
}
