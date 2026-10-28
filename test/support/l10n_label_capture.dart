import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sirati/core/l10n/remote_strings.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/remote_app_localizations.dart';

/// Runtime record of which l10n key produced which final (formatted) string.
///
/// Filled by [RecordingRemoteStringLookup] while widgets build, so the
/// mapping comes from the real label lookups, never from reading source.
class L10nLabelRecorder {
  final Map<String, Set<String>> _keysByValue = {};

  /// Final trimmed string -> every key that produced it.
  Map<String, Set<String>> get keysByValue => {
        for (final e in _keysByValue.entries) e.key: Set.unmodifiable(e.value),
      };

  void record(String key, String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    _keysByValue.putIfAbsent(text, () => <String>{}).add(key);
  }

  void clear() => _keysByValue.clear();
}

/// Remote lookup whose layers hold the bundled ARB messages, so every label
/// resolves through it (formatted by the same IcuLite path remote strings
/// use) and is recorded with its key.
class RecordingRemoteStringLookup extends RemoteStringLookup {
  RecordingRemoteStringLookup(super.layers, this.recorder);

  final L10nLabelRecorder recorder;

  @override
  String? text(String key) {
    final value = super.text(key);
    if (value != null) recorder.record(key, value);
    return value;
  }

  @override
  String? format(
    String key,
    String Function(String message, String locale) render,
  ) {
    final value = super.format(key, render);
    if (value != null) recorder.record(key, value);
    return value;
  }
}

/// Test-only replacement for the app's localizations delegate that records
/// every label lookup into [recorder].
///
/// [catalogs] maps a language code to its ARB messages (key -> ICU source);
/// see [readArbCatalog]. Values may be overridden to test arbitrary strings.
class RecordingLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const RecordingLocalizationsDelegate({
    required this.recorder,
    required this.catalogs,
  });

  final L10nLabelRecorder recorder;
  final Map<String, Map<String, String>> catalogs;

  @override
  bool isSupported(Locale locale) => catalogs.containsKey(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final code = locale.languageCode;
    return SynchronousFuture<AppLocalizations>(RemoteAppLocalizations(
      code,
      base: lookupAppLocalizations(Locale(code)),
      fallbackBase: lookupAppLocalizations(const Locale('en')),
      remote: RecordingRemoteStringLookup(
        [RemoteStringLayer(locale: code, strings: catalogs[code]!)],
        recorder,
      ),
    ));
  }

  @override
  bool shouldReload(RecordingLocalizationsDelegate old) =>
      old.recorder != recorder || old.catalogs != catalogs;
}

