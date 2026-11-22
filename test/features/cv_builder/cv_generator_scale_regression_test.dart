// Regression test from checker2's review of ticket 14: at 320x568 and text
// scales 1.5 and 2.0, keyboard open or closed, the wizard lays out every
// step without any overflow (body Column, header status row, chips).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/application/cv_draft_store.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/draft_restore_banner.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class _FakeDraftStore extends CvDraftStore {
  _FakeDraftStore(this.draft) : super(const PreferenceStore());

  SavedCvDraft? draft;
  final saves = <(CvFormData, int)>[];
  var clears = 0;

  @override
  Future<SavedCvDraft?> read({required int stepCount}) async => draft;

  @override
  Future<void> save(CvFormData data, {required int step}) async =>
      saves.add((data, step));

  @override
  Future<void> clear() async {
    clears++;
    draft = null;
  }
}

class _FakeApi extends CvApiService {}

/// A form that passes every step's validation, in the CV's own language.
CvFormData _completeForm(String language) => CvFormData(
      fullName: 'Sara Ali',
      email: 'sara@example.com',
      phone: '+966 59 189 0300',
      targetJobTitle: 'Backend Developer',
      skills: 'Laravel, PHP, MySQL',
      summary: 'Backend developer building payment APIs.',
      experience: serializeExperience(const [
        ExperienceEntry(
          title: 'Backend Developer',
          company: 'Acme',
          start: YearMonth(2020, 1),
          current: true,
          description:
              'Built and ran payment APIs serving two million requests a day '
              'for retail clients across the region.',
        ),
      ], language),
      education: serializeEducation(const [
        EducationEntry(
          degree: 'BSc Computer Science',
          institution: 'King Saud University',
          start: YearMonth(2014, 9),
          end: YearMonth(2018, 6),
        ),
      ], language),
      language: language,
    );

Future<void> _pump(
  WidgetTester tester, {
  required String language,
  required bool dark,
  SavedCvDraft? draft,
  Size size = const Size(390, 844),
  double textScale = 1,
  double keyboard = 0,
  _FakeDraftStore? store,
}) async {
  // A fresh screen each time: the wizard reads its draft once, in initState.
  await tester.pumpWidget(const SizedBox());
  AppLocale.languageCode.value = language;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final english = language == 'en';
  await tester.pumpWidget(ProviderScope(
    overrides: [
      cvApiServiceProvider.overrideWithValue(_FakeApi()),
      cvDraftStoreProvider.overrideWithValue(store ?? _FakeDraftStore(draft)),
    ],
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: !english)
          : AppTheme.lightFor(arabic: !english),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const CvGeneratorScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Opens [step] the way a user gets there with a saved draft: restore it.
Future<void> _restoreTo(WidgetTester tester) async {
  final restore = find.descendant(
      of: find.byType(DraftRestoreBanner), matching: find.byType(FilledButton));
  await tester.ensureVisible(restore);
  await tester.pumpAndSettle();
  await tester.tap(restore);
  await tester.pumpAndSettle();
}

void main() {
  // Invariant: at 320x568 with the largest common accessibility text sizes,
  // every step lays out without overflow, keyboard open or closed.
  for (final language in ['ar', 'en']) {
    for (final keyboard in [0.0, 260.0]) {
      for (final scale in [1.5, 2.0]) {
        testWidgets('$language kb=$keyboard x$scale: no overflow',
            (tester) async {
          final errors = <String>[];
          final old = FlutterError.onError;
          FlutterError.onError = (d) => errors.add(d.exceptionAsString());
          addTearDown(() => FlutterError.onError = old);
          for (var step = 0; step < 4; step++) {
            await _pump(tester,
                language: language,
                dark: false,
                draft: step == 0
                    ? null
                    : SavedCvDraft(
                        data: _completeForm(language),
                        step: step,
                        savedAt: null,
                      ),
                size: const Size(320, 568),
                textScale: scale,
                keyboard: keyboard);
            if (step > 0) await _restoreTo(tester);
            expect(errors, isEmpty, reason: 'step ${step + 1}');
          }
          FlutterError.onError = old;
        });
      }
    }
  }
}
