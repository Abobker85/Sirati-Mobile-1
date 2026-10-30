import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/features/jobs/domain/job_news_feed.dart';
import 'package:sirati/features/jobs/domain/job_news_filters.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';

Map<String, dynamic> _job(int id) => {
      'id': id,
      'language': 'en',
      'title': 'Job $id',
      'body': 'Body $id',
      'category': 'tech',
    };

void main() {
  group('JobNewsFeed.fromPayload', () {
    test('skips malformed entries instead of rendering blank jobs', () {
      final feed = JobNewsFeed.fromPayload({
        'items': [_job(1), null, 'x', 42, [], _job(2), <String, dynamic>{}],
      }, english: true);
      // The empty map is still a map and parses; non-maps are dropped.
      expect(feed.items.where((j) => j.id != 0).map((j) => j.id), [1, 2]);
      expect(feed.items.length, 3);
    });

    test('non-list items, missing keys and wrong types never throw', () {
      for (final payload in <Map<String, dynamic>>[
        {},
        {'items': 'nope', 'profile_context': 'nope', 'title': 7},
        {'items': null, 'profile_context': null, 'title': null},
      ]) {
        expect(
          () => JobNewsFeed.fromPayload(payload, english: false),
          returnsNormally,
        );
      }
    });

    test('offline flag follows the cache marker', () {
      expect(
        JobNewsFeed.fromPayload(
          {MobileContentService.offlineMetaKey: true},
          english: true,
        ).offline,
        isTrue,
      );
      expect(JobNewsFeed.fromPayload({}, english: true).offline, isFalse);
    });
  });

  group('JobNewsProfileContext', () {
    test('reads the keys the API actually sends', () {
      final p = JobNewsProfileContext.fromJson({
        'has_profile': true,
        'job_title_name': 'Backend Developer',
        'location': 'Riyadh',
      });
      expect(p.hasProfile, isTrue);
      expect(p.careerField, 'Backend Developer');
      expect(p.city, 'Riyadh');
    });

    test('accepts the legacy keys and prefers the API ones', () {
      final legacy = JobNewsProfileContext.fromJson(
          {'career_field': 'HR', 'city': 'Jeddah'});
      expect(legacy.careerField, 'HR');
      expect(legacy.city, 'Jeddah');

      final both = JobNewsProfileContext.fromJson({
        'job_title_name': 'API',
        'career_field': 'Legacy',
        'location': 'Dammam',
        'city': 'Legacy',
      });
      expect(both.careerField, 'API');
      expect(both.city, 'Dammam');
    });

    test('only has_profile == true enables the banner', () {
      for (final raw in [null, false, 'true', 1, 'yes']) {
        expect(
          JobNewsProfileContext.fromJson({'has_profile': raw}).hasProfile,
          isFalse,
          reason: 'raw=$raw',
        );
      }
    });
  });

  group('JobNewsFilters', () {
    test('"all" is never sent to the API; other values pass through', () {
      for (final preset in JobNewsFilters.presets) {
        for (final region in JobNewsFilters.regions) {
          final f = JobNewsFilters(preset: preset, region: region);
          expect(f.presetParam, preset == JobNewsFilters.all ? null : preset);
          expect(f.regionParam, region == JobNewsFilters.all ? null : region);
          expect(f.isRemote, preset == JobNewsFilters.remote);
          expect(f.isActive,
              preset != JobNewsFilters.all || region != JobNewsFilters.all);
        }
      }
    });

    test('equality is by value and copyWith changes only what it names', () {
      const base = JobNewsFilters(preset: 'matched', region: 'eastern');
      expect(base, const JobNewsFilters(preset: 'matched', region: 'eastern'));
      expect(base.hashCode,
          const JobNewsFilters(preset: 'matched', region: 'eastern').hashCode);
      final changed = base.copyWith(query: 'nurse');
      expect(changed.preset, 'matched');
      expect(changed.region, 'eastern');
      expect(changed, isNot(base));
      expect(changed.isActive, isTrue);
    });
  });

  group('freshness and the hero', () {
    final now = DateTime.utc(2026, 10, 29, 12);
    JobNews job(int id, {Duration? age, String? applyUrl}) => JobNews.fromJson({
          'id': id,
          'title': 'Job $id',
          'body': 'b',
          'category': 'general',
          if (age != null) 'published_at': now.subtract(age).toIso8601String(),
          if (applyUrl != null) 'apply_method': 'url',
          if (applyUrl != null) 'apply_url': applyUrl,
        });

    test('fresh means published within 48 hours, not in the future', () {
      for (var h = -3; h < 80; h++) {
        expect(
            isFreshJob(job(1, age: Duration(hours: h)), now), h >= 0 && h < 48,
            reason: 'age ${h}h');
      }
      expect(isFreshJob(job(1), now), isFalse, reason: 'unknown date');
    });

    test('the hero is the best-ranked eligible item within the top 3', () {
      for (final eligibleAt in [0, 1, 2, 3, 4]) {
        final items = [
          for (var i = 0; i < 6; i++)
            job(i + 1,
                age: const Duration(hours: 1),
                applyUrl: i == eligibleAt ? 'https://jadarat.sa/x' : null),
        ];
        final feed = JobNewsFeed(items: items);
        final hero = feed.featuredAt(now);
        expect(hero?.id,
            eligibleAt < JobNewsFeed.heroWindow ? eligibleAt + 1 : null);
        final shown = [
          if (hero != null) hero.id,
          ...feed.latestAt(now).map((j) => j.id)
        ];
        expect(shown.toSet(), {for (var i = 1; i <= 6; i++) i});
        expect(shown.length, 6);
        expect(
            feed.latestAt(now).map((j) => j.id).toList(),
            [
              for (var i = 1; i <= 6; i++)
                if (i != hero?.id) i
            ],
            reason: 'the rest keep server order');
      }
    });

    test(
        'a hero needs a fresh first item with an allowed link; nothing is listed twice',
        () {
      final cases = <(Duration?, String?, bool)>[
        (const Duration(hours: 2), 'https://jadarat.sa/x', true),
        (const Duration(hours: 2), 'https://t.me/jobs/5', false),
        (const Duration(hours: 2), null, false),
        (const Duration(days: 3), 'https://jadarat.sa/x', false),
        (null, 'https://jadarat.sa/x', false),
      ];
      for (final (age, url, expectHero) in cases) {
        for (final count in [1, 2, 5]) {
          final feed = JobNewsFeed(items: [
            job(1, age: age, applyUrl: url),
            for (var i = 2; i <= count; i++)
              job(i, age: const Duration(hours: 1)),
          ]);
          expect(feed.featuredAt(now) != null, expectHero, reason: '$age $url');
          final shown = [
            if (feed.featuredAt(now) case final f?) f.id,
            ...feed.latestAt(now).map((j) => j.id),
          ];
          expect(shown, [for (var i = 1; i <= count; i++) i],
              reason: 'every item exactly once, in order');
        }
      }
    });
  });
  group('ApplyDestination guard', () {
    JobNews job(Map<String, dynamic> extra) =>
        JobNews.fromJson({'id': 1, 'title': 't', 'body': 'b', ...extra});

    test('denied hosts, shorteners and search pages never become links', () {
      for (final url in [
        'https://t.me/jobs/1',
        'https://www.t.me/jobs/1',
        'https://lnkd.in/eAb12',
        'https://clck.ru/Ab12',
        'https://dlvr.it/Ab12',
        'https://dlvr.it/Ab12?utm_source=tg',
        'https://dlvr.it/Ab12Cd34Ef56Gh7',
        'https://xyz.co/k9F2x',
        'https://example.com/hashtag/jobs',
        'https://example.com/search?x=1',
        'https://example.com/?q=%23jobs',
        'https://www.linkedin.com/in/someone',
        'http://careers.example.com/jobs/1',
        'https://10.0.0.1/jobs',
        'https://user:pw@careers.example.com/jobs',
        'https://careers.example.com:8443/jobs',
      ]) {
        for (final method in ['url', '']) {
          expect(
              ApplyDestination.of(
                  job({'apply_method': method, 'apply_url': url})),
              isA<ApplyNone>(),
              reason: '$method $url');
        }
      }
    });

    test('real careers pages are not mistaken for shorteners', () {
      for (final url in [
        'https://qiwa.sa/login',
        'https://hr.sabb.sa/Ab3k',
        'https://acme.sa/about',
        'https://herfy.com/careers',
        'https://www.uap.sa/',
        'https://jadarat.sa/ExploreJobs',
        'https://forms.gle/2HHVtUTWwp8xhM2i9',
        'https://acme.sa/jobs/12',
      ]) {
        expect(isApplyLinkAllowed(url), isTrue, reason: url);
      }
    });

    test('the source post is never the fallback', () {
      final d = ApplyDestination.of(
          job({'url': 'https://careers.example.com/jobs/1'}));
      expect(d, isA<ApplyNone>());
    });

    test('allowed links and emails resolve; method none wins over stray fields',
        () {
      expect(
          ApplyDestination.of(job(
              {'apply_method': 'url', 'apply_url': 'https://jadarat.sa/x'})),
          isA<ApplyLink>());
      expect(
          ApplyDestination.of(
              job({'apply_method': 'email', 'apply_email': 'HR@x.example'})),
          isA<ApplyEmail>()
              .having((e) => e.address, 'address', 'hr@x.example'));
      expect(
          ApplyDestination.of(job(
              {'apply_method': 'none', 'apply_url': 'https://jadarat.sa/x'})),
          isA<ApplyNone>());
    });
  });
}
