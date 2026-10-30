import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/presentation/delete_account_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/provider_reauth.dart';
import 'package:sirati/shared/theme/app_theme.dart';

typedef _Delete = ({
  String? password,
  String? provider,
  String? idToken,
  String? nonce,
});

class _FakeAuth extends AuthApiService {
  final deletes = <_Delete>[];
  Object? error;
  Completer<void>? gate;

  @override
  Future<void> deleteAccount({
    String? password,
    String? provider,
    String? idToken,
    String? nonce,
  }) async {
    deletes.add((
      password: password,
      provider: provider,
      idToken: idToken,
      nonce: nonce,
    ));
    await gate?.future;
    final e = error;
    if (e != null) throw e;
  }
}

/// What the fake re-authentication answers; one per test.
class _ReauthScript {
  final asked = <String>[];
  ProviderProof? Function(String provider) answer = (provider) => ProviderProof(
        provider: provider,
        idToken: 'fresh-$provider-token',
        nonce: provider == 'apple' ? 'raw-nonce' : null,
      );
  Object? error;
}

class _FakeReauth implements ProviderReauth {
  _FakeReauth(this.script);
  final _ReauthScript script;

  @override
  Future<ProviderProof?> prove(String provider) async {
    script.asked.add(provider);
    final e = script.error;
    if (e != null) throw e;
    return script.answer(provider);
  }
}

AuthUser _user(
        {required bool hasPassword, List<String> providers = const []}) =>
    AuthUser(
      id: 1,
      name: 'S',
      email: 's@example.com',
      emailVerified: true,
      hasPassword: hasPassword,
      socialProviders: providers,
    );

