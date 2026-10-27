// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:sirati/core/l10n/icu_lite.dart';

/// Generates `lib/l10n/remote_app_localizations.dart` from the template ARB.
///
/// Usage (from `flutter_app/`):
///   dart run tool/gen_remote_l10n.dart
///
/// The output is committed. `remote_l10n_generator_sync_test.dart` fails when
/// it is out of date with `lib/l10n/app_ar.arb`.
const templateArbPath = 'lib/l10n/app_ar.arb';
const outputPath = 'lib/l10n/remote_app_localizations.dart';

Future<void> main() async {
  final arb = File(templateArbPath).readAsStringSync();
  File(outputPath).writeAsStringSync(generateRemoteLocalizations(arb));
  final format = await Process.run(
    'dart',
    ['format', outputPath],
    runInShell: Platform.isWindows,
  );
  stdout.write(format.stdout);
  stderr.write(format.stderr);
  if (format.exitCode != 0) exit(format.exitCode);
  print('Wrote $outputPath');
}

/// Names the generated lambdas use; placeholders must not shadow them.
const _reserved = {'icuMessage', 'icuLocale'};

/// Pure generator: template ARB JSON in, Dart source out (unformatted).
String generateRemoteLocalizations(String arbJson) {
  final arb = jsonDecode(arbJson) as Map<String, dynamic>;
  final out = StringBuffer()
    ..writeln('// GENERATED FILE - DO NOT EDIT BY HAND.')
    ..writeln('//')
    ..writeln('// Regenerate after changing lib/l10n/app_ar.arb (the template'
        ' ARB), from flutter_app/:')
    ..writeln('//   flutter gen-l10n && dart run tool/gen_remote_l10n.dart')
    ..writeln('// test/localization/remote_l10n_generator_sync_test.dart fails'
        ' while this file is out of date.')
    ..writeln('//')
    ..writeln('// Every label resolves: remote string of the language -> remote'
        ' string of its')
    ..writeln('// fallback language -> bundled ARB string. Methods format'
        ' remote strings with')
    ..writeln('// IcuLite; a formatting failure uses the bundled result.')
    ..writeln()
    ..writeln("import 'package:flutter/foundation.dart';")
    ..writeln("import 'package:sirati/core/l10n/icu_lite.dart';")
    ..writeln("import 'package:sirati/core/l10n/remote_strings.dart';")
    ..writeln("import 'package:sirati/l10n/generated/app_localizations.dart';")
    ..writeln()
    ..writeln('class RemoteAppLocalizations extends AppLocalizations {')
    ..writeln('  RemoteAppLocalizations(')
    ..writeln('    super.locale, {')
    ..writeln('    this.base,')
    ..writeln('    required this.fallbackBase,')
    ..writeln('    this.remote = const RemoteStringLookup.empty(),')
    ..writeln('  });')
    ..writeln()
    ..writeln('  /// Bundled localization of this language; null when it has'
        ' no ARB.')
    ..writeln('  final AppLocalizations? base;')
    ..writeln()
    ..writeln("  /// Bundled localization of the language's fallback"
        ' (default English).')
    ..writeln('  final AppLocalizations fallbackBase;')
    ..writeln()
    ..writeln('  /// Published remote strings, most specific layer first.')
    ..writeln('  final RemoteStringLookup remote;')
    ..writeln()
    ..writeln('  AppLocalizations get _base => base ?? fallbackBase;');

  final types = StringBuffer();
  final invokes = StringBuffer();
  for (final entry in arb.entries) {
    final key = entry.key;
    if (key.startsWith('@')) continue;
    final message = entry.value;
    if (message is! String) {
      throw FormatException('ARB value of "$key" is not a string');
    }
    final meta = arb['@$key'];
    final placeholders = _placeholders(key, message, meta);
    types.writeln(
        "    '$key': ${_literalList(placeholders.map((p) => p.type))},");
    var index = 0;
    final casts =
        placeholders.map((p) => 'a[${index++}] as ${p.type}').join(', ');
    invokes.writeln(placeholders.isEmpty
        ? "        '$key' => l.$key,"
        : "        '$key' => l.$key($casts),");
    out.writeln();
    out.writeln('  @override');
    if (placeholders.isEmpty) {
      out.writeln("  String get $key => remote.text('$key') ?? _base.$key;");
      continue;
    }
    final params = placeholders.map((p) => '${p.type} ${p.name}').join(', ');
    final callArgs = placeholders.map((p) => p.name).join(', ');
    final icuArgs =
        placeholders.map((p) => "'${p.name}': ${p.argExpression()}").join(', ');
    out
      ..writeln('  String $key($params) =>')
      ..writeln('      remote.format(')
      ..writeln("        '$key',")
      ..writeln('        (icuMessage, icuLocale) => IcuLite.format(')
      ..writeln('          icuMessage,')
      ..writeln('          locale: icuLocale,')
      ..writeln('          args: {$icuArgs},')
      ..writeln('        ),')
      ..writeln('      ) ??')
      ..writeln('      _base.$key($callArgs);');
  }
  out
    ..writeln()
    ..writeln(
        '  /// Placeholder Dart types of every label, in parameter order.')
    ..writeln('  @visibleForTesting')
    ..writeln('  static const debugPlaceholderTypes = <String, List<String>>{')
    ..write(types)
    ..writeln('  };')
    ..writeln()
    ..writeln('  /// Calls label [key] on [l] with positional args [a].')
    ..writeln('  @visibleForTesting')
    ..writeln('  static String debugInvoke(')
    ..writeln('    AppLocalizations l,')
    ..writeln('    String key,')
    ..writeln('    List<Object?> a,')
    ..writeln('  ) =>')
    ..writeln('      switch (key) {')
    ..write(invokes)
    ..writeln("        _ => throw ArgumentError.value(key, 'key'),")
    ..writeln('      };')
    ..writeln('}');
  return out.toString();
}

