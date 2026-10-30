import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sirati/core/l10n/icu_lite.dart';
import 'package:sirati/core/l10n/remote_strings.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/l10n/remote_app_localizations.dart';

/// Runtime record of which l10n key produced which final (formatted) string.
///
/// Filled by [RecordingRemoteStringLookup] while widgets build, so the
/// mapping comes from the real label lookups, never from reading source.
class L10nLabelRecorder {
  final Map<String, Set<String>> _keysByValue = {};
  final Map<(String, String), Map<String, String>> _args = {};

  /// Final trimmed string -> every key that produced it.
  Map<String, Set<String>> get keysByValue => {
        for (final e in _keysByValue.entries) e.key: Set.unmodifiable(e.value),
      };

  /// (key, final trimmed string) -> the placeholder arguments, as displayed
  /// text keyed by placeholder name, of the call that produced it.
  Map<(String, String), Map<String, String>> get argsByKeyValue => {
        for (final e in _args.entries) e.key: Map.unmodifiable(e.value),
      };

  void record(String key, String value, [Map<String, String>? args]) {
    final text = value.trim();
    if (text.isEmpty) return;
    _keysByValue.putIfAbsent(text, () => <String>{}).add(key);
    if (args != null && args.isNotEmpty) _args[(key, text)] = args;
  }

  void clear() {
    _keysByValue.clear();
    _args.clear();
  }
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
    if (value != null) recorder.record(key, value, _args(key, value, render));
    return value;
  }

  /// Arguments of the call: [render] closes over them, so rendering a bare
  /// `{name}` message per placeholder of the layer that produced [value]
  /// yields each argument's display text (number/date formats applied).
  Map<String, String>? _args(
    String key,
    String value,
    String Function(String message, String locale) render,
  ) {
    for (final layer in layers) {
      final message = layer.strings[key];
      if (message == null || message.trim().isEmpty) continue;
      try {
        if (render(message, layer.locale) != value) continue;
        return {
          for (final name in IcuLite.argumentNames(message))
            name: render('{$name}', layer.locale),
        };
      } catch (_) {
        continue;
      }
    }
    return null;
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

double _round(double v) => (v * 10).roundToDouble() / 10;

String _hex(int rgb) =>
    '#${(rgb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// How a label's text is painted, read from the laid-out render object, so
/// the admin can repaint edited text over the screenshot.
@immutable
class LabelStyle {
  const LabelStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.opacity,
    required this.align,
    required this.direction,
    required this.lineHeight,
    required this.maxLines,
    required this.lines,
    this.maxWidth,
  });

  /// Null when the style names none (the platform font is used).
  final String? fontFamily;

  /// Logical px, text scaling applied.
  final double fontSize;

  /// 100..900.
  final int fontWeight;

  /// Text colour without alpha (`0xRRGGBB`).
  final int color;

  /// Colour alpha times every ancestor opacity, 0..1.
  final double opacity;

  /// [TextAlign] name.
  final String align;

  /// [TextDirection] name (`rtl` / `ltr`).
  final String direction;

  /// Laid-out height of the line holding the label, logical px.
  final double lineHeight;
  final int? maxLines;

  /// Laid-out line count of the whole paragraph.
  final int lines;

  /// Widest the text may grow (its layout constraint), logical px; null when
  /// unbounded. The painted rect only hugs the current text.
  final double? maxWidth;

  Map<String, Object?> toJson() => {
        'font_family': fontFamily,
        'font_size': _round(fontSize),
        'font_weight': fontWeight,
        'color': _hex(color),
        'opacity': (opacity * 1000).roundToDouble() / 1000,
        'align': align,
        'direction': direction,
        'line_height': _round(lineHeight),
        'max_lines': maxLines,
        'lines': lines,
        if (maxWidth case final w?) 'max_width': _round(w),
      };
}

/// One on-screen label: the key it came from and its rect in logical px,
/// relative to the top-left of the walked root, plus the painted paragraph
/// [text], the part of it that came from this key ([value]), the call's
/// placeholder [args] (when the key has any) and its [style].
@immutable
class LabelHit {
  const LabelHit(
    this.key,
    this.rect, {
    this.text = '',
    this.value = '',
    this.args,
    this.style,
  });

  final String key;
  final Rect rect;
  final String text;
  final String value;
  final Map<String, String>? args;
  final LabelStyle? style;

