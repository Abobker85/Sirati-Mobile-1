import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/generated/app_localizations_ar.dart';
import 'package:sirati/l10n/generated/app_localizations_en.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Server contract for `GET /api/cv-analyses` (issues #16, #20).
Map<String, dynamic> _json({
  String? source = 'category',
  Object? jobMatch,
  Object? access,
  String? category = 'general',
  String? labelAr,
  String? labelEn,
}) =>
    {
      'id': 1,
      'target_job_title': 'Backend Developer',
      'score_total': 72,
      'grade': 'B',
      'job_match': jobMatch,
      'keyword_source': source,
      'category': category,
      'category_label': labelAr,
      'category_label_en': labelEn,
      'ai_status': 'completed',
      'strengths': const ['Clear summary'],
      'weaknesses': const [
        {'priority': 'high', 'issue': 'Few metrics', 'fix': 'Quantify'},
      ],
      'keywords_found': const ['PHP'],
      'keywords_missing': const ['Docker'],
      'quick_wins': const ['Add outcomes'],
      'criteria': const [],
      if (access != null) 'access': access,
    };

Widget _app(CvAnalysis analysis) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: AnalysisResultScreen(analysis: analysis),
      ),
    );

Future<void> _pump(WidgetTester tester, CvAnalysis analysis) async {
  tester.view.physicalSize = const Size(1080, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(analysis));
  await tester.pump(const Duration(seconds: 2));
}

final _arabic = RegExp(r'[؀-ۿ]');

void main() {
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsAr();
  setUp(() => AppLocale.languageCode.value = 'en');

  group('job match exists only with a job description', () {
    const percentages = [0, 1, 37, 50, 99, 100];

    test('any category-sourced value is not a job match', () {
      for (final source in ['category', null, '', 'something_else']) {
        for (final value in [...percentages, '64', null]) {
          final a = CvAnalysis.fromJson(_json(source: source, jobMatch: value));
          expect(a.hasJobMatch, isFalse, reason: '$source / $value');
        }
      }
    });

    test('a job-description value in range is a job match', () {
      for (final value in percentages) {
        final a = CvAnalysis.fromJson(
            _json(source: 'job_description', jobMatch: value));
        expect(a.hasJobMatch, isTrue, reason: '$value');
        expect(a.jobMatch, value);
      }
      for (final value in [null, -1, 101, 'abc']) {
        final a = CvAnalysis.fromJson(
            _json(source: 'job_description', jobMatch: value));
        expect(a.hasJobMatch, isFalse, reason: '$value');
      }
    });

    testWidgets('score tab hides job match without a job description',
        (tester) async {
      await _pump(tester, CvAnalysis.fromJson(_json(jobMatch: 55)));
      expect(find.text('55%'), findsNothing);
      expect(find.text(en.atsJobMatchPercentage), findsNothing);
    });

    testWidgets('score tab shows job match with a job description',
        (tester) async {
      await _pump(
        tester,
        CvAnalysis.fromJson(_json(source: 'job_description', jobMatch: 55)),
      );
      expect(find.text('55%'), findsOneWidget);
      expect(find.text(en.atsJobMatchPercentage), findsOneWidget);
    });
  });

  group('hidden-item counts from the server access block', () {
    Map<String, dynamic> access(Map<String, Object?> hidden) => {
          'is_locked': true,
          'hidden_total': 0,
          'hidden': hidden,
        };

    test('parses each count and treats junk as zero', () {
      final a = CvAnalysis.fromJson(_json(
        access: access({
          'strengths': 3,
          'weaknesses': '4',
          'keywords_missing': 5.0,
          'quick_wins': -2,
          'ai_feedback': 'x',
        }),
      ));
      expect(a.hidden.strengths, 3);
      expect(a.hidden.weaknesses, 4);
      expect(a.hidden.keywordsMissing, 5);
      expect(a.hidden.quickWins, 0);
      expect(a.hidden.aiFeedback, 0);

      for (final raw in [null, 'locked', 7, const <String, dynamic>{}]) {
        final none = CvAnalysis.fromJson(_json(access: raw));
        expect(none.hidden.strengths, 0);
        expect(none.hidden.weaknesses, 0);
        expect(none.hidden.keywordsMissing, 0);
        expect(none.hidden.quickWins, 0);
      }
    });

    testWidgets('result screen shows "N more" for every trimmed list',
        (tester) async {
      await _pump(
        tester,
        CvAnalysis.fromJson(_json(
          access: access({
            'strengths': 3,
            'weaknesses': 4,
            'keywords_missing': 5,
            'quick_wins': 6,
          }),
        )),
      );
      expect(find.text(en.atsHiddenMore(5)), findsOneWidget);

      await tester.tap(find.byType(Tab).at(1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      for (final n in [3, 4, 6]) {
        expect(find.text(en.atsHiddenMore(n)), findsOneWidget, reason: '$n');
      }
    });

    testWidgets('hidden items show even when the visible list is empty',
        (tester) async {
      final json = _json(access: access({'strengths': 2, 'weaknesses': 7}))
        ..['strengths'] = const []
        ..['weaknesses'] = const [];
      await _pump(tester, CvAnalysis.fromJson(json));
      await tester.tap(find.byType(Tab).at(1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(en.atsHiddenMore(2)), findsOneWidget);
      expect(find.text(en.atsHiddenMore(7)), findsOneWidget);
      expect(find.text(en.atsNoStrengths), findsNothing);
    });

    testWidgets('nothing extra when the server hides nothing', (tester) async {
      await _pump(
        tester,
        CvAnalysis.fromJson(_json(
          access: {'is_locked': false, 'hidden_total': 0, 'hidden': {}},
        )),
      );
      for (final tab in [0, 1]) {
        await tester.tap(find.byType(Tab).at(tab));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        for (var n = 0; n <= 10; n++) {
          expect(find.text(en.atsHiddenMore(n)), findsNothing);
        }
      }
    });
  });

  group('category label comes from the server or the catalog', () {
    test('server labels win in their language', () {
      final a = CvAnalysis.fromJson(
          _json(category: 'it', labelAr: 'تقنية المعلومات', labelEn: 'IT'));
      expect(a.displayCategoryLabel(en, english: true), 'IT');
      expect(a.displayCategoryLabel(ar, english: false), 'تقنية المعلومات');
    });

    test('general profile without a server label uses the catalog', () {
      for (final category in ['general', null]) {
        final a = CvAnalysis.fromJson(_json(category: category));
        expect(
            a.displayCategoryLabel(en, english: true), en.atsCategoryGeneral);
        expect(
            a.displayCategoryLabel(ar, english: false), ar.atsCategoryGeneral);
      }
    });

    test('an unlabelled category is never shown as its raw key', () {
      for (final category in ['it', 'ecommerce', 'nursing']) {
        final a = CvAnalysis.fromJson(_json(category: category));
        expect(a.displayCategoryLabel(en, english: true), isNull);
        expect(a.displayCategoryLabel(ar, english: false), isNull);
      }
    });

    test('English never falls back to an Arabic server label', () {
      final a = CvAnalysis.fromJson(
          _json(category: 'it', labelAr: 'تقنية المعلومات'));
      final label = a.displayCategoryLabel(en, english: true);
      expect(label == null || !_arabic.hasMatch(label), isTrue);
    });

    testWidgets('benchmark row is hidden when there is no label',
        (tester) async {
      await _pump(tester, CvAnalysis.fromJson(_json(category: 'it')));
      expect(find.text(en.atsBenchmark('it')), findsNothing);
    });
  });
}
