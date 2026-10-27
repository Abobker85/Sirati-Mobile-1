import 'package:intl/intl.dart' as intl;

/// One language's published remote strings, used for plural rules and
/// number/date formatting with that language's [locale].
class RemoteStringLayer {
  const RemoteStringLayer({required this.locale, required this.strings});

  final String locale;
  final Map<String, String> strings;
}

/// Ordered remote string sources for one app language: the language itself,
/// then (for languages without a bundled ARB) its fallback language.
///
/// Missing, blank or unformattable values are skipped; when every layer is
/// skipped the caller uses the bundled string. Remote data never throws.
class RemoteStringLookup {
  const RemoteStringLookup(this.layers);

  const RemoteStringLookup.empty() : layers = const [];

  final List<RemoteStringLayer> layers;

  bool get isEmpty => layers.every((layer) => layer.strings.isEmpty);

  /// First usable remote value for a plain (placeholder-free) label.
  String? text(String key) {
    for (final layer in layers) {
      final value = layer.strings[key];
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  /// First remote value that [render] formats without error.
  String? format(
    String key,
    String Function(String message, String locale) render,
  ) {
    for (final layer in layers) {
      final value = layer.strings[key];
      if (value == null || value.trim().isEmpty) continue;
      try {
        final result = render(value, layer.locale);
        if (result.trim().isNotEmpty) return result;
      } catch (_) {
        // Malformed remote value: try the next source.
      }
    }
    return null;
  }
}

/// Formats typed ARB placeholders exactly like gen-l10n's generated code.
abstract final class L10nPlaceholderFormat {
  /// `type: int|double|num` with an optional `format` (a NumberFormat
  /// constructor name) and `optionalParameters`.
  static String number(
    num value,
    String locale, {
    String? format,
    Map<String, Object?> optional = const {},
  }) {
    if (format == null) return '$value';
    final decimalDigits = optional['decimalDigits'] as int?;
    final name = optional['name'] as String?;
    final symbol = optional['symbol'] as String?;
    final customPattern = optional['customPattern'] as String?;
    final intl.NumberFormat formatter = switch (format) {
      'compact' => intl.NumberFormat.compact(locale: locale),
      'compactCurrency' => intl.NumberFormat.compactCurrency(
          locale: locale,
          name: name,
          symbol: symbol,
          decimalDigits: decimalDigits,
        ),
      'compactSimpleCurrency' => intl.NumberFormat.compactSimpleCurrency(
          locale: locale,
          name: name,
          decimalDigits: decimalDigits,
        ),
      'compactLong' => intl.NumberFormat.compactLong(locale: locale),
      'currency' => intl.NumberFormat.currency(
          locale: locale,
          name: name,
          symbol: symbol,
          decimalDigits: decimalDigits,
          customPattern: customPattern,
        ),
      'decimalPattern' => intl.NumberFormat.decimalPattern(locale),
      'decimalPatternDigits' => intl.NumberFormat.decimalPatternDigits(
          locale: locale,
          decimalDigits: decimalDigits,
        ),
      'decimalPercentPattern' => intl.NumberFormat.decimalPercentPattern(
          locale: locale,
          decimalDigits: decimalDigits,
        ),
      'percentPattern' => intl.NumberFormat.percentPattern(locale),
      'scientificPattern' => intl.NumberFormat.scientificPattern(locale),
      'simpleCurrency' => intl.NumberFormat.simpleCurrency(
          locale: locale,
          name: name,
          decimalDigits: decimalDigits,
        ),
      _ => throw ArgumentError.value(format, 'format', 'Unknown number format'),
    };
    return formatter.format(value);
  }

  /// `type: DateTime` with `format` (skeletons joined by `+`, as gen-l10n)
  /// or a custom pattern when `isCustomDateFormat` is true.
  static String date(
    DateTime value,
    String locale, {
    String? format,
    bool custom = false,
  }) {
    if (format == null) return '$value';
    if (custom) return intl.DateFormat(format, locale).format(value);
    final parts = format.split('+').map((part) => part.trim()).toList();
    final formatter = intl.DateFormat(parts.first, locale);
    for (final part in parts.skip(1)) {
      formatter.addPattern(part);
    }
    return formatter.format(value);
  }
}