  /// Manifest entry; [bg] is the sampled background colour (`0xRRGGBB`).
  Map<String, Object?> toJson({int? bg}) => {
        'key': key,
        'x': _round(rect.left),
        'y': _round(rect.top),
        'w': _round(rect.width),
        'h': _round(rect.height),
        'text': text,
        'value': value,
        if (args case final a? when a.isNotEmpty) 'args': a,
        if (style case final s?) 'style': s.toJson(),
        if (bg != null) 'bg': _hex(bg),
      };

  @override
  bool operator ==(Object other) =>
      other is LabelHit && other.key == key && other.rect == rect;

  @override
  int get hashCode => Object.hash(key, rect);

  @override
  String toString() => 'LabelHit($key, $rect)';
}

/// Effective (merged) style of the span holding [offset] in [root]'s plain
/// text (placeholders count as one character).
TextStyle? _styleAt(InlineSpan root, int offset) {
  TextStyle? found;
  var position = 0;
  bool visit(InlineSpan span, TextStyle? inherited) {
    final own = span.style;
    final style = inherited == null
        ? own
        : (own == null ? inherited : inherited.merge(own));
    if (span is TextSpan) {
      final length = span.text?.length ?? 0;
      if (offset >= position && offset < position + length) {
        found = style;
        return false;
      }
      position += length;
      for (final child in span.children ?? const <InlineSpan>[]) {
        if (!visit(child, style)) return false;
      }
    } else {
      if (offset == position) {
        found = style;
        return false;
      }
      position += 1;
    }
    return true;
  }

  visit(root, null);
  return found ?? root.style;
}

/// A painter laid out like [box]'s own (same text, options and width
/// constraints), for the line metrics the render objects keep private.
TextPainter? _relayout(RenderBox box) {
  if (box is RenderParagraph) {
    final painter = TextPainter(
      text: box.text,
      textAlign: box.textAlign,
      textDirection: box.textDirection,
      textScaler: box.textScaler,
      maxLines: box.maxLines,
      ellipsis: box.overflow == TextOverflow.ellipsis ? '…' : null,
      locale: box.locale,
      strutStyle: box.strutStyle,
      textWidthBasis: box.textWidthBasis,
      textHeightBehavior: box.textHeightBehavior,
    );
    final placeholders = <PlaceholderSpan>[];
    box.text.visitChildren((span) {
      if (span is PlaceholderSpan) placeholders.add(span);
      return true;
    });
    if (placeholders.isNotEmpty) {
      final children = <RenderBox>[];
      box.visitChildren((c) {
        if (c is RenderBox) children.add(c);
      });
      Size sizeOf(int i) => i < children.length && children[i].hasSize
          ? children[i].size
          : Size.zero;
      painter.setPlaceholderDimensions([
        for (final (i, span) in placeholders.indexed)
          PlaceholderDimensions(
            size: sizeOf(i),
            alignment: span.alignment,
            baseline: span.baseline,
            baselineOffset: span.alignment == ui.PlaceholderAlignment.baseline
                ? sizeOf(i).height
                : null,
          ),
      ]);
    }
    final c = box.constraints;
    painter.layout(
      minWidth: c.minWidth,
      maxWidth: box.softWrap || box.overflow == TextOverflow.ellipsis
          ? c.maxWidth
          : double.infinity,
    );
    return painter;
  }
  if (box is RenderEditable && box.text != null) {
    final painter = TextPainter(
      text: box.text,
      textAlign: box.textAlign,
      textDirection: box.textDirection,
      textScaler: box.textScaler,
      maxLines: box.maxLines,
      locale: box.locale,
      strutStyle: box.strutStyle,
      textWidthBasis: box.textWidthBasis,
      textHeightBehavior: box.textHeightBehavior,
    );
    // RenderEditable keeps a 1 px caret gap plus the cursor width free.
    final c = box.constraints;
    final maxWidth = max(0.0, c.maxWidth - 1.0 - box.cursorWidth);
    painter.layout(
      minWidth: box.forceLine ? maxWidth : min(c.minWidth, maxWidth),
      maxWidth: box.maxLines == 1 ? double.infinity : maxWidth,
    );
    return painter;
  }
  return null;
}

