import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_contrast.dart';

import 'contrast_probe.dart';

/// Asserts every visible [Icon] meets WCAG 1.4.11 (3:1) against what it is
/// actually painted on. Icons inside disabled controls are exempt, matching
/// WCAG; every other icon carries meaning or affordance here.
void expectAllIconsNonTextAa(String label) {
  final icons = find.byType(Icon).evaluate().toList();
  for (final element in icons) {
    if (_insideDisabledControl(element)) continue;
    final icon = element.widget as Icon;
    final color = icon.color ?? IconTheme.of(element).color;
    if (color == null || color.a == 0) continue;
    for (final background in paintedBackgroundsOf(element)) {
      expect(
        AppContrast.ratio(Color.alphaBlend(color, background), background),
        greaterThanOrEqualTo(3.0),
        reason: '${icon.icon} on $background ($label)',
      );
    }
  }
}

bool _insideDisabledControl(Element element) {
  var disabled = false;
  element.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;
    if (widget is ButtonStyleButton) {
      disabled = !widget.enabled;
      return false;
    }
    if (widget is IconButton) {
      disabled = widget.onPressed == null;
      return false;
    }
    return true;
  });
  return disabled;
}

/// Pumps at the given text scale on a phone-width view. Height is generous so
/// every lazily-built list child is laid out and can report an overflow.
void usePhoneViewAtTextScale(WidgetTester tester, {double scale = 2.0}) {
  tester.view.physicalSize = const Size(390, 9000);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}