String _literalList(Iterable<String> values) =>
    '[${values.map(_literal).join(', ')}]';

class _Placeholder {
  _Placeholder(this.name, this.type, this.format, this.custom, this.optional);

  final String name;
  final String type;
  final String? format;
  final bool custom;
  final Map<String, Object?> optional;

  String argExpression() {
    if (format == null) return name;
    if (type == 'DateTime') {
      return 'IcuArgument($name, L10nPlaceholderFormat.date($name, icuLocale, '
          'format: ${_literal(format)}${custom ? ', custom: true' : ''}))';
    }
    if (type == 'int' || type == 'double' || type == 'num') {
      final optionalArg =
          optional.isEmpty ? '' : ', optional: const ${_literal(optional)}';
      return 'IcuArgument($name, L10nPlaceholderFormat.number($name, '
          'icuLocale, format: ${_literal(format)}$optionalArg))';
    }
    return name;
  }
}

List<_Placeholder> _placeholders(String key, String message, Object? meta) {
  final declared = meta is Map && meta['placeholders'] is Map
      ? Map<String, dynamic>.from(meta['placeholders'] as Map)
      : const <String, dynamic>{};
  final List<String> used;
  final Set<String> plurals = {};
  final Set<String> selects = {};
  try {
    used = IcuLite.argumentNames(message);
    void visit(List<IcuNode> nodes) {
      for (final node in nodes) {
        if (node is IcuChoice) {
          (node.isPlural ? plurals : selects).add(node.name);
          node.branches.values.forEach(visit);
        }
      }
    }

    visit(IcuLite.parse(message));
  } on IcuFormatException catch (e) {
    throw FormatException('ARB value of "$key" is not valid ICU: $e');
  }
  final names = [
    ...declared.keys,
    ...used.where((n) => !declared.containsKey(n))
  ];
  return [
    for (final name in names)
      () {
        if (_reserved.contains(name)) {
          throw FormatException('Placeholder "$name" of "$key" is reserved');
        }
        final spec = declared[name] is Map
            ? Map<String, dynamic>.from(declared[name] as Map)
            : const <String, dynamic>{};
        final type = spec['type'] as String? ??
            (plurals.contains(name)
                ? 'num'
                : selects.contains(name)
                    ? 'String'
                    : 'Object');
        final optional = spec['optionalParameters'] is Map
            ? Map<String, Object?>.from(spec['optionalParameters'] as Map)
            : const <String, Object?>{};
        return _Placeholder(
          name,
          type,
          spec['format'] as String?,
          spec['isCustomDateFormat'] == true ||
              spec['isCustomDateFormat'] == 'true',
          optional,
        );
      }(),
  ];
}

String _literal(Object? value) {
  if (value == null) return 'null';
  if (value is num || value is bool) return '$value';
  if (value is String) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r');
    return "'$escaped'";
  }
  if (value is Map) {
    final entries = value.entries
        .map((e) => '${_literal(e.key.toString())}: ${_literal(e.value)}')
        .join(', ');
    return '<String, Object?>{$entries}';
  }
  throw FormatException('Unsupported ARB metadata value: $value');
}
