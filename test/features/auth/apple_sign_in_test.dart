import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/application/login_controller.dart';
import 'package:sirati/features/auth/data/apple_credential_source.dart';
import 'package:sirati/features/auth/data/google_id_token_source.dart';
import 'package:sirati/features/auth/domain/social_sign_in.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _FakeApple implements AppleCredentialSource {
  _FakeApple([this.result = _result]);
  static const _result = AppleSignInResult(
    idToken: 'apple-id-token',
    authorizationCode: 'apple-code',
    rawNonce: 'raw-nonce',
    name: 'سالم Sayer',
  );
  AppleSignInResult? result;
  Object? error;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<AppleSignInResult?> signIn() async {
    calls++;
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    return result;
  }
}

typedef _SocialCall = ({
  String provider,
  String idToken,
  String? nonce,
  String? code,
  String? name,
});

class _FakeAuth extends AuthApiService {
  final calls = <_SocialCall>[];
  Object? error;

  @override
  Future<AuthSession> socialSignIn({
    required String provider,
    required String idToken,
    String? nonce,
    String? authorizationCode,
    String? name,
  }) async {
    calls.add((
      provider: provider,
      idToken: idToken,
      nonce: nonce,
      code: authorizationCode,
      name: name,
    ));
    final e = error;
    if (e != null) throw e;
    return const AuthSession(
      token: 't',
      tokenType: 'Bearer',
      user: AuthUser(
          id: 9,
          name: 'S',
          email: 'a@privaterelay.appleid.com',
          emailVerified: true),
    );
  }
}

