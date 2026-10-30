/// Filter state for the job-news list. 'all' means "no filter" for every
/// chip group, which is what the API expects as an omitted parameter.
class JobNewsFilters {
  const JobNewsFilters({
    this.preset = all,
    this.region = all,
    this.query = '',
  });

  static const all = 'all';

  /// The "remote" preset maps to the API's is_remote filter.
  static const remote = 'remote';

  /// Presets in chip order: all, in my field, government, companies,
  /// Tamheer & training, remote.
  static const presets = [
    all,
    'matched',
    'gov',
    'enterprise',
    'tamheer',
    remote
  ];

  /// Saudi regions accepted by the API's `region` parameter.
  static const regions = [
    all,
    'central',
    'eastern',
    'western',
    'northern',
    'southern'
  ];

  final String preset;
  final String region;
  final String query;

  String? get presetParam => preset == all ? null : preset;
  String? get regionParam => region == all ? null : region;
  bool get isRemote => preset == remote;
  bool get isActive =>
      preset != all || region != all || query.trim().isNotEmpty;

  JobNewsFilters copyWith({
    String? preset,
    String? region,
    String? query,
  }) =>
      JobNewsFilters(
        preset: preset ?? this.preset,
        region: region ?? this.region,
        query: query ?? this.query,
      );

  @override
  bool operator ==(Object other) =>
      other is JobNewsFilters &&
      other.preset == preset &&
      other.region == region &&
      other.query == query;

  @override
  int get hashCode => Object.hash(preset, region, query);
}
