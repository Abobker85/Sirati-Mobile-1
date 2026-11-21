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

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final lang in ['en', 'ar']) {
    for (final scale in [1.5, 2.0]) {
      testWidgets('$lang experience editor has no overflow at x$scale on 390pt',
          (tester) async {
        tester.view.physicalSize = const Size(390, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        AppLocale.languageCode.value = lang;
        final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
        await repo.saveCv(
            CvDocument.createEmpty(id: 'cv1', title: 'CV').copyWith(
          experience: const [
            ExperienceEntry(
                id: 'x',
                startDate: '2020',
                endDate: '2022',
                title: LocalizedText(en: 'T')),
          ],
          education: const [
            EducationEntry(
                id: 'd',
                institution: LocalizedText(en: 'U'),
                startDate: '2010',
                graduationDate: '2014'),
          ],
        ));
        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.exceptionAsString());
        try {
          await tester.pumpWidget(ProviderScope(
            overrides: [cvRepositoryProvider.overrideWithValue(repo)],
            child: MaterialApp(
              theme: AppTheme.lightFor(arabic: lang == 'ar'),
              locale: Locale(lang),
              builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(c)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const CvBuilderScreen(cvId: 'cv1'),
            ),
          ));
          await tester.pumpAndSettle();
          final l = await AppLocalizations.delegate.load(Locale(lang));
          await tester.tap(find.text(l.tabExperience).last);
          await tester.pumpAndSettle();
        } finally {
          FlutterError.onError = old;
        }
        expect(errors.where((e) => e.contains('overflowed')).toSet(), isEmpty);
      });
    }
  }
}
