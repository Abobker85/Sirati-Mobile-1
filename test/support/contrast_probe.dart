import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_contrast.dart';

/// Nearest opaque background painted behind [element] in a pumped tree:
/// a coloured or gradient [DecoratedBox], a non-transparent [Material], or a
/// button's resolved fill. A gradient yields every stop, so text must pass
/// against the worst one.
List<Color> paintedBackgroundsOf(Element element) {
  var accumulated = <Color>[Colors.transparent];
  var found = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    List<Color> candidates = [];
    if (widget is DecoratedBox && widget.decoration is BoxDecoration) {
      final decoration = widget.decoration as BoxDecoration;
      candidates =
          decoration.gradient?.colors ??
          [if (decoration.color != null) decoration.color!];
    } else if (widget is Material && widget.type != MaterialType.transparency) {
      candidates = [if (widget.color != null) widget.color!];
    }
    if (candidates.isNotEmpty) {
      accumulated = [
        for (final foreground in accumulated)
          for (final background in candidates)
            Color.alphaBlend(foreground, background),
      ];
      found = accumulated.every((color) => color.a == 1);
    }
    return !found;
  });
  return found
      ? accumulated
      : fail('no opaque painted background above ${element.widget}');
}

/// Asserts every [Text] currently on screen meets WCAG AA (4.5:1) against
/// what it is actually painted on.
void expectAllTextAa(String label) {
  final texts = find.byType(Text).evaluate().toList();
  expect(texts, isNotEmpty, reason: label);
  for (final element in texts) {
    final text = element.widget as Text;
    final color =
        text.style?.color ?? DefaultTextStyle.of(element).style.color!;
    for (final background in paintedBackgroundsOf(element)) {
      expect(
        AppContrast.ratio(Color.alphaBlend(color, background), background),
        greaterThanOrEqualTo(4.5),
        reason: '"${text.data}" on $background ($label)',
      );
    }
  }
}
