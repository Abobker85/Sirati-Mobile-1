import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../support/app_screens.dart';

Future<AppLocalizations> _pump(WidgetTester tester, CvDocument doc) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  AppLocale.languageCode.value = 'en';
  final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
  await repo.saveCv(doc);
  await tester.pumpWidget(ProviderScope(
    overrides: [cvRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: AppTheme.lightFor(arabic: false),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const CvBuilderScreen(cvId: 'cv1'),
    ),
  ));
  await tester.pumpAndSettle();
  final l = await AppLocalizations.delegate.load(const Locale('en'));
  await tester.tap(find.text(l.tabExperience).last);
  await tester.pumpAndSettle();
  return l;
}

CvDocument _doc(String start, String end) =>
    CvDocument.createEmpty(id: 'cv1', title: 'CV').copyWith(experience: [
      ExperienceEntry(
          id: 'x',
          startDate: start,
          endDate: end,
          title: const LocalizedText(en: 'T')),
    ]);

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Invariant: whenever the end date precedes the start date, the inline
  // error is visible - for several start/end pairs, typed or loaded.
  for (final pair in const [
    ['2022', '2023', '2019'],
    ['2015', '2018', '2010'],
  ]) {
    testWidgets('typing an end before start ${pair[0]}->${pair[2]} shows error',
        (tester) async {
      final l = await _pump(tester, _doc(pair[0], pair[1]));
      await tester.enterText(find.widgetWithText(TextField, pair[1]), pair[2]);
      await tester.pumpAndSettle();
      expect(find.text(l.endDateBeforeStart), findsOneWidget);
    });
  }

  testWidgets('an entry loaded with end before start shows error',
      (tester) async {
    final l = await _pump(tester, _doc('2022', '2019'));
    expect(find.text(l.endDateBeforeStart), findsOneWidget);
  });
}
