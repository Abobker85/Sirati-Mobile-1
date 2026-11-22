import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_tab.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  setUp(() => AppLocale.languageCode.value = 'en');

  // Invariant: the keyword summary reports the real number of missing keywords
  // (visible + hidden), for any split the server's free limit produces.
  for (final split in const [(10, 3), (10, 0), (1, 0), (7, 6), (4, 4)]) {
    final total = split.$1, visible = split.$2;
    testWidgets('locked analysis $total missing, $visible visible',
        (tester) async {
      final analysis = CvAnalysis.fromJson({
        'id': 1,
        'score_total': 60,
        'grade': 'C',
        'keywords_found': ['A', 'B'],
        'keywords_missing': [for (var i = 0; i < visible; i++) 'M$i'],
        'criteria': const [],
        'access': {
          'locked': true,
          'hidden': {'keywords_missing': total - visible},
        },
      });
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: inner!,
          ),
          home: Scaffold(body: ScoreTab(analysis: analysis, english: true)),
        ),
      ));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(ScoreTab)));
      final summary = tester
          .widget<Text>(
              find.byKey(const ValueKey('ats-result-keyword-summary')))
          .data;
      expect(summary, l.atsResultKeywordSummary(2, total));
    });
  }
}
