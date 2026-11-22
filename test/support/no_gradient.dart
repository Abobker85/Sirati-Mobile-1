import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Asserts that nothing mounted under [root] paints a gradient, walking the
/// real pumped tree: every `DecoratedBox` (what `Container`, `AnimatedContainer`
/// and friends build) and `Ink` decoration, Box or Shape, and every
/// `ShaderMask`. Returns how many decorations were checked, and fails when
/// the walk checked nothing (a vacuous pass).
int expectNoGradient(Finder root, String label) {
  var checked = 0;
  void checkDecoration(Decoration? decoration, String what) {
    if (decoration == null) return;
    checked++;
    final gradient = switch (decoration) {
      BoxDecoration(:final gradient) => gradient,
      ShapeDecoration(:final gradient) => gradient,
      _ => null,
    };
    expect(gradient, isNull, reason: '$label: $what paints $gradient');
  }

  for (final element in find
      .descendant(
          of: root, matching: find.byType(DecoratedBox), matchRoot: true)
      .evaluate()) {
    checkDecoration(
        (element.widget as DecoratedBox).decoration, 'DecoratedBox');
  }
  for (final element in find
      .descendant(of: root, matching: find.byType(Ink), matchRoot: true)
      .evaluate()) {
    checkDecoration((element.widget as Ink).decoration, 'Ink');
  }
  expect(
      find.descendant(
          of: root, matching: find.byType(ShaderMask), matchRoot: true),
      findsNothing,
      reason: '$label: a ShaderMask paints a gradient');
  expect(checked, greaterThan(0), reason: '$label: walk checked nothing');
  return checked;
}
