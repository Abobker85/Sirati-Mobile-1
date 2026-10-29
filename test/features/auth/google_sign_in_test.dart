import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/application/login_controller.dart';
import 'package:sirati/features/auth/data/google_id_token_source.dart';
import 'package:sirati/features/auth/domain/social_sign_in.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _FakeGoogle implements GoogleIdTokenSource {
  _FakeGoogle([this.token = 'google-id-token']);
  String? token;
  Object? error;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<String?> idToken() async {
    calls++;
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    return token;
  }
}

class _FakeAuth extends AuthApiService {
  final social = <(String, String)>[];
  final logins = <String>[];
  Object? error;
  bool verified = true;

  AuthSession _session(String email) => AuthSession(
        token: 't',
        tokenType: 'Bearer',
        user: AuthUser(id: 7, name: 'S', email: email, emailVerified: verified),
      );

  @override
  Future<AuthSession> socialSignIn({
    required String provider,
    required String idToken,
    String? nonce,
    String? authorizationCode,
    String? name,
  }) async {
    social.add((provider, idToken));
    final e = error;
    if (e != null) throw e;
    return _session('g@example.com');
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    logins.add(email);
    return _session(email);
  }
}

void main() {
  group('SocialSignInOptions.fromBuild', () {
    test('a non-debug iOS build never offers Google without Apple', () {
      for (final platform in TargetPlatform.values) {
        for (final google in [true, false]) {
          for (final apple in [true, false]) {
            for (final debug in [true, false]) {
              final o = SocialSignInOptions.fromBuild(
                google: google,
                apple: apple,
                platform: platform,
                debug: debug,
              );
              final label = '$platform google=$google apple=$apple '
                  'debug=$debug';
              expect(o.apple, apple, reason: label);
              if (!google) expect(o.google, isFalse, reason: label);
              if (platform == TargetPlatform.iOS && !debug && o.google) {
                expect(o.apple, isTrue, reason: label);
              }
              if (platform != TargetPlatform.iOS || debug) {
                expect(o.google, google, reason: label);
              }
              expect(o.any, o.google || o.apple, reason: label);
            }
          }
        }
      }
    });
  });

  group('LoginController.signInWithGoogle', () {
    late _FakeAuth auth;
    late _FakeGoogle google;
    late ProviderContainer container;

    ProviderContainer make(GoogleIdTokenSource? source) {
      final c = ProviderContainer(overrides: [
        authApiServiceProvider.overrideWithValue(auth),
        googleIdTokenSourceProvider.overrideWithValue(source),
      ]);
      c.listen(loginControllerProvider, (_, __) {});
      return c;
    }

    setUp(() {
      auth = _FakeAuth();
      google = _FakeGoogle();
      container = make(google);
    });
    tearDown(() => container.dispose());

    LoginController ctrl() => container.read(loginControllerProvider.notifier);

    test('the picked account\'s ID token is sent to the server', () async {
      for (final verified in [true, false]) {
        auth.verified = verified;
        google.token = 'token-$verified';
        final outcome = await ctrl().signInWithGoogle();
        expect(
          outcome,
          isA<LoginSucceeded>()
              .having((o) => o.emailVerified, 'verified', verified),
        );
        expect(auth.social.last, ('google', 'token-$verified'));
      }
    });

    test('closing the account picker does nothing', () async {
      google.token = null;
      expect(await ctrl().signInWithGoogle(), isA<LoginIgnored>());
      expect(auth.social, isEmpty);
      expect(container.read(loginControllerProvider), isFalse);
    });

    test('a build without a client id never opens the SDK', () async {
      container.dispose();
      container = make(null);
      expect(
          await ctrl().signInWithGoogle(), isA<LoginProviderNotConfigured>());
      expect(auth.social, isEmpty);
    });

    test('failures are classified and release the flag', () async {
      for (final (error, type) in <(Object, Type)>[
        for (final status in [401, 403, 422, 429, 503])
          (ApiException.fromStatus(status, message: 'm'), LoginRejected),
        (
          const ApiException('offline', type: ApiErrorType.network),
          LoginRejected
        ),
        (PlatformException(code: 'sign_in_failed'), LoginFailedUnexpectedly),
        (StateError('no id token'), LoginFailedUnexpectedly),
      ]) {
        google.error = error is ApiException ? null : error;
        auth.error = error is ApiException ? error : null;
        final outcome = await ctrl().signInWithGoogle();
        expect(outcome.runtimeType, type, reason: '$error');
        expect(container.read(loginControllerProvider), isFalse);
      }
    });

    test('one sign-in at a time, across email and Google', () async {
      google.gate = Completer<void>();
      final first = ctrl().signInWithGoogle();
      for (var i = 0; i < 3; i++) {
        expect(await ctrl().signInWithGoogle(), isA<LoginIgnored>());
        expect(await ctrl().signIn(email: 'a@b.io', password: 'p'),
            isA<LoginIgnored>());
      }
      google.gate!.complete();
      expect(await first, isA<LoginSucceeded>());
      expect(google.calls, 1);
      expect(auth.social, hasLength(1));
      expect(auth.logins, isEmpty);
    });
  });

  group('AuthApiService.socialSignIn', () {
    const secureStorage =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final written = <String, String>{};
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      written.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, (call) async {
        if (call.method == 'write') {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          written[args['key'] as String] = args['value'] as String;
        }
        return null;
      });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, null);
    });

    test('posts the token to the provider route and keeps the session',
        () async {
      for (final provider in ['google', 'apple']) {
        late http.Request sent;
        final session = await http.runWithClient(
          () => AuthApiService().socialSignIn(
            provider: provider,
            idToken: 'id-$provider',
            nonce: provider == 'apple' ? 'n' : null,
          ),
          () => MockClient((request) async {
            sent = request;
            return http.Response(
              jsonEncode({
                'data': {
                  'token': 'session-$provider',
                  'token_type': 'Bearer',
                  'user': {
                    'id': 3,
                    'name': 'S',
                    'email': 's@example.com',
                    'email_verified': true,
                  },
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        expect(sent.method, 'POST');
        expect(sent.url.path, endsWith('/auth/social/$provider'));
        final body = jsonDecode(sent.body) as Map<String, dynamic>;
        expect(body['id_token'], 'id-$provider');
        expect(body.containsKey('nonce'), provider == 'apple');
        expect(session.token, 'session-$provider');
        expect(written.values, contains('session-$provider'));
      }
    });
  });

  group('LoginScreen social buttons', () {
    const secureStorage =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    setUp(() {
      AppLocale.languageCode.value = 'en';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, (_) async => null);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(secureStorage, null);
    });

    Widget app({
      required AuthApiService auth,
      GoogleIdTokenSource? google,
      SocialSignInOptions options =
          const SocialSignInOptions(google: true, apple: true),
    }) =>
        ProviderScope(
          overrides: [
            authApiServiceProvider.overrideWithValue(auth),
            googleIdTokenSourceProvider.overrideWithValue(google),
            socialSignInOptionsProvider.overrideWithValue(options),
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

    Future<void> tapGoogle(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google'));
    }

    String snackText(WidgetTester tester) => tester
        .widgetList<Text>(find.descendant(
            of: find.byType(SnackBar), matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .join(' ');

    testWidgets('each button shows only when its provider is on',
        (tester) async {
      for (final google in [true, false]) {
        for (final apple in [true, false]) {
          await tester.pumpWidget(app(
            auth: _FakeAuth(),
            options: SocialSignInOptions(google: google, apple: apple),
          ));
          await tester.pumpAndSettle();
          final label = 'google=$google apple=$apple';
          expect(find.text('Google'), google ? findsOneWidget : findsNothing,
              reason: label);
          expect(find.text('Apple'), apple ? findsOneWidget : findsNothing,
              reason: label);
          expect(find.text('Or continue with'),
              google || apple ? findsOneWidget : findsNothing,
              reason: label);
          await tester.pumpWidget(const SizedBox());
        }
      }
    });

    testWidgets('a Google sign-in opens the app like an email sign-in',
        (tester) async {
      final auth = _FakeAuth();
      await tester.pumpWidget(app(auth: auth, google: _FakeGoogle()));
      await tester.pumpAndSettle();
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(auth.social.single.$1, 'google');
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.textContaining('route:'), findsOneWidget);
    });

    testWidgets('closing the picker leaves the screen quiet', (tester) async {
      final auth = _FakeAuth();
      await tester.pumpWidget(app(auth: auth, google: _FakeGoogle(null)));
      await tester.pumpAndSettle();
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(auth.social, isEmpty);
    });

    testWidgets('a build without a client id says so and never opens the SDK',
        (tester) async {
      await tester.pumpWidget(app(auth: _FakeAuth()));
      await tester.pumpAndSettle();
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(snackText(tester), contains('Google sign-in is not set up'));
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('the server\'s answer is shown and the user stays on login',
        (tester) async {
      for (final (status, body) in [
        (
          401,
          '{"message":"تعذّر التحقق من حساب Google. حاول مرة أخرى.","reason":"invalid_token"}'
        ),
        (
          422,
          '{"message":"البريد الإلكتروني لحساب Google غير مؤكد.","reason":"email_unverified"}'
        ),
        (
          503,
          '{"message":"تسجيل الدخول عبر Google غير متاح حالياً. حاول لاحقاً.","reason":"not_configured"}'
        ),
        (500, '<html>oops</html>'),
      ]) {
        final google = _FakeGoogle();
        await http.runWithClient(() async {
          await tester.pumpWidget(app(auth: AuthApiService(), google: google));
          await tester.pumpAndSettle();
          await tapGoogle(tester);
          await tester.pumpAndSettle();
        },
            () => MockClient((_) async => http.Response.bytes(
                utf8.encode(body), status,
                headers: {'content-type': 'application/json'})));
        final shown = snackText(tester);
        expect(shown.trim(), isNotEmpty, reason: 'HTTP $status: no feedback');
        if (status != 500) {
          final message =
              (jsonDecode(body) as Map<String, dynamic>)['message'] as String;
          expect(shown, contains(message), reason: 'HTTP $status');
        }
        expect(find.byType(LoginScreen), findsOneWidget, reason: '$status');
        expect(google.calls, 1);
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
            .removeCurrentSnackBar();
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a Google SDK failure shows the generic error', (tester) async {
      final google = _FakeGoogle()..error = PlatformException(code: '10');
      await tester.pumpWidget(app(auth: _FakeAuth(), google: google));
      await tester.pumpAndSettle();
      await tapGoogle(tester);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
