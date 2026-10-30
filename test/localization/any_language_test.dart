import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirati/core/l10n/remote_l10n.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_l10n_store.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/network/api_client.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/storage/disk_cache.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/features/job_match/domain/job_match.dart';
import 'package:sirati/features/settings/presentation/change_password_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';
import 'package:sirati/shared/widgets/components/app_dialog.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/screen_header.dart';

/// Remote languages the app has no ARB for: every direction paired with
/// every base language, so direction and content language never coincide.
const _languages = [
  RemoteLanguage(
    code: 'tr',
    name: 'Turkish',
    nativeName: 'Türkçe',
    direction: TextDirection.ltr,
  ),
  RemoteLanguage(
    code: 'fa',
    name: 'Persian',
    nativeName: 'فارسی',
    direction: TextDirection.rtl,
    fallback: 'ar',
  ),
  RemoteLanguage(
    code: 'ur',
    name: 'Urdu',
    nativeName: 'اردو',
    direction: TextDirection.rtl,
  ),
  RemoteLanguage(
    code: 'sw',
    name: 'Swahili',
    nativeName: 'Kiswahili',
    direction: TextDirection.ltr,
    fallback: 'ar',
  ),
];

/// Keys whose catalog text the touched code must show.
const _keys = [
  'sharedOk',
  'sharedLoading',
  'sharedErrorNetworkSubtitle',
  'sharedErrorTimeoutSubtitle',
  'coreApiErrorBadResponse',
  'coreApiErrorEmptyResponse',
  'coreApiErrorUnexpected',
  'coreApiErrorRequestFailed',
  'settingsPasswordChanged',
  'settingsCurrentPasswordIncorrect',
  'settingsUpdatePassword',
  'authForgotCodeSent',
  'authForgotSendCode',
];

/// Catalog of [code]: a distinct marker per key, so a match proves the
/// text came from this language's catalog and from no other source.
Map<String, String> _catalog(String code) => {
      for (final key in _keys) key: '⟦$code:$key⟧',
      'coreApiErrorStatus': '⟦$code:status {code}⟧',
    };

RemoteL10nState _state() => RemoteL10nState(
      languages: const RemoteLanguageList(languages: _languages),
      bundles: {
        for (final language in _languages)
          language.code: RemoteStringBundle(
            code: language.code,
            version: 1,
            strings: _catalog(language.code),
          ),
      },
    );

Future<void> _useLanguage(String code) async {
  final repository = RemoteL10nRepository(
    store: MemoryRemoteL10nStore(),
    client: MockClient((_) async => http.Response('', 503)),
  );
  repository.debugSetState(_state());
  RemoteL10n.debugReset(repository);
  await RemoteL10n.loadCache();
  AppLocale.resetForTest(
      language: code,
      languages: const RemoteLanguageList(
        languages: _languages,
      ));
}

Widget _app(String code, Widget home, {AuthApiService? auth}) {
  final state = _state();
  return ProviderScope(
    overrides: [
      if (auth != null) authApiServiceProvider.overrideWithValue(auth),
    ],
    child: MaterialApp(
      theme: AppTheme.lightFor(
        arabic: AppLocale.directionOf(code) == TextDirection.rtl,
      ),
      locale: localeForLanguageCode(code),
      supportedLocales: appSupportedLocales(state),
      localizationsDelegates: appLocalizationsDelegates(state),
      home: home,
    ),
  );
}

class _FakeAuth extends AuthApiService {
  _FakeAuth({this.changeError});

  final ApiException? changeError;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    if (changeError != null) throw changeError!;
  }

  @override
  Future<void> forgotPassword({required String email}) async {}
}

