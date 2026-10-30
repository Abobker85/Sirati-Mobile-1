import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/domain/dashboard_summary.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/navigation/notification_target.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';

void main() {
  group('DashboardTab.fromIndex', () {
    test('round-trips every tab and clamps anything else to home', () {
      for (final tab in DashboardTab.values) {
        expect(DashboardTab.fromIndex(tab.index), tab);
      }
      for (final i in [-100, -1, DashboardTab.values.length, 99]) {
        expect(DashboardTab.fromIndex(i), DashboardTab.home, reason: 'i=$i');
      }
    });

    test('analytics screen names are unique', () {
      final names = DashboardTab.values.map((t) => t.screenName).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('resolveScreenRoute', () {
    const aliases = {
      'home': OpenTab(DashboardTab.home),
      'my-cvs': OpenTab(DashboardTab.myCvs),
      'mycvs': OpenTab(DashboardTab.myCvs),
      'education': OpenTab(DashboardTab.education),
      'job-news': OpenTab(DashboardTab.jobNews),
      'jobs': OpenTab(DashboardTab.jobNews),
      'cv-analysis': OpenScreen(NotificationScreen.cvAnalysis),
      'analysis-new': OpenScreen(NotificationScreen.cvAnalysis),
      'analysis': OpenScreen(NotificationScreen.cvAnalysis),
      'create-cv': OpenScreen(NotificationScreen.cvGenerator),
      'cv-generator': OpenScreen(NotificationScreen.cvGenerator),
      'notifications': OpenScreen(NotificationScreen.notifications),
      'settings': OpenScreen(NotificationScreen.settings),
    };

    test('leading/trailing slashes, case, query and fragment are ignored', () {
      for (final MapEntry(key: root, value: expected) in aliases.entries) {
        for (final form in [
          root,
          '/$root',
          '$root/',
          '//$root//',
          root.toUpperCase(),
          '$root?ref=push&x=1',
          '/$root#top',
          '  /$root  ',
        ]) {
          expect(resolveScreenRoute(form), expected, reason: form);
        }
      }
    });

    test('education carries only a positive numeric id', () {
      for (final id in [1, 7, 12345]) {
        for (final form in [
          'education/$id',
          '/education/$id/',
          'education/$id?x=1',
        ]) {
          expect(
            resolveScreenRoute(form),
            OpenTab(DashboardTab.education, educationId: id),
            reason: form,
          );
        }
      }
      for (final bad in ['0', '-3', 'abc', '1.5', '']) {
        expect(
          resolveScreenRoute('education/$bad'),
          const OpenTab(DashboardTab.education),
          reason: bad,
        );
      }
    });

    test('a CV route with a positive id opens that CV, else the My CVs tab',
        () {
      for (final root in ['cv', 'my-cvs', 'mycvs', 'CV']) {
        for (final id in [1, 9, 40213]) {
          for (final form in ['$root/$id', '/$root/$id/', '$root/$id?x=1']) {
            expect(resolveScreenRoute(form), OpenGeneratedCv(id),
                reason: form);
          }
        }
        for (final bad in ['0', '-2', 'abc', '']) {
          expect(resolveScreenRoute('$root/$bad'),
              const OpenTab(DashboardTab.myCvs),
              reason: '$root/$bad');
        }
      }
    });

    test('a leading mobile/ segment is ignored for every route', () {
      for (final route in [
        ...aliases.keys,
        'education/7',
        'cv/3',
        'job-news/12',
        'analysis/4',
      ]) {
        for (final prefix in ['mobile/', '/mobile/', 'MOBILE/']) {
          expect(resolveScreenRoute('$prefix$route'),
              resolveScreenRoute(route),
              reason: '$prefix$route');
        }
      }
      expect(resolveScreenRoute('mobile'),
          const OpenScreen(NotificationScreen.notifications));
    });

    test('a specific analysis opens history; a bare one starts a new one', () {
      expect(resolveScreenRoute('analysis/42'),
          const OpenScreen(NotificationScreen.history));
      expect(resolveScreenRoute('analysis/nope'),
          const OpenScreen(NotificationScreen.cvAnalysis));
    });

    test('unknown or empty routes fall back to the inbox', () {
      for (final route in [null, '', '   ', '/', '???', 'admin', 'x/y/z']) {
        expect(
          resolveScreenRoute(route),
          const OpenScreen(NotificationScreen.notifications),
          reason: '$route',
        );
      }
    });
  });

  group('resolveNotificationTarget', () {
    test('url actions pass the url through untouched', () {
      for (final url in [null, '', 'https://sirati.app/x', 'javascript:x']) {
        expect(
          resolveNotificationTarget({'action_type': 'url', 'action_url': url}),
          OpenExternalUrl(url),
        );
      }
    });

    test('open_cv and job_news resolve their url like a screen route', () {
      for (final type in ['open_cv', 'job_news']) {
        for (final url in [
          '/cv/5',
          'my-cvs/8',
          '/mobile/job-news/3',
          'jobs',
          'education/2',
          null,
          '',
          'admin',
        ]) {
          expect(
            resolveNotificationTarget({'action_type': type, 'action_url': url}),
            resolveScreenRoute(url),
            reason: '$type $url',
          );
        }
      }
    });

    test('unknown or missing action types open the inbox', () {
      for (final type in [null, '', 'unknown', 42]) {
        expect(
          resolveNotificationTarget(
              {'action_type': type, 'action_url': 'home'}),
          const OpenScreen(NotificationScreen.notifications),
          reason: '$type',
        );
      }
    });
  });

  group('DashboardSummary.fromPayload', () {
    test('counts are non-negative ints or null, never invented', () {
      final cases = <(Object?, int?)>[
        (null, null),
        (0, 0),
        (3, 3),
        (4.9, 4),
        ('7', 7),
        (' 8 ', 8),
        ('-1', null),
        (-5, null),
        ('abc', null),
        (double.nan, null),
        (double.infinity, null),
        (true, null),
      ];
      for (final (raw, expected) in cases) {
        final summary = DashboardSummary.fromPayload({
          'stats': {'generated_cvs': raw, 'analyses': raw},
        }, english: true);
        expect(summary.cvCount, expected, reason: '$raw');
        expect(summary.analysisCount, expected, reason: '$raw');
      }
    });

    test('unread is null only when the key is absent', () {
      expect(
        DashboardSummary.fromPayload({}, english: true).unreadNotifications,
        isNull,
      );
      for (final raw in [null, 'x', -2]) {
        expect(
          DashboardSummary.fromPayload(
            {'unread_notifications': raw},
            english: true,
          ).unreadNotifications,
          0,
          reason: '$raw',
        );
      }
      expect(
        DashboardSummary.fromPayload(
          {'unread_notifications': 5},
          english: true,
        ).unreadNotifications,
        5,
      );
    });

    test('name falls back to the cached session name', () {
      for (final raw in [null, '', '   ']) {
        expect(
          DashboardSummary.fromPayload(
            {
              'profile': {'name': raw},
            },
            english: true,
            cachedName: ' Sara ',
          ).name,
          'Sara',
        );
      }
      expect(
        DashboardSummary.fromPayload(
          {
            'profile': {'name': 'Omar'},
          },
          english: true,
          cachedName: 'Sara',
        ).name,
        'Omar',
      );
    });

    test('malformed sections never throw', () {
      for (final payload in <Map<String, dynamic>>[
        {},
        {'profile': 1, 'stats': 'x', 'latest_news': [], 'primary_action': 2},
        {'profile': null, 'stats': null, 'latest_news': null},
      ]) {
        final s = DashboardSummary.fromPayload(payload, english: false);
        expect(s.hasLatestNews, isFalse);
        expect(s.cvCount, isNull);
      }
    });

    test('offline follows the cache marker', () {
      expect(
        DashboardSummary.fromPayload(
          {MobileContentService.offlineMetaKey: true},
          english: true,
        ).offline,
        isTrue,
      );
      expect(DashboardSummary.fromPayload({}, english: true).offline, isFalse);
    });
  });
}
