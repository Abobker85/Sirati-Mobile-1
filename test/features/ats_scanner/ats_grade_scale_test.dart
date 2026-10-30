import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/dashboard/presentation/history/history_cards.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/generated/app_localizations_en.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// The server's grade floors, highest first
/// (`AtsScoringService::GRADE_THRESHOLDS`, documented on issue #16).
const _serverFloors = [
  ('A+', 90),
  ('A', 80),
  ('B', 70),
  ('C', 60),
  ('D', 50),
  ('F', 0),
];

String _serverGrade(int score) =>
    _serverFloors.firstWhere((g) => score >= g.$2, orElse: () => ('F', 0)).$1;

/// Product mapping from grade to the band copy and colours.
ScoreBand _expectedBand(String grade) => switch (grade) {
      'A+' || 'A' => ScoreBand.excellent,
      'B' => ScoreBand.veryGood,
      'C' => ScoreBand.fair,
      _ => ScoreBand.weak,
    };

CvAnalysis _analysis(int score, {String grade = 'B'}) => CvAnalysis.fromJson({
      'id': 1,
      'target_job_title': 'Backend Developer',
      'score_total': score,
      // Deliberately stale: the screen must follow the one scale, not a
      // grade stored under older thresholds.
      'grade': grade,
      'job_match': null,
      'keyword_source': 'category',
      'ai_status': 'completed',
      'strengths': const [],
      'weaknesses': const [],
      'keywords_found': const ['PHP'],
      'keywords_missing': const ['Docker'],
      'quick_wins': const [],
      'criteria': const [],
    });

Widget _app(Widget home) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: home,
      ),
    );

void main() {
  final l = AppLocalizationsEn();
  setUp(() => AppLocale.languageCode.value = 'en');

  group('one grade scale equal to the server', () {
    test('AtsGrade.of matches the server grade for every score 0-100', () {
      for (var s = 0; s <= 100; s++) {
        expect(AtsGrade.of(s).label, _serverGrade(s), reason: 'score $s');
      }
    });

    test('out-of-range scores clamp to the end grades', () {
      for (final s in [-50, -1]) {
        expect(AtsGrade.of(s).label, 'F');
      }
      for (final s in [101, 250]) {
        expect(AtsGrade.of(s).label, 'A+');
      }
    });

    test('ScoreBand.of follows the grade for every score 0-100', () {
      for (var s = 0; s <= 100; s++) {
        expect(ScoreBand.of(s), _expectedBand(_serverGrade(s)),
            reason: 'score $s');
      }
    });
  });

  testWidgets('ATS score tab shows grade and band from one scale (0-100)',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (var s = 0; s <= 100; s++) {
      await tester.pumpWidget(_app(AnalysisResultScreen(
        analysis: _analysis(s),
        key: ValueKey(s),
      )));
      await tester.pump(const Duration(seconds: 2));
      final grade = _serverGrade(s);
      expect(find.text(l.atsGradeLabel(grade)), findsOneWidget,
          reason: 'score $s');
      final band = _expectedBand(grade);
      final description = switch (band) {
        ScoreBand.excellent => l.atsBandExcellent,
        ScoreBand.veryGood => l.atsBandVeryGood,
        ScoreBand.fair => l.atsBandFair,
        ScoreBand.weak => l.atsBandWeak,
      };
      expect(find.text(description), findsOneWidget, reason: 'score $s');
    }
  });

  testWidgets('My CVs ring and warning follow the same scale (0-100)',
      (tester) async {
    for (var s = 0; s <= 100; s++) {
      await tester.pumpWidget(_app(Scaffold(
        body: ListView(children: [
          CvDocumentCard(
            key: ValueKey(s),
            item: CvListItem.fromJson({
              'id': 1,
              'title': 'Backend Developer CV',
              'is_draft': false,
              'score_total': s,
              'updated_label': '2 days ago',
            }),
            onOpen: () {},
            onEdit: () {},
            onDelete: () {},
            onDownload: () {},
            onScan: () {},
          ),
        ]),
      )));
      final colors = tester.element(find.byType(CvDocumentCard)).sirati;
      final band = _expectedBand(_serverGrade(s));
      final ring = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator));
      final expected = switch (band) {
        ScoreBand.excellent || ScoreBand.veryGood => colors.success,
        ScoreBand.fair => colors.warning,
        ScoreBand.weak => colors.error,
      };
      expect(ring.color, expected, reason: 'score $s');
      expect(find.text(l.cvCardNeedsWork),
          band == ScoreBand.weak ? findsOneWidget : findsNothing,
          reason: 'score $s');
    }
  });

  testWidgets('history score badge shows the scale grade (0-100)',
      (tester) async {
    for (var s = 0; s <= 100; s++) {
      await tester.pumpWidget(_app(Scaffold(
        body: ScoreBadge(key: ValueKey(s), score: s),
      )));
      expect(find.text(_serverGrade(s)), findsOneWidget, reason: 'score $s');
    }
  });
}
