import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';

CvAnalysis _analysis(List<ScoreCriterion> criteria) => CvAnalysis(
      id: 1,
      targetJobTitle: 'Engineer',
      originalFilename: null,
      inputMethod: 'paste',
      scoreTotal: 50,
      grade: 'C',
      jobMatch: 40,
      criteria: criteria,
      strengths: const [],
      weaknesses: const [],
      keywordsFound: const [],
      keywordsMissing: const [],
      quickWins: const [],
      aiStatus: AiStatus.completed,
      aiFeedback: null,
      aiError: null,
      createdAt: null,
    );

Future<void> _pump(WidgetTester tester, Locale locale, CvAnalysis a) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AnalysisResultScreen(analysis: a),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const keys = [
    'format',
    'keywords',
    'structure',
    'experience',
    'education',
    'summary',
    'contact',
  ];
  // Backend labels are Arabic-only; the app must not show them in English.
  const backendLabel = 'تسمية من الخادم';

  for (final code in ['en', 'ar']) {
    testWidgets('every known criterion key is localized for $code',
        (tester) async {
      final criteria = [
        for (final k in keys)
          ScoreCriterion(key: k, label: '$backendLabel-$k', score: 3, max: 10),
      ];
      await _pump(tester, Locale(code), _analysis(criteria));

      for (final k in keys) {
        expect(find.text('$backendLabel-$k'), findsNothing,
            reason: 'key $k must use the localized label, not the backend one');
      }
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AnalysisResultScreen)),
      );
      for (final label in [
        l10n.atsCriterionFormat,
        l10n.atsCriterionKeywords,
        l10n.atsCriterionStructure,
        l10n.atsCriterionExperience,
        l10n.atsCriterionEducation,
        l10n.atsCriterionSummary,
        l10n.atsCriterionContact,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });
  }

  testWidgets('unknown or missing key falls back to the backend label',
      (tester) async {
    await _pump(
      tester,
      const Locale('en'),
      _analysis(const [
        ScoreCriterion(
            key: 'brand_new', label: 'Server label', score: 1, max: 5),
        ScoreCriterion(label: 'Old saved label', score: 2, max: 5),
      ]),
    );
    expect(find.text('Server label'), findsOneWidget);
    expect(find.text('Old saved label'), findsOneWidget);
  });
}
