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
import 'package:sirati/core/storage/auth_token_store.dart';
import 'package:sirati/features/auth/data/auth_session_guard.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/session_expired_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthSessionGuard.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });

  tearDown(() {
    AuthSessionGuard.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  test('delayed 401 for token A does not clear a newer token B', () async {
    final store = MemoryAuthTokenStore('token-a');
    AuthSessionGuard.resetForTest(store: store);
    ApiClient.onAuthExpired = AuthSessionGuard.handleAuthExpired;

    final release = Completer<void>();
    final client = ApiClient(
      tokenProvider: store.readToken,
      httpClient: MockClient((request) async {
        await release.future;
        return http.Response(
          jsonEncode({'message': 'Unauthenticated'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final pending = client.getJson('/auth/me');
    await store.saveToken('token-b');
    release.complete();

    await expectLater(pending, throwsA(isA<ApiException>()));
    expect(store.value, 'token-b');
  });

  group('where an expired session lands', () {
    Future<GlobalKey<NavigatorState>> pumpSignedIn(
      WidgetTester tester,
      MemoryAuthTokenStore store,
    ) async {
      final key = GlobalKey<NavigatorState>();
      AuthSessionGuard.resetForTest(
        store: store,
        localSessionCleanup: LocalSessionCleanup(
          clearToken: store.clearToken,
          clearSession: () {},
          clearCaches: () {},
          wipeStorage: () {},
          forgetDevice: () {},
          clearAnalytics: () {},
        ),
      );
      AuthSessionGuard.install(navigatorKey: key, store: store);
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          navigatorKey: key,
          theme: AppTheme.light,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: Text('signed-in home')),
        ),
      ));
      return key;
    }

    for (final showMessage in [true, false]) {
      testWidgets('showMessage=$showMessage clears the session and the stack',
          (tester) async {
        final store = MemoryAuthTokenStore('expired');
        final key = await pumpSignedIn(tester, store);

        await tester.runAsync(() => AuthSessionGuard.handleAuthExpired(
              requestToken: 'expired',
              showMessage: showMessage,
            ));
        await tester.pumpAndSettle();

        expect(store.value, isNull);
        expect(find.text('signed-in home'), findsNothing);
        expect(key.currentState!.canPop(), isFalse);
        expect(
          find.byType(SessionExpiredScreen),
          showMessage ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(LoginScreen),
          showMessage ? findsNothing : findsOneWidget,
        );
      });
    }

    testWidgets('a burst of 401s shows the screen once', (tester) async {
      final store = MemoryAuthTokenStore('expired');
      await pumpSignedIn(tester, store);

      await tester.runAsync(() => Future.wait([
            for (var i = 0; i < 4; i++)
              AuthSessionGuard.handleAuthExpired(requestToken: 'expired'),
          ]));
      await tester.pumpAndSettle();

      expect(find.byType(SessionExpiredScreen), findsOneWidget);
    });
  });

  test('failed account deletion keeps the local session', () async {
    final store = MemoryAuthTokenStore('keep-me');
    final service = AuthApiService(
      tokenStore: store,
      apiClient: ApiClient(
        tokenProvider: store.readToken,
        httpClient: MockClient((request) async {
          expect(request.method, 'DELETE');
          return http.Response(
            jsonEncode({
              'message': 'The password is incorrect.',
              'errors': {
                'password': ['The password is incorrect.'],
              },
            }),
            422,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    await expectLater(
      service.deleteAccount(password: 'wrong'),
      throwsA(isA<ApiException>()),
    );
    expect(store.value, 'keep-me');
  });

  test('logout clears the local session immediately', () async {
    final store = MemoryAuthTokenStore('session');
    final service = AuthApiService(tokenStore: store);

    await http.runWithClient(
      service.logout,
      () => MockClient((_) async => http.Response('{}', 200)),
    );
    expect(store.value, isNull);
  });

  test('public login does not send a leftover bearer token', () async {
    String? authorization;
    final store = MemoryAuthTokenStore('stale-token');
    final service = AuthApiService(
      tokenStore: store,
      publicApiClient: ApiClient(
        httpClient: MockClient((request) async {
          authorization = request.headers['authorization'];
          return http.Response(
            jsonEncode({
              'data': {
                'token': 'fresh-token',
                'token_type': 'Bearer',
                'user': {
                  'id': 1,
                  'name': 'Salem',
                  'email': 'salem@example.com',
                  'email_verified': true,
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );

    final session = await service.login(
      email: 'salem@example.com',
      password: 'password123',
    );

    expect(authorization, isNull);
    expect(session.token, 'fresh-token');
    expect(store.value, 'fresh-token');
  });

  test('empty and malformed API bodies become typed errors', () async {
    final emptyClient = ApiClient(
      httpClient: MockClient((request) async => http.Response('', 200)),
    );
    await expectLater(
      emptyClient.getJson('/auth/me'),
      throwsA(isA<ApiException>().having(
        (error) => error.type,
        'type',
        ApiErrorType.unknown,
      )),
    );

    final malformedClient = ApiClient(
      httpClient: MockClient((request) async => http.Response('<html>', 200)),
    );
    await expectLater(
      malformedClient.getJson('/auth/me'),
      throwsA(isA<ApiException>().having(
        (error) => error.type,
        'type',
        ApiErrorType.unknown,
      )),
    );
  });
}
