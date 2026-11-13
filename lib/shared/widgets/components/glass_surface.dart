import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// A frosted-glass pane: whatever is behind it is blurred and tinted with
/// the theme's glass fill, with a thin light edge and a soft lift.
///
/// When the phone asks for more contrast ([MediaQueryData.highContrast]) the
/// pane is drawn solid instead, with a firm outline and no blur.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
    this.elevated = true,
  });

  final BorderRadius borderRadius;
  final Widget child;

  /// Floating panes cast a soft shadow; panes that sit on an edge do not.
  final bool elevated;

  /// Blur strength of the frosted glass.
  static const blurSigma = 20.0;

  /// Whether glass is drawn solid for this context.
  static bool solid(BuildContext context) =>
      MediaQuery.maybeHighContrastOf(context) ?? false;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    // Rows and buttons inside paint their ink on this clear Material, above
    // the tint, so taps stay visible.
    final child = Material(type: MaterialType.transparency, child: this.child);
    if (solid(context)) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: borderRadius,
          border: Border.all(color: c.outline),
        ),
        child: ClipRRect(borderRadius: borderRadius, child: child),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated ? c.glassShadow : const [],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.glassFill,
              borderRadius: borderRadius,
              border: Border.all(color: c.glassEdge),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
