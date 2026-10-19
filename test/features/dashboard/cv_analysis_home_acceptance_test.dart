import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/application/saved_analysis_cvs.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_cv_hero.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_tab.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_tool_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

GeneratedCv cv(
  int score, {
  String status = 'completed',
  String text = 'خبرة Data analysis\nSQL أدوات البيانات',
}) => GeneratedCv.fromJson({
  'id': 71,
  'target_job_title': 'محلل بيانات Data Analyst',
  'generated_markdown': text,
  'score_total': score,
  'ai_status': status,
  'created_at': '2026-10-17T12:00:00Z',
});
CvAnalysis analysis(int score) => CvAnalysis.fromJson({
  'id': 92,
  'target_job_title': 'محلل بيانات Data Analyst',
  'score_total': score,
  'grade': 'B',
  'job_match': score,
  'ai_status': 'completed',
  'strengths': ['ملخص واضح Clear summary'],
  'quick_wins': ['أضف نتائج قابلة للقياس'],
  'weaknesses': [
    {'priority': 'low', 'issue': 'تفاصيل إضافية', 'fix': 'راجع التفاصيل'},
    {
      'priority': 'high',
      'issue': 'النتائج المهنية',
      'fix': 'اذكر نتائجك الحقيقية',
    },
  ],
  'keywords_found': ['تحليل البيانات Data analysis'],
  'keywords_missing': ['إدارة المشاريع Project management'],
  'criteria': [
    {'label': 'المهارات المهنية Skills', 'score': 7, 'max': 10},
  ],
});

class Content extends MobileContentService {
  @override
  Future<Map<String, dynamic>> dashboard(
    bool english, {
    bool force = false,
  }) async => {
    'profile': {'name': 'سارة Sara'},
  };
  @override
  Future<Map<String, dynamic>> myCvs(
    bool english, {
    bool force = false,
  }) async => {'items': []};
}

class Api extends CvApiService {
  String? submittedText;
  String? submittedJd;
  http.MultipartFile? submittedFile;
  @override
  Future<GeneratedCv> getGeneratedCv(int id) async => cv(72);
  @override
  Future<CvAnalysis> submitAnalysis({
    required String targetJobTitle,
    required String resumeText,
    String? jobDescription,
    http.MultipartFile? resumeFile,
    String? idempotencyKey,
  }) async {
    submittedText = resumeText;
    submittedJd = jobDescription;
    submittedFile = resumeFile;
    return analysis(72);
  }

  @override
  Future<PagedList<CvAnalysis>> listAnalysesPage({int page = 1}) async =>
      const PagedList(items: [], currentPage: 1, lastPage: 1);
  @override
  Future<PagedList<GeneratedCv>> listGeneratedCvsPage({int page = 1}) async =>
      const PagedList(items: [], currentPage: 1, lastPage: 1);
}

Widget app(
  Widget home, {
  required bool arabic,
  required bool dark,
  required double scale,
  GeneratedCv? latest,
  Api? api,
  AsyncValue<List<SavedAnalysisCv>>? saved,
}) {
  AppLocale.languageCode.value = arabic ? 'ar' : 'en';
  return ProviderScope(
    overrides: [
      cvApiServiceProvider.overrideWithValue(api ?? Api()),
      mobileContentServiceProvider.overrideWithValue(Content()),
      latestDashboardCvProvider(
        arabic == false,
      ).overrideWith((ref) async => latest),
      analysisSavedCvsProvider(arabic == false).overrideWith((ref) async => []),
    ],
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: arabic)
          : AppTheme.lightFor(arabic: arabic),
      locale: Locale(arabic ? 'ar' : 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: home,
    ),
  );
}

Future<void> checkScroll(WidgetTester tester, String label) async {
  for (var i = 0; i < 18; i++) {
    expect(tester.takeException(), isNull, reason: label);
    expectAllTextAa(label);
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().isEmpty) break;
    final position = tester.state<ScrollableState>(scrollables.first).position;
    if (position.pixels >= position.maxScrollExtent) break;
    await tester.drag(scrollables.first, const Offset(0, -430));
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull, reason: label);
}

