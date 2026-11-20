import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/presentation/settings/language_picker_sheet.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';

import '../../support/contrast_probe.dart';

const _french = RemoteLanguage(
  code: 'fr',
  name: 'French',
  nativeName: 'Français',
  direction: TextDirection.ltr,
);

Widget _app({ThemeData? theme}) {
  final state = RemoteL10nState(
    languages: AppLocale.catalog.value,
  );
  return MaterialApp(
    theme: theme ?? AppTheme.lightFor(arabic: true),
    locale: AppLocale.locale,
    supportedLocales: appSupportedLocales(state),
    localizationsDelegates: appLocalizationsDelegates(state),
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showLanguagePicker(context),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  tearDown(AppLocale.resetForTest);

  testWidgets('offline (no cached list) the picker still offers ar and en',
      (tester) async {
    AppLocale.resetForTest();
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('language-option-ar')), findsOneWidget);
    expect(find.byKey(const ValueKey('language-option-en')), findsOneWidget);
    expect(find.text(RemoteLanguage.arabic.nativeName), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('cached languages appear by native name and can be selected',
      (tester) async {
    AppLocale.resetForTest(
      languages: const RemoteLanguageList(languages: [_french]),
    );
    await tester.pumpWidget(_app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Français'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-option-fr')));
    await tester.pumpAndSettle();
    expect(AppLocale.languageCode.value, 'fr');
    expect(currentLanguageName(), 'Français');
  });
  for (final dark in [false, true]) {
    testWidgets(
        'rows are one grouped card; the current one is announced selected '
        '(${dark ? 'dark' : 'light'})', (tester) async {
      AppLocale.resetForTest(
        languages: const RemoteLanguageList(languages: [_french]),
      );
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(
        theme: dark
            ? AppTheme.darkFor(arabic: true)
            : AppTheme.lightFor(arabic: true),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final options = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('language-option-'));
      expect(options.evaluate().length, greaterThanOrEqualTo(3));
      expect(
        find.descendant(of: find.byType(AppListSection), matching: options),
        findsNWidgets(options.evaluate().length),
      );
      final current = AppLocale.languageCode.value;
      for (final e in options.evaluate()) {
        final code = (e.widget.key! as ValueKey<String>).value.split('-').last;
        final node = tester.getSemantics(find.byWidget(e.widget));
        expect(node.flagsCollection.isButton, isTrue, reason: code);
        expect(
            node.flagsCollection.isSelected == Tristate.isTrue, code == current,
            reason: code);
        expect(tester.getSize(find.byWidget(e.widget)).height,
            greaterThanOrEqualTo(AppTouchTarget.min));
      }
      expectAllTextAa('language picker ${dark ? 'dark' : 'light'}');
      handle.dispose();
    });
  }
}
