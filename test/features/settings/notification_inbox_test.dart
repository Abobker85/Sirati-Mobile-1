import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/domain/notification_groups.dart';
import 'package:sirati/features/settings/domain/notification_item.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/notification_target.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

NotificationItem _item(
  int id, {
  String type = '',
  String actionType = 'screen',
  String url = '',
  bool read = false,
  DateTime? at,
  String? title,
}) =>
    NotificationItem.fromJson({
      'id': id,
      'type': type,
      'title': title ?? 'Note $id',
      'body': 'Body $id',
      'is_read': read,
      'created_at': at?.toIso8601String(),
      'action_type': actionType,
      'action_url': url,
    });

/// Every server type the backend sends today, with the url it sends.
const _known = <String, (NotificationCategory, String)>{
  'cv_ready': (NotificationCategory.cv, 'my-cvs/4'),
  'cv_failed': (NotificationCategory.cv, 'my-cvs/4'),
  'cv': (NotificationCategory.cv, 'create-cv'),
  'job_match': (NotificationCategory.jobs, 'job-news/9'),
  'job': (NotificationCategory.jobs, 'job-news/9'),
  'analysis': (NotificationCategory.analysis, 'analysis/3'),
  'education': (NotificationCategory.learning, 'education/2'),
  'tip': (NotificationCategory.learning, 'cv-analysis'),
};

/// Any url the admin campaign form accepts, and what it is about.
const _urls = <String, NotificationCategory>{
  'my-cvs': NotificationCategory.cv,
  'my-cvs/12': NotificationCategory.cv,
  '/mobile/cv/3': NotificationCategory.cv,
  'create-cv': NotificationCategory.cv,
  'job-news/5': NotificationCategory.jobs,
  'jobs?ref=push': NotificationCategory.jobs,
  'analysis/7': NotificationCategory.analysis,
  'cv-analysis': NotificationCategory.analysis,
  'education': NotificationCategory.learning,
  'education/8': NotificationCategory.learning,
  'home': NotificationCategory.general,
  'settings': NotificationCategory.general,
  'notifications': NotificationCategory.general,
  'nowhere/1': NotificationCategory.general,
};

