import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/expand_page_route.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/featured_job_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_filters_bar.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

import '../../support/contrast_probe.dart';

class _FakeContent extends MobileContentService {
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
  }) async {
    return {
      'title': 'Jobs',
      'items': [
        {
          'id': 10,
          'language': english ? 'en' : 'ar',
          'title': english ? 'Platform Engineer' : 'مهندس منصات',
          'body': 'Build resilient APIs.',
          'category': 'tech',
          'company': 'Sirati',
          'location': 'Riyadh',
          'apply_method': 'url',
          'apply_url': 'https://careers.sirati.example/10',
          'published_at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'id': 11,
          'language': english ? 'en' : 'ar',
          'title': english ? 'Data Analyst' : 'محلل بيانات',
          'body': 'SQL and dashboards.',
          'category': 'tech',
          'company': 'Acme',
          'location': 'Jeddah',
          'apply_method': 'email',
          'apply_email': 'jobs@acme.example',
        },
      ],
    };
  }
}

class _RouteObserver extends NavigatorObserver {
  final pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

Widget _host(
  Widget child, {
  String language = 'en',
  bool reduce = false,
  bool dark = false,
  NavigatorObserver? observer,
}) {
  AppLocale.languageCode.value = language;
  final arabic = language == 'ar';
  return MaterialApp(
    theme: dark
        ? AppTheme.darkFor(arabic: arabic)
        : AppTheme.lightFor(arabic: arabic),
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    navigatorObservers: [if (observer != null) observer],
    builder: (context, widget) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: widget!,
    ),
    home: child,
  );
}

void main() {
  tearDown(() => AppLocale.languageCode.value = 'ar');

  group('Jobs filter bar & search motion', () {
    for (final lang in ['en', 'ar']) {
      for (final reduce in [false, true]) {
        testWidgets(
            '$lang (reduce=$reduce): filter pill morphs icon & preserves 48dp target',
            (tester) async {
          var selected = 'all';
          await tester.pumpWidget(
            _host(
              StatefulBuilder(
                builder: (context, setState) => Scaffold(
                  body: Column(
                    children: [
                      PresetChips(
                        english: lang == 'en',
                        selectedPreset: selected,
                        onSelected: (next) => setState(() => selected = next),
                      ),
                    ],
                  ),
                ),
              ),
              language: lang,
              reduce: reduce,
            ),
          );
          await tester.pumpAndSettle();

          final l = AppLocalizations.of(
              tester.element(find.byType(PresetChips)));
          final govFinder = find.text(l.jobsPresetGov);
          await tester.ensureVisible(govFinder);
          await tester.pump();

          final inkWell = find.ancestor(
            of: govFinder,
            matching: find.byType(InkWell),
          );
          final size = tester.getSize(inkWell);
          expect(size.height, greaterThanOrEqualTo(48));
          expect(size.width, greaterThanOrEqualTo(48));

          await tester.tap(govFinder);
          await tester.pump();
          if (reduce) {
            expect(tester.hasRunningAnimations, isFalse);
          } else {
            await tester.pumpAndSettle();
          }
          expect(
            tester.widget<PresetChips>(find.byType(PresetChips)).selectedPreset,
            'gov',
          );
          expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        });
      }

      testWidgets('$lang: search clear button appears, clears, and disappears',
          (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final changes = <String>[];

        await tester.pumpWidget(
          _host(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: JobSearchBar(
                  english: lang == 'en',
                  controller: controller,
                  onChanged: changes.add,
                ),
              ),
            ),
            language: lang,
          ),
        );

        expect(find.byKey(const ValueKey('jobs-search-clear')), findsNothing);
        await tester.enterText(find.byType(TextField), 'Flutter');
        await tester.pumpAndSettle();

        final clear = find.byKey(const ValueKey('jobs-search-clear'));
        expect(clear, findsOneWidget);
        expect(tester.getSize(clear).height, greaterThanOrEqualTo(48));

        await tester.tap(clear);
        await tester.pumpAndSettle();
        expect(controller.text, isEmpty);
        expect(changes.last, isEmpty);
        expect(clear, findsNothing);
      });
    }
  });

  group('Jobs feed expand route & detail motion', () {
    for (final reduce in [false, true]) {
      testWidgets(
          'reduce=$reduce: tapping FeaturedJobCard pushes ExpandPageRoute',
          (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.5;
        addTearDown(tester.view.reset);

        final observer = _RouteObserver();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              mobileContentServiceProvider.overrideWithValue(_FakeContent()),
            ],
            child: _host(
              const Scaffold(body: JobNewsScreen()),
              language: 'en',
              reduce: reduce,
              observer: observer,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(FeaturedJobCard), findsOneWidget);
        await tester.tap(find.text('Platform Engineer'));
        await tester.pump();
        if (reduce) {
          // Under reduced motion, ExpandPageRoute renders the destination on the next frame.
          await tester.pump();
          expect(find.byType(JobNewsDetailScreen), findsOneWidget);
        }
        await tester.pump(const Duration(milliseconds: 350));

        expect(observer.pushed.last, isA<ExpandPageRoute<void>>());
        expect(find.byType(JobNewsDetailScreen), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }

    for (final lang in ['en', 'ar']) {
      for (final dark in [false, true]) {
        testWidgets(
            '$lang (dark=$dark): detail reveals, copy morphs for 1.2s, and meets AA',
            (tester) async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            return null;
          });
          addTearDown(() => TestDefaultBinaryMessengerBinding
              .instance.defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null));

          final job = JobNews.fromJson({
            'id': 42,
            'language': lang,
            'title': lang == 'en' ? 'Backend Engineer' : 'مهندس خلفية',
            'body': 'Build APIs.',
            'company': 'Sirati',
            'location': 'Riyadh',
            'skills_required': ['Dart', 'Laravel'],
            'apply_method': 'email',
            'apply_email': 'hr@sirati.example',
          });

          await tester.pumpWidget(
            _host(
              JobNewsDetailScreen(item: job),
              language: lang,
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(MotionReveal), findsNWidgets(4));
          expectAllTextAa('detail $lang dark=$dark');

          final l = AppLocalizations.of(
              tester.element(find.byType(JobNewsDetailScreen)));
          expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

          await tester.tap(find.text(l.jobsCopyEmail));
          await tester.pump();
          await tester.pump(MotionDurations.morph);
          expect(find.byIcon(Icons.check_rounded), findsOneWidget);
          expect(find.text(l.jobsCopyEmail), findsOneWidget);

          // Reverts after 1.2s.
          await tester.pump(const Duration(milliseconds: 1200));
          await tester.pumpAndSettle();
          expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
          expect(find.byIcon(Icons.check_rounded), findsNothing);
        });
      }
    }

    testWidgets('reduced motion on detail screen runs zero animations',
        (tester) async {
      final job = JobNews.fromJson({
        'id': 99,
        'language': 'ar',
        'title': 'مهندس برمجيات',
        'body': 'وصف الوظيفة',
        'apply_method': 'none',
      });
      await tester.pumpWidget(
        _host(
          JobNewsDetailScreen(item: job),
          language: 'ar',
          reduce: true,
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('مهندس برمجيات'), findsOneWidget);
    });
  });
}
