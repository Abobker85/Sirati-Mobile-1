import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/application/history_controllers.dart';
import 'package:sirati/features/dashboard/domain/history_page.dart';
import 'package:sirati/features/dashboard/presentation/history/history_cards.dart';
import 'package:sirati/features/dashboard/presentation/history_screen.dart';
import 'package:sirati/features/settings/domain/notification_groups.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

import '../../support/contrast_probe.dart';

CvAnalysis _analysis(int id,
        {int score = 70, String method = 'paste', DateTime? at}) =>
    CvAnalysis.fromJson({
      'id': id,
      'created_at': at?.toIso8601String(),
      'target_job_title': 'Role $id',
      'score_total': score,
      'grade': 'B',
      'input_method': method,
    });

GeneratedCv _cv(int id, {int score = 70, DateTime? at}) =>
    GeneratedCv.fromJson({
      'id': id,
      'created_at': at?.toIso8601String(),
      'full_name': 'Sara $id',
      'target_job_title': 'Role $id',
      'score_total': score,
      'grade': 'B',
      'language': 'en',
    });

/// Serves pages of ids; each page request can be held or failed.
class _PagedApi extends CvApiService {
  final int lastPage = 3;
  final int perPage = 2;
  final requests = <String>[];
  Object? analysesError;
  Object? cvsError;
  Completer<void>? gate;

  /// Ids per page; overridable to simulate shifting pages.
  List<int> Function(int page)? idsFor;

  /// When each id happened; undated by default.
  DateTime? Function(int id)? dateFor;

  List<int> _ids(int page) =>
      idsFor?.call(page) ??
      [for (var i = 0; i < perPage; i++) (page - 1) * perPage + i + 1];

  @override
  Future<PagedList<CvAnalysis>> listAnalysesPage({int page = 1}) async {
    requests.add('a$page');
    await gate?.future;
    if (analysesError != null) throw analysesError!;
    return PagedList(
      items: [
        for (final id in _ids(page)) _analysis(id, at: dateFor?.call(id)),
      ],
      currentPage: page,
      lastPage: lastPage,
    );
  }

  @override
  Future<PagedList<GeneratedCv>> listGeneratedCvsPage({int page = 1}) async {
    requests.add('c$page');
    if (cvsError != null) throw cvsError!;
    return PagedList(
      items: [for (final id in _ids(page)) _cv(id, at: dateFor?.call(id))],
      currentPage: page,
      lastPage: lastPage,
    );
  }
}

