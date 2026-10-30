import 'package:flutter/material.dart';

import 'package:sirati/core/l10n/remote_l10n.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

/// Token-driven button (SIRATI-21). Min 48px target, semantic label, RTL-safe.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final enabled = onPressed != null && !isLoading;
    final style = AppTypography.of(context, AppTypography.labelLg);
    final l10n =
        Localizations.of<AppLocalizations>(context, AppLocalizations) ??
            RemoteL10n.current;
    final loadingStatus = l10n.sharedLoading;

    final foreground =
        !enabled && !isLoading ? c.textSecondary : _foreground(c);

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              semanticsLabel: loadingStatus,
              color: variant == AppButtonVariant.primary
                  ? c.onPrimary
                  : variant == AppButtonVariant.destructive
                      ? c.onError
                      : c.primaryInk,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: foreground),
        if (isLoading || icon != null) const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: style.copyWith(color: foreground),
          ),
        ),
      ],
    );

    final minSize = Size(
      expand ? double.infinity : AppTouchTarget.min,
      AppTouchTarget.min,
    );

    late final Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: c.primary,
            disabledBackgroundColor: isLoading ? c.primary : c.surfaceHigh,
            disabledForegroundColor: isLoading ? c.onPrimary : c.textSecondary,
            foregroundColor: c.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            minimumSize: minSize,
            foregroundColor: c.primaryInk,
            disabledForegroundColor: c.textSecondary,
            side: BorderSide(
              color: !enabled && !isLoading ? c.outline : c.primaryInk,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          ),
          child: child,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            minimumSize: minSize,
            foregroundColor: c.primaryInk,
            disabledForegroundColor: c.textSecondary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          ),
          child: child,
        );
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            minimumSize: minSize,
            backgroundColor: c.error,
            disabledBackgroundColor: isLoading ? c.error : c.surfaceHigh,
            disabledForegroundColor: isLoading ? c.onError : c.textSecondary,
            foregroundColor: c.onError,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
          ),
          child: child,
        );
    }

    return PressScale(enabled: enabled, child: button);
  }

  Color _foreground(SiratiColors c) {
    switch (variant) {
      case AppButtonVariant.primary:
        return c.onPrimary;
      case AppButtonVariant.destructive:
        return c.onError;
      case AppButtonVariant.secondary:
      case AppButtonVariant.text:
        return c.primaryInk;
    }
  }
}
