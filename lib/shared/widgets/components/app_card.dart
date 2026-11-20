import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';

/// Token-driven surface card (SIRATI-21).
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Borderless, unshadowed fill of the page it sits on (iOS 26): grey on a
    // plain page, white on a grouped one. Pressing darkens the fill.
    final c = context.sirati;
    final fill = PageSurface.fillOf(context);
    final body = Material(
      color: fill,
      borderRadius: AppRadius.cardAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardAll,
        highlightColor: c.pressOverlay(fill),
        splashFactory: NoSplash.splashFactory,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: body,
    );
  }
}