LabelStyle _labelStyle(
  RenderBox box,
  InlineSpan span,
  int start,
  int end,
  double opacity, {
  double scale = 1.0,
  double atLeast = 0.0,
}) {
  final (align, direction, scaler, maxLines) = switch (box) {
    RenderParagraph p => (
        p.textAlign,
        p.textDirection,
        p.textScaler,
        p.maxLines
      ),
    RenderEditable e => (
        e.textAlign,
        e.textDirection,
        e.textScaler,
        e.maxLines
      ),
    _ => (TextAlign.start, TextDirection.ltr, TextScaler.noScaling, null),
  };
  final style = _styleAt(span, start);
  final color =
      style?.color ?? style?.foreground?.color ?? const Color(0xFF000000);
  final fontSize = scaler.scale(style?.fontSize ?? kDefaultFontSize);
  var lines = 1;
  var lineHeight = fontSize * (style?.height ?? 1.0);
  final painter = _relayout(box);
  if (painter != null) {
    final metrics = painter.computeLineMetrics();
    if (metrics.isNotEmpty) {
      lines = metrics.length;
      final boxes = painter.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end));
      final y =
          boxes.isEmpty ? null : (boxes.first.top + boxes.first.bottom) / 2;
      var line = metrics.first;
      for (final m in metrics) {
        if (y != null &&
            y >= m.baseline - m.ascent - 0.01 &&
            y <= m.baseline + m.descent + 0.01) {
          line = m;
          break;
        }
      }
      lineHeight = line.height;
    }
    painter.dispose();
  }
  var maxWidth = box.constraints.maxWidth;
  // RenderEditable keeps a 1 px caret gap plus the cursor width free.
  if (box is RenderEditable) maxWidth -= 1.0 + box.cursorWidth;
  return LabelStyle(
    fontFamily: style?.fontFamily,
    fontSize: fontSize,
    fontWeight: (style?.fontWeight ?? FontWeight.normal).value,
    color: color.toARGB32() & 0xFFFFFF,
    opacity: (color.a * opacity).clamp(0.0, 1.0),
    align: align.name,
    direction: direction.name,
    lineHeight: lineHeight,
    maxLines: maxLines,
    lines: lines,
    // In root units; overflowing text (no wrap) may already be wider.
    maxWidth: maxWidth.isFinite ? max(maxWidth * scale, atLeast) : null,
  );
}

