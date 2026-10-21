import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Primary/outlined action with a minimum height and room for scaled text.
class SubmitButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool outlined;
  final double height;

  const SubmitButton({
    super.key,
    required this.label,
    this.loadingLabel,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.outlined = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final text = isLoading ? (loadingLabel ?? label) : label;
    final c = context.sirati;
    // Filled disabled must not inherit the enabled onPrimary ink. The button
    // animates foreground, so the label sets its own colour on the first frame.
    final filledForeground = !enabled && !isLoading ? c.textSecondary : c.onPrimary;
    final spinnerColor = outlined ? c.primaryInk : c.onPrimary;
    final iconColor = outlined ? null : filledForeground;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: spinnerColor,
            ),
          )
        else if (icon != null)
          DirectionalIcon.isDirectional(icon!)
              ? DirectionalIcon(icon!, size: 18, color: iconColor)
              : Icon(icon, size: 18, color: iconColor),
        if (isLoading || icon != null) const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: outlined ? null : TextStyle(color: filledForeground),
          ),
        ),
      ],
    );

    // minimumSize only — fixedSize clips Arabic/large text scales.
    final button = outlined
        ? OutlinedButton(
            onPressed: enabled ? onPressed : null,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(
                double.infinity,
                height.clamp(AppTouchTarget.min, double.infinity),
              ),
              disabledForegroundColor: context.sirati.primaryInk,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: content,
          )
        : ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              minimumSize: Size(
                double.infinity,
                height.clamp(AppTouchTarget.min, double.infinity),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              // Loading keeps the enabled pair. A disabled control uses the
              // same neutral pair as AppButton so it does not look pressable.
              disabledBackgroundColor:
                  isLoading ? c.primary : c.surfaceHigh,
              disabledForegroundColor:
                  isLoading ? c.onPrimary : c.textSecondary,
            ),
            child: content,
          );

    return PressScale(
      enabled: enabled,
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}