void main() {
  group('appleNonce', () {
    test('is long, URL-safe and different every attempt', () {
      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        final nonce = appleNonce();
        expect(nonce.length, greaterThanOrEqualTo(43));
        expect(nonce, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
        seen.add(nonce);
      }
      expect(seen, hasLength(200));
    });

    test('uses every byte of the random source', () {
      expect(appleNonce(Random(1)), isNot(appleNonce(Random(2))));
      expect(base64Url.decode('${appleNonce(Random(3))}='), hasLength(32));
    });
  });

  group('LoginController.signInWithApple', () {
    late _FakeAuth auth;
    late _FakeApple apple;
    late ProviderContainer container;

    ProviderContainer make(AppleCredentialSource? source) {
      final c = ProviderContainer(overrides: [
        authApiServiceProvider.overrideWithValue(auth),
        appleCredentialSourceProvider.overrideWithValue(source),
        googleIdTokenSourceProvider.overrideWithValue(null),
      ]);
      c.listen(loginControllerProvider, (_, __) {});
      return c;
    }

    setUp(() {
      auth = _FakeAuth();
      apple = _FakeApple();
      container = make(apple);
    });
    tearDown(() => container.dispose());

    LoginController ctrl() => container.read(loginControllerProvider.notifier);

    test('token, raw nonce, code and name all reach the server', () async {
      for (final name in ['سالم Sayer', null]) {
        apple.result = AppleSignInResult(
          idToken: 'id-$name',
          authorizationCode: 'code-$name',
          rawNonce: 'nonce-$name',
          name: name,
        );
        expect(await ctrl().signInWithApple(), isA<LoginSucceeded>());
        expect(auth.calls.last, (
          provider: 'apple',
          idToken: 'id-$name',
          nonce: 'nonce-$name',
          code: 'code-$name',
          name: name,
        ));
      }
    });

    test('cancelling does nothing', () async {
      apple.result = null;
      expect(await ctrl().signInWithApple(), isA<LoginIgnored>());
      expect(auth.calls, isEmpty);
      expect(container.read(loginControllerProvider), isFalse);
    });

    test('a build that can\'t run Apple sign-in says so', () async {
      container.dispose();
      container = make(null);
      expect(await ctrl().signInWithApple(), isA<LoginProviderNotConfigured>());
      expect(auth.calls, isEmpty);
    });

    test('failures are classified and release the flag', () async {
      for (final (error, type) in <(Object, Type)>[
        for (final status in [401, 422, 503])
          (ApiException.fromStatus(status, message: 'm'), LoginRejected),
        (PlatformException(code: 'x'), LoginFailedUnexpectedly),
        (StateError('no token'), LoginFailedUnexpectedly),
      ]) {
        apple.error = error is ApiException ? null : error;
        auth.error = error is ApiException ? error : null;
        expect((await ctrl().signInWithApple()).runtimeType, type,
            reason: '$error');
        expect(container.read(loginControllerProvider), isFalse);
      }
    });

    test('one sign-in at a time across Apple, Google and email', () async {
      apple.gate = Completer<void>();
      final first = ctrl().signInWithApple();
      expect(await ctrl().signInWithApple(), isA<LoginIgnored>());
      expect(await ctrl().signInWithGoogle(), isA<LoginIgnored>());
      expect(await ctrl().signIn(email: 'a@b.io', password: 'p'),
          isA<LoginIgnored>());
      apple.gate!.complete();
      expect(await first, isA<LoginSucceeded>());
      expect(apple.calls, 1);
    });
  });

  test('AuthApiService sends the Apple fields', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const storage =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (_) async => null);
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null));

    late Map<String, dynamic> body;
    await http.runWithClient(
      () => AuthApiService().socialSignIn(
        provider: 'apple',
        idToken: 'i',
        nonce: 'n',
        authorizationCode: 'c',
        name: 'سالم',
      ),
      () => MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'data': {
              'token': 't',
              'token_type': 'Bearer',
              'user': {'id': 1, 'name': 'S', 'email': 'e@x.io'},
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    expect(body, containsPair('authorization_code', 'c'));
    expect(body, containsPair('nonce', 'n'));
    expect(body, containsPair('name', 'سالم'));
  });

  group('LoginScreen Apple button', () {
    const storage =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    setUp(() {
      AppLocale.languageCode.value = 'en';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storage, (_) async => null);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storage, null);
    });

    Widget app(AuthApiService auth, AppleCredentialSource? apple) =>
        ProviderScope(
          overrides: [
            authApiServiceProvider.overrideWithValue(auth),
            appleCredentialSourceProvider.overrideWithValue(apple),
            googleIdTokenSourceProvider.overrideWithValue(null),
            socialSignInOptionsProvider.overrideWithValue(
                const SocialSignInOptions(google: true, apple: true)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightFor(arabic: false),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const LoginScreen(),
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Text('route:${settings.name}'),
            ),
          ),
        );

    Future<void> tapApple(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Apple'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();
    }

    testWidgets('signing in opens the app', (tester) async {
      final auth = _FakeAuth();
      await tester.pumpWidget(app(auth, _FakeApple()));
      await tester.pumpAndSettle();
      await tapApple(tester);
      expect(auth.calls.single.provider, 'apple');
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('cancelling stays quiet; no setup says so', (tester) async {
      await tester.pumpWidget(app(_FakeAuth(), _FakeApple(null)));
      await tester.pumpAndSettle();
      await tapApple(tester);
      expect(find.byType(SnackBar), findsNothing);
      await tester.pumpWidget(const SizedBox());

      await tester.pumpWidget(app(_FakeAuth(), null));
      await tester.pumpAndSettle();
      await tapApple(tester);
      final shown = tester
          .widgetList<Text>(find.descendant(
              of: find.byType(SnackBar), matching: find.byType(Text)))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(shown, contains('Apple sign-in is not set up'));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('a rejection shows the server message', (tester) async {
      const message = 'تعذّر التحقق من حساب Apple. حاول مرة أخرى.';
      final auth = _FakeAuth()
        ..error = ApiException.fromStatus(401, message: message);
      await tester.pumpWidget(app(auth, _FakeApple()));
      await tester.pumpAndSettle();
      await tapApple(tester);
      expect(find.textContaining(message), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