/// Background colour (`0xRRGGBB`) behind [rect] (logical px) in an RGBA
/// image ([rgba], [width] x [height] device px at [pixelRatio]): the most
/// common colour on the rings 2..4 device px outside the rect, where glyphs
/// do not reach. Translucent pixels are composited over white.
int sampleBackground(
  ByteData rgba,
  int width,
  int height,
  Rect rect,
  double pixelRatio,
) {
  final counts = <int, int>{};
  void sample(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final i = (y * width + x) * 4;
    final a = rgba.getUint8(i + 3);
    int over(int c) => (c * a + 255 * (255 - a) + 127) ~/ 255;
    final rgb = (over(rgba.getUint8(i)) << 16) |
        (over(rgba.getUint8(i + 1)) << 8) |
        over(rgba.getUint8(i + 2));
    counts[rgb] = (counts[rgb] ?? 0) + 1;
  }

  final left = (rect.left * pixelRatio).floor();
  final top = (rect.top * pixelRatio).floor();
  final right = (rect.right * pixelRatio).ceil() - 1;
  final bottom = (rect.bottom * pixelRatio).ceil() - 1;
  for (var d = 2; d <= 4; d++) {
    for (var x = left - d; x <= right + d; x++) {
      sample(x, top - d);
      sample(x, bottom + d);
    }
    for (var y = top - d + 1; y < bottom + d; y++) {
      sample(left - d, y);
      sample(right + d, y);
    }
  }
  if (counts.isEmpty) return 0xFFFFFF;
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
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
///
/// Each hit also carries the paragraph's plain [LabelHit.text], the matched
/// [LabelHit.value], the call's arguments from [args] (see
/// [L10nLabelRecorder.argsByKeyValue]) and the style of the span holding it.
List<LabelHit> findLabelHits(
  RenderObject root,
  Map<String, Set<String>> keysByValue, {
  Map<(String, String), Map<String, String>> args = const {},
}) {
  final hits = <LabelHit>{};
  final rootBox = root is RenderBox ? root : null;
  final bounds = rootBox == null ? Rect.largest : Offset.zero & rootBox.size;

  void addRange(
    RenderBox box,
    InlineSpan span,
    List<TextBox> Function(TextSelection) boxesFor,
    int start,
    int end,
    Set<String> keys,
    Rect clip,
    double opacity,
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
    final plain = span.toPlainText(includeSemanticsLabels: false);
    final value = plain.substring(start, end);
    final text = span.toPlainText(
        includeSemanticsLabels: false, includePlaceholders: false);
    final style = _labelStyle(box, span, start, end, opacity,
        scale: local.width > 0 ? global.width / local.width : 1.0,
        atLeast: visible.width);
    for (final key in keys) {
      hits.add(LabelHit(key, visible,
          text: text, value: value, args: args[(key, value)], style: style));
    }
  }

  void matchText(
    RenderBox box,
    InlineSpan span,
    List<TextBox> Function(TextSelection) boxesFor,
    Rect clip,
    double opacity,
  ) {
    void add(int s, int e, Set<String> keys) =>
        addRange(box, span, boxesFor, s, e, keys, clip, opacity);

    final plain = span.toPlainText(includeSemanticsLabels: false);
    final trimmed = plain.trim();
    if (trimmed.isEmpty) return;
    final whole = keysByValue[trimmed];
    if (whole != null) {
      final start = plain.indexOf(trimmed);
      add(start, start + trimmed.length, whole);
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
          add(s, s + t.length, keys);
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
      add(s, e, keys);
      covered.add((s, e));
    }
  }

  void walk(RenderObject node, Rect clip, double opacity) {
    if (node is RenderParagraph) {
      matchText(node, node.text, node.getBoxesForSelection, clip, opacity);
    } else if (node is RenderEditable && !node.obscureText) {
      final text = node.text;
      if (text != null) {
        matchText(node, text, node.getBoxesForSelection, clip, opacity);
      }
    }
    final childOpacity = opacity *
        switch (node) {
          RenderOpacity(:final opacity) => opacity,
          RenderSliverOpacity(:final opacity) => opacity,
          RenderAnimatedOpacityMixin(:final opacity) => opacity.value,
          _ => 1.0,
        };
    node.visitChildrenForSemantics((child) {
      var childClip = clip;
      final local = node.describeApproximatePaintClip(child);
      if (local != null) {
        childClip = clip.intersect(
          MatrixUtils.transformRect(node.getTransformTo(root), local),
        );
      }
      if (childClip.width <= 0 || childClip.height <= 0) return;
      walk(child, childClip, childOpacity);
    });
  }

  walk(root, bounds, 1.0);
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

final _letter = RegExp(r'\p{L}', unicode: true);

/// Directional marks and isolates the app wraps around Latin runs in Arabic
/// text (see `BidiText`): invisible, so ignored on both sides of a match.
final _bidiControls = RegExp('[\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069]');

/// Painted text under [root] that is neither a label nor data: each onstage
/// RenderParagraph/RenderEditable's plain text with every [explained] string
/// (recorded label values and sample data) removed, longest first, reported
/// when any letter is left. Digits, punctuation and icon glyphs never count.
/// Obscured (password) fields are skipped: they paint dots, not text.
/// Directional controls are removed from both sides first.
List<String> findUnexplainedText(
  RenderObject root,
  Iterable<String> explained,
) {
  final known = explained
      .map((s) => s.replaceAll(_bidiControls, '').trim())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  final found = <String>{};

  void check(InlineSpan span) {
    final text = span
        .toPlainText(includeSemanticsLabels: false, includePlaceholders: false)
        .replaceAll(_bidiControls, '');
    var rest = text;
    for (final value in known) {
      if (rest.contains(value)) rest = rest.replaceAll(value, ' ');
    }
    if (_letter.hasMatch(rest)) {
      found.add('"${text.trim()}" (left: "${rest.trim()}")');
    }
  }

  void walk(RenderObject node) {
    if (node is RenderParagraph) {
      check(node.text);
    } else if (node is RenderEditable && !node.obscureText) {
      final text = node.text;
      if (text != null) check(text);
    }
    node.visitChildrenForSemantics(walk);
  }

  walk(root);
  return found.toList();
}
