import 'dart:async';
import 'dart:convert';

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
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/settings/presentation/change_password_screen.dart';
import 'package:sirati/features/settings/presentation/delete_account_screen.dart';
import 'package:sirati/features/settings/presentation/deleted_account_cleanup_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

/// Real AuthApiService over a recording HTTP client.
({AuthApiService auth, List<String> requests, MemoryAuthTokenStore tokens})
    _service({required int deleteStatus}) {
  final requests = <String>[];
  final client = MockClient((request) async {
    requests.add('${request.method} ${request.url.path}');
    if (request.url.path.endsWith('/auth/account')) {
      return http.Response(
        jsonEncode(deleteStatus == 200
            ? {'message': 'deleted'}
            : {
                'message': 'invalid',
                'errors': {
                  'password': ['كلمة المرور غير صحيحة.'],
                },
              }),
        deleteStatus,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('{}', 200,
        headers: {'content-type': 'application/json'});
  });
  final tokens = MemoryAuthTokenStore()..value = 'bearer-1';
  final auth = AuthApiService(
    apiClient: ApiClient(httpClient: client, tokenProvider: tokens.readToken),
    tokenStore: tokens,
  );
  return (auth: auth, requests: requests, tokens: tokens);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  group('AuthApiService.deleteAccount', () {
    test('a wrong password leaves the session and push untouched', () async {
      final s = _service(deleteStatus: 422);
      await expectLater(
        s.auth.deleteAccount(password: 'nope'),
        throwsA(isA<ApiException>()),
      );
      expect(await s.tokens.readToken(), 'bearer-1');
      expect(s.requests.where((r) => r.contains('fcm-tokens')), isEmpty,
          reason: 'device push must not be unregistered before the server '
              'confirms');
    });

    test('success clears the session without a post-delete API call', () async {
      final s = _service(deleteStatus: 200);
      await s.auth.deleteAccount(password: 'right');
      expect(await s.tokens.readToken(), isNull);
      expect(s.requests, ['DELETE /api/auth/account'].map((r) => r).toList(),
          reason: 'any further call would use the revoked bearer and 401');
    });
  });

  group('screens', () {
    setUp(() {
      AppLocale.languageCode.value = 'en';
      registerSiratiRouteWidgets();
    });

    Widget app(Widget home, AuthApiService auth, ThemeData theme,
            {String language = 'en'}) =>
        ProviderScope(
          overrides: [authApiServiceProvider.overrideWithValue(auth)],
          child: MaterialApp(
            theme: theme,
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: home,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );

    testWidgets('delete: Done + button open one confirmation', (tester) async {
      final s = _service(deleteStatus: 422);
      await tester.pumpWidget(app(
        const DeleteAccountScreen(),
        s.auth,
        AppTheme.lightFor(arabic: false),
      ));
      await tester.enterText(find.byType(TextField), 'secret');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.tap(find.text('Delete my account'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    for (final language in ['en', 'ar']) {
      testWidgets(
          'delete: removes private routes and retries only local cleanup '
          'in $language', (tester) async {
        AppLocale.languageCode.value = language;
        final en = language == 'en';
        final requests = <String>[];
        final calls = <String>[];
        var failCleanup = true;
        final auth = AuthApiService(
          apiClient: ApiClient(httpClient: MockClient((request) async {
            requests.add('${request.method} ${request.url.path}');
            return http.Response('{}', 200);
          })),
          localSessionCleanup: LocalSessionCleanup(
            clearToken: () => calls.add('token'),
            clearSession: () => calls.add('session'),
            clearCaches: () {
              calls.add('caches');
              if (failCleanup) throw StateError('cache locked');
            },
            wipeStorage: () => calls.add('storage'),
            forgetDevice: () => calls.add('device'),
            clearAnalytics: () => calls.add('analytics'),
          ),
        );
        await tester.pumpWidget(app(
          Scaffold(
            body: Builder(builder: (context) {
              return TextButton(
                onPressed: () => unawaited(Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                )),
                child: const Text('Private account data'),
              );
            }),
          ),
          auth,
          AppTheme.lightFor(arabic: !en),
          language: language,
        ));
        await tester.tap(find.text('Private account data'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'secret');
        await tester.tap(find.text(en ? 'Delete my account' : 'احذف حسابي'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(en ? 'Delete forever' : 'حذف نهائي'));
        await tester.pumpAndSettle();

        expect(requests, ['DELETE /api/auth/account']);
        expect(calls, [
          'token',
          'session',
          'caches',
          'storage',
          'device',
          'analytics',
        ]);
        expect(
          find.text(en
              ? 'Your account was deleted, but some data could not be cleared from this device.'
              : 'تم حذف حسابك، لكن تعذر مسح بعض البيانات من هذا الجهاز.'),
          findsOneWidget,
        );
        expect(
          find.text(en ? 'Account deleted.' : 'تم حذف الحساب.'),
          findsNothing,
        );
        expect(find.byType(DeleteAccountScreen), findsNothing);
        expect(find.text('Private account data'), findsNothing);
        final retry = find.text(en ? 'Retry cleanup' : 'إعادة محاولة المسح');
        expect(retry, findsOneWidget);
        final retryContext = tester.element(retry);
        expect(ModalRoute.of(retryContext)?.settings.name, AppRoutes.login);
        expect(Navigator.of(retryContext).canPop(), isFalse);
        expect(await Navigator.of(retryContext).maybePop(), isFalse);
        await tester.pumpAndSettle();
        expect(find.text('Private account data'), findsNothing);
        expect(find.byType(DeleteAccountScreen), findsNothing);

        // A retry that still fails stays on the signed-out route.
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(retry, findsOneWidget);
        expect(requests, ['DELETE /api/auth/account']);
        expect(find.byType(LoginScreen), findsNothing);

        failCleanup = false;
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(requests, ['DELETE /api/auth/account']);
        expect(calls, [
          for (var i = 0; i < 3; i++) ...[
            'token',
            'session',
            'caches',
            'storage',
            'device',
            'analytics'
          ],
        ]);
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
          isFalse,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('delete: success leaves only the signed-out entry route',
        (tester) async {
      final service = _service(deleteStatus: 200);
      await tester.pumpWidget(app(
        Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => unawaited(Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const DeleteAccountScreen()),
                    )),
                    child: const Text('Private account data'),
                  ),
                )),
        service.auth,
        AppTheme.lightFor(arabic: false),
      ));
      await tester.tap(find.text('Private account data'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'secret');
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete forever'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Private account data'), findsNothing);
      expect(find.byType(DeleteAccountScreen), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(LoginScreen))).canPop(),
        isFalse,
      );
      expect(service.requests, ['DELETE /api/auth/account']);
    });

    testWidgets('cleanup retry allows only one attempt in flight',
        (tester) async {
      final gate = Completer<void>();
      var attempts = 0;
      await tester.pumpWidget(app(
        DeletedAccountCleanupScreen(retryCleanup: () {
          attempts++;
          return gate.future;
        }),
        AuthApiService(),
        AppTheme.lightFor(arabic: false),
      ));
      await tester.tap(find.text('Retry cleanup'));
      await tester.pump();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(attempts, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('change password: one request in flight', (tester) async {
      var calls = 0;
      final gate = Completer<void>();
      final auth = _GatedChange(() {
        calls++;
        return gate.future;
      });
      await tester.pumpWidget(app(
        const ChangePasswordScreen(),
        auth,
        AppTheme.lightFor(arabic: false),
      ));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'oldpass1');
      await tester.enterText(fields.at(1), 'newpass12');
      await tester.enterText(fields.at(2), 'newpass12');
      await tester.tap(find.text('Update password'));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(calls, 1);
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('change password: confirm re-checks when the new one changes',
        (tester) async {
      await tester.pumpWidget(app(
        const ChangePasswordScreen(),
        _GatedChange(() async {}),
        AppTheme.lightFor(arabic: false),
      ));
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'oldpass1');
      await tester.enterText(fields.at(1), 'newpass12');
      await tester.enterText(fields.at(2), 'newpass1');
      await tester.tap(find.text('Update password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);

      await tester.enterText(fields.at(1), 'newpass1');
      await tester.pump();
      expect(find.text('Passwords do not match'), findsNothing);
    });

    for (final (mode, theme) in [
      ('light', AppTheme.lightFor(arabic: false)),
      ('dark', AppTheme.darkFor(arabic: false)),
    ]) {
      for (final (name, screen) in [
        ('delete', const DeleteAccountScreen() as Widget),
        ('change', const ChangePasswordScreen()),
        ('cleanup', DeletedAccountCleanupScreen(retryCleanup: () async {})),
      ]) {
        testWidgets('$name account screen is AA in $mode', (tester) async {
          await tester.pumpWidget(
            app(screen, _service(deleteStatus: 200).auth, theme),
          );
          await tester.pump();
          expectAllTextAa('$name $mode');
          if (name != 'cleanup') {
            expect(find.byTooltip('Show password'), findsWidgets);
          }
        });
      }
    }
  });
}

class _GatedChange extends AuthApiService {
  _GatedChange(this.onChange);
  final Future<void> Function() onChange;

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    await onChange();
    return 'ok';
  }
}
