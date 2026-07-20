import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../app_locale.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_token_store.dart';
import 'notification_engagement_service.dart';
import 'preference_store.dart';

/// Handles all push notification logic: permissions, token management,
/// foreground display, tap handling, and backend registration.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _registeringToken = false;
  String? _lastRegisteredToken;
  DateTime? _lastRegisterAttemptAt;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Set this from the UI layer to handle notification-triggered navigation.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Android notification channel — must match backend's channel_id.
  static const _androidChannel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize local notifications and start listening to FCM streams.
  /// Call once at app startup after [Firebase.initializeApp].
  Future<void> initialize() async {
    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Initialize local notifications plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // iOS: show notification banners even when app is in foreground
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Token refresh → re-register with backend
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// Check if a notification launched the app from terminated state.
  /// Call after [initialize] in main.dart.
  Future<void> handleTerminatedLaunchNotification() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      // Short delay to let the UI tree build before navigating
      Future.delayed(const Duration(milliseconds: 600), () {
        _navigateFromPayload(message.data);
      });
    }
  }

  /// Request notification permission from the user.
  /// Returns true if authorized or provisional.
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('[FCM] Permission request skipped: $e');
      return false;
    }
  }

  /// Get the current FCM registration token.
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
      return null;
    }
  }

  /// Register the current FCM token with the backend.
  /// Call after successful login and on token refresh.
  Future<void> registerToken() async {
    if (_registeringToken) return;

    final token = await getToken();
    if (token == null) return;

    final now = DateTime.now();
    if (_lastRegisteredToken == token &&
        _lastRegisterAttemptAt != null &&
        now.difference(_lastRegisterAttemptAt!) < const Duration(minutes: 5)) {
      return;
    }

    final authToken = await const AuthTokenStore().readToken();
    if (authToken == null) return; // Not authenticated

    final deviceId = await _getDeviceId();
    final platform = Platform.isIOS ? 'ios' : 'android';
    final notificationsEnabled =
        await const PreferenceStore().readNotificationsEnabled();

    _registeringToken = true;
    _lastRegisterAttemptAt = now;

    try {
      final client = ApiClient(
        tokenProvider: () => const AuthTokenStore().readToken(),
      );
      await client.postJson('/fcm-tokens', {
        'token': token,
        'device_id': deviceId,
        'platform': platform,
        'app_version': ApiConfig.appVersion,
        'language': AppLocale.languageCode.value == 'en' ? 'en' : 'ar',
        'timezone_offset_minutes': now.timeZoneOffset.inMinutes,
        'notifications_enabled': notificationsEnabled,
      });
      _lastRegisteredToken = token;
      debugPrint('[FCM] Token registered with backend');
      // Keep activity + language/timezone fresh for smart scheduling.
      unawaited(NotificationEngagementService.instance.reportActivity());
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    } finally {
      _registeringToken = false;
    }
  }

  /// Deactivate the current FCM token on the backend.
  /// Call on user logout ([optOut]=false) or Settings toggle off ([optOut]=true).
  Future<void> unregisterToken({bool optOut = false}) async {
    final token = await getToken();
    if (token == null) return;

    try {
      final client = ApiClient(
        tokenProvider: () => const AuthTokenStore().readToken(),
      );
      await client.deleteJson('/fcm-tokens', body: {
        'token': token,
        if (optOut) 'opt_out': true,
      });
      debugPrint('[FCM] Token unregistered from backend (opt_out=$optOut)');
    } catch (e) {
      debugPrint('[FCM] Token unregister failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.messageId}');
    final notification = message.notification;

    if (notification == null) {
      // Data-only message in foreground — handle silently
      debugPrint('[FCM] Data-only foreground message: ${message.data}');
      return;
    }

    // Display as local notification so the user sees it
    _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM] Notification opened app: ${message.data}');
    _navigateFromPayload(message.data);
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null || response.payload!.isEmpty) return;

    try {
      final data = Map<String, dynamic>.from(
        jsonDecode(response.payload!) as Map,
      );
      _navigateFromPayload(data);
    } catch (e) {
      debugPrint('[FCM] Failed to parse local notification payload: $e');
    }
  }

  void _navigateFromPayload(Map<String, dynamic> data) {
    final notificationId = data['notification_id']?.toString();
    unawaited(
      NotificationEngagementService.instance.markOpened(notificationId),
    );

    if (onNotificationTap != null) {
      onNotificationTap!(data);
    } else {
      debugPrint('[FCM] onNotificationTap not set, payload ignored: $data');
    }
  }

  void _onTokenRefresh(String newToken) {
    debugPrint('[FCM] Token refreshed, re-registering...');
    registerToken();
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return info.id;
      } else {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'unknown-ios';
      }
    } catch (e) {
      return 'unknown';
    }
  }
}
