import 'package:flutter/material.dart';

import 'package:sirati/core/l10n/remote_l10n.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Shows any dialog the Sirati way: it fades in and grows from 96% over
/// `medium` (leaving over `fast`), and with reduced motion it simply
/// appears. Every dialog in the app goes through here, so they all move
/// alike.
Future<T?> showSiratiDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(
    SiratiDialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    ),
  );
}

/// The dialog route behind [showSiratiDialog].
class SiratiDialogRoute<T> extends DialogRoute<T> {
  SiratiDialogRoute({
    required super.context,
    required super.builder,
    super.themes,
    super.barrierDismissible,
    super.barrierLabel,
  });

  /// Smallest scale as it grows in.
  static const scaleFrom = .96;

  @override
  Duration get transitionDuration => MotionDurations.medium;

  @override
  Duration get reverseTransitionDuration => MotionDurations.fast;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MotionSettings.reduce(context)) return child;
    final a = CurvedAnimation(
      parent: animation,
      curve: MotionCurves.enter,
      reverseCurve: MotionCurves.exit,
    );
    return FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween<double>(begin: scaleFrom, end: 1).animate(a),
        child: child,
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required String body,
  String? confirmLabel,
  String? cancelLabel,
  VoidCallback? onConfirm,
  bool destructive = false,
}) {
  final c = context.sirati;
  return showSiratiDialog<T>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: Text(title,
            style: AppTypography.of(context, AppTypography.titleLg)),
        content: Text(
          body,
          style: AppTypography.of(context, AppTypography.bodyMd,
              color: c.textSecondary),
        ),
        actions: [
          if (cancelLabel != null)
            AppButton.text(
              label: cancelLabel,
              onPressed: () => Navigator.of(context).pop(),
            ),
          AppButton(
            label: confirmLabel ??
                (Localizations.of<AppLocalizations>(
                          context,
                          AppLocalizations,
                        ) ??
                        RemoteL10n.current)
                    .sharedOk,
            variant: destructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            expand: false,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
          ),
        ],
      );
    },
  );
}
