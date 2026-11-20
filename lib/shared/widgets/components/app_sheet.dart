import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Corner radius of glass sheets (top corners only).
const appSheetRadius = AppRadius.sheet;

/// How long a sheet takes to rise.
const appSheetDuration = Duration(milliseconds: 400);

/// How far the screen behind an open sheet shrinks.
const appSheetBackgroundScale = 0.95;

/// Height of a sheet that is not scroll controlled, as a share of the
/// screen, before its close row is added (Flutter's own cap).
const appSheetContentHeightRatio = 9 / 16;

/// Corner radius the screen behind an open sheet takes on as it shrinks.
const appSheetBackgroundRadius = 12.0;

/// Opens a modal bottom sheet on frosted glass. It rises over 400ms on the
/// standard curve while the screen behind shrinks to about 95% with rounded
/// corners and dims; a swipe down, a tap outside or the round close (X)
/// button closes it. Sheets have no grab bar. With reduced motion the sheet
/// simply appears and the screen behind does not shrink. Every sheet in the
/// app goes through here so they all look and move the same.
///
/// [showDragHandle] is kept for existing callers: it now means "draw the
/// standard sheet top", which is the close button at the end side (left in
/// Arabic, right in English). Callers that draw their own top pass false.
/// [showCloseButton], when given, decides on its own.
///
/// A sheet that is not scroll controlled keeps 9/16 of the screen for its
/// content, with the close row on top of that, and scrolls when its content
/// is taller (small phones, large text) instead of overflowing.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool showDragHandle = true,
  bool? showCloseButton,
}) {
  final c = context.sirati;
  final closeButton = showCloseButton ?? showDragHandle;
  final navigator = Navigator.of(context);
  final screenHeight = MediaQuery.sizeOf(context).height;
  final maxHeightRatio = closeButton && screenHeight > 0
      ? (appSheetContentHeightRatio + _closeRowHeight / screenHeight)
          .clamp(appSheetContentHeightRatio, 1.0)
      : appSheetContentHeightRatio;
  final localizations = MaterialLocalizations.of(context);
  return navigator.push(
    _GlassSheetRoute<T>(
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: isScrollControlled,
      scrollControlDisabledMaxHeightRatio: maxHeightRatio,
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint:
          localizations.scrimOnTapHint(localizations.bottomSheetLabel),
      // The sheet's own Material stays clear; the glass pane paints it.
      backgroundColor: c.surface.withValues(alpha: 0),
      elevation: 0,
      showDragHandle: false,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      sheetAnimationStyle: MotionSettings.reduce(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: appSheetDuration,
              reverseDuration: MotionDurations.sheet,
              curve: MotionCurves.standard,
            ),
      builder: (context) => GlassSurface(
        borderRadius: AppRadius.sheetTop,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (closeButton)
              const Padding(
                padding: EdgeInsetsDirectional.only(
                  top: _closeRowTop,
                  start: AppSpacing.md,
                  end: AppSpacing.md,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: SheetCloseButton(),
                ),
              ),
            Flexible(
              child: isScrollControlled
                  ? builder(context)
                  // Not primary: a caller's own list may claim that.
                  : SingleChildScrollView(
                      primary: false,
                      child: builder(context),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Space above the close button.
const _closeRowTop = AppSpacing.md;

/// The close row: its top space plus the button's 48 tap target.
const _closeRowHeight = _closeRowTop + kMinInteractiveDimension;

/// The bottom sheet route, plus the transition it hands to the screen below:
/// that screen shrinks and rounds its corners while the sheet is up. The
/// shrink follows the sheet's own animation, so it tracks a swipe down too.
class _GlassSheetRoute<T> extends ModalBottomSheetRoute<T> {
  _GlassSheetRoute({
    required super.builder,
    required super.capturedThemes,
    required super.isScrollControlled,
    required super.scrollControlDisabledMaxHeightRatio,
    required super.barrierLabel,
    required super.barrierOnTapHint,
    required super.backgroundColor,
    required super.elevation,
    required super.showDragHandle,
    required super.shape,
    required super.modalBarrierColor,
    required super.sheetAnimationStyle,
  });

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _shrinkBehind;

  static Widget? _shrinkBehind(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    if (child == null || MotionSettings.reduce(context)) return child;
    return AnimatedBuilder(
      animation: secondaryAnimation,
      child: child,
      builder: (context, child) {
        final t = MotionCurves.standard.transform(
          secondaryAnimation.value.clamp(0.0, 1.0),
        );
        return Transform.scale(
          key: const ValueKey('sheet-background-scale'),
          scale: 1 - (1 - appSheetBackgroundScale) * t,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(appSheetBackgroundRadius * t),
            child: child,
          ),
        );
      },
    );
  }
}

/// The round close (X) button at the top of a sheet. Screen readers hear the
/// platform's localized "Close".
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key});

  /// Diameter of the round button.
  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return IconButton(
      key: const ValueKey('sheet-close'),
      onPressed: () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        backgroundColor: c.cardFill,
        foregroundColor: c.textPrimary,
        fixedSize: const Size.square(size),
        minimumSize: const Size.square(size),
        shape: const CircleBorder(),
      ),
      icon: Icon(
        Icons.close_rounded,
        size: 22,
        semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip,
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
    showCloseButton: true,
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
