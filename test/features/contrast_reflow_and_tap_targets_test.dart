import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_ring.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/dashboard/application/education_interest_controller.dart';
import 'package:sirati/features/dashboard/presentation/education_screen.dart';
import 'package:sirati/features/dashboard/presentation/history/history_cards.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/jobs/domain/job_news_filters.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_common.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_filters_bar.dart';
import 'package:sirati/features/settings/presentation/onboarding_screen.dart';
import 'package:sirati/features/settings/presentation/settings/settings_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../support/contrast_probe.dart';

Map<String, dynamic> _jobJson(String content) => {
  'id': 1,
  'title': content,
  'body': content,
  'company': content,
  'location': content,
  'source_badge': content,
  'is_verified': true,
  // `isTamheer` reads employment_type / source_type, not a boolean flag.
  'employment_type': 'tamheer',
  'source_type': 'gov',
  'apply_method': 'url',
  'apply_url': 'https://careers.example.sa/jobs/1',
  'source_url': 'https://t.me/jobs/1',
  'source_name': content,
  'skills_required': [content, 'TypeScript', 'إدارة المشاريع'],
  // Use the actual API field; `salary` is silently ignored by the model.
  'salary_range': content,
  'published_at': '2026-10-19T08:00:00Z',
};

Widget _app(Widget child, {required String lang, required bool dark,
    double scale = 2, bool scroll = false}) {
  AppLocale.languageCode.value = lang;
  return MaterialApp(
    theme: dark ? AppTheme.darkFor(arabic: lang == 'ar')
        : AppTheme.lightFor(arabic: lang == 'ar'),
    locale: Locale(lang),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale), disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(body: scroll ? SingleChildScrollView(child: child) : child),
  );
}

void _narrow(WidgetTester tester) {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void _target(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}

// Resolve painted ancestors including Ink gradients and translucent layers.
// Every gradient endpoint must pass; no literal palette pair stands in for UI.
List<Color> _backgrounds(Element element) {
  var colors = <Color>[Colors.transparent];
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    Decoration? decoration;
    Color? fill;
    if (widget is DecoratedBox) decoration = widget.decoration;
    if (widget is Ink) decoration = widget.decoration;
    if (widget is Material && widget.type != MaterialType.transparency) {
      fill = widget.color ?? Theme.of(ancestor).canvasColor;
    }
    if (widget is Scaffold) fill = widget.backgroundColor ?? Theme.of(ancestor).scaffoldBackgroundColor;
    List<Color> layer = fill == null ? [] : [fill];
    if (decoration is BoxDecoration) {
      layer = decoration.gradient?.colors ??
          (decoration.color == null ? [] : [decoration.color!]);
    }
    if (layer.isNotEmpty) {
      colors = [for (final top in colors) for (final below in layer)
        Color.alphaBlend(top, below)];
    }
    return colors.any((color) => color.a < 1);
  });
  expect(colors.every((color) => color.a == 1), isTrue);
  return colors;
}

void _contrast(WidgetTester tester, Finder textFinder) {
  expect(textFinder, findsWidgets);
  for (final element in textFinder.evaluate()) {
    final paragraph = paragraphOf(element.findRenderObject()!);
    final ink = paragraph.text.style!.color!;
    for (final background in _backgrounds(element)) {
      expect(AppContrast.ratio(Color.alphaBlend(ink, background), background),
          greaterThanOrEqualTo(4.5), reason: '${paragraph.text.toPlainText()} on $background');
    }
  }
}

class _Filters extends JobNewsFiltersController {
  _Filters(this.initial);
  final JobNewsFilters initial;
  @override
  JobNewsFilters build() => initial;
}

class _Content extends MobileContentService {
  _Content({this.items = const []});
  final List<Map<String, dynamic>> items;
  final calls = <JobNewsFilters>[];
  @override
  Future<Map<String, dynamic>> jobNews(bool english, {
    String? category, String? preset, String? city, int? jobTitleId,
    String? region,
    bool? isRemote, bool? isVerified, String? sourceType,
    String? employmentType, String? query, bool force = false,
  }) async {
    calls.add(JobNewsFilters(preset: preset ?? 'all', region: region ?? 'all',
        query: query ?? ''));
    return {'title': 'Jobs', 'items': items};
  }
}

