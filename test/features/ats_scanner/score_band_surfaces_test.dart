import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/recommendations_tab.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_band_style.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_tab.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

import '../../support/contrast_probe.dart';

/// Ticket 16: on the borderless grey cards, every score band keeps AA text
/// and badges on the fills it is really painted on, carries a shape cue
/// (icon) as well as colour, and every number is written in Latin digits,
/// in Arabic and English, light and dark.

/// Arabic-Indic (U+0660-0669) and extended Arabic-Indic (U+06F0-06F9).
final _easternDigits = RegExp('[٠-٩۰-۹]');

CvAnalysis _analysis(int score, List<(int, int)> criteria) =>
    CvAnalysis.fromJson({
      'keyword_source': score.isEven ? 'job_description' : 'category',
      'id': 3,
      'target_job_title': 'مهندس Backend',
      'score_total': score,
      'grade': 'B',
      'job_match': (score * 7) % 101,
      'ai_status': 'completed',
      'strengths': ['Clear summary', 'ملخص واضح'],
      'weaknesses': [
        {'title': 'Few metrics', 'suggestion': 'Quantify outcomes'},
      ],
      'keywords_found': ['PHP', 'Laravel', 'SQL'],
      'keywords_missing': ['Docker', 'Kubernetes'],
      'quick_wins': ['Add measurable outcomes', 'أضف أرقاماً'],
      'criteria': [
        for (final (i, (s, max)) in criteria.indexed)
          {'label': 'Criterion $i', 'score': s, 'max': max},
      ],
      'access': {
        'is_locked': true,
        'hidden_total': 23,
        'hidden': {
          'strengths': 12,
          'weaknesses': 4,
          'keywords_missing': 17,
          'quick_wins': 6,
        },
      },
    });

/// Every rendered string under the app, including the score ring's.
Iterable<String> _paintedStrings(WidgetTester tester) => tester.allRenderObjects
    .whereType<RenderParagraph>()
    .map((p) => p.text.toPlainText());

void _expectLatinDigits(WidgetTester tester, String label) {
  final strings = _paintedStrings(tester).toList();
  expect(strings, isNotEmpty, reason: label);
  for (final s in strings) {
    expect(_easternDigits.hasMatch(s), isFalse, reason: '"$s" ($label)');
  }
}

void main() {
  tearDown(() => AppLocale.languageCode.value = 'en');

  // Scores at both edges of every band threshold, with criteria spread over
  // every criterion band (and their edges).
  const scores = [0, 49, 50, 64, 65, 79, 80, 100];
  const criteria = [(0, 10), (5, 10), (13, 20), (7, 10), (9, 12), (10, 10)];

  for (final arabic in [false, true]) {
    for (final dark in [false, true]) {
      final label = '${arabic ? 'ar' : 'en'} ${dark ? 'dark' : 'light'}';
      testWidgets('$label: every band is AA, iconed and in Latin digits',
          (tester) async {
        AppLocale.languageCode.value = arabic ? 'ar' : 'en';
        tester.view.physicalSize = const Size(1080, 5200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final theme = dark
            ? AppTheme.darkFor(arabic: arabic)
            : AppTheme.lightFor(arabic: arabic);

        for (final score in scores) {
          final analysis = _analysis(score, criteria);
          await tester.pumpWidget(ProviderScope(
            key: UniqueKey(),
            child: MaterialApp(
              theme: theme,
              locale: Locale(arabic ? 'ar' : 'en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: AnalysisResultScreen(analysis: analysis),
            ),
          ));
          await tester.pumpAndSettle();
          final where = '$label score $score';

          // The hero sits on the page's own card fill, borderless.
          final c = tester.element(find.byType(ScoreTab)).sirati;
          final hero = tester.widget<Material>(find
              .descendant(
                of: find.byKey(ScoreTab.heroKey),
                matching: find.byType(Material),
              )
              .first);
          expect(hero.color, c.cardFill, reason: where);
          expect(hero.shape, isNull, reason: where);

          // Band: badge icon names the band, not just its colour.
          final band = ScoreBand.of(score);
          final bandIcon = tester.widget<Icon>(find.byKey(ScoreTab.bandIconKey));
          expect(bandIcon.icon, band.icon, reason: where);
          expect(bandIcon.color, band.onContainer(c), reason: where);
          expect(
            find.text(band.description(AppLocalizations.of(
              tester.element(find.byType(ScoreTab)),
            ))),
            findsOneWidget,
            reason: where,
          );

          // Every criterion chip carries its band's icon.
          final chipIcons = tester
              .widgetList<Icon>(find.byKey(ScoreTab.criterionIconKey))
              .map((i) => i.icon)
              .toList();
          expect(
            chipIcons,
            [
              for (final (s, max) in criteria)
                CriterionBand.of(criterionRatio(s, max)).icon,
            ],
            reason: where,
          );

          expectAllTextAa('$where score tab');
          expectAllIconsAa('$where score tab');
          _expectLatinDigits(tester, '$where score tab');
          expect(find.text('$score'), findsWidgets, reason: where);

          final l = AppLocalizations.of(tester.element(find.byType(ScoreTab)));
          await tester.tap(find.descendant(
            of: find.byType(AppSegmentedTabBar),
            matching: find.text(l.atsTabRecommendations),
          ));
          await tester.pumpAndSettle();
          expect(find.byType(RecommendationsTab).hitTestable(), findsOneWidget);
          expectAllTextAa('$where recommendations');
          expectAllIconsAa('$where recommendations');
          _expectLatinDigits(tester, '$where recommendations');
        }
      });
    }
  }

  test('band icons are distinct, so no band relies on colour alone', () {
    expect(ScoreBand.values.map((b) => b.icon).toSet(),
        hasLength(ScoreBand.values.length));
    expect(CriterionBand.values.map((b) => b.icon).toSet(),
        hasLength(CriterionBand.values.length));
  });
}
