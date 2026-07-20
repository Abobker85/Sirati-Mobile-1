class JobNews {
  final int id;
  final String language;
  final String title;
  final String? company;
  final String? location;
  final String body;
  final String category;
  final String? url;
  final String? applyUrl;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? validUntilLabel;
  final String? publishedLabel;
  final DateTime? publishedAt;

  const JobNews({
    required this.id,
    required this.language,
    required this.title,
    required this.company,
    required this.location,
    required this.body,
    required this.category,
    required this.url,
    required this.applyUrl,
    required this.validFrom,
    required this.validUntil,
    required this.validUntilLabel,
    required this.publishedLabel,
    required this.publishedAt,
  });

  factory JobNews.fromJson(Map<String, dynamic> json) {
    return JobNews(
      id: _asInt(json['id']),
      language: json['language']?.toString() ?? 'ar',
      title: json['title']?.toString() ?? '',
      company: _nullable(json['company']),
      location: _nullable(json['location']),
      body: json['body']?.toString() ?? '',
      category: json['category']?.toString() ?? 'general',
      url: _nullable(json['url']),
      applyUrl: _nullable(json['apply_url']),
      validFrom: _date(json['valid_from']),
      validUntil: _date(json['valid_until']),
      validUntilLabel: _nullable(json['valid_until_label']),
      publishedLabel: _nullable(json['published_label']),
      publishedAt: _date(json['published_at']),
    );
  }

  String? get actionUrl {
    if (applyUrl != null && applyUrl!.isNotEmpty) return applyUrl;
    if (url != null && url!.isNotEmpty) return url;
    return null;
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _nullable(dynamic value) {
  final str = value?.toString();
  if (str == null || str.isEmpty) return null;
  return str;
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
