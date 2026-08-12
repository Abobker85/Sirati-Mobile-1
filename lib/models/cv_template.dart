class CvTemplate {
  final int id;
  final String slug;
  final String name;
  final String nameAr;
  final String nameEn;
  final String? previewImageUrl;
  final String languageDirection;
  final List<String> supportedLanguages;
  final List<String> supportedSections;
  final bool isDefault;

  const CvTemplate({
    required this.id,
    required this.slug,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.previewImageUrl,
    required this.languageDirection,
    required this.supportedLanguages,
    required this.supportedSections,
    required this.isDefault,
  });

  factory CvTemplate.fromJson(Map<String, dynamic> json) {
    return CvTemplate(
      id: _asInt(json['id']),
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      nameAr: json['name_ar']?.toString() ?? '',
      nameEn: json['name_en']?.toString() ?? '',
      previewImageUrl: _nullable(json['preview_image_url']),
      languageDirection: json['language_direction']?.toString() ?? 'rtl',
      supportedLanguages: _stringList(json['supported_languages']),
      supportedSections: _stringList(json['supported_sections']),
      isDefault: json['is_default'] == true,
    );
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _nullable(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}
