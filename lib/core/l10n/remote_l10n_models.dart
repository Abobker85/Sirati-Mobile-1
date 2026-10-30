import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// Language codes the app ships ARB files for.
const bundledLanguageCodes = {'ar', 'en'};

/// One enabled language from `GET /i18n/languages`.
@immutable
class RemoteLanguage {
  const RemoteLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.direction,
    this.fallback = 'en',
    this.version = 0,
  });

  /// Built-in records so the picker always offers both bundled languages.
  static const arabic = RemoteLanguage(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    direction: TextDirection.rtl,
  );
  static const english = RemoteLanguage(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    direction: TextDirection.ltr,
  );

  final String code;
  final String name;
  final String nativeName;
  final TextDirection direction;
  final String fallback;
  final int version;

  bool get isBundled => bundledLanguageCodes.contains(code);

  /// Null when the record is unusable (bad code); other fields default.
  static RemoteLanguage? tryParse(Object? json) {
    if (json is! Map) return null;
    final code = normalizeLanguageCode(json['code']);
    if (code == null) return null;
    final name = _string(json['name']) ?? code;
    final fallback = normalizeLanguageCode(json['fallback']) ??
        normalizeLanguageCode(json['fallback_code']) ??
        'en';
    return RemoteLanguage(
      code: code,
      name: name,
      nativeName: _string(json['native_name']) ?? name,
      direction: parseDirection(json['direction']) ?? defaultDirectionOf(code),
      fallback: fallback == code ? 'en' : fallback,
      version: _int(json['version']) ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
        'code': code,
        'name': name,
        'native_name': nativeName,
        'direction': direction == TextDirection.rtl ? 'rtl' : 'ltr',
        'fallback': fallback,
        'version': version,
      };

  @override
  bool operator ==(Object other) =>
      other is RemoteLanguage &&
      other.code == code &&
      other.name == name &&
      other.nativeName == nativeName &&
      other.direction == direction &&
      other.fallback == fallback &&
      other.version == version;

  @override
  int get hashCode =>
      Object.hash(code, name, nativeName, direction, fallback, version);
}

/// `GET /i18n/languages` response.
@immutable
class RemoteLanguageList {
  const RemoteLanguageList(
      {this.defaultCode = 'ar', this.languages = const []});

  static const empty = RemoteLanguageList();

  final String defaultCode;

  /// Enabled languages in the server's sort order (duplicates dropped).
  final List<RemoteLanguage> languages;

  RemoteLanguage? byCode(String code) {
    for (final language in languages) {
      if (language.code == code) return language;
    }
    return null;
  }

  /// Throws [FormatException] when the payload has no language array.
  factory RemoteLanguageList.fromJson(Object? json) {
    if (json is! Map || json['data'] is! List) {
      throw const FormatException('Languages payload has no data list');
    }
    final seen = <String>{};
    final languages = <RemoteLanguage>[];
    for (final item in json['data'] as List) {
      final language = RemoteLanguage.tryParse(item);
      if (language != null && seen.add(language.code)) {
        languages.add(language);
      }
    }
    return RemoteLanguageList(
      defaultCode: normalizeLanguageCode(json['default']) ?? 'ar',
      languages: List.unmodifiable(languages),
    );
  }

  Map<String, Object?> toJson() => {
        'default': defaultCode,
        'data': [for (final language in languages) language.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      other is RemoteLanguageList &&
      other.defaultCode == defaultCode &&
      _listEquals(other.languages, languages);

  @override
  int get hashCode => Object.hash(defaultCode, Object.hashAll(languages));
}

/// `GET /i18n/languages/{code}/strings` response plus its ETag.
@immutable
class RemoteStringBundle {
  const RemoteStringBundle({
    required this.code,
    required this.version,
    required this.strings,
    this.direction,
    this.fallback,
    this.etag,
  });

  final String code;
  final int version;
  final Map<String, String> strings;
  final TextDirection? direction;
  final String? fallback;
  final String? etag;

  /// Throws [FormatException] for a payload that is not [expectedCode]'s
  /// bundle. Non-string values are dropped, never coerced.
  factory RemoteStringBundle.fromJson(
    Object? json, {
    required String expectedCode,
    String? etag,
  }) {
    if (json is! Map || json['strings'] is! Map) {
      throw const FormatException('Strings payload has no strings map');
    }
    final code = normalizeLanguageCode(json['code']);
    if (code != expectedCode) {
      throw FormatException('Bundle for "$code", expected "$expectedCode"');
    }
    final strings = <String, String>{};
    (json['strings'] as Map).forEach((key, value) {
      if (key is String && value is String) strings[key] = value;
    });
    return RemoteStringBundle(
      code: code!,
      version: _int(json['version']) ?? 0,
      strings: Map.unmodifiable(strings),
      direction: parseDirection(json['direction']),
      fallback: normalizeLanguageCode(json['fallback']),
      etag: etag ?? _string(json['etag']),
    );
  }

  Map<String, Object?> toJson() => {
        'code': code,
        'version': version,
        if (direction != null)
          'direction': direction == TextDirection.rtl ? 'rtl' : 'ltr',
        if (fallback != null) 'fallback': fallback,
        if (etag != null) 'etag': etag,
        'strings': strings,
      };
}

/// Lower-case BCP-47-ish language code (`fr`, `pt-br`), or null.
String? normalizeLanguageCode(Object? raw) {
  if (raw is! String) return null;
  final code = raw.trim().toLowerCase().replaceAll('_', '-');
  if (code.isEmpty || code.length > 12) return null;
  for (final unit in code.codeUnits) {
    final letter = unit >= 0x61 && unit <= 0x7A;
    final digit = unit >= 0x30 && unit <= 0x39;
    if (!letter && !digit && unit != 0x2D) return null;
  }
  final first = code.codeUnitAt(0);
  if (first < 0x61 || first > 0x7A) return null;
  return code;
}

/// Direction of [code] when the server names none: intl's RTL list.
TextDirection defaultDirectionOf(String code) =>
    intl.Bidi.isRtlLanguage(code) ? TextDirection.rtl : TextDirection.ltr;

TextDirection? parseDirection(Object? raw) => switch (raw) {
      'rtl' => TextDirection.rtl,
      'ltr' => TextDirection.ltr,
      _ => null,
    };

String? _string(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

int? _int(Object? raw) => raw is int
    ? raw
    : raw is num
        ? raw.toInt()
        : raw is String
            ? int.tryParse(raw)
            : null;

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Flutter [Locale] for an app language code (`ar` -> ar_SA, `pt-br` ->
/// pt_BR, `fr` -> fr).
Locale localeForLanguageCode(String code) {
  switch (code) {
    case 'ar':
      return const Locale('ar', 'SA');
    case 'en':
      return const Locale('en', 'US');
  }
  final dash = code.indexOf('-');
  if (dash <= 0) return Locale(code);
  return Locale(
      code.substring(0, dash), code.substring(dash + 1).toUpperCase());
}

/// App language code for [locale]: the regional code when [known] has it
/// (`pt-br`), else the language subtag (`ar_SA` -> `ar`).
String languageCodeOfLocale(Locale locale,
    [Iterable<String> known = const []]) {
  final language = locale.languageCode.toLowerCase();
  final country = locale.countryCode?.toLowerCase();
  if (country != null && country.isNotEmpty) {
    final regional = '$language-$country';
    if (known.contains(regional)) return regional;
  }
  return language;
}
