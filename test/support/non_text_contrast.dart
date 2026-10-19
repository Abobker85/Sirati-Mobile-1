import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/shared/theme/app_contrast.dart';

import 'contrast_probe.dart';

/// Asserts every visible [Icon] meets WCAG 1.4.11 (3:1) against what it is
/// actually painted on, including disabled controls. These screens deliberately
/// keep disabled content legible; disabled semantics carry the interaction state.
void expectAllIconsNonTextAa(String label) {
  final icons = find.byType(Icon).evaluate().toList();
  for (final element in icons) {
    final icon = element.widget as Icon;
    if (icon.icon == null) continue;
    final color = icon.color ??
        IconTheme.of(element).color ??
        Theme.of(element).colorScheme.onSurface;
    final paintedColor = color.withValues(
      alpha: color.a * (IconTheme.of(element).opacity ?? 1),
    );
    for (final background in paintedBackgroundsOf(element)) {
      expect(
        AppContrast.ratio(
            Color.alphaBlend(paintedColor, background), background),
        greaterThanOrEqualTo(3.0),
        reason: '${icon.icon} on $background ($label)',
      );
    }
  }
}

/// A real phone viewport: list children must be reached by scrolling.
void usePhoneViewAtTextScale(WidgetTester tester, {double scale = 2.0}) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

/// Reveals lazy list children by scrolling the actual screen, including when
/// a previous action left the list below the requested child.
Future<void> revealPhoneWidget(WidgetTester tester, Finder target) async {
  if (target.evaluate().isNotEmpty) {
    await tester.ensureVisible(target);
  } else {
    final scrollable = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(target, 220,
        scrollable: scrollable, maxScrolls: 120);
  }
  await tester.pump();
}

/// Traverse the phone viewport rather than laying the whole page out on an
/// artificial canvas. Checks run at each scroll position, including the end.
Future<void> inspectPhoneScreen(WidgetTester tester, String label) async {
  final list = find.byType(ListView).last;
  final scrollable =
      find.descendant(of: list, matching: find.byType(Scrollable)).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(0);
  await tester.pump();
  for (var step = 0; step < 120; step++) {
    expectAllTextAa(label);
    expectAllIconsNonTextAa(label);
    expectPaintedControlsAa(label);
    await expectRenderedControlsAa(tester, label);
    expect(tester.takeException(), isNull, reason: label);
    if (position.pixels >= position.maxScrollExtent) return;
    await tester.drag(list, const Offset(0, -350));
    await tester.pump(const Duration(milliseconds: 200));
  }
  fail('Page cannot be traversed on a phone: $label');
}

const phonePaintKey = ValueKey('phone-paint');

