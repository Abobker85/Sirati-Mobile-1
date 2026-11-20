import 'package:flutter/material.dart';
import 'dart:ui' show SemanticsFlag;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/recommendations_tab.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_tab.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

/// Ticket 16: the results tabs sit on the shared segmented control
/// (ticket 11). Tap and swipe stay in sync with the thumb, and under reduced
/// motion the page jumps in one frame, in both directions and both
/// reading orders.

CvAnalysis _analysis() => CvAnalysis.fromJson({
      'keyword_source': 'category',
      'id': 7,
      'target_job_title': 'Backend Developer',
      'score_total': 72,
      'grade': 'B',
      'job_match': 61,
      'ai_status': 'completed',
      'strengths': ['Clear summary'],
      'weaknesses': [
        {'title': 'Few metrics', 'suggestion': 'Quantify outcomes'},
      ],
      'keywords_found': ['PHP'],
      'keywords_missing': ['Docker'],
      'quick_wins': ['Add measurable outcomes'],
      'criteria': [
        {'label': 'Structure', 'score': 6, 'max': 10},
      ],
    });

Widget _app({required bool arabic, required bool reduceMotion}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightFor(arabic: arabic),
      locale: Locale(arabic ? 'ar' : 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: AnalysisResultScreen(analysis: _analysis()),
    ),
  );
}

List<String> _labels(WidgetTester tester) {
  final l = AppLocalizations.of(tester.element(find.byType(ScoreTab)));
  return [l.atsTabScore, l.atsTabRecommendations];
}

Finder _segment(String label) => find.descendant(
      of: find.byType(AppSegmentedTabBar),
      matching: find.text(label),
    );

Finder _page(int index) =>
    find.byType(index == 0 ? ScoreTab : RecommendationsTab).hitTestable();

/// The segment the tab bar reports as selected to assistive tech.
int _selectedSegment(WidgetTester tester, List<String> labels) {
  final selected = <int>[];
  for (var i = 0; i < labels.length; i++) {
    final data = tester.getSemantics(_segment(labels[i])).getSemanticsData();
    if (data.hasFlag(SemanticsFlag.isSelected)) selected.add(i);
  }
  expect(selected, hasLength(1), reason: 'exactly one selected segment');
  return selected.single;
}

TabController _controller(WidgetTester tester) =>
    DefaultTabController.of(tester.element(find.byType(AppSegmentedTabBar)));

void main() {
  setUp(() => AppLocale.languageCode.value = 'en');

  for (final arabic in [false, true]) {
    final lang = arabic ? 'ar (RTL)' : 'en (LTR)';

    testWidgets('$lang: the results tabs are the shared segmented control',
        (tester) async {
      AppLocale.languageCode.value = arabic ? 'ar' : 'en';
      await tester.pumpWidget(_app(arabic: arabic, reduceMotion: false));
      await tester.pumpAndSettle();

      expect(find.byType(AppSegmentedTabBar), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      final labels = _labels(tester);
      for (final label in labels) {
        expect(_segment(label), findsOneWidget);
      }
      // The first tab sits at the reading start edge.
      final score = tester.getCenter(_segment(labels[0])).dx;
      final recs = tester.getCenter(_segment(labels[1])).dx;
      expect(arabic ? score > recs : score < recs, isTrue);
    });

    testWidgets('$lang: reduced motion jumps the page in one frame, '
        'both ways', (tester) async {
      AppLocale.languageCode.value = arabic ? 'ar' : 'en';
      await tester.pumpWidget(_app(arabic: arabic, reduceMotion: true));
      await tester.pumpAndSettle();
      final labels = _labels(tester);
      expect(_controller(tester).animationDuration, Duration.zero);
      expect(_page(0), findsOneWidget);

      for (final target in [1, 0, 1, 0]) {
        await tester.tap(_segment(labels[target]));
        await tester.pump();
        expect(_controller(tester).index, target);
        expect(_page(target), findsOneWidget,
            reason: 'page $target shown one frame after the tap');
        expect(_page(1 - target), findsNothing);
        await tester.pump();
        expect(_selectedSegment(tester, labels), target);
      }
    });

    testWidgets('$lang: a tap slides to the page and the thumb follows',
        (tester) async {
      AppLocale.languageCode.value = arabic ? 'ar' : 'en';
      await tester.pumpWidget(_app(arabic: arabic, reduceMotion: false));
      await tester.pumpAndSettle();
      final labels = _labels(tester);
      expect(_controller(tester).animationDuration, isNot(Duration.zero));

      for (final target in [1, 0]) {
        await tester.tap(_segment(labels[target]));
        await tester.pumpAndSettle();
        expect(_controller(tester).index, target);
        expect(_page(target), findsOneWidget);
        expect(_selectedSegment(tester, labels), target);
      }
    });

    testWidgets('$lang: a swipe changes the tab and the selected segment',
        (tester) async {
      AppLocale.languageCode.value = arabic ? 'ar' : 'en';
      await tester.pumpWidget(_app(arabic: arabic, reduceMotion: false));
      await tester.pumpAndSettle();
      final labels = _labels(tester);
      final view = find.byType(TabBarView);
      // Next page lies toward the reading end: swipe from end to start.
      final forward = Offset(arabic ? 400 : -400, 0);

      await tester.fling(view, forward, 1500);
      await tester.pumpAndSettle();
      expect(_controller(tester).index, 1);
      expect(_page(1), findsOneWidget);
      expect(_selectedSegment(tester, labels), 1);

      await tester.fling(view, -forward, 1500);
      await tester.pumpAndSettle();
      expect(_controller(tester).index, 0);
      expect(_page(0), findsOneWidget);
      expect(_selectedSegment(tester, labels), 0);
    });
  }
}