/// Messages of `lib/l10n/app_<language>.arb` (metadata entries dropped).
/// Paths are relative to the package root, the working dir of `flutter test`.
Map<String, String> readArbCatalog(String language) {
  final json = jsonDecode(
    File('lib/l10n/app_$language.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };
}

/// One on-screen label: the key it came from and its rect in logical px,
/// relative to the top-left of the walked root.
@immutable
class LabelHit {
  const LabelHit(this.key, this.rect);

  final String key;
  final Rect rect;

  static double _round(double v) => (v * 10).roundToDouble() / 10;

  Map<String, Object> toJson() => {
        'key': key,
        'x': _round(rect.left),
        'y': _round(rect.top),
        'w': _round(rect.width),
        'h': _round(rect.height),
      };

  @override
  bool operator ==(Object other) =>
      other is LabelHit && other.key == key && other.rect == rect;

  @override
  int get hashCode => Object.hash(key, rect);

  @override
  String toString() => 'LabelHit($key, $rect)';
}

final _wordChar = RegExp(r'[\p{L}\p{N}\p{M}]', unicode: true);

/// Walks the painted render tree under [root] and returns every text run
/// whose displayed string is a recorded label value.
///
/// Only onstage, painted content is visited (`visitChildrenForSemantics`
/// skips offstage routes, inactive IndexedStack children, transparent
/// opacity and culled list items); rects are clipped by every ancestor clip,
/// and a run covered by something painted above it (a modal barrier, a
/// bottom sheet) is dropped: see [_occluded].
/// A text node matches, in order: its whole text exactly; a span's own text
/// exactly (RichText); then the longest recorded values that occur in it on
/// word boundaries. One value with several keys yields one hit per key.
/// Results are deduped and sorted by y, then x.
List<LabelHit> findLabelHits(
  RenderObject root,
  Map<String, Set<String>> keysByValue,
) {
  final hits = <LabelHit>{};
  final rootBox = root is RenderBox ? root : null;
  final bounds = rootBox == null ? Rect.largest : Offset.zero & rootBox.size;

  void addRange(
    RenderBox box,
    List<TextBox> Function(TextSelection) boxesFor,
    int start,
    int end,
    Set<String> keys,
    Rect clip,
  ) {
    final boxes = boxesFor(TextSelection(baseOffset: start, extentOffset: end));
    if (boxes.isEmpty) return;
    var local = boxes.first.toRect();
    for (final b in boxes.skip(1)) {
      local = local.expandToInclude(b.toRect());
    }
    final global = MatrixUtils.transformRect(box.getTransformTo(root), local);
    final visible = global.intersect(clip);
    if (visible.width <= 0 || visible.height <= 0) return;
    if (rootBox != null && _occluded(rootBox, box, visible.center)) return;
    for (final key in keys) {
      hits.add(LabelHit(key, visible));
    }
  }

  void matchText(
    RenderBox box,
    InlineSpan span,
    List<TextBox> Function(TextSelection) boxesFor,
    Rect clip,
  ) {
    final plain = span.toPlainText(includeSemanticsLabels: false);
    final trimmed = plain.trim();
    if (trimmed.isEmpty) return;
    final whole = keysByValue[trimmed];
    if (whole != null) {
      final start = plain.indexOf(trimmed);
      addRange(box, boxesFor, start, start + trimmed.length, whole, clip);
      return;
    }

    // Matched ranges [start, end) so later, shorter matches don't overlap.
    final covered = <(int, int)>[];
    bool overlaps(int s, int e) => covered.any((r) => s < r.$2 && r.$1 < e);

    // Exact span text inside a RichText.
    var offset = 0;
    span.visitChildren((child) {
      if (child is TextSpan) {
        final text = child.text ?? '';
        final t = text.trim();
        final keys = t.isEmpty ? null : keysByValue[t];
        if (keys != null) {
          final s = offset + text.indexOf(t);
          addRange(box, boxesFor, s, s + t.length, keys, clip);
          covered.add((s, s + t.length));
        }
        offset += text.length;
      } else {
        offset += 1; // PlaceholderSpan: one U+FFFC in the paragraph text.
      }
      return true;
    });

    // Recorded values embedded in a longer string, longest first.
    final candidates = <(int, int, Set<String>)>[];
    for (final entry in keysByValue.entries) {
      final value = entry.key;
      if (value.length < 2 || value.length >= trimmed.length) continue;
      for (var i = plain.indexOf(value);
          i >= 0;
          i = plain.indexOf(value, i + 1)) {
        final end = i + value.length;
        final before = i == 0 ? '' : plain[i - 1];
        final after = end >= plain.length ? '' : plain[end];
        final boundary =
            !(_wordChar.hasMatch(before) && _wordChar.hasMatch(value[0])) &&
                !(_wordChar.hasMatch(after) &&
                    _wordChar.hasMatch(value[value.length - 1]));
        if (boundary) candidates.add((i, end, entry.value));
      }
    }
    candidates.sort((a, b) {
      final byLength = (b.$2 - b.$1).compareTo(a.$2 - a.$1);
      return byLength != 0 ? byLength : a.$1.compareTo(b.$1);
    });
    for (final (s, e, keys) in candidates) {
      if (overlaps(s, e)) continue;
      addRange(box, boxesFor, s, e, keys, clip);
      covered.add((s, e));
    }
  }

  void walk(RenderObject node, Rect clip) {
    if (node is RenderParagraph) {
      matchText(node, node.text, node.getBoxesForSelection, clip);
    } else if (node is RenderEditable && !node.obscureText) {
      final text = node.text;
      if (text != null) {
        matchText(node, text, node.getBoxesForSelection, clip);
      }
    }
    node.visitChildrenForSemantics((child) {
      var childClip = clip;
      final local = node.describeApproximatePaintClip(child);
      if (local != null) {
        childClip = clip.intersect(
          MatrixUtils.transformRect(node.getTransformTo(root), local),
        );
      }
      if (childClip.width <= 0 || childClip.height <= 0) return;
      walk(child, childClip);
    });
  }

  walk(root, bounds);
  final sorted = hits.toList()
    ..sort((a, b) {
      final byY = a.rect.top.compareTo(b.rect.top);
      if (byY != 0) return byY;
      final byX = a.rect.left.compareTo(b.rect.left);
      return byX != 0 ? byX : a.key.compareTo(b.key);
    });
  return sorted;
}

bool _isAncestorOrSelf(RenderObject ancestor, RenderObject node) {
  for (RenderObject? n = node; n != null; n = n.parent) {
    if (identical(n, ancestor)) return true;
  }
  return false;
}

/// Whether a hit test at [point] (root coordinates) lands on something
/// outside [text]'s own branch, i.e. a surface painted above the text.
/// Landing on the text, inside it (WidgetSpan) or on one of its ancestors
/// (IgnorePointer/AbsorbPointer around it) counts as visible. Editable text
/// is transparent here, so an empty field's hint below it stays visible.
bool _occluded(RenderBox root, RenderObject text, Offset point) {
  final result = BoxHitTestResult();
  root.hitTest(result, position: point);
  RenderEditable? editable;
  for (final entry in result.path) {
    final target = entry.target;
    if (target is! RenderObject) continue;
    if (identical(target, text)) return false;
    // A text field's editable (and its own wrappers) sits over its hint.
    if (target is RenderEditable) {
      editable = target;
      continue;
    }
    if (editable != null &&
        _isAncestorOrSelf(target, editable) &&
        !_isAncestorOrSelf(target, text)) {
      continue;
    }
    return !_isAncestorOrSelf(text, target) && !_isAncestorOrSelf(target, text);
  }
  return false;
}

/// Render objects reachable through the painted tree under [root]
/// (offstage routes and inactive tabs excluded).
Set<RenderObject> onstageRenderObjects(RenderObject root) {
  final found = <RenderObject>{};
  void walk(RenderObject node) {
    found.add(node);
    node.visitChildrenForSemantics(walk);
  }

  walk(root);
  return found;
}