class _Interest extends EducationInterestStore {
  @override
  Future<bool> read() async => false;
  @override
  Future<void> save() async {}
}

Future<List<int>> _pixels(WidgetTester tester, GlobalKey key) async {
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = bytes!.buffer.asUint8List().toList();
    image.dispose();
    return pixels;
  }))!;
}

void main() {
  for (final lang in ['en', 'ar']) {
    for (final dark in [false, true]) {
      final variant = '$lang dark=$dark';
      for (final content in [
        'Senior platform engineering and distributed systems specialist',
        'مسؤول تطوير الخدمات الرقمية وإدارة المشاريع التقنية',
        'مهندس Infrastructure Architecture وتطوير الخدمات المتقدمة',
        'X' * 100,
      ]) {
        for (final screen in ['card', 'featured', 'detail']) {
          testWidgets('$screen reflows at 200%: $variant / $content', (tester) async {
            _narrow(tester);
            final job = JobNews.fromJson(_jobJson(content));
            final widget = switch (screen) {
              'card' => JobNewsCard(item: job, english: lang == 'en', onTap: () {}),
              'featured' => FeaturedJobCard(item: job, english: lang == 'en', onTap: () {}),
              _ => JobNewsDetailScreen(item: job),
            };
            await tester.pumpWidget(_app(widget, lang: lang, dark: dark, scroll: screen != 'detail'));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            // Also lay out the bottom of the actual scrollable screen.
            await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          });
        }
      }

      testWidgets('rendered featured text and warning badges meet AA: $variant', (tester) async {
        final job = JobNews.fromJson(_jobJson('Engineering'));
        await tester.pumpWidget(_app(
          FeaturedJobCard(item: job, english: lang == 'en', onTap: () {}),
          lang: lang, dark: dark, scale: 1, scroll: true));
        await tester.pumpAndSettle();
        _contrast(tester, find.descendant(of: find.byType(FeaturedJobCard), matching: find.byType(Text)));
        for (final widget in [
          JobNewsCard(item: job, english: lang == 'en', onTap: () {}),
          JobNewsDetailScreen(item: job),
        ]) {
          await tester.pumpWidget(_app(widget, lang: lang, dark: dark, scale: 1,
              scroll: widget is JobNewsCard));
          await tester.pumpAndSettle();
          final warning = find.byWidgetPredicate((w) => w is Text &&
              (w.data?.contains(lang == 'en' ? 'Government' : 'جهات حكومية') ?? false));
          _contrast(tester, warning);
        }
      });

      testWidgets('history uses readable shipped typography: $variant', (tester) async {
        _narrow(tester);
        await tester.pumpWidget(_app(Column(children: [
          AnalysisHistoryCard(analysis: CvAnalysis.fromJson({
            'id': 1, 'target_job_title': 'مدير Technology Services والعمليات',
            'score_total': 88, 'grade': 'A', 'input_method': 'paste',
            'created_at': '2026-10-19T10:00:00Z',
          }), onTap: () {}),
          GeneratedCvHistoryCard(cv: GeneratedCv.fromJson({
            'id': 2, 'full_name': 'Sara أحمد',
            'target_job_title': 'مدير Technology Services والعمليات',
            'score_total': 95, 'grade': 'A+', 'language': lang,
            'created_at': '2026-10-19T10:00:00Z',
          }), onTap: () {}),
        ]), lang: lang, dark: dark, scroll: true));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final texts = find.byType(Text).evaluate();
        expect(texts, isNotEmpty);
        for (final element in texts) {
          final style = (element.findRenderObject()! as RenderParagraph).text.style!;
          expect(style.fontSize, greaterThanOrEqualTo(13));
          expect([FontWeight.w400, FontWeight.w600, FontWeight.w700], contains(style.fontWeight));
        }
      });

      for (final filters in [
        const JobNewsFilters(),
        const JobNewsFilters(preset: 'gov'),
        const JobNewsFilters(region: 'northern'),
        const JobNewsFilters(query: 'علم البيانات'),
        const JobNewsFilters(preset: 'remote', region: 'central', query: 'platform'),
      ]) {
        testWidgets('real empty feed ${filters.preset}/${filters.region}/${filters.query}: $variant', (tester) async {
          _narrow(tester);
          final content = _Content();
          await tester.pumpWidget(ProviderScope(
            overrides: [
              mobileContentServiceProvider.overrideWithValue(content),
              jobNewsFiltersProvider.overrideWith(() => _Filters(filters)),
            ],
            child: _app(const JobNewsScreen(), lang: lang, dark: dark),
          ));
          await tester.pumpAndSettle();
          final l10n = await AppLocalizations.delegate.load(Locale(lang));
          // Region alone gets its own empty state and offers all regions;
          // any other filter offers to clear everything.
          final regionOnly = filters.region != 'all' && filters.preset == 'all' && filters.query.isEmpty;
          final clear = find.widgetWithText(FilledButton,
              regionOnly ? l10n.jobsShowAllRegions : l10n.clearFilters);
          expect(find.text(l10n.noMatchingJobs),
              filters.isActive && !regionOnly ? findsOneWidget : findsNothing);
          if (regionOnly) {
            expect(find.text(l10n.jobsEmptyRegionTitle(jobRegionLabel(l10n, filters.region))), findsOneWidget);
          }
          if (filters.isActive) {
            // A pending debounce must not reapply a search after clearing.
            if (!regionOnly) await tester.enterText(find.byType(TextField), 'pending search');
            await tester.ensureVisible(clear);
            await tester.pumpAndSettle();
            _target(tester, clear);
            await tester.tap(clear);
            await tester.pumpAndSettle();
            expect(content.calls.last, const JobNewsFilters());
            expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
          }
          expect(find.byType(EmptyJobNews), findsOneWidget);
          expect(find.text(lang == 'en' ? 'No job news is published yet.' : 'لا توجد أخبار وظائف منشورة حالياً.'), findsOneWidget);
          expect(clear, findsNothing);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('a single-item real feed shows that job once: $variant', (tester) async {
        _narrow(tester);
        for (final published in [DateTime.now().toUtc(), DateTime.utc(2026, 1, 1)]) {
          await tester.pumpWidget(ProviderScope(overrides: [
            mobileContentServiceProvider.overrideWithValue(_Content(items: [
              {..._jobJson('Data engineer'), 'published_at': published.toIso8601String()},
            ])),
          ], child: _app(const JobNewsScreen(), lang: lang, dark: dark)));
          await tester.pumpAndSettle();
          // Fresh with a link -> hero; older -> plain card. Never both, never empty.
          expect(find.byType(FeaturedJobCard).evaluate().length + find.byType(JobNewsCard).evaluate().length, 1);
          expect(find.byType(EmptyJobNews), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('every filter chip has a rendered 48dp target: $variant', (tester) async {
        _narrow(tester);
        final selected = <String>[];
        await tester.pumpWidget(_app(Column(children: [
          PresetChips(english: lang == 'en', selectedPreset: 'all', onSelected: selected.add),
          RegionChips(selectedRegion: 'all', onSelected: selected.add),
        ]), lang: lang, dark: dark, scale: 1, scroll: true));
        await tester.pumpAndSettle();
        final chips = find.descendant(
            of: find.byWidgetPredicate((w) => w is PresetChips || w is RegionChips),
            matching: find.byType(InkWell));
        expect(chips, findsWidgets);
        for (final element in chips.evaluate().toList()) {
          final chip = find.byElementPredicate((e) => e == element);
          _target(tester, chip);
          await tester.ensureVisible(chip);
          await tester.tap(chip);
          await tester.pumpAndSettle();
        }
        expect(selected.length, chips.evaluate().length);
        expect(selected.toSet(), {...JobNewsFilters.presets, ...JobNewsFilters.regions});
      });

      testWidgets('education registers interest with a 48dp action: $variant', (tester) async {
        _narrow(tester);
        await tester.pumpWidget(ProviderScope(overrides: [
          educationInterestStoreProvider.overrideWithValue(_Interest()),
        ], child: _app(const EducationScreen(), lang: lang, dark: dark)));
        await tester.pumpAndSettle();
        final l10n = await AppLocalizations.delegate.load(Locale(lang));
        final action = find.widgetWithText(ElevatedButton, l10n.registerInterest);
        await tester.ensureVisible(action);
        _target(tester, action);
        expect(tester.takeException(), isNull);
      });

      testWidgets('theme options measure 48dp: $variant', (tester) async {
        _narrow(tester);
        await tester.pumpWidget(_app(ThemeModeSelector(mode: ThemeMode.system,
            onChanged: (_) {}), lang: lang, dark: dark, scale: 1, scroll: true));
        await tester.pumpAndSettle();
        final options = find.descendant(of: find.byType(ThemeModeSelector), matching: find.byType(InkWell));
        expect(options, findsNWidgets(3));
        for (final element in options.evaluate()) {
          _target(tester, find.byElementPredicate((e) => e == element));
        }
      });

      testWidgets('CV action ink and focus paint above the card: $variant', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final key = GlobalKey();
          var opens = 0;
          await tester.pumpWidget(_app(RepaintBoundary(key: key, child: CvDocumentCard(
            item: const CvListItem(id: 10, title: 'Engineer', badge: '', isDraft: false,
              canDownload: true, pdfUrl: '', templatePdfUrl: '', updatedAt: null, updatedLabel: ''),
            onOpen: () => opens++, onEdit: () {}, onDelete: () {}, onDownload: () {}, onScan: () {},
          )), lang: lang, dark: dark, scale: 1));
          await tester.pumpAndSettle();
          final action = find.byKey(CvDocumentCard.openKey(10));
          _target(tester, action);
          _target(tester, find.byKey(CvDocumentCard.scanKey(10)));
          _target(tester, find.byKey(CvDocumentCard.menuKey(10)));
          final before = await _pixels(tester, key);
          final oldStrategy = FocusManager.instance.highlightStrategy;
          addTearDown(() => FocusManager.instance.highlightStrategy = oldStrategy);
          FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
          Focus.of(tester.element(find.descendant(of: action, matching: find.byType(Text)))).requestFocus();
          await tester.pumpAndSettle();
          final focused = await _pixels(tester, key);
          expect(focused, isNot(equals(before)), reason: 'focus must visibly paint over the opaque card');
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final gesture = await tester.startGesture(tester.getCenter(action));
          // Tap down is deferred by kPressTimeout (100ms). That timer starts the
          // highlight while the scheduler is idle, so the same frame's first
          // tick is elapsed 0 and the circle is fully transparent. The next
          // elapsed pump is the first frame toImage can see. Stay under the
          // 500ms tooltip long-press, which cancels the pressed highlight.
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 50));
          final pressed = await _pixels(tester, key);
          expect(pressed, isNot(equals(before)), reason: 'tap ink must be visible');
          await gesture.up();
          await tester.pumpAndSettle();
          expect(opens, 1);
        } finally {
          semantics.dispose();
        }
      });

      testWidgets('score semantics announce one localized value: $variant', (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final l10n = await AppLocalizations.delegate.load(Locale(lang));
          for (final score in [0, 37, 100]) {
            await tester.pumpWidget(_app(Builder(builder: (context) => AnimatedScoreRing(
              score: score, scoreColor: context.sirati.primaryInk)), lang: lang, dark: dark));
            await tester.pumpAndSettle();
            final ring = find.bySemanticsLabel(l10n.compatibilityScoreLabel);
            expect(ring, findsOneWidget);
            expect(tester.getSemantics(ring).getSemanticsData().value, l10n.compatibilityScoreValue(score));
          }
        } finally {
          semantics.dispose();
        }
      });
    }
  }

  testWidgets('onboarding dots render 48dp semantic targets', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_app(OnboardingScreen(onFinished: () {}), lang: 'en', dark: false, scale: 1));
      await tester.pumpAndSettle();
      final dots = find.bySemanticsLabel(RegExp(r'^Page \d+ of \d+$'));
      expect(dots, findsNWidgets(3));
      for (final element in dots.evaluate()) {
        _target(tester, find.byElementPredicate((candidate) => candidate == element));
      }
    } finally {
      semantics.dispose();
    }
  });
}
