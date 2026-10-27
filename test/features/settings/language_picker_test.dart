import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/l10n/remote_l10n_repository.dart';
import 'package:sirati/core/l10n/remote_localizations_delegate.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/presentation/settings/language_picker_sheet.dart';
import 'package:sirati/shared/theme/app_theme.dart';

const _french = RemoteLanguage(
  code: 'fr',
  name: 'French',
  nativeName: 'Français',
  direction: TextDirection.ltr,
);

Widget _app() {
  final state = RemoteL10nState(
    languages: AppLocale.catalog.value,
  );
  return MaterialApp(
    theme: AppTheme.lightFor(arabic: true),
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
}