/// Sample actual raster paint as well as resolved styles. Ring samples use
/// separate angular positions in a bounded stroke annulus, without consulting
/// the declared colours. Returns the number of fully visible rings checked.
Future<int> expectRenderedControlsAa(WidgetTester tester, String label) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(phonePaintKey));
  final snapshot =
      (await tester.runAsync(() => boundary.toImage(pixelRatio: 1)))!;
  try {
    final bytes = (await tester.runAsync(
      () => snapshot.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    final viewport = Offset.zero & boundary.size;
    Rect rectOf(Element element) {
      final box = element.findRenderObject()! as RenderBox;
      return MatrixUtils.transformRect(
          box.getTransformTo(boundary), Offset.zero & box.size);
    }

    Rect clipOf(Element element) {
      final box = element.findRenderObject()!;
      var visible = viewport;
      var child = box;
      while (child != boundary && child.parent is RenderObject) {
        final parent = child.parent!;
        final clip = parent.describeApproximatePaintClip(child);
        if (clip != null) {
          visible = visible.intersect(MatrixUtils.transformRect(
            parent.getTransformTo(boundary),
            clip,
          ));
        }
        child = parent;
      }
      return visible;
    }

    Rect visibleOf(Element element) =>
        rectOf(element).intersect(clipOf(element));

    Color sample(Rect region, Color expected) =>
        _nearestPaint(bytes, snapshot.width, snapshot.height, region, expected);

    for (final element in find.byType(DecoratedBox).evaluate()) {
      final decoration = (element.widget as DecoratedBox).decoration;
      if (decoration is! BoxDecoration || decoration.border is! Border) {
        continue;
      }
      final border = decoration.border! as Border;
      final rect = rectOf(element);
      final visible = visibleOf(element);
      if (visible.width < 40 || visible.height < 40) continue;
      final left = border.left;
      final top = border.top;
      final vertical = left.style != BorderStyle.none && left.width > 0;
      final side = vertical ? left : top;
      if (side.style == BorderStyle.none || side.width == 0) continue;
      final point = vertical
          ? Offset(rect.left,
              visible.center.dy.clamp(rect.top + 20, rect.bottom - 20))
          : Offset(visible.center.dx, rect.top);
      final inward = vertical ? const Offset(5, 0) : const Offset(0, 5);
      final core = Rect.fromCenter(center: point, width: 6, height: 6);
      if (!viewport.contains(point) || !viewport.contains(point + inward)) {
        continue;
      }
      final backgrounds = paintedBackgroundsOf(element);
      final expectedFill = decoration.color ?? backgrounds.first;
      final ink = sample(core, side.color);
      final fill = sample(
          Rect.fromCenter(center: point + inward, width: 2, height: 2),
          expectedFill);
      _nonTextPair(
          ink, fill, '$label raster border $rect at $point: $ink on $fill');
    }

    for (final element in find.byType(Checkbox).evaluate()) {
      final checkbox = element.widget as Checkbox;
      final rect = rectOf(element);
      final visual = Rect.fromCenter(
          center: rect.center,
          width: Checkbox.width + 4,
          height: Checkbox.width + 4);
      final visible = visibleOf(element);
      if (!visible.contains(visual.topLeft) ||
          !visible.contains(visual.bottomRight)) {
        continue;
      }
      final states = <WidgetState>{
        if (checkbox.value == true) WidgetState.selected,
        if (checkbox.onChanged == null) WidgetState.disabled,
      };
      final side = checkbox.side is WidgetStateBorderSide
          ? (checkbox.side as WidgetStateBorderSide).resolve(states)
          : checkbox.side;
      final background = paintedBackgroundsOf(element).first;
      if (checkbox.value == true) {
        final interior = visual.deflate(5);
        final fill = sample(interior, checkbox.fillColor!.resolve(states)!);
        final mark = sample(interior, checkbox.checkColor!);
        _nonTextPair(mark, fill, '$label raster checkbox check $states');
        final outside = sample(
            Rect.fromCenter(center: visual.topLeft, width: 2, height: 2),
            background);
        _nonTextPair(fill, outside, '$label raster checkbox fill $states');
      } else {
        final outline = sample(visual, side!.color);
        final fill = sample(visual.deflate(6), background);
        _nonTextPair(outline, fill, '$label raster checkbox outline $states');
      }
    }

    var ringsChecked = 0;
    for (final ring in _scoreRings()) {
      final rect = rectOf(ring.element);
      if (visibleOf(ring.element) != rect) continue;
      final box = ring.element.findRenderObject()! as RenderBox;
      final center = box.size.center(Offset.zero);
      final radius =
          box.size.shortestSide / 2 + ring.strokeAlign * ring.strokeWidth / 2;
      final sweep = ring.progress * ring.fullSweep;
      const start = -math.pi / 2;

      Color segment(double from, double to) => _ringSegmentPixel(
            bytes,
            snapshot.width,
            snapshot.height,
            box: box,
            boundary: boundary,
            radius: radius,
            strokeWidth: ring.strokeWidth,
            from: start + from,
            sweep: to - from,
          );

      final arc = ring.progress > 0 ? segment(0, sweep) : null;
      final track = ring.progress < 1 ? segment(sweep, 2 * math.pi) : null;
      // Sample the clear card above the stroke, away from the centre label.
      final cardPoint = box.localToGlobal(
          center - Offset(0, radius + ring.strokeWidth / 2 + 4),
          ancestor: boundary);
      if (!clipOf(ring.element).contains(cardPoint)) continue;
      final card = _pixelAt(bytes, snapshot.width, snapshot.height, cardPoint);
      if (arc != null) {
        _nonTextPair(arc, card, '$label raster ring arc versus card');
      }
      if (track != null) {
        expect(AppContrast.ratio(track, card), greaterThanOrEqualTo(1.3),
            reason: '$label raster ring track versus card');
      }
      if (arc != null && track != null) {
        _nonTextPair(arc, track, '$label raster ring arc versus track');
      }
      ringsChecked++;
    }
    return ringsChecked;
  } finally {
    snapshot.dispose();
  }
}

class _ScoreRing {
  const _ScoreRing(this.element, this.progress, this.strokeWidth,
      this.strokeAlign, this.fullSweep);

  final Element element;
  final double progress;
  final double strokeWidth;
  final double strokeAlign;
  final double fullSweep;
}

Iterable<_ScoreRing> _scoreRings() sync* {
  for (final element in find.byType(CircularProgressIndicator).evaluate()) {
    final indicator = element.widget as CircularProgressIndicator;
    if (indicator.value == null || indicator.backgroundColor == null) continue;
    final theme = ProgressIndicatorTheme.of(element);
    // Flutter's determinate painter starts at twelve o'clock and leaves a
    // .001-radian seam; its default stroke alignment is centred in this theme.
    yield _ScoreRing(
        element,
        indicator.value!.clamp(0, 1),
        indicator.strokeWidth ?? theme.strokeWidth ?? 4,
        indicator.strokeAlign ?? theme.strokeAlign ?? 0,
        2 * math.pi - .001);
  }
  for (final element in find.byType(JobMatchScoreRing).evaluate()) {
    final ring = element.widget as JobMatchScoreRing;
    // _RingPainter uses a ten-pixel stroke inset by half its width.
    yield _ScoreRing(
        element, ring.score.clamp(0, 100) / 100, 10, -1, 2 * math.pi);
  }
}

Color _pixelAt(ByteData bytes, int width, int height, Offset point) {
  final x = point.dx.floor();
  final y = point.dy.floor();
  if (x < 0 || x >= width || y < 0 || y >= height) {
    throw StateError('Raster point outside frame: $point');
  }
  final index = (y * width + x) * 4;
  return Color.fromARGB(bytes.getUint8(index + 3), bytes.getUint8(index),
      bytes.getUint8(index + 1), bytes.getUint8(index + 2));
}

Color _ringSegmentPixel(
  ByteData bytes,
  int width,
  int height, {
  required RenderBox box,
  required RenderObject boundary,
  required double radius,
  required double strokeWidth,
  required double from,
  required double sweep,
}) {
  final center = box.size.center(Offset.zero);
  final midpoint = from + sweep / 2;
  final target = box.localToGlobal(
      center + Offset(math.cos(midpoint), math.sin(midpoint)) * radius,
      ancestor: boundary);
  // Stay in the central half of the stroke, with BOTH radial bounds enforced.
  final inner = radius - strokeWidth / 4;
  final outer = radius + strokeWidth / 4;
  Offset? closest;
  var distance = double.infinity;
  for (var y = target.dy.floor() - 2; y <= target.dy.ceil() + 2; y++) {
    for (var x = target.dx.floor() - 2; x <= target.dx.ceil() + 2; x++) {
      final point = Offset(x + .5, y + .5);
      final delta = box.globalToLocal(point, ancestor: boundary) - center;
      final angle = (math.atan2(delta.dy, delta.dx) - from) % (2 * math.pi);
      if (delta.distance < inner || delta.distance > outer || angle > sweep) {
        continue;
      }
      final current = (point - target).distanceSquared;
      if (current < distance) {
        distance = current;
        closest = point;
      }
    }
  }
  if (closest == null) {
    throw StateError('No pixel inside ring segment $from + $sweep');
  }
  return _pixelAt(bytes, width, height, closest);
}

Color _nearestPaint(
    ByteData bytes, int width, int height, Rect region, Color expected) {
  var distance = double.infinity;
  Color? nearest;
  for (var y = region.top.floor().clamp(0, height).toInt();
      y < region.bottom.ceil().clamp(0, height);
      y++) {
    for (var x = region.left.floor().clamp(0, width).toInt();
        x < region.right.ceil().clamp(0, width);
        x++) {
      final index = (y * width + x) * 4;
      final color = Color.fromARGB(
          bytes.getUint8(index + 3),
          bytes.getUint8(index),
          bytes.getUint8(index + 1),
          bytes.getUint8(index + 2));
      final dr = color.r - expected.r;
      final dg = color.g - expected.g;
      final db = color.b - expected.b;
      final current = dr * dr + dg * dg + db * db;
      if (current < distance) {
        distance = current;
        nearest = color;
      }
    }
  }
  return nearest ?? (throw StateError('No paint inside $region'));
}

void _nonTextPair(Color foreground, Color background, String label) {
  expect(
      AppContrast.ratio(Color.alphaBlend(foreground, background), background),
      greaterThanOrEqualTo(3),
      reason: label);
}

/// Resolve the paint in the pumped tree: card/button boundaries, checkbox
/// outlines, fills and check marks, plus progress arc/track differentiation.
/// Disabled controls use the same strict contrast contract as active controls.
void expectPaintedControlsAa(String label) {
  for (final element in find.byType(DecoratedBox).evaluate()) {
    final decoration = (element.widget as DecoratedBox).decoration;
    if (decoration is! BoxDecoration || decoration.border == null) continue;
    final border = decoration.border!;
    final sides = switch (border) {
      Border() => [border.top, border.right, border.bottom, border.left],
      BorderDirectional() => [
          border.top,
          border.start,
          border.bottom,
          border.end
        ],
      _ => <BorderSide>[],
    };
    for (final side in sides) {
      if (side.style == BorderStyle.none || side.width == 0) continue;
      final backgrounds = paintedBackgroundsOf(element);
      for (final background in backgrounds) {
        _nonTextPair(side.color, background, '$label outer border');
        if (decoration.color case final fill?) {
          _nonTextPair(side.color, Color.alphaBlend(fill, background),
              '$label inner border');
        }
      }
    }
  }
  for (final element in find.byType(Material).evaluate()) {
    final material = element.widget as Material;
    final shape = material.shape;
    if (shape is! OutlinedBorder || shape.side.style == BorderStyle.none) {
      continue;
    }
    for (final background in paintedBackgroundsOf(element)) {
      _nonTextPair(shape.side.color, background, '$label button border');
    }
  }
  for (final element in find.byType(Checkbox).evaluate()) {
    final checkbox = element.widget as Checkbox;
    final states = <WidgetState>{
      if (checkbox.value == true) WidgetState.selected,
      if (checkbox.onChanged == null) WidgetState.disabled,
    };
    final side = checkbox.side is WidgetStateBorderSide
        ? (checkbox.side as WidgetStateBorderSide).resolve(states)
        : checkbox.side;
    expect(side, isNotNull, reason: '$label explicit checkbox outline');
    final fill = checkbox.fillColor?.resolve(states);
    for (final background in paintedBackgroundsOf(element)) {
      if (checkbox.value == true) {
        expect(fill, isNotNull, reason: '$label explicit checkbox fill');
        _nonTextPair(fill!, background, '$label checkbox fill $states');
        _nonTextPair(
            checkbox.checkColor!, fill, '$label checkbox check $states');
      } else {
        _nonTextPair(side!.color, background, '$label checkbox border $states');
      }
    }
  }
  for (final element in find.byType(CircularProgressIndicator).evaluate()) {
    final indicator = element.widget as CircularProgressIndicator;
    final arc = indicator.color ??
        ProgressIndicatorTheme.of(element).color ??
        Theme.of(element).colorScheme.primary;
    for (final background in paintedBackgroundsOf(element)) {
      _nonTextPair(arc, background, '$label progress arc');
    }
    if (indicator.backgroundColor case final track?) {
      _nonTextPair(arc, track, '$label progress arc versus track');
      if (indicator.value != null) {
        for (final background in paintedBackgroundsOf(element)) {
          expect(
              AppContrast.ratio(track, background), greaterThanOrEqualTo(1.3),
              reason: '$label progress track versus card');
        }
      }
    }
  }
}
