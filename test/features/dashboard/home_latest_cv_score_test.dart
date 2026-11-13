import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/home/home_latest_cv_section.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/score_ring.dart';

const _id = 71;

class _Content extends MobileContentService {
  _Content(this.items);
  final List<Map<String, dynamic>> items;

  @override
  Future<Map<String, dynamic>> myCvs(bool english,
          {bool force = false}) async =>
      {'title': 'My CVs', 'items': items};
}

GeneratedCv _cv(Object? score) => GeneratedCv.fromJson({
      'id': _id,
      'target_job_title': 'محلل بيانات Data Analyst',
      'generated_markdown': 'خبرة Data analysis',
      'score_total': score,
      'ai_status': 'completed',
      'created_at': '2026-10-17T12:00:00Z',
    });

/// Pumps the home "latest CV" card. [row] is this CV's row in the My CVs
/// list (null: the list does not have it); [cvScore] is the score on the CV
/// itself.
Future<AppLocalizations> _pump(
  WidgetTester tester, {
  required String language,
  required Object? cvScore,
  Map<String, dynamic>? row,
}) async {
  SharedPreferences.setMockInitialValues({});
  AppLocale.languageCode.value = language;
  final arabic = language == 'ar';
  await tester.pumpWidget(ProviderScope(
    // A new scope per case, so no provider keeps the previous case's CV.
    key: UniqueKey(),
    overrides: [
      mobileContentServiceProvider
          .overrideWithValue(_Content([if (row != null) row])),
      latestDashboardCvProvider(!arabic)
          .overrideWith((ref) async => _cv(cvScore)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightFor(arabic: arabic),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeLatestCvSection(onViewAll: () {}),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(HomeLatestCvSection)));
}

void main() {
  const scores = [0, 1, 37, 60, 74, 100];
  final ring = find.byKey(HomeLatestCvSection.scoreKey);

  for (final language in ['ar', 'en']) {
    testWidgets('$language: shows the score of this CV\'s My CVs row',
        (tester) async {
      final handle = tester.ensureSemantics();
      for (final score in scores) {
        // The CV itself carries a different score: the list row wins.
        final l = await _pump(
          tester,
          language: language,
          cvScore: (score + 13) % 101,
          row: {'id': _id, 'title': 'CV', 'score_total': score},
        );
        expect(tester.widget<ScoreRing>(ring).score, score);
        expect(find.bySemanticsLabel(l.cvCardScore(score)), findsOneWidget);
        expect(find.byKey(HomeLatestCvSection.editKey), findsOneWidget);
        expect(find.byKey(HomeLatestCvSection.checkKey), findsOneWidget);
      }
      handle.dispose();
    });

    testWidgets('$language: an unscanned row shows no ring', (tester) async {
      for (final cvScore in <Object?>[null, 0, 55]) {
        await _pump(
          tester,
          language: language,
          cvScore: cvScore,
          row: {'id': _id, 'title': 'CV', 'score_total': null},
        );
        expect(ring, findsNothing);
      }
    });

    testWidgets('$language: without a list row the CV\'s own score is used',
        (tester) async {
      for (final score in scores) {
        await _pump(tester, language: language, cvScore: score);
        expect(tester.widget<ScoreRing>(ring).score, score);
      }
      for (final missing in <Object?>[null, '', 'n/a', -1, 101]) {
        await _pump(tester, language: language, cvScore: missing);
        expect(ring, findsNothing, reason: 'score_total: $missing');
      }
    });
  }
}