void main() {
  group('NotificationItem.category', () {
    test('known server types win over whatever url they carry', () {
      for (final MapEntry(key: type, value: (expected, _)) in _known.entries) {
        for (final url in ['', ..._urls.keys, 'https://x.io']) {
          for (final variant in [type, type.toUpperCase()]) {
            expect(_item(1, type: variant, url: url).category, expected,
                reason: '$variant + "$url"');
          }
        }
      }
    });

    test('unknown or missing types fall back to where the row opens', () {
      for (final type in ['', 'info', 'promo', 'campaign_42']) {
        for (final MapEntry(key: url, value: expected) in _urls.entries) {
          expect(_item(1, type: type, url: url).category, expected,
              reason: '"$type" + $url');
        }
        expect(_item(1, type: type).category, NotificationCategory.general,
            reason: '"$type" without a url');
        expect(
            _item(1, type: type, actionType: 'url', url: 'https://x.io')
                .category,
            NotificationCategory.general);
      }
    });

    test('type survives asRead; only cv_failed is a failure', () {
      for (final type in [..._known.keys, 'info', '']) {
        final item = _item(1, type: type, url: 'home');
        expect(item.asRead().type, type);
        expect(item.asRead().category, item.category);
        expect(item.isFailure, type == 'cv_failed');
      }
    });
  });

  group('notificationPeriodOf', () {
    final nows = [
      DateTime(2026, 10, 28, 0, 0, 30),
      DateTime(2026, 10, 28, 12),
      DateTime(2026, 10, 28, 23, 59, 59),
      DateTime(2026, 3, 1, 0, 5), // month and leap-day boundary
      DateTime(2027, 1, 1, 0, 1), // year boundary
    ];

    test('calendar-day boundaries, not 24 h spans', () {
      for (final now in nows) {
        final midnight = DateTime(now.year, now.month, now.day);
        DateTime dayStart(int back) =>
            DateTime(midnight.year, midnight.month, midnight.day - back);
        DateTime dayEnd(int back) =>
            dayStart(back - 1).subtract(const Duration(seconds: 1));

        expect(notificationPeriodOf(midnight, now), NotificationPeriod.today);
        expect(
            notificationPeriodOf(dayEnd(1), now), NotificationPeriod.yesterday);
        expect(notificationPeriodOf(dayStart(1), now),
            NotificationPeriod.yesterday);
        expect(
            notificationPeriodOf(dayEnd(2), now), NotificationPeriod.thisWeek);
        expect(notificationPeriodOf(dayStart(6), now),
            NotificationPeriod.thisWeek);
        expect(
            notificationPeriodOf(dayEnd(7), now), NotificationPeriod.earlier);
        expect(notificationPeriodOf(dayStart(400), now),
            NotificationPeriod.earlier);
      }
    });

    test('future dates count as today, missing dates as earlier', () {
      for (final now in nows) {
        expect(notificationPeriodOf(now.add(const Duration(days: 3)), now),
            NotificationPeriod.today);
        expect(notificationPeriodOf(null, now), NotificationPeriod.earlier);
      }
    });

    test('UTC timestamps are bucketed by the local day', () {
      for (final now in nows) {
        final local = DateTime(now.year, now.month, now.day - 1, 23, 30);
        expect(notificationPeriodOf(local.toUtc(), now),
            notificationPeriodOf(local, now));
      }
    });

    test('older rows never land in a newer section', () {
      for (final now in nows) {
        var last = 0;
        for (var hours = -5; hours < 24 * 30; hours++) {
          final index =
              notificationPeriodOf(now.subtract(Duration(hours: hours)), now)
                  .index;
          expect(index, greaterThanOrEqualTo(last), reason: '$hours h ago');
          last = index;
        }
      }
    });
  });

  group('groupNotifications', () {
    test('keeps every row once, sections in order, rows in server order', () {
      final now = DateTime(2026, 10, 28, 15);
      final items = [
        for (var i = 0; i < 40; i++)
          _item(i,
              read: i % 3 == 0,
              at: i % 11 == 0 ? null : now.subtract(Duration(hours: i * 7))),
      ];
      final groups = groupNotifications(items, now);

      expect([for (final g in groups) ...g.items.map((i) => i.id)]..sort(),
          [for (final i in items) i.id]);
      expect(groups.map((g) => g.period.index).toList(),
          (groups.map((g) => g.period.index).toList()..sort()));
      expect(groups.map((g) => g.period).toSet(), hasLength(groups.length));
      for (final g in groups) {
        expect(g.items, isNotEmpty);
        final ids = g.items.map((i) => i.id!).toList();
        expect(ids, [...ids]..sort(), reason: 'server order kept');
        expect(g.unreadCount, g.items.where((i) => !i.isRead).length);
        for (final i in g.items) {
          expect(notificationPeriodOf(i.createdAt, now), g.period);
        }
      }
      expect(groupNotifications(const [], now), isEmpty);
    });
  });

  final now = DateTime(2026, 10, 28, 15);
  List<NotificationItem> mixed() => [
        _item(1,
            type: 'cv_ready',
            url: 'my-cvs/4',
            at: now.subtract(const Duration(minutes: 5)),
            title: 'سيرتك الذاتية جاهزة'),
        _item(2,
            type: 'job_match',
            url: 'job-news/9',
            at: now.subtract(const Duration(hours: 2)),
            title: 'Platform Engineer في الرياض'),
        _item(3,
            type: 'analysis',
            url: 'analysis/3',
            read: true,
            at: now.subtract(const Duration(days: 1)),
            title: 'ATS result'),
        _item(4,
            type: 'cv_failed',
            url: 'my-cvs/5',
            at: now.subtract(const Duration(days: 3)),
            title: 'تعذر إكمال توليد السيرة'),
        _item(5,
            type: 'tip',
            url: 'cv-analysis',
            read: true,
            at: now.subtract(const Duration(days: 20)),
            title: 'Tip'),
        _item(6, type: 'info', read: true, title: 'Campaign'),
      ];

  Widget inbox(
    List<NotificationItem> items, {
    String language = 'en',
    bool dark = false,
    List<NotificationItem>? opened,
  }) =>
      MaterialApp(
        theme: dark
            ? AppTheme.darkFor(arabic: language == 'ar')
            : AppTheme.lightFor(arabic: language == 'ar'),
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: NotificationInbox(
            items: items,
            now: now,
            onRefresh: () async {},
            onOpen: (item) => opened?.add(item),
          ),
        ),
      );

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final language in ['en', 'ar']) {
    testWidgets('each chip shows exactly its rows ($language)', (tester) async {
      tallView(tester);
      AppLocale.languageCode.value = language;
      final items = mixed();
      await tester.pumpWidget(inbox(items, language: language));
      await tester.pumpAndSettle();
      final l10n =
          AppLocalizations.of(tester.element(find.byType(NotificationInbox)));

      Future<void> expectShown(
          String chip, bool Function(NotificationItem) keep) async {
        await tester.tap(find.widgetWithText(NotificationFilterChip, chip));
        await tester.pumpAndSettle();
        for (final item in items) {
          expect(
              find.text(item.title), keep(item) ? findsOneWidget : findsNothing,
              reason: '${item.title} under "$chip"');
        }
      }

      final present = items.map((i) => i.category).toSet();
      for (final c in NotificationCategory.values) {
        final label = notificationCategoryLabel(l10n, c);
        expect(find.widgetWithText(NotificationFilterChip, label),
            present.contains(c) ? findsOneWidget : findsNothing,
            reason: 'chip for $c only when it has rows');
        if (present.contains(c)) {
          await expectShown(label, (i) => i.category == c);
        }
      }
      await expectShown(l10n.settingsNotificationsUnread, (i) => !i.isRead);
      await expectShown(l10n.settingsNotificationsFilterAll, (_) => true);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('filter that empties after refresh shows a message, then All',
      (tester) async {
    tallView(tester);
    AppLocale.languageCode.value = 'en';
    final all = mixed();
    await tester.pumpWidget(inbox(all));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NotificationFilterChip, 'Unread'));
    await tester.pumpAndSettle();

    final read = [for (final i in all) i.asRead()];
    await tester.pumpWidget(inbox(read));
    await tester.pumpAndSettle();
    expect(find.text('Nothing in this section yet.'), findsOneWidget);

    await tester.tap(find.widgetWithText(NotificationFilterChip, 'Jobs'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(inbox([
      for (final i in read)
        if (i.category != NotificationCategory.jobs) i
    ]));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(NotificationFilterChip, 'Jobs'), findsNothing);
    for (final i
        in read.where((i) => i.category != NotificationCategory.jobs)) {
      expect(find.text(i.title), findsOneWidget,
          reason: 'a vanished category falls back to All');
    }
  });

  testWidgets('section headers count unread rows, else all rows',
      (tester) async {
    tallView(tester);
    AppLocale.languageCode.value = 'en';
    await tester.pumpWidget(inbox(mixed()));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('2 new'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('1 notification'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('1 new'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.text('2 notifications'), findsOneWidget);
    // "All" chip badge: unread rows across sections.
    expect(
        find.descendant(
            of: find.byType(NotificationFilterChip), matching: find.text('3')),
        findsOneWidget);
  });

  testWidgets('View CV only on unread cv_ready rows, and it opens the row',
      (tester) async {
    tallView(tester);
    AppLocale.languageCode.value = 'en';
    final items = [
      for (final MapEntry(key: type, value: (_, url)) in _known.entries) ...[
        _item(type.hashCode, type: type, url: url, title: '$type unread'),
        _item(type.hashCode + 1,
            type: type, url: url, read: true, title: '$type read'),
      ],
      _item(1, type: 'cv_ready', title: 'cv_ready without url'),
    ];
    final opened = <NotificationItem>[];
    await tester.pumpWidget(inbox(items, opened: opened));
    await tester.pumpAndSettle();
    expect(find.text('View CV'), findsOneWidget);
    expect(
        find.descendant(
            of: find.widgetWithText(NotificationCard, 'cv_ready unread'),
            matching: find.text('View CV')),
        findsOneWidget);
    await tester.tap(find.text('View CV'));
    expect(opened.single.title, 'cv_ready unread');
  });

  for (final language in ['en', 'ar']) {
    for (final dark in [false, true]) {
      final mode = '$language ${dark ? 'dark' : 'light'}';
      testWidgets('every category, read and unread, is AA ($mode)',
          (tester) async {
        tallView(tester);
        AppLocale.languageCode.value = language;
        final items = [
          for (final MapEntry(key: type, value: (_, url)) in _known.entries)
            for (final read in [false, true])
              _item(type.hashCode + (read ? 1 : 0),
                  type: type, url: url, read: read, at: now),
          _item(1, type: 'info', at: now),
          _item(2, type: 'info', read: true, at: now),
        ];
        await tester.pumpWidget(inbox(items, language: language, dark: dark));
        await tester.pumpAndSettle();
        expectAllTextAa('inbox $mode');
        expectAllIconsAa('inbox $mode');

        await tester.tap(find.byType(NotificationFilterChip).at(1));
        await tester.pumpAndSettle();
        expectAllTextAa('inbox selected chip $mode');
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('unread dot is a visible graphic on the unread row (>= 3:1)', () {
    for (final c in [SiratiColors.light, SiratiColors.dark]) {
      expect(AppContrast.ratio(c.primaryInk, c.primaryLight),
          greaterThanOrEqualTo(3));
    }
  });

  group('empty inbox', () {
    tearDown(() => NotificationService.instance.onNotificationTap = null);

    Widget app({String language = 'en', bool dark = false}) => ProviderScope(
          overrides: [
            mobileContentServiceProvider.overrideWithValue(_EmptyContent()),
          ],
          child: MaterialApp(
            theme: dark
                ? AppTheme.darkFor(arabic: language == 'ar')
                : AppTheme.lightFor(arabic: language == 'ar'),
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: Center(child: Text('home'))),
            routes: {'/inbox': (_) => const NotificationsScreen()},
          ),
        );

    Future<AppLocalizations> open(WidgetTester tester,
        {String language = 'en', bool dark = false}) async {
      tallView(tester);
      AppLocale.languageCode.value = language;
      SessionCache.instance.clear();
      await tester.pumpWidget(app(language: language, dark: dark));
      unawaited(tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed('/inbox'));
      await tester.pumpAndSettle();
      return AppLocalizations.of(
          tester.element(find.byType(NotificationsEmptyState)));
    }

    for (final (label, target) in [
      ('scan', const OpenScreen(NotificationScreen.cvAnalysis)),
      ('create', const OpenScreen(NotificationScreen.cvGenerator)),
    ]) {
      testWidgets('$label CTA leaves the inbox and routes like a push',
          (tester) async {
        final routed = <Map<String, dynamic>>[];
        NotificationService.instance.onNotificationTap = routed.add;
        final l10n = await open(tester);
        await tester.tap(find.text(label == 'scan'
            ? l10n.settingsNotificationsScanCta
            : l10n.settingsNotificationsCreateCvCta));
        await tester.pumpAndSettle();
        expect(routed, hasLength(1));
        expect(resolveNotificationTarget(routed.single), target,
            reason: 'the payload resolves through the real push router');
        expect(find.byType(NotificationsScreen), findsNothing);
      });
    }

    testWidgets('preview rows use the inbox tiles; no router, no buttons',
        (tester) async {
      NotificationService.instance.onNotificationTap = null;
      final l10n = await open(tester);
      final c = tester.element(find.byType(NotificationsEmptyState)).sirati;
      expect(find.text(l10n.settingsNotificationsEmptyTitle), findsOneWidget);
      expect(find.text(l10n.settingsNotificationsPreviewTitle), findsOneWidget);
      for (final category in [
        NotificationCategory.cv,
        NotificationCategory.jobs,
        NotificationCategory.analysis,
      ]) {
        final tile = notificationCategoryTile(category, c);
        expect(
            find.byWidgetPredicate(
                (w) => w is Icon && w.icon == tile.icon && w.color == tile.fg),
            findsOneWidget,
            reason: '$category preview matches its inbox tile');
      }
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
    });

    for (final language in ['en', 'ar']) {
      for (final dark in [false, true]) {
        final mode = '$language ${dark ? 'dark' : 'light'}';
        testWidgets('empty state is AA ($mode)', (tester) async {
          NotificationService.instance.onNotificationTap = (_) {};
          await open(tester, language: language, dark: dark);
          expectAllTextAa('empty inbox $mode');
          expectAllIconsAa('empty inbox $mode');
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}

class _EmptyContent extends MobileContentService {
  @override
  Future<Map<String, dynamic>> notifications({bool force = false}) async =>
      {'items': <Object>[]};
}