void main() {
  for (final arabic in [true, false]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        final label = 'ar=$arabic dark=$dark scale=$scale';
        testWidgets('input sources, visible JD, contrast and layout $label', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(390, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final source in AnalysisCvSource.values) {
            await tester.pumpWidget(
              app(
                const CvAnalysisScreen(savedCvs: AsyncData([])),
                arabic: arabic,
                dark: dark,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.byKey(ValueKey(source)));
            await tester.tap(find.byKey(ValueKey(source)));
            await tester.pumpAndSettle();
            await checkScroll(tester, '$label $source');
            expect(
              find.byKey(const ValueKey('ats-input-job-description')),
              findsOneWidget,
            );
            await tester.pumpWidget(const SizedBox());
          }
        });
        testWidgets('result bands, recommendations and chips $label', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(390, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final score in [0, 49, 50, 64, 65, 79, 80, 100]) {
            await tester.pumpWidget(
              app(
                AnalysisResultScreen(analysis: analysis(score)),
                arabic: arabic,
                dark: dark,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            await checkScroll(tester, '$label score=$score');
            expect(find.byType(Checkbox), findsNothing);
            await tester.pumpWidget(const SizedBox());
          }
        });
        testWidgets(
          'home first, returning, pending states and compact tools $label',
          (tester) async {
            tester.view.physicalSize = const Size(390, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            for (final latest in [
              null,
              cv(72),
              cv(91),
              cv(0, status: 'queued'),
            ]) {
              await tester.pumpWidget(
                app(
                  Scaffold(body: DashboardHomeTab(onNavigate: (_) {})),
                  arabic: arabic,
                  dark: dark,
                  scale: scale,
                  latest: latest,
                ),
              );
              await tester.pumpAndSettle();
              await checkScroll(tester, '$label home=${latest?.scoreTotal}');
              expect(find.byType(DashboardToolCard), findsNWidgets(2));
              await tester.pumpWidget(const SizedBox());
            }
          },
        );
      }
    }
  }
  testWidgets('saved CV markdown and JD reach analysis result without upload', (
    tester,
  ) async {
    final api = Api();
    await tester.pumpWidget(
      app(
        const CvAnalysisScreen(
          savedCvs: AsyncData([
            SavedAnalysisCv(id: 71, title: 'محلل بيانات Data Analyst'),
          ]),
        ),
        arabic: true,
        dark: true,
        scale: 1,
        api: api,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('ats-input-job-title')));
    await tester.enterText(
      find.byKey(const ValueKey('ats-input-job-title')),
      'محلل بيانات Data Analyst',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('ats-input-job-description')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('ats-input-job-description')),
      'متطلبات SQL إدارة البيانات',
    );
    final submit = find.widgetWithText(ElevatedButton, 'تحليل السيرة الذاتية');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    for (
      var i = 0;
      i < 30 && find.byType(AnalysisResultScreen).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(api.submittedText, cv(72).generatedMarkdown);
    expect(api.submittedJd, 'متطلبات SQL إدارة البيانات');
    expect(api.submittedFile, isNull);
    expect(find.byType(AnalysisResultScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
    'new semantic pairs have strict text and non-text contrast in both modes',
    () {
      for (final c in [SiratiColors.light, SiratiColors.dark]) {
        for (final bg in [c.surface, c.background]) {
          for (final fg in [c.textPrimary, c.textSecondary, c.primaryInk]) {
            expect(AppContrast.ratio(fg, bg), greaterThanOrEqualTo(4.5));
          }
          expect(
            AppContrast.ratio(c.textSecondary, bg),
            greaterThanOrEqualTo(3),
          );
        }
        expect(
          AppContrast.ratio(c.primaryInk, c.primaryLight),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          AppContrast.ratio(c.onPrimary, c.primary),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}
