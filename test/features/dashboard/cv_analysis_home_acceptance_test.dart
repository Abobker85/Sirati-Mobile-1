import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/application/saved_analysis_cvs.dart';
import 'package:sirati/features/ats_scanner/domain/analysis_draft.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/prioritized_fixes.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_header.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_tab.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_jobs_section.dart';
import 'package:sirati/features/dashboard/presentation/home/home_latest_cv_section.dart';
import 'package:sirati/features/dashboard/presentation/home/home_pressable_card.dart';
import 'package:sirati/features/dashboard/presentation/home/home_service_tile.dart';
import 'package:sirati/features/dashboard/presentation/home/home_start_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/animated_ats_score_bar.dart';

import '../../support/contrast_probe.dart';

GeneratedCv cv(
  int score, {
  int id = 71,
  String status = 'completed',
  String text = 'خبرة Data analysis\nSQL أدوات البيانات',
}) =>
    GeneratedCv.fromJson({
      'id': id,
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

/// More jobs than Home shows, so the section's limit is exercised.
const homeJobTitles = [
  'Web developer مطور ويب',
  'HR specialist أخصائي موارد بشرية',
  'Accountant محاسب',
  'Data engineer مهندس بيانات',
];

class Content extends MobileContentService {
  Content({this.latest, this.rows});
  final GeneratedCv? latest;
  final List<Map<String, dynamic>>? rows;
  @override
  Future<Map<String, dynamic>> dashboard(
    bool english, {
    bool force = false,
  }) async =>
      {
        'profile': {'name': 'سارة Sara'},
        'stats': {'generated_cvs': 17, 'analyses': 23},
        'primary_action': {
          'title': 'Build your professional CV ابنِ سيرتك',
          'subtitle': 'Server action description وصف الإجراء',
          'button_label': 'Create now ابدأ الآن',
        },
        'latest_news': {
          'title': 'Career workshop ورشة مهنية',
          'subtitle': 'Registration opens tomorrow يبدأ التسجيل غداً',
        },
      };
  @override
  Future<Map<String, dynamic>> jobNews(
    bool english, {
    String? category,
    String? preset,
    String? city,
    String? region,
    int? jobTitleId,
    bool? isRemote,
    bool? isVerified,
    String? sourceType,
    String? employmentType,
    String? query,
    bool force = false,
  }) async =>
      {
        'items': [
          for (final (i, title) in homeJobTitles.indexed)
            {'id': 500 + i, 'title': title, 'company': 'Company $i شركة'},
        ],
      };

  @override
  Future<Map<String, dynamic>> myCvs(
    bool english, {
    bool force = false,
  }) async =>
      {
        'items': rows ??
            [
              if (latest != null) ...[
                {
                  'id': 13,
                  'title': 'Older Research Engineer مهندس أبحاث',
                  'updated_at': '2026-08-01T09:00:00Z',
                },
                {
                  'id': latest!.id,
                  'title': latest!.targetJobTitle,
                  'updated_at': '2026-10-19T12:00:00Z',
                },
                {
                  'id': 29,
                  'title': 'Previous Product Designer مصمم منتجات',
                  'updated_at': '2026-09-03T09:00:00Z',
                },
              ],
            ],
      };
}

class Api extends CvApiService {
  Api({this.latest});
  final GeneratedCv? latest;
  String? submittedText;
  String? submittedJd;
  http.MultipartFile? submittedFile;
  final fetchedCvIds = <int>[];
  int get savedCvFetches => fetchedCvIds.length;
  @override
  Future<GeneratedCv> getGeneratedCv(int id) async {
    fetchedCvIds.add(id);
    return latest?.id == id
        ? latest!
        : cv(72, id: id, text: 'CV $id SQL خبرة مهنية');
  }

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
      PagedList(items: [analysis(63)], currentPage: 1, lastPage: 1);
  @override
  Future<PagedList<GeneratedCv>> listGeneratedCvsPage({int page = 1}) async =>
      PagedList(
        items: [cv(58, id: 13), if (latest != null) latest!],
        currentPage: 1,
        lastPage: 1,
      );
}

Widget app(
  Widget home, {
  required bool arabic,
  required bool dark,
  required double scale,
  GeneratedCv? latest,
  Api? api,
  Content? content,
}) {
  AppLocale.languageCode.value = arabic ? 'ar' : 'en';
  return ProviderScope(
    overrides: [
      cvApiServiceProvider.overrideWithValue(api ?? Api(latest: latest)),
      mobileContentServiceProvider.overrideWithValue(
        content ?? Content(latest: latest),
      ),
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
      routes: {
        AppRoutes.createCv: (_) =>
            const Scaffold(body: Text('CV builder destination')),
      },
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text('route ${settings.name}')),
      ),
      home: home,
    ),
  );
}

