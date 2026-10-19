import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_contrast.dart';

/// Backgrounds resolved from the mounted paint widgets, compositing translucent
/// layers before comparing ink. PhysicalModel/PhysicalShape carry Material's
/// resolved button state (including disabled fills). Gradients check every stop.
List<Color> paintedBackgroundsOf(Element element) {
  var layers = <Color>[];
  var opaque = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    List<Color> candidates = [];
    if (widget is DecoratedBox) {
      final d = widget.decoration;
      if (d is BoxDecoration) {
        candidates = d.gradient?.colors ?? [if (d.color != null) d.color!];
      }
    } else if (widget is ColoredBox) {
      candidates = [widget.color];
    } else if (widget is PhysicalModel) {
      candidates = [widget.color];
    } else if (widget is PhysicalShape) {
      candidates = [widget.color];
    } else if (widget is InputDecorator) {
      // Helper/error copy sits outside the input's painted fill.
      final container = InputDecorator.containerOf(element);
      final target = element.findRenderObject();
      if (container != null && target is RenderBox && target.hasSize) {
        final bounds = container.localToGlobal(Offset.zero) & container.size;
        final center = target.localToGlobal(target.size.center(Offset.zero));
        final decoration = widget.decoration.applyDefaults(
          Theme.of(ancestor).inputDecorationTheme,
        );
        if (bounds.contains(center) && decoration.filled == true) {
          candidates = [if (decoration.fillColor != null) decoration.fillColor!];
        }
      }
    }
    if (candidates.isEmpty || candidates.every((color) => color.a == 0)) {
      return true;
    }
    layers = layers.isEmpty
        ? candidates
        : [
            for (final layer in layers)
              for (final background in candidates)
                Color.alphaBlend(layer, background),
          ];
    opaque = layers.every((color) => color.a == 1);
    return !opaque;
  });
  if (!opaque) fail('no opaque painted background above ${element.widget}');
  return layers;
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

void expectAllIconsAa(String label) {
  for (final element in find.byType(Icon).evaluate()) {
    final icon = element.widget as Icon;
    final theme = IconTheme.of(element);
    final ink = icon.color ?? theme.color!;
    final color = ink.withValues(alpha: ink.a * (theme.opacity ?? 1));
    for (final background in paintedBackgroundsOf(element)) {
      expect(
        AppContrast.ratio(Color.alphaBlend(color, background), background),
        greaterThanOrEqualTo(3),
        reason: '${icon.icon} on $background ($label)',
      );
    }
  }
}

void expectAllProgressIndicatorsAa(String label) {
  for (final element in find.byWidgetPredicate((widget) =>
      widget is CircularProgressIndicator ||
      widget is LinearProgressIndicator).evaluate()) {
    final indicator = element.widget as ProgressIndicator;
    final ink = indicator.valueColor?.value ??
        indicator.color ??
        ProgressIndicatorTheme.of(element).color ??
        Theme.of(element).colorScheme.primary;
    final backgrounds = indicator.backgroundColor == null
        ? paintedBackgroundsOf(element)
        : [indicator.backgroundColor!];
    for (final background in backgrounds) {
      expect(
        AppContrast.ratio(Color.alphaBlend(ink, background), background),
        greaterThanOrEqualTo(3),
        reason: '${indicator.runtimeType} on $background ($label)',
      );
    }
  }
}