void main() {
  // Tests below switch the app language; put it back after each one so no
  // later test inherits it.
  final startLanguage = AppLocale.languageCode.value;
  tearDown(() => AppLocale.languageCode.value = startLanguage);

  group('historySections', () {
    test('keeps every item once, in order, in runs of one period', () {
      final now = DateTime(2026, 11, 20, 9);
      final random = Random(7);
      for (var round = 0; round < 200; round++) {
        final dates = [
          for (var i = 0; i < random.nextInt(25); i++)
            random.nextInt(6) == 0
                ? null
                : now.subtract(Duration(hours: random.nextInt(24 * 20))),
        ];
        final sections = historySections(dates, (d) => d, now);
        // Flattened, the sections are the list itself with its indices.
        expect([for (final s in sections) ...s.items],
            [for (final (i, d) in dates.indexed) (i, d)]);
        for (final (i, section) in sections.indexed) {
          expect(section.items, isNotEmpty);
          for (final (_, d) in section.items) {
            expect(notificationPeriodOf(d, now), section.period);
          }
          if (i > 0) expect(sections[i - 1].period, isNot(section.period));
        }
      }
    });
  });

  group('HistoryPage.append', () {
    test('never duplicates an id and keeps first-seen order', () {
      for (final (first, next) in <(List<int>, List<int>)>[
        ([1, 2], [3, 4]),
        ([1, 2], [2, 3]), // page shifted by one new item
        ([1, 2], [1, 2]),
        ([], [1, 1, 2]),
        ([5], []),
      ]) {
        final page = HistoryPage<int>(items: first, page: 1, hasMore: true)
            .append(next, nextPage: 2, nextHasMore: false, idOf: (i) => i);
        expect(page.items.toSet().length, page.items.length,
            reason: '$first + $next');
        expect(page.items, [
          ...first,
          ...next.where((i) => !first.contains(i)).toSet(),
        ]);
        expect(page.page, 2);
        expect(page.hasMore, isFalse);
        expect(page.loadingMore, isFalse);
        expect(page.loadMoreFailed, isFalse);
      }
    });

    test('input method labels are localised and total', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final ar = lookupAppLocalizations(const Locale('ar'));
      for (final m in ['upload', 'mixed', 'paste', null, 'other']) {
        expect(inputMethodLabel(m, en), isNot(matches(r'[؀-ۿ]')));
        expect(inputMethodLabel(m, ar), matches(r'[؀-ۿ]'));
        expect(inputMethodLabel(m, en), isNotEmpty);
      }
      // Distinct methods never collapse onto one label.
      for (final l in [en, ar]) {
        expect(
          {
            for (final m in ['upload', 'mixed', 'paste']) inputMethodLabel(m, l)
          },
          hasLength(3),
        );
      }
    });
  });

  group('PagedHistoryController', () {
    late _PagedApi api;
    late ProviderContainer container;

    setUp(() {
      api = _PagedApi();
      container = ProviderContainer(
        overrides: [cvApiServiceProvider.overrideWithValue(api)],
      );
      container.listen(analysesHistoryProvider, (_, __) {});
    });
    tearDown(() => container.dispose());

    HistoryPage<CvAnalysis> page() =>
        container.read(analysesHistoryProvider).value!;
    AnalysesHistoryController ctrl() =>
        container.read(analysesHistoryProvider.notifier);

    test('pages until the end, then load-more is a no-op', () async {
      await container.read(analysesHistoryProvider.future);
      for (var i = 0; i < 5; i++) {
        await ctrl().loadMore();
      }
      expect(page().items.map((a) => a.id), [1, 2, 3, 4, 5, 6]);
      expect(page().hasMore, isFalse);
      expect(api.requests, ['a1', 'a2', 'a3']);
    });

    test('concurrent load-more calls fetch one page', () async {
      await container.read(analysesHistoryProvider.future);
      api.gate = Completer<void>();
      final calls = [for (var i = 0; i < 3; i++) ctrl().loadMore()];
      api.gate!.complete();
      await Future.wait(calls);
      expect(api.requests, ['a1', 'a2']);
    });

    test('a load-more that finishes after a refresh is discarded', () async {
      await container.read(analysesHistoryProvider.future);
      final oldGate = Completer<void>();
      api.gate = oldGate;
      final stale = ctrl().loadMore();
      await Future<void>.delayed(Duration.zero);

      api.gate = null;
      final refreshed = container.refresh(analysesHistoryProvider.future);
      await refreshed;
      oldGate.complete(); // the pre-refresh page 2 arrives late
      await stale;

      expect(page().items.map((a) => a.id), [1, 2],
          reason: 'page 2 of the old list must not land on the new one');
    });

    test('a failed load-more keeps the rows and can be retried', () async {
      await container.read(analysesHistoryProvider.future);
      api.analysesError = const ApiException('offline');
      await ctrl().loadMore();
      expect(page().items.map((a) => a.id), [1, 2]);
      expect(page().loadMoreFailed, isTrue);
      expect(page().loadingMore, isFalse);

      api.analysesError = null;
      await ctrl().loadMore();
      expect(page().items.map((a) => a.id), [1, 2, 3, 4]);
      expect(page().loadMoreFailed, isFalse);
    });

    test('shifted pages do not duplicate rows', () async {
      api.idsFor = (page) => page == 1 ? [5, 4] : [4, 3];
      container.invalidate(analysesHistoryProvider);
      await container.read(analysesHistoryProvider.future);
      await ctrl().loadMore();
      expect(page().items.map((a) => a.id), [5, 4, 3]);
    });
  });

  group('HistoryScreen', () {
    Widget app(CvApiService api, {ThemeData? theme}) => ProviderScope(
          overrides: [cvApiServiceProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: theme ?? AppTheme.lightFor(arabic: false),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const HistoryScreen(),
          ),
        );

    setUp(() => AppLocale.languageCode.value = 'en');

    testWidgets('one failing tab does not hide the other', (tester) async {
      final api = _PagedApi()..analysesError = const ApiException('down');
      await tester.pumpWidget(app(api));
      await tester.pumpAndSettle();
      expect(find.byType(AnalysisHistoryCard), findsNothing);

      await tester.tap(find.text('Generated CVs'));
      await tester.pumpAndSettle();
      expect(find.byType(GeneratedCvHistoryCard), findsWidgets);
    });

    for (final language in ['en', 'ar']) {
      for (final dark in [false, true]) {
        final mode = '$language ${dark ? 'dark' : 'light'}';
        testWidgets(
            'each tab is date headers over white cards on the grey page, '
            'and Load more still adds rows ($mode)', (tester) async {
          tester.view.physicalSize = const Size(800, 3000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          AppLocale.languageCode.value = language;
          final now = DateTime.now();
          final dates = <int, DateTime?>{
            1: now,
            2: now,
            3: now.subtract(const Duration(days: 1)),
            4: now.subtract(const Duration(days: 30)),
            5: null,
            6: now.subtract(const Duration(days: 40)),
          };
          final api = _PagedApi()..dateFor = (id) => dates[id];
          await tester.pumpWidget(ProviderScope(
            overrides: [cvApiServiceProvider.overrideWithValue(api)],
            child: MaterialApp(
              theme: dark
                  ? AppTheme.darkFor(arabic: language == 'ar')
                  : AppTheme.lightFor(arabic: language == 'ar'),
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const HistoryScreen(),
            ),
          ));
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(HistoryScreen));
          final c = context.sirati;
          final l10n = AppLocalizations.of(context);
          expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
              c.groupedBackground);

          void expectTab(Type rowType, List<int> ids) {
            final sections =
                historySections(ids, (id) => dates[id], DateTime.now());
            final found = find.byType(AppListSection);
            expect(found, findsNWidgets(sections.length));
            for (final (i, section) in sections.indexed) {
              final widget = tester.widget<AppListSection>(found.at(i));
              expect(widget.header, historyPeriodLabel(l10n, section.period));
              final card = find.descendant(
                  of: found.at(i),
                  matching: find.byKey(AppListSection.cardKey));
              expect(tester.widget<Material>(card).color, c.groupedCard);
              expect(find.descendant(of: card, matching: find.byType(rowType)),
                  findsNWidgets(section.items.length));
              expect(find.descendant(of: card, matching: find.byType(Divider)),
                  findsNWidgets(section.items.length - 1));
            }
            expectAllTextAa('history $mode $rowType');
          }

          expectTab(AnalysisHistoryCard, [1, 2]);
          await tester.tap(find.byType(LoadMoreFooter));
          await tester.pumpAndSettle();
          expect(api.requests, contains('a2'));
          expectTab(AnalysisHistoryCard, [1, 2, 3, 4]);

          await tester.tap(find.text(l10n.dashboardHistoryGeneratedCvsTab));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(LoadMoreFooter));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(LoadMoreFooter));
          await tester.pumpAndSettle();
          expectTab(GeneratedCvHistoryCard, [1, 2, 3, 4, 5, 6]);
          expect(find.byType(LoadMoreFooter), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final language in ['en', 'ar']) {
      for (final reduce in [false, true]) {
        testWidgets(
            'tabs are the shared segmented control on the grouped page '
            '($language, reduced motion: $reduce)', (tester) async {
          AppLocale.languageCode.value = language;
          await tester.pumpWidget(ProviderScope(
            overrides: [cvApiServiceProvider.overrideWithValue(_PagedApi())],
            child: MaterialApp(
              theme: AppTheme.lightFor(arabic: language == 'ar'),
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              builder: (context, child) => MediaQuery(
                data:
                    MediaQuery.of(context).copyWith(disableAnimations: reduce),
                child: child!,
              ),
              home: const HistoryScreen(),
            ),
          ));
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(TabBarView));
          final l10n = AppLocalizations.of(context);
          expect(Directionality.of(context),
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
          expect(PageSurface.of(context), PageSurfaceKind.grouped,
              reason: 'the control follows the grouped page palette');
          expect(find.byType(TabBar), findsNothing);
          final bar = tester
              .widget<AppSegmentedTabBar>(find.byType(AppSegmentedTabBar));
          expect(bar.textScaler, MediaQuery.textScalerOf(context));
          final controller = DefaultTabController.of(context);
          expect(controller.animationDuration,
              reduce ? Duration.zero : isNot(Duration.zero));

          // The page strip behind the tabs: page i rests at i page widths.
          final pages = tester.state<ScrollableState>(find
              .descendant(
                  of: find.byType(TabBarView),
                  matching: find.byType(Scrollable))
              .first);
          final width = tester.getSize(find.byType(TabBarView)).width;
          final analyses = find.byType(AnalysisHistoryCard).first;

          for (final (target, label) in [
            (1, l10n.dashboardHistoryGeneratedCvsTab),
            (0, l10n.analyses),
          ]) {
            await tester.tap(find.text(label));
            await tester.pump();
            final offset = pages.position.pixels;
            if (reduce) {
              // One frame later the pages have jumped, not slid.
              expect(offset, target * width, reason: 'to $label');
            } else {
              expect(offset, isNot(target * width), reason: 'to $label slides');
            }
            await tester.pumpAndSettle();
            expect(pages.position.pixels, target * width);
            expect(controller.index, target);
          }
          expect(analyses.hitTestable(), findsOneWidget);
          expect(
              find.byType(GeneratedCvHistoryCard).hitTestable(), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final language in ['en', 'ar']) {
      testWidgets('the tab bar grows with the text scale ($language)',
          (tester) async {
        AppLocale.languageCode.value = language;
        // The reserved height, read while that scale is live (the system
        // scaler reads the current factor).
        Future<double> pumpAt(double scale) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(ProviderScope(
            key: UniqueKey(),
            overrides: [cvApiServiceProvider.overrideWithValue(_PagedApi())],
            child: MaterialApp(
              theme: AppTheme.lightFor(arabic: language == 'ar'),
              locale: Locale(language),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const HistoryScreen(),
            ),
          ));
          await tester.pumpAndSettle();
          final bar = tester
              .widget<AppSegmentedTabBar>(find.byType(AppSegmentedTabBar));
          final scaler =
              MediaQuery.textScalerOf(tester.element(find.byType(TabBarView)));
          expect(scaler.scale(10), closeTo(10 * scale, 1e-9),
              reason: 'the page really is at ${scale}x');
          final height = bar.preferredSize.height;
          expect(height,
              AppSegmentedControl.heightFor(scaler) + bar.padding.vertical,
              reason: 'the app bar reserves the control at ${scale}x');
          return height;
        }

        final normal = await pumpAt(1);
        final large = await pumpAt(2);
        expect(large, greaterThan(normal));
        final context = tester.element(find.byType(TabBarView));

        // Both labels are on screen and switch the page at 2x.
        final l10n = AppLocalizations.of(context);
        final controller = DefaultTabController.of(context);
        for (final (index, label) in [
          (1, l10n.dashboardHistoryGeneratedCvsTab),
          (0, l10n.analyses),
        ]) {
          expect(find.text(label).hitTestable(), findsOneWidget);
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
          expect(controller.index, index, reason: label);
        }
        expect(tester.takeException(), isNull);
      });
    }

    for (final (mode, theme) in [
      ('light', AppTheme.lightFor(arabic: false)),
      ('dark', AppTheme.darkFor(arabic: false)),
    ]) {
      testWidgets('history cards are AA in every score band ($mode)',
          (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ListView(
              children: [
                for (final score in [0, 49, 50, 64, 65, 79, 80, 100]) ...[
                  AnalysisHistoryCard(
                    analysis: _analysis(score, score: score, method: 'upload'),
                    onTap: () {},
                  ),
                  GeneratedCvHistoryCard(
                    cv: _cv(score, score: score),
                    onTap: () {},
                  ),
                ],
                LoadMoreFooter(loading: false, failed: true, onPressed: () {}),
              ],
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expectAllTextAa('history $mode');
      });
    }
  });
}
