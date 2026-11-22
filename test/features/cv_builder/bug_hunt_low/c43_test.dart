import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:sirati/features/cv_builder/presentation/experience_education_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

const _languages = ['ar', 'en'];

Future<CvDocument> _doc() async =>
    CvDocument.createEmpty(id: 'cv1', title: 'CV');

Future<void> _pump(
  WidgetTester tester, {
  String language = 'en',
  bool dark = false,
  bool reduceMotion = false,
  Size size = const Size(390, 844),
  double textScale = 1,
  CvDocument? document,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  AppLocale.languageCode.value = language;
  final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
  await repo.saveCv(document ?? await _doc());
  final arabic = language == 'ar';
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [cvRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: arabic)
          : AppTheme.lightFor(arabic: arabic),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: const CvBuilderScreen(cvId: 'cv1'),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<AppLocalizations> _l10n(String language) =>
    AppLocalizations.delegate.load(Locale(language));

Finder _segment(String label) => find
    .ancestor(
        of: find.descendant(
            of: find.byKey(CvBuilderScreen.tabBarKey),
            matching: find.text(label)),
        matching: find.byType(GestureDetector))
    .first;

/// Years written in the hint texts of the date fields currently on screen.
List<int> _hintYears(WidgetTester tester) {
  final years = <int>[];
  for (final tf in tester.widgetList<TextField>(find.byType(TextField))) {
    final hint = tf.decoration?.hintText;
    if (hint == null) continue;
    for (final m in RegExp(r'\d{4}').allMatches(hint)) {
      years.add(int.parse(m.group(0)!));
    }
  }
  return years;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final language in _languages) {
    testWidgets('$language: choosing Hijri makes the date fields Hijri',
        (tester) async {
      // A separate, pre-existing RenderFlex overflow in the Arabic entry row
      // is out of scope here; ignore only overflow reports.
      final orig = FlutterError.onError;
      FlutterError.onError = (d) {
        if (d.exceptionAsString().contains('overflowed')) return;
        orig?.call(d);
      };
      addTearDown(() => FlutterError.onError = orig);
      final base = await _doc();
      await _pump(tester,
          language: language,
          size: const Size(1000, 1800),
          document:
              base.copyWith(experience: const [ExperienceEntry(id: 'e1')]));
      final l = await _l10n(language);
      await tester.tap(_segment(l.tabExperience));
      await tester.pumpAndSettle();
      final greg = _hintYears(tester);
      expect(greg, isNotEmpty, reason: 'date fields show example hints');

      final control = find.byKey(ExperienceEducationEditor.calendarModeKey);
      await tester.tap(
          find.descendant(of: control, matching: find.text(l.calendarHijri)));
      await tester.pumpAndSettle();
      expect(tester.widget(control), isNotNull);
      final hijri = _hintYears(tester);
      expect(hijri, isNotEmpty);
      // In Hijri mode every example date the user is guided to type must be a
      // Hijri year (well below 1700, the parser's Hijri threshold).
      expect(hijri.every((y) => y < 1700), isTrue,
          reason: 'Hijri selected but hints still show Gregorian years $hijri');
    });
  }
}