Future<void> checkScroll(WidgetTester tester, String label) async {
  for (var i = 0; i < 60; i++) {
    expect(tester.takeException(), isNull, reason: label);
    expectAllTextAa(label);
    expectRenderedControls(tester, label);
    final scrollables = find.byWidgetPredicate(
      (w) =>
          w is Scrollable &&
          axisDirectionToAxis(w.axisDirection) == Axis.vertical,
    );
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
                const CvAnalysisScreen(),
                arabic: arabic,
                dark: dark,
                scale: scale,
                latest: cv(72),
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
            expect(find.byType(Tab), findsNWidgets(2));
            await checkScroll(tester, '$label score=$score');
            final keywordSummary = find.byKey(
              const ValueKey('ats-result-keyword-summary'),
            );
            await tester.scrollUntilVisible(
              keywordSummary,
              -300,
              scrollable: verticalScroll(),
            );
            await tester.pumpAndSettle();
            final l = AppLocalizations.of(
              tester.element(find.byType(AnalysisResultScreen)),
            );
            expect(
              tester.widget<Text>(keywordSummary).data,
              l.atsResultKeywordSummary(
                analysis(score).keywordsFound.length,
                analysis(score).keywordsMissing.length,
              ),
            );
            await tester.ensureVisible(find.byType(Tab).last);
            await tester.tap(find.byType(Tab).last);
            await tester.pumpAndSettle();
            await checkScroll(tester, '$label recommendations=$score');
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

              await tester.pumpWidget(const SizedBox());
            }
          },
        );
      }
    }
  }
  testWidgets('service tiles share one width, and one height side by side', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var sideBySide = 0;
    for (final arabic in [true, false]) {
      for (final width in [320.0, 360.0, 375.0, 390.0, 430.0, 768.0]) {
        for (final scale in [1.0, 1.3, 2.0]) {
          final label = 'arabic=$arabic width=$width scale=$scale';
          tester.view.physicalSize = Size(width, 2400);
          await tester.pumpWidget(
            app(
              Scaffold(body: DashboardHomeTab(onNavigate: (_) {})),
              arabic: arabic,
              dark: false,
              scale: scale,
            ),
          );
          await tester.pumpAndSettle();
          final tiles = find.byType(HomeServiceTile);
          await tester.scrollUntilVisible(
            tiles.last,
            300,
            scrollable: verticalScroll(),
          );
          await tester.pumpAndSettle();
          expect(tiles, findsNWidgets(3), reason: label);
          final rects = [
            for (final e in tiles.evaluate())
              tester.getRect(find.byWidget(e.widget))
          ];
          for (final r in rects.skip(1)) {
            expect(r.width, rects.first.width, reason: label);
          }
          if (rects[1].top < rects[0].bottom) {
            sideBySide++;
            for (final r in rects.skip(1)) {
              expect(r.top, rects.first.top, reason: label);
              expect(r.height, rects.first.height, reason: label);
            }
          } else {
            for (final r in rects.skip(1)) {
              expect(r.left, rects.first.left, reason: label);
            }
          }
          expect(tester.takeException(), isNull, reason: label);
          await tester.pumpWidget(const SizedBox());
        }
      }
    }
    expect(sideBySide, greaterThan(0), reason: 'row layout was exercised');
  });
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('ats-input-job-title')),
    );
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
    for (var i = 0;
        i < 30 && find.byType(AnalysisResultScreen).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(api.submittedText,
        cv(72, id: 71, text: 'CV 71 SQL خبرة مهنية').resumeText);
    expect(api.submittedJd, 'متطلبات SQL إدارة البيانات');
    expect(api.submittedFile, isNull);
    expect(find.byType(AnalysisResultScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  const markdowns = {
    'Arabic': '# الخبرات\n\n- تطوير الأنظمة وتحليل البيانات\n- إدارة المشاريع',
    'Latin': '# Experience\n\n- Platform engineering\n- SQL and C++\n',
    'mixed multiline':
        '  ## الخبرات Experience\n\n**مهندسة Systems**\n- C++ / SQL\n\n',
  };
  const savedRows = AsyncData([
    SavedAnalysisCv(id: 83, title: 'Another CV'),
    SavedAnalysisCv(id: 71, title: 'Selected CV'),
  ]);
  for (final entry in markdowns.entries) {
    testWidgets(
      'hub markdown reaches the analysis without a saved-CV refetch (${entry.key})',
      (tester) async {
        final api = Api(latest: cv(72, text: 'Stale server version'));
        await tester.pumpWidget(app(
          CvAnalysisScreen(
            initialCvId: 71,
            initialMarkdown: entry.value,
            savedCvs: savedRows,
          ),
          arabic: true,
          dark: true,
          scale: 1,
          api: api,
        ));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<DropdownButtonFormField<int>>(
                    find.byType(DropdownButtonFormField<int>))
                .initialValue,
            71);
        expect(api.savedCvFetches, 0);
        await submitSavedAnalysis(tester);
        expect(api.submittedText, entry.value);
        expect(api.submittedFile, isNull);
        expect(api.savedCvFetches, 0);
        expect(find.byType(AnalysisResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    for (final seed in [null, '', ' \t\n ']) {
      final label = seed == null
          ? 'only initialCvId'
          : seed.isEmpty
              ? 'empty hub markdown'
              : 'blank hub markdown';
      testWidgets('$label falls back to the fetched saved CV (${entry.key})',
          (tester) async {
        final api = Api(latest: cv(72, text: entry.value));
        await tester.pumpWidget(app(
          CvAnalysisScreen(
              initialCvId: 71, initialMarkdown: seed, savedCvs: savedRows),
          arabic: false,
          dark: false,
          scale: 1,
          api: api,
        ));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<DropdownButtonFormField<int>>(
                    find.byType(DropdownButtonFormField<int>))
                .initialValue,
            71);
        await submitSavedAnalysis(tester);
        expect(api.submittedText, api.latest!.resumeText);
        expect(api.submittedFile, isNull);
        expect(api.savedCvFetches, greaterThanOrEqualTo(1));
        expect(api.fetchedCvIds, everyElement(71));
        expect(find.byType(AnalysisResultScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
        'changing the selected CV stops using hub markdown (${entry.key})',
        (tester) async {
      final api = Api();
      await tester.pumpWidget(app(
        CvAnalysisScreen(
            initialCvId: 71, initialMarkdown: entry.value, savedCvs: savedRows),
        arabic: false,
        dark: false,
        scale: 1,
        api: api,
      ));
      await tester.pumpAndSettle();
      expect(api.savedCvFetches, 0);
      final dropdown = find.byType(DropdownButtonFormField<int>);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Another CV').last);
      await tester.pumpAndSettle();
      expect(tester.widget<DropdownButtonFormField<int>>(dropdown).initialValue,
          83);
      await submitSavedAnalysis(tester);
      expect(api.submittedText,
          cv(72, id: 83, text: 'CV 83 SQL خبرة مهنية').resumeText);
      expect(api.fetchedCvIds, isNotEmpty);
      expect(api.fetchedCvIds, everyElement(83));
      expect(find.byType(AnalysisResultScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'carried markdown cannot bypass a missing saved CV (${entry.key})',
        (tester) async {
      final api = Api();
      await tester.pumpWidget(app(
        CvAnalysisScreen(
            initialCvId: 999,
            initialMarkdown: entry.value,
            savedCvs: savedRows),
        arabic: false,
        dark: false,
        scale: 1,
        api: api,
      ));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<DropdownButtonFormField<int>>(
                  find.byType(DropdownButtonFormField<int>))
              .initialValue,
          isNull);
      await tester
          .ensureVisible(find.byKey(const ValueKey('ats-input-job-title')));
      await tester.enterText(
          find.byKey(const ValueKey('ats-input-job-title')), 'Engineer');
      await tester.tap(find.byKey(const ValueKey('ats-input-docked-analyze')));
      await tester.pumpAndSettle();
      expect(api.submittedText, isNull);
      expect(api.savedCvFetches, 0);
      expect(find.byType(AnalysisResultScreen), findsNothing);
      final l =
          AppLocalizations.of(tester.element(find.byType(CvAnalysisScreen)));
      expect(find.text(l.atsInputSelectSourceRequired), findsOneWidget);
    });
  }
  additionalTests();
}

Future<void> submitSavedAnalysis(WidgetTester tester) async {
  final title = find.byKey(const ValueKey('ats-input-job-title'));
  final description = find.byKey(const ValueKey('ats-input-job-description'));
  await tester.ensureVisible(title);
  await tester.enterText(title, 'مهندس نظم Systems Engineer');
  await tester.ensureVisible(description);
  await tester.enterText(description, 'SQL وتطوير الأنظمة');
  await tester.tap(find.byKey(const ValueKey('ats-input-docked-analyze')));
  for (var i = 0;
      i < 30 && find.byType(AnalysisResultScreen).evaluate().isEmpty;
      i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Finder verticalScroll() => find
    .byWidgetPredicate(
      (w) =>
          w is Scrollable &&
          axisDirectionToAxis(w.axisDirection) == Axis.vertical,
    )
    .first;

void expectRenderedControls(WidgetTester tester, String label) {
  void contrast(Color foreground, Element element, {Color? background}) {
    for (final bg
        in background == null ? paintedBackgroundsOf(element) : [background]) {
      expect(
        AppContrast.ratio(Color.alphaBlend(foreground, bg), bg),
        greaterThanOrEqualTo(3),
        reason: '$label ${element.widget} on $bg',
      );
    }
  }

  for (final element in find.byType(Icon).evaluate()) {
    final icon = element.widget as Icon;
    final color = icon.color ?? IconTheme.of(element).color!;
    contrast(
      color.withValues(alpha: color.a * (IconTheme.of(element).opacity ?? 1)),
      element,
    );
  }
  for (final element in find.byType(InputDecorator).evaluate()) {
    final input = element.widget as InputDecorator;
    final border = input.isFocused
        ? input.decoration.focusedBorder
        : input.decoration.enabledBorder;
    if (border != null && border.borderSide.style != BorderStyle.none) {
      contrast(
        border.borderSide.color,
        element,
        background: input.decoration.fillColor,
      );
      contrast(border.borderSide.color, element);
    }
  }
  for (final element in find.byType(CircularProgressIndicator).evaluate()) {
    final ring = element.widget as CircularProgressIndicator;
    final color = ring.valueColor?.value ?? ring.color;
    if (color != null) {
      contrast(color, element);
      if (ring.backgroundColor != null) {
        contrast(color, element, background: ring.backgroundColor);
      }
    }
  }
  for (final bar in find.byType(AnimatedAtsScoreBar).evaluate()) {
    final boxes = find
        .descendant(
          of: find.byWidget(bar.widget),
          matching: find.byType(ColoredBox),
        )
        .evaluate()
        .toList();
    expect(boxes.length, 2);
    final track = (boxes[0].widget as ColoredBox).color;
    final fill = (boxes[1].widget as ColoredBox).color;
    contrast(fill, boxes[1], background: track);
    contrast(fill, bar);
  }
  for (final button in find.byType(OutlinedButton).evaluate()) {
    final material = find
        .descendant(
          of: find.byWidget(button.widget),
          matching: find.byType(Material),
        )
        .evaluate()
        .first;
    final widget = material.widget as Material;
    contrast(
      (widget.shape! as OutlinedBorder).side.color,
      material,
      background: widget.color,
    );
  }
  for (final element in find
      .byWidgetPredicate(
        (w) =>
            w is ButtonStyleButton ||
            w is HomePressableCard ||
            w is ListTile && w.onTap != null ||
            w is Tab,
      )
      .evaluate()) {
    final box = element.findRenderObject();
    if (box is! RenderBox || !box.hasSize) continue;
    expect(
      box.size.width,
      greaterThanOrEqualTo(48),
      reason: '$label width ${element.widget}',
    );
    expect(
      box.size.height,
      greaterThanOrEqualTo(48),
      reason: '$label height ${element.widget}',
    );
  }
}

void additionalTests() {
  test('latest CV selection is independent of service ordering', () async {
    final records = [
      {'id': 431, 'title': 'QA Engineer', 'updated_at': '2026-07-04T08:30:00Z'},
      {
        'id': 27,
        'title': 'مهندس Research Engineer',
        'updated_at': '2026-10-19T15:00:00+03:00',
      },
      {
        'id': 902,
        'title': 'Product designer مصمم',
        'updated_at': '2026-09-18T11:59:00Z',
      },
    ];
    for (final order in [
      [0, 1, 2],
      [0, 2, 1],
      [1, 0, 2],
      [1, 2, 0],
      [2, 0, 1],
      [2, 1, 0],
    ]) {
      final container = ProviderContainer(
        overrides: [
          mobileContentServiceProvider.overrideWithValue(
            Content(rows: [for (final i in order) records[i]]),
          ),
          cvApiServiceProvider.overrideWithValue(Api()),
        ],
      );
      try {
        final selected = await container.read(
          latestDashboardCvProvider(true).future,
        );
        expect(selected?.id, 27);
      } finally {
        container.dispose();
      }
    }
  });
  for (final arabic in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets(
        'returning user home: latest CV, edit, ATS check, start cards and jobs ar=$arabic dark=$dark at 2x',
        (tester) async {
          tester.view.physicalSize = const Size(390, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          // Shuffle the service order across cases: the newest record is never first.
          final latest = cv(67, id: arabic ? 503 : 109);
          final api = Api(latest: latest);
          await tester.pumpWidget(
            app(
              Scaffold(body: DashboardHomeTab(onNavigate: (_) {})),
              arabic: arabic,
              dark: dark,
              scale: 2,
              latest: latest,
              api: api,
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(DashboardHomeTab)),
          );

          // Profile row: the server's name and the board's hint.
          final header = find.byType(DashboardHomeHeader);
          expect(
            find.descendant(
              of: header,
              matching: find.textContaining('سارة Sara'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: header,
              matching: find.text(l.homeProfileSubtitle),
            ),
            findsOneWidget,
          );

          // Latest CV: the newest by update time, with its edit time.
          final section = find.byType(HomeLatestCvSection);
          final check = find.byKey(HomeLatestCvSection.checkKey);
          await tester.scrollUntilVisible(
            check,
            300,
            scrollable: verticalScroll(),
          );
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: section,
              matching: find.text(latest.targetJobTitle),
            ),
            findsOneWidget,
          );
          final edited = DateTime.parse('2026-10-19T12:00:00Z').toLocal();
          expect(
            find.descendant(
              of: section,
              matching: find.text(
                l.homeMyCvEdited(
                  AppFormat.relativeTime(edited, l),
                ),
              ),
            ),
            findsOneWidget,
          );
          expect(find.byKey(HomeLatestCvSection.createKey), findsNothing);
          expect(
            find.descendant(
              of: section,
              matching: find.text(l.homeMyCvEmptyTitle),
            ),
            findsNothing,
          );

          // Edit opens the editor on that CV; a saved edit reloads Home,
          // leaving without saving does not.
          for (final saved in [false, true]) {
            await tester.ensureVisible(
              find.byKey(HomeLatestCvSection.editKey),
            );
            await tester.pumpAndSettle();
            final fetchesBefore = api.savedCvFetches;
            await tester.tap(find.byKey(HomeLatestCvSection.editKey));
            await tester.pumpAndSettle();
            final editor = find.byType(CvGeneratorScreen);
            expect(editor, findsOneWidget, reason: 'saved=$saved');
            expect(tester.widget<CvGeneratorScreen>(editor).initialCv?.id,
                latest.id);
            Navigator.of(tester.element(editor)).pop(saved ? latest : null);
            await tester.pumpAndSettle();
            expect(
              api.savedCvFetches > fetchesBefore,
              saved,
              reason: 'Home reloads only after a saved edit',
            );
          }

          // ATS check preselects it and runs on its text.
          await tester.ensureVisible(check);
          await tester.pumpAndSettle();
          await tester.tap(check);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<CvAnalysisScreen>(find.byType(CvAnalysisScreen))
                .initialCvId,
            latest.id,
          );
          expect(
            tester
                .widget<DropdownButtonFormField<int>>(
                  find.byType(DropdownButtonFormField<int>),
                )
                .initialValue,
            latest.id,
          );
          expectAllTextAa('preselected $arabic $dark');
          expectRenderedControls(tester, 'preselected');
          await tester.ensureVisible(
            find.byKey(const ValueKey('ats-input-job-title')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('ats-input-job-title')),
            'Research Engineer مهندس أبحاث',
          );
          await tester.ensureVisible(
            find.byKey(const ValueKey('ats-input-job-description')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('ats-input-job-description')),
            'SQL إدارة البيانات',
          );
          await tester.tap(
            find.byKey(const ValueKey('ats-input-docked-analyze')),
          );
          for (var i = 0;
              i < 30 && find.byType(AnalysisResultScreen).evaluate().isEmpty;
              i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
          expect(api.submittedText, latest.resumeText);
          expect(api.submittedJd, 'SQL إدارة البيانات');
          expect(api.submittedFile, isNull);
          expect(find.byType(AnalysisResultScreen), findsOneWidget);
          Navigator.of(tester.element(find.byType(AnalysisResultScreen))).pop();
          await tester.pumpAndSettle();
          Navigator.of(tester.element(find.byType(CvAnalysisScreen))).pop();
          await tester.pumpAndSettle();

          // Start cards: create first, then the ATS check.
          await tester.drag(verticalScroll(), const Offset(0, 4000));
          await tester.pumpAndSettle();
          final starts = find.byType(HomeStartCard);
          expect(starts, findsNWidgets(2));
          expect(
            tester.getRect(starts.last).top,
            greaterThanOrEqualTo(tester.getRect(starts.first).bottom),
          );
          await tester.tap(find.byKey(const ValueKey('home-start-create')));
          await tester.pumpAndSettle();
          expect(find.text('CV builder destination'), findsOneWidget);
          Navigator.of(
            tester.element(find.text('CV builder destination')),
          ).pop();
          await tester.pumpAndSettle();

          // Latest jobs: the feed's first jobs, compact, never more than the limit.
          await tester.scrollUntilVisible(
            find.byType(DashboardJobsSection),
            300,
            scrollable: verticalScroll(),
          );
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byType(DashboardJobsSection),
              matching: find.byType(JobNewsCard),
            ),
            findsNWidgets(DashboardJobsSection.limit),
          );
          final cards =
              tester.widgetList<JobNewsCard>(find.byType(JobNewsCard));
          expect(
            cards.map((card) => card.item.title),
            homeJobTitles.take(DashboardJobsSection.limit),
          );
          expect(cards.every((card) => card.compact), isTrue);
          await checkScroll(tester, 'populated home $arabic $dark');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  // A new user (no CV yet): the empty "my latest CV" state, and every Home
  // exit lands where it says; Learning is not ready and does nothing.
  for (final arabic in [false, true]) {
    for (final dark in [false, true]) {
      testWidgets('new user home and its exits ar=$arabic dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final navigated = <DashboardTab>[];
        await tester.pumpWidget(
          app(
            Scaffold(body: DashboardHomeTab(onNavigate: navigated.add)),
            arabic: arabic,
            dark: dark,
            scale: 1,
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(DashboardHomeTab)),
        );
        await checkScroll(tester, 'new user ar=$arabic dark=$dark');
        final section = find.byType(HomeLatestCvSection);
        expect(
          find.descendant(
            of: section,
            matching: find.text(l.homeMyCvEmptyTitle),
          ),
          findsOneWidget,
        );
        expect(find.byKey(HomeLatestCvSection.editKey), findsNothing);
        expect(find.byKey(HomeLatestCvSection.viewAllKey), findsNothing);
        expect(
          find.descendant(of: section, matching: find.text(l.homeHonesty)),
          findsOneWidget,
        );

        await tester.tap(find.byKey(HomeLatestCvSection.createKey));
        await tester.pumpAndSettle();
        expect(find.text('CV builder destination'), findsOneWidget);
        Navigator.of(tester.element(find.text('CV builder destination'))).pop();
        await tester.pumpAndSettle();

        // The ATS start card and "upload a CV" both upload, never preselect.
        for (final key in const ['home-start-ats', 'home-service-upload']) {
          final finder = find.byKey(ValueKey(key));
          await tester.scrollUntilVisible(
            finder,
            -300,
            scrollable: verticalScroll(),
          );
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pumpAndSettle();
          final screen =
              tester.widget<CvAnalysisScreen>(find.byType(CvAnalysisScreen));
          expect(screen.initialCvId, isNull, reason: key);
          if (key == 'home-service-upload') {
            expect(screen.initialSource, AnalysisCvSource.upload);
          }
          Navigator.of(tester.element(find.byType(CvAnalysisScreen))).pop();
          await tester.pumpAndSettle();
        }

        // Target a job opens job match.
        const jobMatchRoute = 'route ${AppRoutes.jobMatch}';
        await tester.tap(find.byKey(const ValueKey('home-service-target')));
        await tester.pumpAndSettle();
        expect(find.text(jobMatchRoute), findsOneWidget);
        Navigator.of(tester.element(find.text(jobMatchRoute))).pop();
        await tester.pumpAndSettle();

        // Learning is "soon": shown, labelled, not a button.
        final education = find.byKey(const ValueKey('home-service-education'));
        expect(tester.widget<InkWell>(education).onTap, isNull);
        expect(
          find.bySemanticsLabel(
            l.homeServiceSoonA11y(l.homeServiceEducation),
          ),
          findsOneWidget,
        );
        await tester.tap(education, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(navigated, isEmpty);

        await tester.scrollUntilVisible(
          find.byKey(DashboardJobsSection.viewAllKey),
          300,
          scrollable: verticalScroll(),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(DashboardJobsSection.viewAllKey));
        await tester.pumpAndSettle();
        expect(navigated.last, DashboardTab.jobNews);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('latest CV shows the server label when the list has no timestamp',
      (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final label in ['آخر تحديث: قبل يومين', 'Last updated: 2 days ago']) {
      final latest = cv(70, id: 71);
      await tester.pumpWidget(
        app(
          Scaffold(body: DashboardHomeTab(onNavigate: (_) {})),
          arabic: !label.startsWith('Last'),
          dark: false,
          scale: 1,
          latest: latest,
          content: Content(
            latest: latest,
            rows: [
              {
                'id': 71,
                'title': latest.targetJobTitle,
                'updated_label': label
              },
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(HomeLatestCvSection),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: label,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('the bell is a screen-reader button that opens notifications',
      (tester) async {
    final semantics = tester.ensureSemantics();
    for (final unread in [0, 3]) {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightFor(arabic: true),
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: DashboardHomeHeader(
              name: 'سارة',
              subtitle: 'x',
              unreadCount: unread,
              onNotifications: () => opened++,
              onAvatarTap: () {},
            ),
          ),
        ),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(DashboardHomeHeader)),
      );
      final label = unread > 0
          ? l.dashboardHeaderNotificationsUnread(unread)
          : l.sharedNotifications;
      final node = tester.getSemantics(find.bySemanticsLabel(label));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.tap(find.semantics.byLabel(label));
      await tester.pumpAndSettle();
      expect(opened, 1, reason: 'unread=$unread');
    }
    semantics.dispose();
  });

  testWidgets('Home cards do not animate presses when motion is reduced',
      (tester) async {
    for (final reduce in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Scaffold(
              body: HomePressableCard(
                onTap: () {},
                child: const SizedBox(width: 120, height: 80),
              ),
            ),
          ),
        ),
      );
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(HomePressableCard),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(box.duration == Duration.zero, reduce, reason: 'reduce=$reduce');
    }
  });

  testWidgets(
    'unknown priorities remain unknown; empty fixes have no heading',
    (tester) async {
      for (final raw in [
        null,
        '',
        'urgent',
        'MEDIUM',
        ' priority-${math.Random(42).nextInt(10000)}',
      ]) {
        final weakness = AnalysisWeakness.fromJson({
          'priority': raw,
          'issue': 'Actual issue $raw',
          'fix': 'Actual recommendation',
        });
        await tester.pumpWidget(
          app(
            Scaffold(body: PrioritizedFixes(weaknesses: [weakness])),
            arabic: false,
            dark: false,
            scale: 1,
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(PrioritizedFixes)),
        );
        for (final label in [
          l.atsResultHighPriority,
          l.atsResultMediumPriority,
          l.atsResultLowPriority,
        ]) {
          expect(find.text(label), findsNothing);
        }
        expect(find.text('Actual issue $raw'), findsOneWidget);
      }
      await tester.pumpWidget(
        app(
          const Scaffold(body: PrioritizedFixes(weaknesses: [])),
          arabic: false,
          dark: false,
          scale: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Text), findsNothing);
    },
  );
  testWidgets(
    'missing requested CV blocks submission instead of selecting another',
    (tester) async {
      final api = Api();
      await tester.pumpWidget(
        app(
          const CvAnalysisScreen(initialCvId: 999),
          arabic: false,
          dark: false,
          scale: 1,
          latest: cv(64),
          api: api,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<int>>(
              find.byType(DropdownButtonFormField<int>),
            )
            .initialValue,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('ats-input-job-title')),
        'QA Engineer',
      );
      await tester.tap(find.byKey(const ValueKey('ats-input-docked-analyze')));
      await tester.pumpAndSettle();
      expect(api.submittedText, isNull);
      expect(
        find.text(
          lookupAppLocalizations(const Locale('en'))
              .atsInputSelectSourceRequired,
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'docked Analyze stays fixed with scrolling and keyboard; limits use original Arabic wording',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          const CvAnalysisScreen(),
          arabic: true,
          dark: true,
          scale: 2,
          latest: cv(64),
        ),
      );
      await tester.pumpAndSettle();
      final dock = find.byKey(const ValueKey('ats-input-docked-analyze'));
      final before = tester.getRect(dock);
      await tester.drag(verticalScroll(), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getRect(dock), before);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(tester.getRect(dock).bottom, lessThanOrEqualTo(640));
      await tester.enterText(
        find.byKey(const ValueKey('ats-input-job-title')),
        'م' * (AnalysisLimits.jobTitleMax + 1),
      );
      await tester.enterText(
        find.byKey(const ValueKey('ats-input-job-description')),
        'ن' * (AnalysisLimits.jobDescriptionMax + 1),
      );
      await tester.tap(dock);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'يجب ألا يزيد وصف الوظيفة عن ${AnalysisLimits.jobDescriptionMax} حرف.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'يجب ألا يزيد المسمى الوظيفي عن ${AnalysisLimits.jobTitleMax} حرفاً.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'absent result measurements never become zero scores or keyword counts',
    (tester) async {
      await tester.pumpWidget(
        app(
          AnalysisResultScreen(
            analysis: CvAnalysis.fromJson({
              'id': 402,
              'target_job_title': 'Research scientist',
            }),
          ),
          arabic: false,
          dark: true,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AnimatedAtsScoreBar), findsNothing);
      expect(find.text('0%'), findsNothing);
      expect(
        find.byKey(const ValueKey('ats-result-keyword-summary')),
        findsNothing,
      );
      expectAllTextAa('unavailable result');
      expectRenderedControls(tester, 'unavailable result');
    },
  );
  test(
    'missing and invalid generated scores are distinguishable from genuine zero',
    () {
      for (final raw in [
        null,
        'unknown',
        -1,
        101,
        double.nan,
        double.infinity,
      ]) {
        expect(GeneratedCv.fromJson({'score_total': raw}).hasScore, isFalse);
      }
      for (final score in [0, 1, 49, 50, 64, 65, 79, 80, 99, 100]) {
        expect(GeneratedCv.fromJson({'score_total': score}).hasScore, isTrue);
      }
    },
  );
}
