import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app_locale.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_controller.dart';
import 'screens/cv_generator_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/job_news_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_session_guard.dart';
import 'services/notification_service.dart';

/// Top-level background message handler — MUST be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Global navigator for session-expiry redirects outside the widget tree.
final GlobalKey<NavigatorState> siratiNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppLocale.bootstrap();
    await AppThemeController.bootstrap();

    // Initialize Firebase
    await Firebase.initializeApp();

    // Crashlytics — collect in release only so debug noise stays local.
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Analytics — never-throwing wrappers; user props from bootstrap prefs.
    await AnalyticsService.initialize();
    unawaited(AnalyticsService.setAppLanguage(AppLocale.languageCode.value));
    unawaited(AnalyticsService.setThemeMode(
      AppThemeController.themeMode.value.name,
    ));

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize notification service (channels, listeners)
    await NotificationService.instance.initialize();

    // Handle notification tap that launched the app from terminated state
    await NotificationService.instance.handleTerminatedLaunchNotification();

    // Re-register the FCM token on every launch for already-authenticated users.
    unawaited(NotificationService.instance.registerToken());

    // Central 401 → clear session and force re-login (debounced in AuthSessionGuard).
    AuthSessionGuard.install(
      navigatorKey: siratiNavigatorKey,
    );

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Edge-to-edge on Android 15+; SafeArea on screens paints content insets.
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // Initial overlay before first frame (theme builder keeps it in sync).
    SystemChrome.setSystemUIOverlayStyle(
      AppTheme.systemUiOverlayStyle(SiratiColors.light, Brightness.light),
    );

    runApp(const SiratiApp());
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class SiratiApp extends StatelessWidget {
  const SiratiApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Preview deep-links are web-only; native always boots via SplashScreen.
    final previewScreen = kIsWeb ? Uri.base.queryParameters['screen'] : null;

    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.languageCode,
      builder: (context, language, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppThemeController.themeMode,
          builder: (context, themeMode, _) {
            return MaterialApp(
              navigatorKey: siratiNavigatorKey,
              title: language == 'en' ? 'Sirati' : 'سيرتي',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              locale: AppLocale.locale,
              navigatorObservers: AnalyticsService.navigatorObservers,
              supportedLocales: const [
                Locale('ar', 'SA'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                final sirati = context.sirati;
                final brightness = Theme.of(context).brightness;
                // Global status / nav bar styling (also set on AppBarTheme).
                SystemChrome.setSystemUIOverlayStyle(
                  AppTheme.systemUiOverlayStyle(sirati, brightness),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final platform = Theme.of(context).platform;
                    final isNativeMobile = !kIsWeb &&
                        (platform == TargetPlatform.android ||
                            platform == TargetPlatform.iOS);
                    final width = isNativeMobile
                        ? constraints.maxWidth
                        : (constraints.maxWidth > 480
                            ? 430.0
                            : constraints.maxWidth);

                    final mq = MediaQuery.of(context);
                    final scale = mq.textScaler.scale(1.0).clamp(1.0, 1.3);

                    return ColoredBox(
                      color: sirati.background,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: width,
                          height: constraints.maxHeight,
                          child: MediaQuery(
                            data: mq.copyWith(
                              textScaler: TextScaler.linear(scale),
                            ),
                            child: Directionality(
                              textDirection: AppLocale.direction(context),
                              child: child ?? const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              home: switch (previewScreen) {
                'register' => const RegisterScreen(),
                'create-cv' => const CvGeneratorScreen(),
                'mycvs' => const HomeScreen(initialIndex: 1),
                'education' => const HomeScreen(initialIndex: 2),
                'history' => const HistoryScreen(),
                'job-news' => const JobNewsScreen(),
                'privacy' => const PrivacyPolicyScreen(),
                'home' => const HomeScreen(),
                _ => const SplashScreen(),
              },
            );
          },
        );
      },
    );
  }
}
