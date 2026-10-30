import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/core/storage/guest_session.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/auth/data/auth_session_guard.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/register_screen.dart';
import 'package:sirati/features/auth/presentation/session_expired_screen.dart';
import 'package:sirati/features/auth/presentation/sign_in_required_screen.dart';
import 'package:sirati/features/dashboard/presentation/education_screen.dart';
import 'package:sirati/features/dashboard/presentation/home_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// A guest ("Continue without account") keeps Jobs and Education; anything
/// that needs an account invites them to sign in. Nobody was signed out, so
/// they must never see the session-expired screen or lose their place.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    AppLocale.languageCode.value = 'en';
    MobileContentService.invalidate();
    SharedPreferences.setMockInitialValues({});
    AuthSessionGuard.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });

  tearDown(() {
    AuthSessionGuard.resetForTest();
    NotificationService.instance.onNotificationTap = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  Widget app({
    required GlobalKey<NavigatorState> navigatorKey,
    required Widget home,
    String language = 'en',
  }) {
    return ProviderScope(
      overrides: [
        jobTitlesProvider.overrideWith((ref) async => const <JobTitle>[]),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        theme: AppTheme.lightFor(arabic: language == 'ar'),
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: home,
      ),
    );
  }

  group('a 401 without any session', () {
    // Every way "no token" can look: never sent, empty, blank, bare prefix.
    for (final sent in <String?>[null, '', '   ', 'Bearer ']) {
      for (final saved in <String?>[null, '', '  ']) {
        testWidgets(
            'sent=${sent == null ? 'none' : '"$sent"'} '
            'saved=${saved == null ? 'none' : '"$saved"'} invites sign-in '
            'on top of the current screen', (tester) async {
          final store = MemoryAuthTokenStore(saved);
          final key = GlobalKey<NavigatorState>();
          AuthSessionGuard.install(navigatorKey: key, store: store);
          await tester.pumpWidget(app(
            navigatorKey: key,
            home: const Scaffold(body: Text('browsing jobs')),
          ));

          await tester.runAsync(() => Future.wait([
                for (var i = 0; i < 3; i++)
                  AuthSessionGuard.handleAuthExpired(requestToken: sent),
              ]));
          await tester.pumpAndSettle();

          expect(find.byType(SignInRequiredScreen), findsOneWidget);
          expect(find.byType(SessionExpiredScreen), findsNothing);
          // Nothing to wipe, and the guest keeps their place.
          expect(store.value, saved);
          expect(key.currentState!.canPop(), isTrue);

          key.currentState!.pop();
          await tester.pumpAndSettle();
          expect(find.text('browsing jobs'), findsOneWidget);
          expect(find.byType(SignInRequiredScreen), findsNothing);

          // Once closed, the next guest 401 may open it again.
          await tester.runAsync(
              () => AuthSessionGuard.handleAuthExpired(requestToken: sent));
          await tester.pumpAndSettle();
          expect(find.byType(SignInRequiredScreen), findsOneWidget);
        });
      }
    }

    testWidgets('a real API 401 for a guest reaches the sign-in page',
        (tester) async {
      final store = MemoryAuthTokenStore();
      final key = GlobalKey<NavigatorState>();
      AuthSessionGuard.install(navigatorKey: key, store: store);
      await tester.pumpWidget(app(
        navigatorKey: key,
        home: const Scaffold(body: Text('browsing jobs')),
      ));

      final api = ApiClient(
        httpClient: MockClient((_) async => http.Response(
            '{"message":"Unauthenticated."}', 401,
            headers: {'content-type': 'application/json'})),
        tokenProvider: store.readToken,
      );
      await tester.runAsync(() async {
        await expectLater(
            api.getJson('/mobile/my-cvs'), throwsA(isA<ApiException>()));
        // The guard runs fire-and-forget after the throw.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();

      expect(find.byType(SignInRequiredScreen), findsOneWidget);
      expect(find.byType(SessionExpiredScreen), findsNothing);
    });

    testWidgets('a signed-in 401 still means the session expired',
        (tester) async {
      final store = MemoryAuthTokenStore('expired');
      final key = GlobalKey<NavigatorState>();
      AuthSessionGuard.install(navigatorKey: key, store: store);
      await tester.pumpWidget(app(
        navigatorKey: key,
        home: const Scaffold(body: Text('signed-in home')),
      ));

      await tester.runAsync(
          () => AuthSessionGuard.handleAuthExpired(requestToken: 'expired'));
      await tester.pumpAndSettle();

      expect(find.byType(SessionExpiredScreen), findsOneWidget);
      expect(find.byType(SignInRequiredScreen), findsNothing);
      expect(store.value, isNull);
    });
  });

  group('the Home shell', () {
    late List<String> requested;

    Future<GlobalKey<NavigatorState>> pumpHome(
      WidgetTester tester, {
      required String? token,
      String language = 'en',
      int initialIndex = 0,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final store = MemoryAuthTokenStore(token);
      final key = GlobalKey<NavigatorState>();
      AuthSessionGuard.install(navigatorKey: key, store: store);
      await tester.pumpWidget(app(
        navigatorKey: key,
        language: language,
        home: HomeScreen(initialIndex: initialIndex),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return key;
    }

    Future<void> runWithApi(Future<void> Function() body) {
      requested = [];
      final client = MockClient((request) async {
        requested.add(request.url.path);
        return http.Response('{"data":[]}', 200,
            headers: {'content-type': 'application/json'});
      });
      return http.runWithClient(body, () => client);
    }

    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(find.text(label).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    for (final language in ['en', 'ar']) {
      for (final initialIndex in [0, 1]) {
        testWidgets(
            '$language, opened on tab $initialIndex: a guest uses Jobs and '
            'Education, and the account tabs invite sign-in', (tester) async {
          await runWithApi(() async {
            await pumpHome(tester,
                token: null, language: language, initialIndex: initialIndex);
            final l10n = lookupAppLocalizations(Locale(language));
            bool visible(Finder f) => f.hitTestable().evaluate().isNotEmpty;
            final signIn = find.byType(SignInRequiredView);

            if (initialIndex == 0) {
              // Lands where a guest can do something.
              expect(visible(find.byType(JobNewsScreen)), isTrue);
            } else {
              expect(visible(signIn), isTrue);
            }

            await openTab(tester, l10n.dashboardNavEducation);
            expect(visible(find.byType(EducationScreen)), isTrue);
            expect(visible(signIn), isFalse);

            for (final label in [
              l10n.dashboardNavHome,
              l10n.dashboardNavMyCvs,
            ]) {
              await openTab(tester, label);
              expect(visible(signIn), isTrue, reason: label);
              expect(find.text(l10n.authSignInRequiredCardTitle).hitTestable(),
                  findsOneWidget);
              // A tab has nothing to go back to.
              expect(
                  find.descendant(
                      of: signIn.hitTestable(),
                      matching:
                          find.byTooltip(language == 'ar' ? 'رجوع' : 'Back')),
                  findsNothing,
                  reason: label);
            }

            await openTab(tester, l10n.dashboardNavJobNews);
            expect(visible(find.byType(JobNewsScreen)), isTrue);

            // No account endpoint is ever called for a guest.
            for (final path in requested) {
              expect(path, isNot(contains('/mobile/dashboard')));
              expect(path, isNot(contains('/mobile/my-cvs')));
              expect(path, isNot(contains('/devices')));
            }
            expect(find.byType(SessionExpiredScreen), findsNothing);
          });
        });
      }
    }

    testWidgets('"Browse jobs" takes a guest to the Jobs tab', (tester) async {
      await runWithApi(() async {
        await pumpHome(tester, token: null, initialIndex: 1);
        final l10n = lookupAppLocalizations(const Locale('en'));
        await tester.tap(find.text(l10n.authSignInRequiredBrowseJobs).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(JobNewsScreen).hitTestable(), findsOneWidget);
      });
    });

    for (final (label, screen) in [
      ('Create New Account', RegisterScreen),
      ('Sign In', LoginScreen),
    ]) {
      testWidgets('"$label" opens $screen and Back returns to the shell',
          (tester) async {
        await runWithApi(() async {
          final key = await pumpHome(tester, token: null, initialIndex: 1);
          await tester.tap(find.text(label).hitTestable().first);
          await tester.pumpAndSettle();
          expect(find.byType(screen), findsOneWidget);

          key.currentState!.pop();
          await tester.pumpAndSettle();
          expect(find.byType(HomeScreen), findsOneWidget);
        });
      });
    }

    testWidgets('a signed-in user never sees the sign-in invitation',
        (tester) async {
      await runWithApi(() async {
        await pumpHome(tester, token: 'session');
        final l10n = lookupAppLocalizations(const Locale('en'));
        for (final label in [
          l10n.dashboardNavMyCvs,
          l10n.dashboardNavJobNews,
          l10n.dashboardNavEducation,
          l10n.dashboardNavHome,
        ]) {
          await openTab(tester, label);
          expect(find.byType(SignInRequiredView), findsNothing, reason: label);
        }
      });
    });
  });

  group('named routes', () {
    setUpAll(registerSiratiRouteWidgets);
    tearDown(() => GuestSession.active.value = false);

    // Every fixed route, plus each family of id routes and a typo.
    const routes = [
      AppRoutes.splash,
      AppRoutes.home,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.history,
      AppRoutes.createCv,
      AppRoutes.myCvs,
      AppRoutes.education,
      AppRoutes.jobNews,
      AppRoutes.privacy,
      AppRoutes.settings,
      AppRoutes.profile,
      AppRoutes.notifications,
      AppRoutes.premium,
      AppRoutes.gallery,
      AppRoutes.cvBuilder,
      AppRoutes.jobMatch,
      AppRoutes.atsScan,
      AppRoutes.notFound,
      '/cv/12',
      '/builder/draft-7',
      '/analysis/5',
      '/education/3',
      '/no-such-page',
    ];
    // What a guest may browse, and the ways in.
    const openToGuests = {
      AppRoutes.splash,
      AppRoutes.home,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.myCvs,
      AppRoutes.education,
      AppRoutes.jobNews,
      AppRoutes.privacy,
      AppRoutes.notFound,
      '/education/3',
      '/no-such-page',
    };

    testWidgets('a guest gets the invitation for every account-only route',
        (tester) async {
      late BuildContext context;
      await tester.pumpWidget(Builder(builder: (c) {
        context = c;
        return const SizedBox();
      }));
      Widget screenFor(String name) =>
          (AppRouter.onGenerateRoute(RouteSettings(name: name))
                  as MaterialPageRoute<dynamic>)
              .builder(context);

      for (final guest in [true, false]) {
        GuestSession.active.value = guest;
        for (final name in routes) {
          final invited = screenFor(name) is SignInRequiredScreen;
          expect(invited, guest && !openToGuests.contains(name),
              reason: 'guest=$guest $name');
        }
      }
    });

    testWidgets('signing in clears guest mode before any deep link opens',
        (tester) async {
      // The account's token is saved before the app leaves the auth screens.
      AuthSessionGuard.resetForTest(store: MemoryAuthTokenStore('session'));
      GuestSession.active.value = true;
      final key = GlobalKey<NavigatorState>();
      await runWithApiStub(() async {
        await tester.pumpWidget(app(
          navigatorKey: key,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppRouter.openAfterAuth(context),
              child: const Text('signed in'),
            ),
          ),
        ));
        await tester.tap(find.text('signed in'));
        expect(GuestSession.active.value, isFalse);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      });
      // Home confirmed the session and kept guest mode off.
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(GuestSession.active.value, isFalse);
      expect(find.byType(SignInRequiredView), findsNothing);
    });
  });
}

/// Answers every request with an empty success, for screens that load data.
Future<void> runWithApiStub(Future<void> Function() body) {
  final client = MockClient((_) async => http.Response('{"data":[]}', 200,
      headers: {'content-type': 'application/json'}));
  return http.runWithClient(body, () => client);
}
