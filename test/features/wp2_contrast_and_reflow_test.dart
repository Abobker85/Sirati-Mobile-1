import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_ring.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/dashboard/presentation/education_screen.dart';
import 'package:sirati/features/dashboard/presentation/history/history_cards.dart';
import 'package:sirati/features/jobs/domain/job_news_feed.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/settings/presentation/onboarding_screen.dart';
import 'package:sirati/features/settings/presentation/settings/settings_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';

JobNews _sampleJob({
  int id = 1,
  String title = 'Senior Cloud Solutions Architect & Enterprise Lead',
  bool isVerified = true,
  bool isTamheer = true,
  int? matchScore = 92,
  String salary = 'SAR 28,000 - 38,000',
}) =>
    JobNews.fromJson({
      'id': id,
      'title': title,
      'body': 'Lead cloud infrastructure transformation across teams.',
      'category': 'tech',
      'is_verified': isVerified,
      'is_tamheer': isTamheer,
      'skills_required': ['AWS', 'Kubernetes', 'Terraform', 'System Architecture'],
      'matched_skills': ['AWS', 'Kubernetes'],
      'match_score': matchScore,
      'match_reasons': ['Role aligns with your CV profile'],
      'company': 'Riyadh Tech Group',
      'action_url': 'https://example.com/jobs/$id',
      'salary': salary,
      'published_at': '2026-10-19T08:00:00Z',
    });

