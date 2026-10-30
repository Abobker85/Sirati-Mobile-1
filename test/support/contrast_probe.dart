import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    } else if (widget is Material && widget.type != MaterialType.transparency) {
      if (widget.color != null) {
        candidates = [widget.color!];
      }
    } else if (widget is ButtonStyleButton) {
      final theme = Theme.of(ancestor);
      final themed = switch (widget) {
        ElevatedButton() => theme.elevatedButtonTheme.style,
        FilledButton() => theme.filledButtonTheme.style,
        OutlinedButton() => theme.outlinedButtonTheme.style,
        TextButton() => theme.textButtonTheme.style,
        _ => null,
      };
      final states = widget.enabled
          ? const <WidgetState>{}
          : const <WidgetState>{WidgetState.disabled};
      final bg = widget.style?.backgroundColor?.resolve(states) ??
          themed?.backgroundColor?.resolve(states);
      if (bg != null) {
        candidates = [bg];
      }
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

/// Counts each painted opacity render layer once, using its current value.
/// AnimatedOpacity and its internal FadeTransition share one such layer.
double effectiveAncestorOpacityOf(Element element) {
  var opacity = 1.0;
  RenderObject? ancestor = element.findRenderObject()?.parent;
  while (ancestor != null) {
    if (ancestor is RenderOpacity) {
      opacity *= ancestor.opacity;
    } else if (ancestor is RenderAnimatedOpacity) {
      opacity *= ancestor.opacity.value;
    }
    ancestor = ancestor.parent;
  }
  return opacity;
}

/// Asserts every [Text] currently on screen meets WCAG AA (4.5:1) against
/// what it is actually painted on.
void expectAllTextAa(String label) {
  final texts = find.byType(Text).evaluate().toList();
  expect(texts, isNotEmpty, reason: label);
  for (final element in texts) {
    final text = element.widget as Text;
    final ancestorOpacity = effectiveAncestorOpacityOf(element);
    // Opacity 0 is not painted: hint placeholders kept for layout, and the
    // first frame of an entrance fade. Partial fades are still checked.
    if (ancestorOpacity == 0) continue;
    final paragraph = paragraphOf(element.findRenderObject()!);
    final ink = paragraph.text.style!.color!;
    final color = ink.withValues(
      alpha: (ink.a * ancestorOpacity).clamp(0.0, 1.0),
    );
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
    final totalOpacity =
        (theme.opacity ?? 1.0) * effectiveAncestorOpacityOf(element);
    final color = ink.withValues(
      alpha: (ink.a * totalOpacity).clamp(0.0, 1.0),
    );
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
    final rawInk = indicator.valueColor?.value ??
        indicator.color ??
        ProgressIndicatorTheme.of(element).color ??
        Theme.of(element).colorScheme.primary;
    final totalOpacity = effectiveAncestorOpacityOf(element);
    final ink = rawInk.withValues(
      alpha: (rawInk.a * totalOpacity).clamp(0.0, 1.0),
    );
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

/// The paragraph a [Text] painted. Inside a `SelectionArea` the Text's own
/// render object is a mouse region (text cursor) wrapping the paragraph, so
/// test helpers must not cast the Text's render object directly.
RenderParagraph paragraphOf(RenderObject root) {
  if (root is RenderParagraph) return root;
  RenderParagraph? found;
  void visit(RenderObject child) {
    if (found != null) return;
    if (child is RenderParagraph) {
      found = child;
    } else {
      child.visitChildren(visit);
    }
  }

  root.visitChildren(visit);
  return found ?? (throw StateError('no RenderParagraph under $root'));
}
