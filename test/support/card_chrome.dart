import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

/// Asserts that nothing painted under [root] draws a card outline or a drop
/// shadow (iOS 26 cards are borderless, unshadowed fills), walking the real
/// pumped tree: every `BoxDecoration` / `ShapeDecoration` side or shadow
/// (a solid width-0 side is a hairline and counts), every `Material` outline
/// or elevation (only a Scaffold's own page is exempt), and every elevated
/// `PhysicalModel` / `PhysicalShape`.
///
/// Buttons ([ButtonStyleButton]), list separators ([Divider]) and segmented
/// controls ([SegmentedTrack], whose thumb is lifted by design) keep their
/// own look, and anything under an
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
          // List separators draw a hairline border by design.
          ancestor.widget is Divider ||
          ancestor.widget is VerticalDivider ||
          ancestor.widget is SegmentedTrack) {
        inside = true;
        return false;
      }
      return true;
    });
    return inside;
  }

  // A side paints unless its style is none or it is fully transparent. A
  // solid side of width 0 is a hairline, so it counts as an outline.
  void expectNoSide(BorderSide side, String what) {
    expect(side.style == BorderStyle.none || side.color.a == 0, isTrue,
        reason: '$label: outlined $what ($side)');
  }

  void expectNoShapeSide(ShapeBorder? shape, String what) {
    if (shape is OutlinedBorder) expectNoSide(shape.side, what);
  }

  var checked = 0;
  for (final element in find
      .descendant(of: root, matching: find.byType(DecoratedBox))
      .evaluate()) {
    if (insideSkipped(element)) continue;
    final widget = element.widget as DecoratedBox;
    switch (widget.decoration) {
      case BoxDecoration(:final border, :final boxShadow):
        checked++;
        final sides = switch (border) {
          Border() => [border.top, border.right, border.bottom, border.left],
          BorderDirectional() => [
              border.top,
              border.start,
              border.bottom,
              border.end,
            ],
          null => <BorderSide>[],
          // Any other border kind is unknown here: reject rather than pass.
          _ => fail('$label: unchecked border kind $border'),
        };
        for (final side in sides) {
          expectNoSide(side, '$widget');
        }
        expect(boxShadow ?? const <BoxShadow>[], isEmpty,
            reason: '$label: shadowed $widget');
      case ShapeDecoration(:final shape, :final shadows):
        checked++;
        expectNoShapeSide(shape, 'ShapeDecoration $shape');
        expect(shadows ?? const <BoxShadow>[], isEmpty,
            reason: '$label: shadowed ShapeDecoration $shape');
      default:
        break;
    }
  }
  for (final element in find
      .descendant(of: root, matching: find.byType(Material))
      .evaluate()) {
    if (insideSkipped(element)) continue;
    checked++;
    final material = element.widget as Material;
    expectNoShapeSide(material.shape, 'Material ${material.color}');
    if (material.type == MaterialType.transparency) continue;
    // Only a Scaffold's own page Material is exempt (it is the page, not a
    // card); every other Material, canvas included, must lie flat.
    if (_isScaffoldPage(element)) continue;
    expect(material.elevation, 0,
        reason: '$label: elevated Material ${material.color}');
  }
  for (final element in find
      .descendant(
          of: root,
          matching: find.byWidgetPredicate(
              (w) => w is PhysicalModel || w is PhysicalShape))
      .evaluate()) {
    if (insideSkipped(element)) continue;
    checked++;
    final elevation = switch (element.widget) {
      PhysicalModel(:final elevation) => elevation,
      PhysicalShape(:final elevation) => elevation,
      _ => 0.0,
    };
    if (elevation == 0) continue;
    // A Material draws its own physical layer at its own elevation; that
    // Material was judged above (and fails there unless it is the page).
    final owner = element.findAncestorWidgetOfExactType<Material>();
    if (owner != null && owner.elevation == elevation) continue;
    fail('$label: elevated ${element.widget}');
  }
  expect(checked, greaterThan(0), reason: '$label: nothing was walked');
}

/// Whether [element] is a [Scaffold]'s own page Material: the nearest
/// Material-or-Scaffold above it is a Scaffold.
bool _isScaffoldPage(Element element) {
  var scaffoldOwned = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is Material) return false;
    if (widget is Scaffold) {
      scaffoldOwned = true;
      return false;
    }
    return true;
  });
  return scaffoldOwned;
}
