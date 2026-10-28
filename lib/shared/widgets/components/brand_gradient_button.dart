import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Full-width primary CTA on the brand gradient used by full-screen states
/// (offline, session expired). The on-brand ink holds AA across the whole
/// brand-surface gradient in both themes.
class BrandGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  /// Shown instead of [label] while [isLoading].
  final String? loadingLabel;

  const BrandGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final enabled = onPressed != null && !isLoading;
    final foreground = c.onBrandSurface;
    final text = isLoading ? (loadingLabel ?? label) : label;

    return PressScale(
      enabled: enabled,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: text,
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgAll,
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [c.brandSurface, c.brandSurfaceDeep],
            ),
            boxShadow: AppShadows.of(c, elevation: AppElevation.raised),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: AppRadius.lgAll,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppTouchTarget.min + 4,
                  minWidth: double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: foreground,
                          ),
                        )
                      else if (icon != null)
                        Icon(icon, size: 20, color: foreground),
                      if (isLoading || icon != null)
                        const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: AppTypography.of(
                            context,
                            AppTypography.titleMd,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
