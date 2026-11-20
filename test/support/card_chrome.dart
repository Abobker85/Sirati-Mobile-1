import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

/// Asserts that nothing painted under [root] draws a card outline or a drop
/// shadow (iOS 26 cards are borderless, unshadowed fills), walking the real
/// pumped tree: every `BoxDecoration` border or shadow and every `Material`
/// with an outlined shape side or elevation.
///
/// Buttons ([ButtonStyleButton]) and segmented controls ([SegmentedTrack],
/// whose thumb is lifted by design) keep their own look, and anything under an
/// [exclude] finder (e.g. a shared header this screen does not own) is
/// skipped.
void expectNoCardChrome(
  Finder root,
  String label, {
  List<Finder> exclude = const [],
}) {
  final skipped = <Element>{
    for (final finder in exclude) ...finder.evaluate(),
  };
  bool insideSkipped(Element element) {
    var inside = false;
    element.visitAncestorElements((ancestor) {
      if (skipped.contains(ancestor) ||
          ancestor.widget is ButtonStyleButton ||
          ancestor.widget is SegmentedTrack) {
        inside = true;
        return false;
      }
      return true;
    });
    return inside;
  }

  var checked = 0;
  for (final element in find
      .descendant(of: root, matching: find.byType(DecoratedBox))
      .evaluate()) {
    if (insideSkipped(element)) continue;
    final decoration = (element.widget as DecoratedBox).decoration;
    if (decoration is! BoxDecoration) continue;
    checked++;
    final border = decoration.border;
    if (border != null) {
      final sides = switch (border) {
        Border() => [border.top, border.right, border.bottom, border.left],
        BorderDirectional() => [
            border.top,
            border.start,
            border.bottom,
            border.end,
          ],
        _ => <BorderSide>[],
      };
      for (final side in sides) {
        expect(side.style == BorderStyle.none || side.width == 0, isTrue,
            reason: '$label: outlined ${element.widget} ($side)');
      }
    }
    expect(decoration.boxShadow ?? const <BoxShadow>[], isEmpty,
        reason: '$label: shadowed ${element.widget}');
  }
  for (final element in find
      .descendant(of: root, matching: find.byType(Material))
      .evaluate()) {
    if (insideSkipped(element)) continue;
    final material = element.widget as Material;
    final shape = material.shape;
    if (shape is OutlinedBorder) {
      expect(
          shape.side.style == BorderStyle.none || shape.side.width == 0, isTrue,
          reason: '$label: outlined Material ${shape.side}');
    }
    if (material.type != MaterialType.transparency &&
        material.type != MaterialType.canvas) {
      expect(material.elevation, 0,
          reason: '$label: elevated Material ${material.color}');
    }
  }
  expect(checked, greaterThan(0), reason: '$label: nothing was walked');
}
