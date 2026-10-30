import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_jobs_section.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/jobs/presentation/job_news_detail_screen.dart';
import 'package:sirati/features/jobs/presentation/job_news_screen.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_common.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_filters_bar.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

/// One `jobNews` request as the screen made it.
typedef _Call = ({String? preset, String? region, String? query, bool force});

/// Content service whose job-news answer is decided per request by
/// [respond]; every other endpoint is untouched.
class _FakeContent extends MobileContentService {
  final calls = <_Call>[];
  late FutureOr<Map<String, dynamic>> Function(_Call call) respond;

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
    final call = (
      preset: preset,
      region: region,
      query: (query ?? '').isEmpty ? null : query,
      force: force,
    );
    calls.add(call);
    return respond(call);
  }
}

Map<String, dynamic> _page(
  List<String> titles, {
  String language = 'en',
  Map<String, dynamic>? profile,
}) =>
    {
      // A server title the screen must not show: its header is a label.
      'title': 'Server title',
      'items': [
        for (var i = 0; i < titles.length; i++)
          {
            'id': i + 1,
            'language': language,
            'title': titles[i],
            'body': 'Body ${titles[i]}',
            'category': 'tech',
            'apply_method': 'none',
          },
      ],
      if (profile != null) 'profile_context': profile,
    };

const _serverError = ApiException('Server down', type: ApiErrorType.server);
const _offline = ApiException('offline', type: ApiErrorType.network);

