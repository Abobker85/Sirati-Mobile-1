import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e, st) {
    debugPrint('[FCM] background init failed: $e\n$st');
    return;
  }
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Global navigator for session-expiry redirects outside the widget tree.
final GlobalKey<NavigatorState> siratiNavigatorKey =
    GlobalKey<NavigatorState>();

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.sendDefaultPii = false;
      options.maxRequestBodySize = MaxRequestBodySize.never;
      options.attachScreenshot = false;
      // View hierarchies can include text entered into CV fields.
      // ignore: experimental_member_use
      options.attachViewHierarchy = false;
      options.recordHttpBreadcrumbs = false;
      options.enablePrintBreadcrumbs = false;

      const environment = String.fromEnvironment('SENTRY_ENVIRONMENT');
      if (environment.isNotEmpty) {
        options.environment = environment;
      }

      const release = String.fromEnvironment('SENTRY_RELEASE');
      if (release.isNotEmpty) {
        options.release = release;
      }
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Local prefs first — never block the UI shell on Firebase.
      try {
        await AppLocale.bootstrap();
      } catch (e, st) {
        debugPrint('[Boot] AppLocale failed: $e\n$st');
      }
      try {
        await AppThemeController.bootstrap();
      } catch (e, st) {
        debugPrint('[Boot] AppThemeController failed: $e\n$st');
      }

      final firebaseReady = await _initFirebaseStack();

      AuthSessionGuard.install(navigatorKey: siratiNavigatorKey);

      try {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
        // Edge-to-edge on Android 15+; SafeArea on screens paints content insets.
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(
          AppTheme.systemUiOverlayStyle(SiratiColors.light, Brightness.light),
        );
      } catch (e, st) {
        debugPrint('[Boot] SystemChrome failed: $e\n$st');
      }

      // Always launch UI — Codemagic previews and devices without Firebase config
      // must still open SplashScreen instead of dying on a white/native shell.
      runApp(const SiratiApp());

      if (kDebugMode) {
        debugPrint(
          firebaseReady
              ? '[Boot] Firebase ready'
              : '[Boot] Running without Firebase (push/analytics limited)',
        );
      }
    },
  );
}

/// Returns true when Firebase + messaging hooks initialized successfully.
Future<bool> _initFirebaseStack() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e, st) {
    // Missing GoogleService-Info.plist (iOS) / google-services.json (Android)
    // must not kill the process — App Preview would "open then close".
    debugPrint('[Firebase] initializeApp failed: $e\n$st');
    return false;
  }

  try {
    _installCrashlyticsErrorHandlers();
  } catch (e, st) {
    debugPrint('[Firebase] Crashlytics setup failed: $e\n$st');
  }

  try {
    await AnalyticsService.initialize();
    unawaited(AnalyticsService.setAppLanguage(AppLocale.languageCode.value));
    unawaited(AnalyticsService.setThemeMode(
      AppThemeController.themeMode.value.name,
    ));
  } catch (e, st) {
    debugPrint('[Firebase] Analytics setup failed: $e\n$st');
  }

  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.instance.initialize();
    await NotificationService.instance.handleTerminatedLaunchNotification();
  } catch (e, st) {
    debugPrint('[Firebase] Messaging setup failed: $e\n$st');
  }

  return true;
}

void _installCrashlyticsErrorHandlers() {
  unawaited(FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true));

  final previousFlutterOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    previousFlutterOnError?.call(details);
  };

  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return previousPlatformOnError?.call(error, stack) ?? false;
  };
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
