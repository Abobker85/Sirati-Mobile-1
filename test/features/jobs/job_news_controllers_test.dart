import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/features/jobs/application/job_news_controllers.dart';
import 'package:sirati/features/jobs/domain/job_news_feed.dart';
import 'package:sirati/features/jobs/domain/job_news_filters.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';

class _Call {
  _Call({
    required this.english,
    required this.category,
    required this.preset,
    required this.city,
    required this.region,
    required this.isRemote,
    required this.query,
    required this.force,
  });

  final bool english;
  final String? category;
  final String? preset;
  final String? city;
  final String? region;
  final bool? isRemote;
  final String? query;
  final bool force;
}

class _FakeContent extends MobileContentService {
  final calls = <_Call>[];
  Object? failWith;

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
    calls.add(_Call(
      english: english,
      category: category,
      preset: preset,
      city: city,
      region: region,
      isRemote: isRemote,
      query: query,
      force: force,
    ));
    final error = failWith;
    if (error != null) throw error;
    return {
      'title': 'Jobs',
      'items': [
        {'id': calls.length, 'title': 'Job', 'body': 'b', 'category': 'tech'},
      ],
    };
  }
}

void main() {
  late _FakeContent content;
  late ProviderContainer container;

  setUp(() {
    content = _FakeContent();
    container = ProviderContainer(
      overrides: [mobileContentServiceProvider.overrideWithValue(content)],
    );
    container.listen(jobNewsFiltersProvider, (_, __) {});
  });

  tearDown(() => container.dispose());

  // Subscribing lazily lets each test arrange the fake before the first load.
  var subscribed = false;
  setUp(() => subscribed = false);
  Future<JobNewsFeed> feed() {
    if (!subscribed) {
      container.listen(jobNewsFeedProvider(true), (_, __) {});
      subscribed = true;
    }
    return container.read(jobNewsFeedProvider(true).future);
  }

  JobNewsFiltersController filters() =>
      container.read(jobNewsFiltersProvider.notifier);

  test('first load may use cache; every later load bypasses it', () async {
    await feed();
    expect(content.calls.single.force, isFalse);

    filters().setRegion('eastern');
    await feed();
    filters().setPreset('matched');
    await feed();
    final next = container.refresh(jobNewsFeedProvider(true).future);
    await next;

    expect(content.calls.length, 4);
    expect(content.calls.skip(1).every((c) => c.force), isTrue);
  });

  test('filters reach the API with "all" omitted and remote derived', () async {
    await feed();
    var call = content.calls.last;
    expect([call.category, call.preset, call.city, call.region],
        [null, null, null, null]);
    expect(call.isRemote, isFalse);

    for (final preset in JobNewsFilters.presets) {
      for (final region in JobNewsFilters.regions) {
        filters()
          ..setPreset(preset)
          ..setRegion(region)
          ..setQuery('  nurse  ');
        await feed();
        call = content.calls.last;
        expect(call.preset, preset == JobNewsFilters.all ? null : preset);
        expect(call.region, region == JobNewsFilters.all ? null : region);
        expect(call.isRemote, preset == JobNewsFilters.remote);
        expect(call.category, isNull, reason: 'category chips were removed');
        expect(call.city, isNull, reason: 'regions replace city chips');
        expect(call.query, 'nurse', reason: 'query is trimmed');
      }
    }
  });

  test('clear resets preset, region and query', () {
    filters()
      ..setPreset('matched')
      ..setRegion('southern')
      ..setQuery('x');
    expect(container.read(jobNewsFiltersProvider).isActive, isTrue);
    filters().clear();
    expect(container.read(jobNewsFiltersProvider), const JobNewsFilters());
  });

  test('a failure surfaces as an error and is not auto-retried', () async {
    content.failWith = const ApiException('offline');
    await expectLater(feed(), throwsA(isA<ApiException>()));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(jobNewsFeedProvider(true)).hasError, isTrue);
    expect(content.calls.length, 1,
        reason: 'the screen offers Retry; no silent background retries');
  });
}