void main() {
  late _FakeContent content;
  late List<String> pushed;

  setUp(() {
    AppLocale.languageCode.value = 'en';
    content = _FakeContent();
    pushed = [];
  });
  tearDown(() => AppLocale.languageCode.value = 'ar');

  // Loads, then state switches (the outgoing child leaves a frame after
  // its animation ends).
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<AppLocalizations> pump(WidgetTester tester, Widget child,
      {String language = 'en'}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    AppLocale.languageCode.value = language;
    await tester.pumpWidget(ProviderScope(
      overrides: [mobileContentServiceProvider.overrideWithValue(content)],
      child: MaterialApp(
        theme: AppTheme.lightFor(arabic: language == 'ar'),
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
        onGenerateRoute: (settings) {
          pushed.add(settings.name ?? '');
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(),
          );
        },
      ),
    ));
    await settle(tester);
    return lookupAppLocalizations(Locale(language));
  }

  /// Chip rows scroll sideways; bring the chip in before tapping it.
  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pump();
    await tester.tap(find.text(label));
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  /// Unmounts timers (offline auto-retry, animations) before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  group('Jobs board states', () {
    testWidgets('loading, then the list under the catalog title',
        (tester) async {
      final gate = Completer<Map<String, dynamic>>();
      content.respond = (_) => gate.future;
      final l = await pump(tester, const JobNewsScreen());

      expect(find.byType(JobNewsSkeleton), findsOneWidget);

      gate.complete(_page(['Flutter Engineer', 'Data Analyst']));
      await settle(tester);

      expect(find.text(l.jobNewsTitle), findsOneWidget);
      expect(find.text('Server title'), findsNothing);
      expect(find.text('Flutter Engineer'), findsOneWidget);
      expect(find.text('Data Analyst'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('no results for the filters offers clearing them',
        (tester) async {
      content.respond = (call) =>
          _page(call.preset == null ? ['Flutter Engineer'] : const []);
      final l = await pump(tester, const JobNewsScreen());

      await tapChip(tester, l.jobsPresetGov);
      await settle(tester);

      expect(find.byType(EmptyJobNews), findsOneWidget);
      expect(find.text('Flutter Engineer'), findsNothing);
      await unmount(tester);
    });

    testWidgets(
        'a failed first load shows the error with Retry under the chips, '
        'and Retry loads the list', (tester) async {
      content.respond = (_) => throw _serverError;
      final l = await pump(tester, const JobNewsScreen());

      expect(find.text(l.retry), findsOneWidget);
      expect(find.byType(PresetChips), findsOneWidget);
      expect(find.text(l.jobNewsTitle), findsOneWidget);

      content.respond = (_) => _page(['Flutter Engineer']);
      await tester.tap(find.text(l.retry));
      await settle(tester);

      expect(find.text('Flutter Engineer'), findsOneWidget);
      expect(find.text(l.retry), findsNothing);
      await unmount(tester);
    });

    testWidgets('a failed refresh replaces stale results with the error',
        (tester) async {
      content.respond = (_) => _page(['Old posting']);
      final l = await pump(tester, const JobNewsScreen());
      expect(find.text('Old posting'), findsOneWidget);

      content.respond = (_) => throw _serverError;
      containerOf(tester).invalidate(jobNewsFeedProvider(true));
      await settle(tester);

      expect(find.text('Old posting'), findsNothing);
      expect(find.text(l.retry), findsOneWidget);
      await unmount(tester);
    });

    testWidgets(
        'a failed filter change shows the error under the new chips, and '
        'Retry asks again for the same filters', (tester) async {
      content.respond = (call) =>
          call.preset == null ? _page(['Old posting']) : throw _serverError;
      final l = await pump(tester, const JobNewsScreen());

      await tapChip(tester, l.jobsPresetGov);
      await settle(tester);

      expect(find.text('Old posting'), findsNothing);
      expect(find.text(l.retry), findsOneWidget);
      expect(
          tester.widget<PresetChips>(find.byType(PresetChips)).selectedPreset,
          'gov');

      content.respond = (call) => _page(['Gov posting']);
      final before = content.calls.length;
      await tester.tap(find.text(l.retry));
      await settle(tester);

      expect(content.calls.skip(before).map((c) => c.preset),
          everyElement(isNotNull));
      expect(find.text('Gov posting'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('offline offers Retry and the CVs saved on the device',
        (tester) async {
      content.respond = (_) => throw _offline;
      final l = await pump(tester, const JobNewsScreen());

      expect(find.byType(OfflineView), findsOneWidget);
      await tester.tap(find.text(l.sharedOfflineOpenSaved));
      await settle(tester);

      expect(pushed, [AppRoutes.myCvs]);
      await unmount(tester);
    });

    testWidgets('"Set job title" opens the profile, where the title is edited',
        (tester) async {
      content.respond = (_) => _page(const [], profile: {'has_profile': false});
      final l = await pump(tester, const JobNewsScreen());

      await tapChip(tester, l.jobsPresetMatched);
      await settle(tester);
      await tester.tap(find.text(l.jobsMatchedSetTitle));
      await settle(tester);

      expect(pushed, [AppRoutes.profile]);
      await unmount(tester);
    });
  });

  group('Home latest jobs', () {
    testWidgets('ignore the Jobs tab search and filters', (tester) async {
      content.respond = (call) =>
          call.preset == null && call.query == null && call.region == null
              ? _page(['Home posting'])
              : _page(const []);
      await pump(tester, DashboardJobsSection(onViewAll: () {}));
      final container = containerOf(tester);
      final keepFilters = container.listen(jobNewsFiltersProvider, (_, __) {});
      addTearDown(keepFilters.close);

      container.read(jobNewsFiltersProvider.notifier)
        ..setQuery('nurse')
        ..setPreset('gov')
        ..setRegion('central');
      await settle(tester);

      expect(find.text('Home posting'), findsOneWidget);
      expect(
          content.calls,
          everyElement(predicate<_Call>(
              (c) => c.preset == null && c.query == null && c.region == null)));
      await unmount(tester);
    });

    testWidgets('a load error says so and offers Retry', (tester) async {
      content.respond = (_) => throw _serverError;
      final l = await pump(tester, DashboardJobsSection(onViewAll: () {}));

      expect(find.text(l.homeJobsEmpty), findsNothing);
      expect(find.text(l.jobsLoadFailed), findsOneWidget);

      content.respond = (_) => _page(['Home posting']);
      await tester.tap(find.text(l.retry));
      await settle(tester);

      expect(find.text('Home posting'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('offline offers the CVs saved on the device', (tester) async {
      var opened = 0;
      content.respond = (_) => throw _offline;
      final l = await pump(
          tester,
          DashboardJobsSection(
            onViewAll: () {},
            onOpenSaved: () => opened++,
          ));

      expect(find.text(l.sharedErrorNetworkSubtitle), findsOneWidget);
      await tester.tap(find.text(l.sharedOfflineOpenSaved));
      expect(opened, 1);
      await unmount(tester);
    });
  });

  group('Job text direction follows the post language', () {
    // Titles mix scripts freely; none is split or reordered by guessing.
    const titles = [
      'مطور برمجيات (Senior Software Engineer)',
      'Network Engineer - مهندس شبكات',
      'محاسب',
      'Data Analyst',
      'iOS / أندرويد 2026',
    ];

    for (final language in ['ar', 'en', 'fr', 'ur']) {
      testWidgets('$language posts', (tester) async {
        content.respond = (_) => _page(titles, language: language);
        await pump(tester, const JobNewsScreen());

        for (final title in titles) {
          final text = find.text(title);
          expect(text, findsWidgets, reason: title);
          for (final widget in tester.widgetList<Text>(text)) {
            expect(widget.textDirection, AppLocale.directionOf(language),
                reason: '$language: $title');
          }
        }
        await unmount(tester);
      });

      testWidgets('$language post details in both app languages',
          (tester) async {
        for (final app in ['ar', 'en']) {
          await pump(
              tester,
              JobNewsDetailScreen(
                  item: JobNews.fromJson({
                'id': 1,
                'language': language,
                'title': titles.first,
                'body': 'Body text',
                'category': 'tech',
              })),
              language: app);

          final title = tester.widget<Text>(find.text(titles.first));
          expect(title.textDirection, AppLocale.directionOf(language));
          final body = tester.widget<Text>(find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').contains('Body text')));
          expect(body.textDirection, AppLocale.directionOf(language),
              reason: 'app $app');
          await unmount(tester);
        }
      });
    }
  });
}
