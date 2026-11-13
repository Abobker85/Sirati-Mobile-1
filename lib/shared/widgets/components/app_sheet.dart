import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Corner radius of glass sheets.
const appSheetRadius = 28.0;

/// Opens a modal bottom sheet on frosted glass, sliding up over 300ms on the
/// standard curve (no motion when the phone reduces motion). Every sheet in
/// the app goes through here so they all look and move the same.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = true,
}) {
  final c = context.sirati;
  const radius = BorderRadius.vertical(top: Radius.circular(appSheetRadius));
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    // The sheet's own Material stays clear; the glass pane paints it.
    backgroundColor: c.surface.withValues(alpha: 0),
    elevation: 0,
    showDragHandle: false,
    shape: const RoundedRectangleBorder(borderRadius: radius),
    sheetAnimationStyle: MotionSettings.reduce(context)
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: MotionDurations.sheet,
            reverseDuration: MotionDurations.medium,
            curve: MotionCurves.standard,
          ),
    builder: (context) => GlassSurface(
      borderRadius: radius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle) const SheetDragHandle(),
          Flexible(child: builder(context)),
        ],
      ),
    ),
  );
}

/// The grab bar at the top of a sheet.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.sirati.outline,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? semanticLabel,
}) {
  return showGlassBottomSheet<T>(
    context: context,
    showDragHandle: false,
    builder: (context) {
      return Semantics(
        namesRoute: true,
        label: semanticLabel,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: child,
          ),
        ),
      );
    },
  );
}
