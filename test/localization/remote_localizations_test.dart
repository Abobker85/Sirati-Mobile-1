import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sirati/core/l10n/icu_lite.dart';
import 'package:sirati/core/l10n/remote_l10n.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_l10n_store.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/l10n/remote_strings.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/remote_app_localizations.dart';
import 'package:sirati/main.dart';

Map<String, String> _arb(String code) {
  final json = jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
      as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

const _keys = RemoteAppLocalizations.debugPlaceholderTypes;

String _randomText(Random random) {
  const pool = ['a', 'Z', ' ', '{', '}', "'", r'$', '#', 'سارة', '7', ','];
  return List.generate(random.nextInt(12), (_) => pool[random.nextInt(11)])
      .join();
}

/// Arbitrary arguments for [key]; select arguments pick a real branch half
/// of the time (branch names come from parsing [message], not a list).
List<Object?> _argsFor(String key, String message, Random random) {
  final selectBranches = <String>[];
  void visit(List<IcuNode> nodes) {
    for (final node in nodes) {
      if (node is IcuChoice) {
        if (!node.isPlural) selectBranches.addAll(node.branches.keys);
        node.branches.values.forEach(visit);
      }
    }
  }

  visit(IcuLite.parse(message));
  return [
    for (final type in _keys[key]!)
      switch (type) {
        'int' => random.nextBool()
            ? random.nextInt(3)
            : random.nextInt(random.nextBool() ? 120 : 1 << 20),
        'String' => selectBranches.isNotEmpty && random.nextBool()
            ? selectBranches[random.nextInt(selectBranches.length)]
            : _randomText(random),
        _ => throw StateError('add a sample for placeholder type $type'),
      },
  ];
}

RemoteL10nState _state({
  List<RemoteLanguage> languages = const [],
  Map<String, Map<String, String>> strings = const {},
}) =>
    RemoteL10nState(
      languages: RemoteLanguageList(languages: languages),
      bundles: {
        for (final e in strings.entries)
          e.key: RemoteStringBundle(code: e.key, version: 1, strings: e.value),
      },
    );

const _french = RemoteLanguage(
  code: 'fr',
  name: 'French',
  nativeName: 'Français',
  direction: TextDirection.ltr,
);

/// A right-to-left language Flutter has no localizations for.
const _sorani = RemoteLanguage(
  code: 'ckb',
  name: 'Central Kurdish',
  nativeName: 'کوردی',
  direction: TextDirection.rtl,
  fallback: 'ar',
);

void main() {
  final random = Random(4521);

  group('RemoteAppLocalizations', () {
    for (final code in bundledLanguageCodes) {
      test(
          '$code: remote copies of the bundled ARB render exactly like the '
          'generated code, for arbitrary arguments', () {
        final bundled = lookupAppLocalizations(Locale(code));
        final arb = _arb(code);
        final remote = RemoteAppLocalizations(
          code,
          base: bundled,
          fallbackBase: lookupAppLocalizations(const Locale('en')),
          remote: RemoteStringLookup(
            [RemoteStringLayer(locale: code, strings: arb)],
          ),
        );
        for (final key in _keys.keys) {
          final runs = _keys[key]!.isEmpty ? 1 : 60;
          for (var i = 0; i < runs; i++) {
            final args = _argsFor(key, arb[key]!, random);
            expect(
              RemoteAppLocalizations.debugInvoke(remote, key, args),
              RemoteAppLocalizations.debugInvoke(bundled, key, args),
              reason: '$key$args',
            );
          }
        }
      });
    }

    test('blank or malformed remote values fall back to the bundled text', () {
      const garbage = [
        '',
        '   ',
        '\n\t',
        '{',
        '}',
        '{zzUnknownArg}',
        '{n, plural, one{x}}',
        '{count, selectordinal, other{x}}',
      ];
      for (final code in bundledLanguageCodes) {
        final bundled = lookupAppLocalizations(Locale(code));
        final arb = _arb(code);
        for (final bad in garbage) {
          final remote = RemoteAppLocalizations(
            code,
            base: bundled,
            fallbackBase: bundled,
            remote: RemoteStringLookup([
              RemoteStringLayer(
                locale: code,
                strings: {for (final key in _keys.keys) key: bad},
              ),
            ]),
          );
          for (final key in _keys.keys) {
            // `{`/`}` are legitimate literal text in a placeholder-free label.
            if (_keys[key]!.isEmpty && bad.trim().isNotEmpty) continue;
            final args = _argsFor(key, arb[key]!, random);
            expect(
              RemoteAppLocalizations.debugInvoke(remote, key, args),
              RemoteAppLocalizations.debugInvoke(bundled, key, args),
              reason: '$code $key with "$bad"',
            );
          }
        }
      }
    });

    test(
        'a remote-only language uses its own remote string, then its '
        "fallback's remote string, then the fallback's bundled string", () {
      final state = _state(
        languages: const [_french],
        strings: {
          'fr': {'appTitle': 'Mon CV'},
          'en': {'appTitle': 'EN remote', 'language': 'EN remote language'},
        },
      );
      final l10n = RemoteLocalizationsDelegate.localizationsFor(
        state,
        const Locale('fr'),
      );
      final english = lookupAppLocalizations(const Locale('en'));
      expect(l10n.localeName, 'fr');
      expect(l10n.appTitle, 'Mon CV');
      expect(l10n.language, 'EN remote language');
      for (final key in _keys.keys) {
        if (key == 'appTitle' || key == 'language') continue;
        final args = _argsFor(key, _arb('en')[key]!, random);
        expect(
          RemoteAppLocalizations.debugInvoke(l10n, key, args),
          RemoteAppLocalizations.debugInvoke(english, key, args),
          reason: key,
        );
      }
    });

    test('remote plurals use the remote language plural rules', () {
      final state = _state(
        languages: const [_french],
        strings: {
          'fr': {
            'cvCount': '{count, plural, one{{count} CV} other{{count} CVs}}'
          },
        },
      );
      final l10n = RemoteLocalizationsDelegate.localizationsFor(
        state,
        const Locale('fr'),
      );
      // French treats 0 as "one", unlike English.
      expect(l10n.cvCount(0), '0 CV');
      expect(l10n.cvCount(1), '1 CV');
      expect(l10n.cvCount(2), '2 CVs');
    });

    test('a bundled language never shows another language remote text', () {
      final state = _state(strings: {
        'en': {for (final key in _keys.keys) key: 'EN remote'},
      });
      final l10n = RemoteLocalizationsDelegate.localizationsFor(
          state, const Locale('ar'));
      expect(
          l10n.appTitle, lookupAppLocalizations(const Locale('ar')).appTitle);
    });

    test('any language code loads; unknown ones use English bundled text', () {
      final english = lookupAppLocalizations(const Locale('en'));
      for (var i = 0; i < 100; i++) {
        final code = String.fromCharCodes(
          List.generate(2 + random.nextInt(2), (_) => 97 + random.nextInt(26)),
        );
        if (bundledLanguageCodes.contains(code)) continue;
        final l10n = RemoteLocalizationsDelegate.localizationsFor(
          RemoteL10nState.empty,
          Locale(code),
        );
        expect(l10n.appTitle, english.appTitle, reason: code);
        expect(l10n.cvCount(3), english.cvCount(3), reason: code);
      }
    });

    test('fallback chains with cycles terminate at a bundled language', () {
      final state = _state(languages: const [
        RemoteLanguage(
          code: 'xa',
          name: 'A',
          nativeName: 'A',
          direction: TextDirection.ltr,
          fallback: 'xb',
        ),
        RemoteLanguage(
          code: 'xb',
          name: 'B',
          nativeName: 'B',
          direction: TextDirection.ltr,
          fallback: 'xa',
        ),
      ]);
      expect(state.chainFor('xa'), ['xa', 'xb', 'en']);
      expect(state.baseOf('xb'), 'en');
    });
  });

  group('pumped widgets', () {
    Widget app(
      ValueNotifier<RemoteL10nState> state,
      Locale locale,
      Widget Function(BuildContext) body,
    ) =>
        ValueListenableBuilder<RemoteL10nState>(
          valueListenable: state,
          builder: (context, value, _) => MaterialApp(
            locale: locale,
            supportedLocales: appSupportedLocales(value),
            localizationsDelegates: appLocalizationsDelegates(value),
            home: Builder(builder: (context) => Scaffold(body: body(context))),
          ),
        );

    testWidgets('a remote override shows, and updates live without restart',
        (tester) async {
      final state = ValueNotifier(_state(strings: {
        'ar': {'appTitle': 'سيرتي برو'},
      }));
      await tester.pumpWidget(app(
        state,
        const Locale('ar', 'SA'),
        (context) => Text(AppLocalizations.of(context).appTitle),
      ));
      expect(find.text('سيرتي برو'), findsOneWidget);

      state.value = _state(strings: {
        'ar': {'appTitle': 'سيرتي ٢'},
      });
      await tester.pump();
      expect(find.text('سيرتي ٢'), findsOneWidget);
    });

    testWidgets('a malformed remote string shows the bundled text',
        (tester) async {
      final state = ValueNotifier(_state(strings: {
        'en': {'atsScoreLabel': 'Score {score'},
      }));
      await tester.pumpWidget(app(
        state,
        const Locale('en', 'US'),
        (context) => Text(AppLocalizations.of(context).atsScoreLabel(87)),
      ));
      expect(
        find.text(lookupAppLocalizations(const Locale('en')).atsScoreLabel(87)),
        findsOneWidget,
      );
    });

    testWidgets(
        'a language without Flutter localizations gets English material '
        'strings instead of failing', (tester) async {
      final state = ValueNotifier(_state(languages: const [_sorani]));
      await tester.pumpWidget(app(
        state,
        const Locale('ckb'),
        (context) => Text(MaterialLocalizations.of(context).okButtonLabel),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('OK'), findsOneWidget);
    });
  });

  group('SiratiApp', () {
    setUp(() {
      const channel =
          MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        null,
      );
      RemoteL10n.debugReset();
      AppLocale.resetForTest();
    });

    testWidgets(
        'a remote RTL language Flutter does not know renders right-to-left '
        'with its remote strings', (tester) async {
      final repository = RemoteL10nRepository(
        store: MemoryRemoteL10nStore(),
        client: MockClient((_) async => http.Response('', 503)),
      );
      repository.debugSetState(_state(
        languages: const [_sorani],
        strings: {
          'ckb': {'appTitle': 'سیرەتی'},
        },
      ));
      RemoteL10n.debugReset(repository);
      await RemoteL10n.loadCache();
      AppLocale.resetForTest(
        language: 'ckb',
        languages: repository.state.value.languages,
      );
      expect(AppLocale.languageCode.value, 'ckb');

      await tester.pumpWidget(const ProviderScope(child: SiratiApp()));
      await tester.pump(const Duration(milliseconds: 50));

      // onGenerateTitle reads AppLocalizations inside the app.
      expect(tester.widget<Title>(find.byType(Title)).title, 'سیرەتی');
      final element = tester.element(find.byType(Navigator).first);
      expect(Directionality.of(element), TextDirection.rtl);
      expect(Localizations.localeOf(element).languageCode, 'ckb');
    });
  });
}
