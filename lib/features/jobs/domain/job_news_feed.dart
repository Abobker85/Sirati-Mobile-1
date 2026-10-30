import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';

/// What the server knows about the viewer's profile, used to explain the
/// "in my field" preset (or ask for a job title when there is none).
class JobNewsProfileContext {
  const JobNewsProfileContext({
    required this.hasProfile,
    this.careerField = '',
    this.city = '',
  });

  final bool hasProfile;
  final String careerField;
  final String city;

  /// The API sends `job_title_name` and `location`. The banner originally
  /// read `career_field` / `city`, keys the API never sends, so it could
  /// never show the user's field. Both spellings are accepted.
  factory JobNewsProfileContext.fromJson(Map<String, dynamic> json) {
    String first(List<String> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    return JobNewsProfileContext(
      hasProfile: json['has_profile'] == true,
      careerField: first(const ['job_title_name', 'career_field']),
      city: first(const ['location', 'city']),
    );
  }
}

/// Parsed `/mobile/job-news` payload.
class JobNewsFeed {
  const JobNewsFeed({
    required this.items,
    this.profile,
    this.offline = false,
  });

  final List<JobNews> items;
  final JobNewsProfileContext? profile;

  /// True when served from the offline cache.
  final bool offline;

  /// How far down the server's ranking a hero may come from.
  static const heroWindow = 3;

  /// The highest-ranked of the first [heroWindow] items worth a hero: fresh
  /// and with a real link to apply. Null when none qualifies.
  JobNews? featuredAt(DateTime now) {
    for (final item in items.take(heroWindow)) {
      if (isFreshJob(item, now) && ApplyDestination.of(item) is ApplyLink) {
        return item;
      }
    }
    return null;
  }

  /// Everything except the featured item, in server order, so no job is
  /// shown twice.
  List<JobNews> latestAt(DateTime now) {
    final featured = featuredAt(now);
    return featured == null
        ? items
        : [
            for (final item in items)
              if (!identical(item, featured)) item
          ];
  }

  factory JobNewsFeed.fromPayload(
    Map<String, dynamic> data, {
    required bool english,
  }) {
    final rawItems = data['items'];
    final rawProfile = data['profile_context'];
    return JobNewsFeed(
      // Skip malformed entries instead of rendering a blank id-0 job.
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(JobNews.fromJson)
              .toList(growable: false)
          : const [],
      profile: rawProfile is Map<String, dynamic>
          ? JobNewsProfileContext.fromJson(rawProfile)
          : null,
      offline: MobileContentService.isOfflinePayload(data),
    );
  }

  /// Shown when the first load fails and nothing is cached.
  const JobNewsFeed.empty() : this(items: const []);
}

/// Posts younger than this carry the "new" marker.
const freshJobWindow = Duration(hours: 48);

/// Whether [item] was published within [freshJobWindow] of [now]. Unknown or
/// future dates are not fresh.
bool isFreshJob(JobNews item, DateTime now) {
  final published = item.publishedAt;
  if (published == null) return false;
  final age = now.difference(published);
  return !age.isNegative && age < freshJobWindow;
}