void main() {
  tearDown(() {
    RemoteL10n.debugReset();
    AppLocale.resetForTest();
    AppRouter.debugRoutesEnabled = true;
  });

  group('direction', () {
    test('a language record without a direction uses the RTL language list',
        () {
      for (final code in ['ar', 'fa', 'ur', 'he', 'ps', 'yi', 'dv', 'sd']) {
        final record = RemoteLanguage.tryParse({'code': code});
        expect(record!.direction, TextDirection.rtl, reason: code);
      }
      for (final code in ['en', 'tr', 'fr', 'sw', 'id', 'hi', 'de', 'pt-br']) {
        final record = RemoteLanguage.tryParse({'code': code});
        expect(record!.direction, TextDirection.ltr, reason: code);
      }
    });

    test('a served direction wins over the RTL language list', () {
      expect(
        RemoteLanguage.tryParse({'code': 'fa', 'direction': 'ltr'})!.direction,
        TextDirection.ltr,
      );
      expect(
        RemoteLanguage.tryParse({'code': 'tr', 'direction': 'rtl'})!.direction,
        TextDirection.rtl,
      );
    });
  });

  group('disk cache keys', () {
    String randomCode(Random random) {
      const letters = 'abcdefghijklmnopqrstuvwxyz';
      final length = 2 + random.nextInt(2);
      final base =
          List.generate(length, (_) => letters[random.nextInt(letters.length)])
              .join();
      return random.nextBool()
          ? base
          : '$base-${letters[random.nextInt(26)]}${letters[random.nextInt(26)]}';
    }

    test('every language has its own key; spellings of one code share it', () {
      final random = Random(1717);
      final codes = {
        'ar',
        'en',
        for (var i = 0; i < 300; i++) randomCode(random)
      };
      for (final keyOf in [
        DiskCache.dashboardKey,
        DiskCache.cvsKey,
        DiskCache.newsKey,
      ]) {
        final keys = {for (final code in codes) keyOf(code)};
        expect(keys, hasLength(codes.length));
        for (final code in codes) {
          expect(keyOf(code.toUpperCase().replaceAll('-', '_')), keyOf(code));
        }
      }
    });
  });

  for (final language in _languages) {
    final code = language.code;
    final base = language.fallback;

    group('$code (${language.direction.name}, base $base)', () {
      setUp(() => _useLanguage(code));

      test('content language follows the fallback chain', () {
        expect(AppLocale.contentLanguageOf(code), base);
        expect(AppLocale.isEnglishCode(code), base == 'en');

        const text = LocalizedText(ar: 'نص', en: 'text');
        expect(text.resolve(code), base == 'en' ? 'text' : 'نص');
        final parsed = LocalizedText.fromJson('x', defaultLanguage: code);
        expect(base == 'en' ? parsed.en : parsed.ar, 'x');

        expect(CvFormData.fromDraftJson({'language': code}).language, base);
        expect(JobMatch.fromJson({'language': code}).language, base);
        expect(
          CvDocument.fromJson({'export_language': code}).exportLanguage,
          base,
        );
      });

      test('API client errors come from the catalog', () async {
        Future<ApiException> failure(MockClientHandler handler) async {
          final client = ApiClient(httpClient: MockClient(handler));
          try {
            await client.getJson('/x');
          } on ApiException catch (e) {
            return e;
          }
          fail('expected an ApiException');
        }

        final catalog = _catalog(code);
        expect(
          (await failure((_) async => throw http.ClientException('x'))).message,
          catalog['sharedErrorNetworkSubtitle'],
        );
        expect(
          (await failure((_) async => throw TimeoutException('x'))).message,
          catalog['sharedErrorTimeoutSubtitle'],
        );
        expect(
          (await failure((_) async => throw StateError('x'))).message,
          catalog['coreApiErrorUnexpected'],
        );
        expect(
          (await failure((_) async => http.Response('', 200))).message,
          catalog['coreApiErrorEmptyResponse'],
        );
        expect(
          (await failure((_) async => http.Response('{oops', 200))).message,
          catalog['coreApiErrorBadResponse'],
        );
        expect(
          (await failure((_) async => http.Response('[1]', 200))).message,
          catalog['coreApiErrorBadResponse'],
        );
        expect(
          (await failure((_) async => http.Response('{}', 400))).message,
          catalog['coreApiErrorRequestFailed'],
        );
        final status = 500 + Random().nextInt(99);
        expect(
          (await failure((_) async => http.Response('<html>', status))).message,
          '⟦$code:status $status⟧',
        );
        // Server-written messages pass through untouched.
        expect(
          (await failure((_) async =>
                  http.Response(jsonEncode({'message': 'srv'}), 422)))
              .message,
          'srv',
        );
      });

      testWidgets('change password shows catalog text, never server text',
          (tester) async {
        await tester.pumpWidget(_app(
          code,
          const ChangePasswordScreen(),
          auth: _FakeAuth(
            changeError: const ApiException('srv', statusCode: 422, errors: {
              'current_password': ['server field text'],
            }),
          ),
        ));
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byType(ChangePasswordScreen))),
          language.direction,
        );
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'oldpass1');
        await tester.enterText(fields.at(1), 'newpass12');
        await tester.enterText(fields.at(2), 'newpass12');
        await tester.tap(find.text(_catalog(code)['settingsUpdatePassword']!));
        await tester.pumpAndSettle();
        final current = tester.state<FormFieldState<String>>(
          find.byType(AppTextFormField).first,
        );
        expect(
          current.errorText,
          _catalog(code)['settingsCurrentPasswordIncorrect'],
        );

        await tester.pumpWidget(_app(
          code,
          const ChangePasswordScreen(),
          auth: _FakeAuth(),
        ));
        await tester.pumpAndSettle();
        await tester.enterText(fields.at(0), 'oldpass1');
        await tester.enterText(fields.at(1), 'newpass12');
        await tester.enterText(fields.at(2), 'newpass12');
        await tester.tap(find.text(_catalog(code)['settingsUpdatePassword']!));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.text(_catalog(code)['settingsPasswordChanged']!),
          findsOneWidget,
        );
      });

      testWidgets('forgot password confirms with catalog text', (tester) async {
        await tester.pumpWidget(_app(
          code,
          const ForgotPasswordScreen(),
          auth: _FakeAuth(),
        ));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'a@b.co');
        await tester.tap(find.text(_catalog(code)['authForgotSendCode']!));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(
            find.text(_catalog(code)['authForgotCodeSent']!), findsOneWidget);
      });

      testWidgets('header avatar never guesses an initial from the title',
          (tester) async {
        await tester.pumpWidget(_app(
          code,
          Scaffold(
            body: Builder(
              builder: (context) => ScreenHeader(
                english: AppLocale.isEnglish(context),
                title: AppLocale.greeting('Zainab', context),
                onNotifications: () {},
              ),
            ),
          ),
        ));
        await tester.pump();
        final avatar = find.byType(ProfileAvatar);
        expect(
          find.descendant(of: avatar, matching: find.byType(Text)),
          findsNothing,
        );
        expect(
          find.descendant(of: avatar, matching: find.byType(Icon)),
          findsOneWidget,
        );
      });

      testWidgets(
          'button and dialog defaults outside the localized tree use the '
          'current language catalog', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  AppButton(label: 'go', isLoading: true, onPressed: () {}),
                  TextButton(
                    onPressed: () => showAppDialog<void>(
                      context: context,
                      title: 't',
                      body: 'm',
                    ),
                    child: const Text('open'),
                  ),
                ],
              ),
            ),
          ),
        ));
        expect(
          tester
              .widget<CircularProgressIndicator>(
                  find.byType(CircularProgressIndicator))
              .semanticsLabel,
          _catalog(code)['sharedLoading'],
        );
        await tester.tap(find.text('open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(_catalog(code)['sharedOk']!), findsOneWidget);
      });

      testWidgets('relative dates use the base language digits',
          (tester) async {
        late AppLocalizations l10n;
        await tester.pumpWidget(_app(
          code,
          Builder(builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          }),
        ));
        final old = DateTime(2020, 3, 14);
        expect(
          AppFormat.relativeTime(old, l10n, now: DateTime(2026, 1, 1)),
          AppFormat.shortDate(old, english: base == 'en'),
        );
      });
    });
  }

  test('/gallery is unknown outside debug builds', () {
    AppRouter.debugRoutesEnabled = false;
    expect(AppRouter.parse(AppRoutes.gallery).unknown, isTrue);
    AppRouter.debugRoutesEnabled = true;
    expect(AppRouter.parse(AppRoutes.gallery).name, AppRoutes.gallery);
    expect(AppRouter.parse(AppRoutes.gallery).unknown, isFalse);
  });
}
