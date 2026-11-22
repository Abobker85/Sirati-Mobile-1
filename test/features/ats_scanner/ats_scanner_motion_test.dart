import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/keyword_group.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/prioritized_fixes.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_ring.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_tab.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis/analysis_form_sections.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Widget _app(
  Widget child, {
  bool english = true,
  bool reduce = false,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightFor(arabic: !english),
      locale: Locale(english ? 'en' : 'ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, inner) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: Directionality(
          textDirection: english ? TextDirection.ltr : TextDirection.rtl,
          child: inner!,
        ),
      ),
      home: Scaffold(body: child),
    ),
  );
}

CvAnalysis _sampleAnalysis() => CvAnalysis.fromJson({
      'id': 7,
      'target_job_title': 'Flutter Engineer',
      'score_total': 82,
      'grade': 'B',
      'job_match': 78,
      'ai_status': 'completed',
      'keywords_found': ['Flutter', 'Dart'],
      'keywords_missing': [
        for (var i = 0; i < 20; i++) 'Skill-$i',
      ],
      'weaknesses': [
        {
          'priority': 'high',
          'title': 'Missing quantified metrics',
          'suggestion': 'Add percentage impact to each role.',
        },
      ],
      'criteria': [
        {'key': 'keywords', 'label': 'Keywords', 'score': 8, 'max': 10},
      ],
    });

void main() {
  setUp(() => AppLocale.languageCode.value = 'en');

  group('ATS Scanner Phase 3 motion', () {
    for (final english in [true, false]) {
      testWidgets(
          'CvAnalysisScreen switches source via MotionSegmentedPill in ${english ? 'LTR' : 'RTL'}',
          (tester) async {
        AppLocale.languageCode.value = english ? 'en' : 'ar';
        await tester.pumpWidget(_app(
          const CvAnalysisScreen(),
          english: english,
        ));
        await tester.pumpAndSettle();

        expect(find.byType(OutlinedButton), findsNWidgets(2));
        expect(find.byType(UploadDropZone), findsNothing);

        await tester.tap(find.byKey(const ValueKey(AnalysisCvSource.upload)));
        await tester.pumpAndSettle();
        expect(find.byType(UploadDropZone), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey(AnalysisCvSource.saved)));
        await tester.pumpAndSettle();
        expect(find.byType(UploadDropZone), findsNothing);
      });
    }

    testWidgets('PrioritizedFixes expands/collapses fix text and respects reduce',
        (tester) async {
      const weaknesses = [
        AnalysisWeakness(
          priority: 'high',
          issue: 'Low metric density',
          fix: 'Quantify outcomes with numbers.',
        ),
      ];
      for (final reduce in [false, true]) {
        await tester.pumpWidget(_app(
          const SingleChildScrollView(
            child: PrioritizedFixes(weaknesses: weaknesses),
          ),
          reduce: reduce,
        ));
        await tester.pumpAndSettle();

        expect(find.text('Quantify outcomes with numbers.'), findsOneWidget);

        await tester.tap(find.text('Low metric density'));
        if (reduce) {
          await tester.pump();
          expect(tester.hasRunningAnimations, isFalse);
        } else {
          await tester.pumpAndSettle();
        }
        expect(find.text('Quantify outcomes with numbers.'), findsNothing);
      }
    });

    testWidgets('KeywordGroup animates expand/collapse cleanly', (tester) async {
      final keywords = [for (var i = 0; i < 22; i++) 'Keyword-$i'];
      await tester.pumpWidget(_app(
        SingleChildScrollView(
          child: KeywordGroup(
            keywords: keywords,
            found: false,
            english: true,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Keyword-17'), findsOneWidget);
      expect(find.text('Keyword-20'), findsNothing);

      final l10n =
          AppLocalizations.of(tester.element(find.byType(KeywordGroup)));
      await tester.tap(find.text(l10n.atsShowMoreCount(4)));
      await tester.pumpAndSettle();
      expect(find.text('Keyword-20'), findsOneWidget);
    });

    testWidgets('ScoreTab reveal choreography settles and snaps under reduce',
        (tester) async {
      final analysis = _sampleAnalysis();

      await tester.pumpWidget(_app(
        ScoreTab(
          analysis: analysis,
          english: true,
          revealScore: true,
          previousScore: 70,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(AnimatedScoreRing.ringKey), findsOneWidget);
      expect(find.byKey(const ValueKey('analysis-score-since-last')),
          findsOneWidget);

      await tester.pumpWidget(_app(
        ScoreTab(
          analysis: analysis,
          english: true,
          revealScore: true,
          previousScore: 70,
        ),
        reduce: true,
      ));
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byKey(const ValueKey('analysis-score-since-last')),
          findsOneWidget);
    });
  });
}
