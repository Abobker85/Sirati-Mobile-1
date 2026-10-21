import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/sirati_colors.dart';
import 'package:xml/xml.dart';

/// Resolve the launch theme's layer-list and night-qualified resources.
void main() {
  for (final api in [19, 21, 34]) {
    test('night LaunchTheme resolves the dark surface and centred mark (API $api)',
        () {
      final table = AndroidResourceTable.parse(
        Directory('android/app/src/main/res'),
        api: api,
      );

      final night = table.launchWindowColor(night: true);
      final day = table.launchWindowColor(night: false);
      final nightSplash = table.colorValue('splash_background', night: true);
      final daySplash = table.colorValue('splash_background', night: false);

      expect(night, nightSplash);
      expect(night, SiratiColors.dark.background.toARGB32());
      expect(day, daySplash);
      expect(night, isNot(day));
      expect(_luminance(night), lessThanOrEqualTo(0.15));
      expect(_luminance(day), greaterThanOrEqualTo(0.7));
      expect(_luminance(night), lessThan(_luminance(day)));

      final drawable = table.launchBackground(night: true);
      expect(drawable.nightQualified, isTrue);
      expect(drawable.hasCenteredMark, isTrue);
      expect(drawable.color, nightSplash);
      expect(drawable.color, night);
    });
  }
}