void main() {
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    AppLocale.languageCode.value = 'en';
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  group('AuthUser password and providers', () {
    test('an older payload without the fields keeps the password flow', () {
      final user = AuthUser.fromJson(const {'id': 1, 'email': 'a@b.io'});
      expect(user.hasPassword, isTrue);
      expect(user.socialProviders, isEmpty);
    });

    test('has_password is read like the other server booleans', () {
      for (final (raw, expected) in <(Object?, bool)>[
        (true, true),
        (false, false),
        ('true', true),
        ('false', false),
        (1, true),
        (0, false),
      ]) {
        expect(AuthUser.fromJson({'has_password': raw}).hasPassword, expected,
            reason: '$raw');
      }
    });

    test('social_providers keeps only non-empty strings', () {
      expect(
        AuthUser.fromJson(const {
          'social_providers': ['apple', '', 3, null, 'google'],
        }).socialProviders,
        ['apple', 'google'],
      );
      for (final raw in [null, 'google', 7, <String, String>{}]) {
        expect(AuthUser.fromJson({'social_providers': raw}).socialProviders,
            isEmpty,
            reason: '$raw');
      }
    });

    test('copyWith keeps both fields', () {
      final user = _user(hasPassword: false, providers: ['google']);
      final copy = user.copyWith(name: 'New');
      expect(copy.hasPassword, isFalse);
      expect(copy.socialProviders, ['google']);
    });
  });

  group('DeleteAccountScreen', () {
    late _FakeAuth auth;
    late _ReauthScript reauth;

    Widget app(AuthUser user) => ProviderScope(
          overrides: [
            authApiServiceProvider.overrideWithValue(auth),
            providerReauthProvider
                .overrideWith((ref) => _FakeReauth(reauth)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightFor(arabic: false),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: DeleteAccountScreen(user: user),
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Text('route:${settings.name}'),
            ),
          ),
        );

    setUp(() {
      auth = _FakeAuth();
      reauth = _ReauthScript();
    });

    Future<void> confirmForever(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete forever'));
      await tester.pumpAndSettle();
    }

    String snack(WidgetTester tester) => tester
        .widgetList<Text>(find.descendant(
            of: find.byType(SnackBar), matching: find.byType(Text)))
        .map((t) => t.data ?? '')
        .join(' ');

    testWidgets('accounts with a password keep the password form',
        (tester) async {
      for (final providers in [
        <String>[],
        ['google'],
        ['apple', 'google']
      ]) {
        await tester
            .pumpWidget(app(_user(hasPassword: true, providers: providers)));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget, reason: '$providers');
        expect(find.textContaining('Delete my account with'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('a password-less account gets one button per linked provider',
        (tester) async {
      for (final (providers, labels) in <(List<String>, List<String>)>[
        (['google'], ['Google']),
        (['apple'], ['Apple']),
        (['apple', 'google'], ['Google', 'Apple']),
        (['google', 'facebook'], ['Google']),
      ]) {
        await tester
            .pumpWidget(app(_user(hasPassword: false, providers: providers)));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing, reason: '$providers');
        final shown = tester
            .widgetList<Text>(find.textContaining('Delete my account with'))
            .map((t) => t.data!.split(' ').last)
            .toList();
        expect(shown, labels, reason: '$providers');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('without a usable provider the password form stays',
        (tester) async {
      for (final providers in [
        <String>[],
        ['facebook']
      ]) {
        await tester
            .pumpWidget(app(_user(hasPassword: false, providers: providers)));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget, reason: '$providers');
        await tester.pumpWidget(const SizedBox());
      }
    });

    for (final provider in ['google', 'apple']) {
      testWidgets('$provider: a fresh sign-in deletes the account',
          (tester) async {
        await tester
            .pumpWidget(app(_user(hasPassword: false, providers: [provider])));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Delete my account with'));
        await confirmForever(tester);

        expect(reauth.asked, [provider]);
        expect(auth.deletes.single, (
          password: null,
          provider: provider,
          idToken: 'fresh-$provider-token',
          nonce: provider == 'apple' ? 'raw-nonce' : null,
        ));
        expect(find.text('route:${AppRoutes.login}'), findsOneWidget);
      });
    }

    testWidgets('backing out of the dialog or the sign-in deletes nothing',
        (tester) async {
      await tester
          .pumpWidget(app(_user(hasPassword: false, providers: ['google'])));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Delete my account with'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(reauth.asked, isEmpty, reason: 'dialog cancelled first');

      reauth.answer = (_) => null;
      await tester.tap(find.textContaining('Delete my account with'));
      await confirmForever(tester);
      expect(reauth.asked, ['google']);
      expect(auth.deletes, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    });

    testWidgets('signing in with another account says it is not linked',
        (tester) async {
      auth.error = ApiException.fromStatus(422, message: 'm', errors: const {
        'id_token': ['هذا الحساب غير مرتبط بحسابك في سيرتي.'],
      });
      await tester
          .pumpWidget(app(_user(hasPassword: false, providers: ['apple'])));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Delete my account with'));
      await confirmForever(tester);

      expect(snack(tester), contains('This Apple account is not linked'));
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
    });

    testWidgets('other failures keep the user on the screen with feedback',
        (tester) async {
      for (final (error, expected) in <(Object, String)>[
        (const ProviderNotConfigured('google'), 'Google sign-in is not set up'),
        (
          ApiException.fromStatus(401, message: 'Token rejected'),
          'Token rejected'
        ),
        (StateError('sdk'), ''),
      ]) {
        await tester
            .pumpWidget(app(_user(hasPassword: false, providers: ['google'])));
        await tester.pumpAndSettle();
        if (error is ApiException) {
          auth.error = error;
        } else {
          reauth.error = error;
        }
        await tester.tap(find.textContaining('Delete my account with'));
        await confirmForever(tester);
        expect(find.byType(SnackBar), findsOneWidget, reason: '$error');
        expect(snack(tester), contains(expected), reason: '$error');
        expect(find.byType(DeleteAccountScreen), findsOneWidget);
        auth.error = null;
        reauth.error = null;
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('one deletion at a time', (tester) async {
      auth.gate = Completer<void>();
      await tester
          .pumpWidget(app(_user(hasPassword: false, providers: ['google'])));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Delete my account with'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete forever'));
      // Let the dialog's exit animation finish; the request stays open.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(find.byType(AlertDialog), findsNothing);
      expect(auth.deletes, hasLength(1), reason: 'request open');

      // While the request is open, the button can't start a second one.
      await tester.tap(find.text('Deleting...'), warnIfMissed: false);
      await tester.pump();
      expect(find.byType(AlertDialog), findsNothing);
      expect(reauth.asked, ['google']);
      expect(auth.deletes, hasLength(1));

      auth.gate!.complete();
      await tester.pumpAndSettle();
      expect(auth.deletes, hasLength(1));
    });
  });
}