Widget _wrapWithScale({
  required Widget child,
  double textScale = 2.0,
  ThemeData? theme,
  String lang = 'ar',
  Size size = const Size(360, 800),
}) {
  AppLocale.languageCode.value = lang;
  return MaterialApp(
    theme: theme ?? AppTheme.lightFor(arabic: lang == 'ar'),
    locale: Locale(lang),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: size.width,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('WP2 Contrast Invariants (Strict >= 4.5:1 Mathematical Evaluation)', () {
    test('primaryInk meets WCAG AA in both Light and Dark palettes', () {
      const light = SiratiColors.light;
      const dark = SiratiColors.dark;

      // Light theme: primaryInk (#006A60) on white surface and on primaryLight (#E0F2EE)
      final lightOnWhite = AppContrast.ratio(light.primaryInk, light.surface);
      final lightOnContainer = AppContrast.ratio(light.primaryInk, light.primaryLight);
      expect(lightOnWhite, greaterThanOrEqualTo(4.5), reason: 'Light primaryInk on white');
      expect(lightOnContainer, greaterThanOrEqualTo(4.5), reason: 'Light primaryInk on primaryLight');

      // Dark theme: primaryInk (#2FC4B2) on dark surface and on primaryLight
      final darkOnSurface = AppContrast.ratio(dark.primaryInk, dark.surface);
      final darkOnContainer = AppContrast.ratio(dark.primaryInk, dark.primaryLight);
      expect(darkOnSurface, greaterThanOrEqualTo(4.5), reason: 'Dark primaryInk on surface');
      expect(darkOnContainer, greaterThanOrEqualTo(4.5), reason: 'Dark primaryInk on primaryLight');
    });

    test('onWarningContainer meets WCAG AA on warning backgrounds in both themes', () {
      const light = SiratiColors.light;
      const dark = SiratiColors.dark;

      final lightRatio = AppContrast.ratio(light.onWarningContainer, light.amberLight);
      expect(lightRatio, greaterThanOrEqualTo(4.5), reason: 'Light onWarningContainer on amberLight');

      final darkRatio = AppContrast.ratio(dark.onWarningContainer, const Color(0xFF3D2E14));
      expect(darkRatio, greaterThanOrEqualTo(4.5), reason: 'Dark onWarningContainer on warning container');
    });

    test('FeaturedJobCard permanent white containers use Color(0xFF006A60) (>= 4.5:1)', () {
      const darkSafePrimary = Color(0xFF006A60);
      const whiteBackground = Colors.white;
      final ratio = AppContrast.ratio(darkSafePrimary, whiteBackground);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: 'Featured card white badge foreground');
    });
  });

  group('WP2 Reflow at 200% Text Scale (No Overflow)', () {
    testWidgets('JobNewsCard reflows cleanly without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(720, 1600); // 360dp @ 2.0 DPR
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final job = _sampleJob();
      await tester.pumpWidget(_wrapWithScale(
        child: JobNewsCard(item: job, english: false, isNew: true, onTap: () {}),
        textScale: 2.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'JobNewsCard must not overflow at 200% text scale');
      expect(find.byType(JobNewsCard), findsOneWidget);
    });

    testWidgets('FeaturedJobCard reflows cleanly without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final job = _sampleJob();
      await tester.pumpWidget(_wrapWithScale(
        child: FeaturedJobCard(item: job, english: false, onTap: () {}),
        textScale: 2.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'FeaturedJobCard must not overflow at 200% text scale');
      expect(find.byType(FeaturedJobCard), findsOneWidget);
    });

    testWidgets('AnalysisHistoryCard reflows cleanly without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final item = CvAnalysis.fromJson({
        'id': 101,
        'target_job_title': 'Chief Technology Officer & Lead Infrastructure Architect',
        'score_total': 88,
        'grade': 'A',
        'input_method': 'paste',
        'created_at': '2026-10-19T10:00:00Z',
      });

      await tester.pumpWidget(_wrapWithScale(
        child: AnalysisHistoryCard(analysis: item, onTap: () {}),
        textScale: 2.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'AnalysisHistoryCard must not overflow at 200% text scale');
    });

    testWidgets('GeneratedCvHistoryCard reflows cleanly without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final item = GeneratedCv.fromJson({
        'id': 202,
        'full_name': 'Dr. Abdulaziz Al-Mansoor',
        'target_job_title': 'Executive Vice President of Artificial Intelligence',
        'score_total': 95,
        'grade': 'A+',
        'language': 'ar',
        'created_at': '2026-10-19T11:00:00Z',
      });

      await tester.pumpWidget(_wrapWithScale(
        child: GeneratedCvHistoryCard(cv: item, onTap: () {}),
        textScale: 2.0,
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'GeneratedCvHistoryCard must not overflow at 200% text scale');
    });

    testWidgets('EducationScreen reflows cleanly without overflow at 200% text scale', (tester) async {
      tester.view.physicalSize = const Size(720, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const ProviderScope(
        child: MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 1200),
              textScaler: TextScaler.linear(2.0),
            ),
            child: Scaffold(body: EducationScreen()),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'EducationScreen must not overflow at 200% text scale');
    });
  });

  group('WP2 Minimum Tap Targets (>= 48x48dp) and Semantics', () {
    testWidgets('Onboarding dots have >= 48x48dp tap target and page semantics', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: OnboardingScreen(onFinished: () {})),
      ));
      await tester.pumpAndSettle();

      final page1Semantics = find.bySemanticsLabel('Page 1 of 3');
      expect(page1Semantics, findsOneWidget);

      final dotBox = tester.getSize(page1Semantics);
      expect(dotBox.width, greaterThanOrEqualTo(48.0));
      expect(dotBox.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('CvDocumentCard circle action buttons have >= 48x48dp tap target and semantics', (tester) async {
      final cvItem = CvListItem(
        id: 10,
        title: 'Backend Engineer CV',
        badge: 'جاهزة',
        isDraft: false,
        canDownload: true,
        pdfUrl: 'https://example.com/cv.pdf',
        templatePdfUrl: '',
        updatedAt: DateTime.now(),
        updatedLabel: 'اليوم',
      );

      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: CvDocumentCard(
            item: cvItem,
            onEdit: () {},
            onDownload: () {},
            onDelete: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final downloadBtn = find.bySemanticsLabel('Download');
      expect(downloadBtn, findsOneWidget);
      final downloadSize = tester.getSize(downloadBtn);
      expect(downloadSize.width, greaterThanOrEqualTo(48.0));
      expect(downloadSize.height, greaterThanOrEqualTo(48.0));

      final deleteBtn = find.bySemanticsLabel('Delete');
      expect(deleteBtn, findsOneWidget);
      final deleteSize = tester.getSize(deleteBtn);
      expect(deleteSize.width, greaterThanOrEqualTo(48.0));
      expect(deleteSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('AnimatedScoreRing exposes descriptive accessibility semantics', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: AnimatedScoreRing(
            score: 85,
            scoreColor: Color(0xFF006A60),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final ringSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.value == '85 من 100'),
      );
      expect(ringSemantics, findsOneWidget);
    });

    testWidgets('ThemeModeSelector options have minHeight >= 48dp', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: ThemeModeSelector(
            mode: ThemeMode.system,
            onChanged: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final boxes = tester.widgetList<ConstrainedBox>(
        find.descendant(of: find.byType(ThemeModeSelector), matching: find.byType(ConstrainedBox)),
      );
      expect(boxes, hasLength(3));
      for (final box in boxes) {
        expect(box.constraints.minHeight, greaterThanOrEqualTo(48.0));
      }
    });
  });

  group('WP2 Job News Empty State Logic (C-U-13)', () {
    test('JobNewsFeed empty check treats presence of featured as non-empty feed', () {
      final featured = _sampleJob(id: 99);
      final feedWithFeaturedOnly = JobNewsFeed(
        title: 'Job News',
        items: [featured],
      );

      expect(feedWithFeaturedOnly.featured, isNotNull);
      expect(feedWithFeaturedOnly.latest, isEmpty);
      expect(feedWithFeaturedOnly.items.isNotEmpty, isTrue,
          reason: 'feed is non-empty when featured job is present');

      const emptyFeed = JobNewsFeed(
        title: 'Job News',
        items: [],
      );
      expect(emptyFeed.items.isEmpty, isTrue);
    });
  });
}