double _luminance(int argb) {
  double channel(int value) {
    final s = value / 255;
    return s <= 0.04045
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel((argb >> 16) & 0xFF);
  final g = channel((argb >> 8) & 0xFF);
  final b = channel(argb & 0xFF);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

int _parseColor(String raw) {
  final text = raw.trim();
  if (!text.startsWith('#') || text.length < 4) {
    throw FormatException('not a colour literal: $raw');
  }
  final hex = text.substring(1);
  final expanded = (hex.length == 3 || hex.length == 4)
      ? hex.split('').map((digit) => '$digit$digit').join()
      : hex;
  final withAlpha = expanded.length == 6 ? 'FF$expanded' : expanded;
  if (withAlpha.length != 8) {
    throw FormatException('unsupported colour literal: $raw');
  }
  return int.parse(withAlpha, radix: 16);
}

class ResolvedLaunchDrawable {
  ResolvedLaunchDrawable({
    required this.color,
    required this.nightQualified,
    required this.hasCenteredMark,
  });

  final int color;
  final bool nightQualified;
  final bool hasCenteredMark;
}

class _ResourceFile {
  _ResourceFile({
    required this.type,
    required this.name,
    required this.night,
    required this.minApi,
    required this.document,
  });

  final String type;
  final String name;
  final bool night;
  final int? minApi;
  final XmlDocument document;
}

class AndroidResourceTable {
  AndroidResourceTable._(this._files, {required this.api});

  final List<_ResourceFile> _files;
  final int api;

  static AndroidResourceTable parse(Directory res, {int api = 34}) {
    final files = <_ResourceFile>[];
    for (final entity in res.listSync(followLinks: false)) {
      if (entity is! Directory) continue;
      final folder = entity.uri.pathSegments
          .where((part) => part.isNotEmpty)
          .last;
      final qualifiers = _Qualifiers.parse(folder);
      if (qualifiers == null) continue;
      for (final file in entity.listSync(followLinks: false)) {
        if (file is! File || !file.path.endsWith('.xml')) continue;
        final slash = file.path.lastIndexOf(Platform.pathSeparator);
        final filename = slash < 0 ? file.path : file.path.substring(slash + 1);
        final dot = filename.lastIndexOf('.');
        final name = dot < 0 ? filename : filename.substring(0, dot);
        files.add(
          _ResourceFile(
            type: qualifiers.type,
            name: name,
            night: qualifiers.night,
            minApi: qualifiers.minApi,
            document: XmlDocument.parse(file.readAsStringSync()),
          ),
        );
      }
    }
    return AndroidResourceTable._(files, api: api);
  }

  int launchWindowColor({required bool night}) {
    final located = _launchTheme(night: night);
    return _resolve(
      located.reference,
      deviceNight: night,
    );
  }

  /// The drawable [LaunchTheme] actually inflates for [night], including
  /// whether that layer-list centres a bitmap mark.
  ResolvedLaunchDrawable launchBackground({required bool night}) {
    final located = _launchTheme(night: night);
    final reference = located.reference;
    if (!reference.startsWith('@drawable/')) {
      fail(
        'LaunchTheme windowBackground is $reference, expected a drawable',
      );
    }
    final drawable = _best(
      _files.where(
        (file) =>
            file.type == 'drawable' &&
            file.name == reference.substring('@drawable/'.length),
      ),
      night: night,
    );
    final root = drawable.document.rootElement;
    if (root.name.local != 'layer-list') {
      fail('${drawable.name} is not a layer-list (${root.name.local})');
    }
    return ResolvedLaunchDrawable(
      color: _drawableColor(drawable, deviceNight: night),
      nightQualified: drawable.night,
      hasCenteredMark: _centeredMark(root),
    );
  }

  ({_ResourceFile style, String reference}) _launchTheme({required bool night}) {
    final style = _best(
      _files.where(
        (file) =>
            file.type == 'values' &&
            file.document
                .findAllElements('style')
                .any((style) => style.getAttribute('name') == 'LaunchTheme'),
      ),
      night: night,
    );
    final theme = style.document.findAllElements('style').firstWhere(
          (element) => element.getAttribute('name') == 'LaunchTheme',
        );
    String? reference;
    for (final item in theme.childElements) {
      if (item.name.local != 'item') continue;
      if (_attr(item, 'name') != 'android:windowBackground') continue;
      reference = item.innerText.trim();
    }
    if (reference == null || reference.isEmpty) {
      fail('LaunchTheme has no android:windowBackground item');
    }
    return (style: style, reference: reference);
  }

  int colorValue(String name, {required bool night}) {
    final file = _best(
      _files.where((file) {
        if (file.type != 'values') return false;
        return file.document.findAllElements('color').any(
              (color) => color.getAttribute('name') == name,
            );
      }),
      night: night,
    );
    final color = file.document.findAllElements('color').firstWhere(
          (element) => element.getAttribute('name') == name,
        );
    return _parseColor(color.innerText);
  }

  int _resolve(
    String reference, {
    required bool deviceNight,
  }) {
    if (reference.startsWith('#')) return _parseColor(reference);
    if (reference.startsWith('@color/')) {
      return colorValue(
        reference.substring('@color/'.length),
        night: deviceNight,
      );
    }
    if (reference.startsWith('@drawable/')) {
      final drawable = _best(
        _files.where(
          (file) =>
              file.type == 'drawable' &&
              file.name == reference.substring('@drawable/'.length),
        ),
        night: deviceNight,
      );
      return _drawableColor(drawable, deviceNight: deviceNight);
    }
    fail('unsupported resource reference $reference');
  }

  int _drawableColor(_ResourceFile drawable, {required bool deviceNight}) {
    final root = drawable.document.rootElement;
    if (root.name.local != 'layer-list') {
      fail('${drawable.name} is not a layer-list (${root.name.local})');
    }
    for (final item in root.childElements) {
      if (item.name.local != 'item') continue;
      final direct = _attr(item, 'drawable');
      if (direct != null) {
        return _resolve(
          direct,
          deviceNight: deviceNight,
        );
      }
      for (final child in item.childElements) {
        if (child.name.local != 'color') continue;
        final nested = child.innerText.trim();
        if (nested.startsWith('#') || nested.startsWith('@')) {
          return _resolve(
            nested,
            deviceNight: deviceNight,
          );
        }
      }
    }
    fail('${drawable.name} has no colour layer');
  }

  bool _centeredMark(XmlElement layerList) {
    for (final item in layerList.childElements) {
      if (item.name.local != 'item') continue;
      for (final child in item.childElements) {
        if (child.name.local != 'bitmap') continue;
        final src = _attr(child, 'src');
        if (_attr(child, 'gravity') == 'center' &&
            src == '@drawable/splash_logo') {
          return true;
        }
      }
    }
    return false;
  }

  _ResourceFile _best(Iterable<_ResourceFile> candidates, {required bool night}) {
    final compatible = candidates.where((file) {
      final minApi = file.minApi;
      if (minApi != null && api < minApi) return false;
      if (file.night && !night) return false;
      return true;
    }).toList();
    if (compatible.isEmpty) {
      fail('no resource matches night=$night');
    }
    compatible.sort((a, b) {
      if (night && a.night != b.night) {
        return (b.night ? 1 : 0).compareTo(a.night ? 1 : 0);
      }
      return (b.minApi ?? 0).compareTo(a.minApi ?? 0);
    });
    return compatible.first;
  }
}

String? _attr(XmlElement element, String localName) {
  for (final attribute in element.attributes) {
    final local = attribute.name.local;
    if (local == localName || local.endsWith(':$localName')) {
      return attribute.value;
    }
  }
  return null;
}

class _Qualifiers {
  _Qualifiers({required this.type, required this.night, required this.minApi});

  final String type;
  final bool night;
  final int? minApi;

  static _Qualifiers? parse(String folder) {
    final parts = folder.split('-');
    if (parts.isEmpty) return null;
    final kind = parts.first;
    if (kind != 'values' && kind != 'drawable') return null;
    var night = false;
    int? minApi;
    for (final part in parts.skip(1)) {
      if (part == 'night') night = true;
      if (part.startsWith('v') && part.length > 1) {
        final api = int.tryParse(part.substring(1));
        if (api != null) minApi = api;
      }
    }
    return _Qualifiers(
      type: kind == 'values' ? 'values' : 'drawable',
      night: night,
      minApi: minApi,
    );
  }
}
