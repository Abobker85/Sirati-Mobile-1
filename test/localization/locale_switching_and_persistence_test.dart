import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final stored = <String, String>{};

  setUp(() {
    AppLocale.resetForTest();
    stored.clear();
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'read':
          final key = (call.arguments as Map)['key'] as String?;
          return stored[key];
        case 'write':
          final args = call.arguments as Map;
          stored[args['key'] as String] = args['value'] as String;
          return null;
        case 'delete':
          final key = (call.arguments as Map)['key'] as String?;
          stored.remove(key);
          return null;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    AppLocale.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  group('resolveLanguageCode', () {
    test('URL lang wins over storage and device', () {
      expect(
        AppLocale.resolveLanguageCode(
          urlLang: 'en',
          storedLang: 'ar',
          deviceLocales: const [Locale('ar', 'SA')],
        ),
        'en',
      );
    });

    test('stored preference wins over device', () {
      expect(
        AppLocale.resolveLanguageCode(
          storedLang: 'en',
          deviceLocales: const [Locale('ar', 'SA')],
        ),
        'en',
      );
    });

    test('Gulf country codes default to Arabic regardless of language tag', () {
      for (final country in gulfCountryCodes) {
        expect(
          AppLocale.resolveLanguageCode(
            deviceLocales: [Locale('en', country)],
          ),
          'ar',
          reason: 'en-$country is a Gulf device',
        );
        expect(
          AppLocale.resolveLanguageCode(
            deviceLocales: [Locale('fr', country)],
          ),
          'ar',
          reason: 'fr-$country is still a Gulf device',
        );
      }
    });

    test('Arabic language tag defaults to Arabic for non-Gulf countries', () {
      expect(
        AppLocale.resolveLanguageCode(
          deviceLocales: const [Locale('ar', 'EG')],
        ),
        'ar',
      );
    });

    test('English devices outside the Gulf default to English', () {
      expect(
        AppLocale.resolveLanguageCode(
          deviceLocales: const [Locale('en', 'US')],
        ),
        'en',
      );
      expect(
        AppLocale.resolveLanguageCode(
          deviceLocales: const [Locale('en', 'GB')],
        ),
        'en',
      );
    });

    test('unrelated locales fall back to the Arabic product default', () {
      expect(
        AppLocale.resolveLanguageCode(
          deviceLocales: const [Locale('fr', 'FR'), Locale('de', 'DE')],
        ),
        'ar',
      );
      expect(
        AppLocale.resolveLanguageCode(deviceLocales: const []),
        'ar',
      );
    });
  });

  group('remote languages', () {
    final random = Random(77);

    String randomCode() => String.fromCharCodes(
          List.generate(2 + random.nextInt(2), (_) => 97 + random.nextInt(26)),
        );

    RemoteLanguageList catalogOf(Iterable<String> codes) => RemoteLanguageList(
          languages: [
            for (final code in codes)
              RemoteLanguage(
                code: code,
                name: code,
                nativeName: 'native $code',
                direction: code.codeUnitAt(0).isEven
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                fallback: code.codeUnitAt(1).isEven ? 'ar' : 'en',
              ),
          ],
        );

    test(
        'any enabled code from URL or storage wins; disabled ones fall '
        'through to device and default', () {
      for (var i = 0; i < 300; i++) {
        final enabled = randomCode();
        final disabled = randomCode();
        if ({enabled, disabled, 'ar', 'en'}.length < 4) continue;
        final available = {'ar', 'en', enabled};
        expect(
          AppLocale.resolveLanguageCode(
            urlLang: enabled.toUpperCase(),
            storedLang: 'en',
            available: available,
          ),
          enabled,
        );
        expect(
          AppLocale.resolveLanguageCode(
            storedLang: enabled,
            deviceLocales: const [Locale('ar', 'SA')],
            available: available,
          ),
          enabled,
        );
        expect(
          AppLocale.resolveLanguageCode(
            urlLang: disabled,
            storedLang: disabled,
            deviceLocales: [Locale(disabled), const Locale('en', 'US')],
            available: available,
          ),
          'en',
        );
        expect(
          AppLocale.resolveLanguageCode(
            storedLang: disabled,
            deviceLocales: [Locale(disabled)],
            available: available,
          ),
          'ar',
        );
      }
    });

    test('malformed codes are ignored', () {
      for (final bad in ['', ' ', 'e n', '../x', '1a', 'fr_FR!', 'ع']) {
        expect(
          AppLocale.resolveLanguageCode(
            urlLang: bad,
            storedLang: bad,
            available: {'ar', 'en', bad},
          ),
          'ar',
          reason: bad,
        );
      }
    });

    test(
        'device order picks the first enabled remote language, after the '
        'Arabic and Gulf rule', () {
      for (var i = 0; i < 200; i++) {
        final code = randomCode();
        if (code == 'ar' || code == 'en') continue;
        // Flutter canonicalizes deprecated subtags (iw -> he); devices
        // report the canonical code.
        if (Locale(code).languageCode != code) continue;
        final available = {'ar', 'en', code};
        expect(
          AppLocale.resolveLanguageCode(
            deviceLocales: [Locale(code, 'FR'), const Locale('en', 'US')],
            available: available,
          ),
          code,
        );
        expect(
          AppLocale.resolveLanguageCode(
            deviceLocales: [Locale(code, 'FR'), const Locale('ar', 'EG')],
            available: available,
          ),
          'ar',
        );
        expect(
          AppLocale.resolveLanguageCode(
            deviceLocales: [Locale(code, 'AE')],
            available: available,
          ),
          'ar',
        );
      }
      expect(
        AppLocale.resolveLanguageCode(
          deviceLocales: const [Locale('pt', 'BR')],
          available: {'ar', 'en', 'pt-br'},
        ),
        'pt-br',
      );
    });

    test('setLanguage persists any enabled code and rejects disabled ones',
        () async {
      for (var i = 0; i < 30; i++) {
        final code = randomCode();
        if (code == 'ar' || code == 'en') continue;
        AppLocale.resetForTest(languages: catalogOf([code]));
        await AppLocale.setLanguage(code);
        expect(AppLocale.languageCode.value, code);
        expect(stored['sirati_lang'], code);
        AppLocale.resetForTest(languages: catalogOf(const []));
        await AppLocale.setLanguage(code);
        expect(AppLocale.languageCode.value, 'ar');
      }
    });

    test('direction, base language and locale come from the language record',
        () {
      for (var i = 0; i < 100; i++) {
        final code = randomCode();
        if (code == 'ar' || code == 'en') continue;
        final catalog = catalogOf([code]);
        final record = catalog.languages.single;
        AppLocale.resetForTest(language: code, languages: catalog);
        expect(AppLocale.currentDirection, record.direction);
        expect(AppLocale.isRtl, record.direction == TextDirection.rtl);
        expect(AppLocale.baseLanguage, record.fallback);
        expect(AppLocale.locale, Locale(code));
      }
      AppLocale.resetForTest(language: 'en');
      expect(AppLocale.currentDirection, TextDirection.ltr);
      AppLocale.resetForTest();
      expect(AppLocale.currentDirection, TextDirection.rtl);
    });

    test('picker always lists ar and en, plus the enabled languages', () {
      AppLocale.resetForTest();
      expect(AppLocale.pickerLanguages.map((l) => l.code), ['ar', 'en']);
      AppLocale.resetForTest(languages: catalogOf(['fr', 'en', 'ckb']));
      expect(
        AppLocale.pickerLanguages.map((l) => l.code),
        ['ar', 'fr', 'en', 'ckb'],
      );
      expect(AppLocale.pickerLanguages[1].nativeName, 'native fr');
    });

    test(
        'a selected language that gets disabled falls back, and returns '
        'when re-enabled', () async {
      AppLocale.resetForTest(languages: catalogOf(['fr']));
      await AppLocale.setLanguage('fr');
      AppLocale.updateCatalog(catalogOf(const []));
      expect(AppLocale.languageCode.value, 'ar');
      expect(stored['sirati_lang'], 'fr');
      AppLocale.updateCatalog(catalogOf(['fr']));
      expect(AppLocale.languageCode.value, 'fr');
    });

    test('a stored language unknown at launch applies once the list has it',
        () async {
      stored['sirati_lang'] = 'fr';
      await AppLocale.bootstrap(deviceLocales: const [Locale('en', 'US')]);
      expect(AppLocale.languageCode.value, 'en');
      AppLocale.updateCatalog(catalogOf(['fr']));
      expect(AppLocale.languageCode.value, 'fr');
    });
  });

  test('bootstrap persists nothing and applies stored language', () async {
    stored['sirati_lang'] = 'en';
    await AppLocale.bootstrap(deviceLocales: const [Locale('ar', 'SA')]);
    expect(AppLocale.languageCode.value, 'en');
  });

  test('setLanguage persists ar/en', () async {
    await AppLocale.setLanguage('en');
    expect(stored['sirati_lang'], 'en');
    expect(AppLocale.languageCode.value, 'en');
    await AppLocale.setLanguage('ar');
    expect(stored['sirati_lang'], 'ar');
  });

  testWidgets(
      'toggling locale flips Directionality and preserves in-progress draft text',
      (tester) async {
    AppLocale.resetForTest(language: 'ar');
    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      ValueListenableBuilder<String>(
        valueListenable: AppLocale.languageCode,
        builder: (context, language, _) {
          return MaterialApp(
            navigatorKey: navKey,
            locale: language == 'en'
                ? const Locale('en', 'US')
                : const Locale('ar', 'SA'),
            supportedLocales: const [
              Locale('ar', 'SA'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection:
                    language == 'en' ? TextDirection.ltr : TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const Scaffold(
              body: TextField(
                key: Key('draft'),
              ),
            ),
          );
        },
      ),
    );

    const draft = 'مسودة مهندس برمجيات Laravel';
    await tester.enterText(find.byKey(const Key('draft')), draft);
    expect(find.text(draft), findsOneWidget);

    final rtlDirection =
        tester.widget<Directionality>(find.byType(Directionality).first);
    expect(rtlDirection.textDirection, TextDirection.rtl);

    await AppLocale.setLanguage('en');
    await tester.pump();
    await tester.pump();

    expect(find.text(draft), findsOneWidget);
    final ltrDirection =
        tester.widget<Directionality>(find.byType(Directionality).first);
    expect(ltrDirection.textDirection, TextDirection.ltr);
    expect(stored['sirati_lang'], 'en');
  });
}
