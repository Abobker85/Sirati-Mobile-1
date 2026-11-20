import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// The iOS 26 card look for job cards: a grey, borderless, shadowless fill
/// with 18dp corners that darkens while [pressed] and springs down to
/// [pressedScale] (no scale with reduced motion; the fill still darkens).
/// Keyboard [focused] draws a 2dp ring outside the card.
///
/// It paints only; the caller owns the tap target, so a card can keep a
/// sibling button (the featured card's Apply) out of its own target.
class JobPressSurface extends StatelessWidget {
  const JobPressSurface({
    super.key,
    required this.pressed,
    required this.child,
    this.focused = false,
    this.color,
  });

  /// How far a held card shrinks (same as Home's cards).
  static const pressedScale = .96;

  final bool pressed;
  final bool focused;
  final Widget child;

  /// Resting fill; the page's card fill by default. The pressed fill is
  /// derived from it by the shared press rule.
  final Color? color;

  /// The resting fill [JobPressSurface] uses in [context].
  static Color restingFill(BuildContext context, [Color? color]) =>
      color ?? PageSurface.fillOf(context);

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);
    final fill = restingFill(context, color);
    final radius = BorderRadius.circular(AppRadius.card);

    Widget card = AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: pressed ? c.pressed(fill) : fill,
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: IconPressHost(pressed: pressed, child: child),
      ),
    );

    // The ring sits outside the card, so focus never shifts the layout.
    card = Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        card,
        if (focused)
          Positioned(
            left: -4,
            top: -4,
            right: -4,
            bottom: -4,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card + 4),
                  border: Border.all(color: c.primary, width: 2),
                ),
              ),
            ),
          ),
      ],
    );

    // Press: down quickly, back with a small spring overshoot.
    return AnimatedScale(
      scale: pressed && !reduce ? pressedScale : 1,
      duration: pressed ? MotionDurations.press : MotionDurations.medium,
      curve: pressed ? MotionCurves.standard : MotionCurves.pop,
      child: card,
    );
  }
}

/// A job card that is one tap target: [JobPressSurface] around an ink area
/// whose only feedback is the darker fill.
class JobPressableCard extends StatefulWidget {
  const JobPressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;

  @override
  State<JobPressableCard> createState() => _JobPressableCardState();
}

class _JobPressableCardState extends State<JobPressableCard> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return JobPressSurface(
      pressed: _pressed,
      focused: _focused,
      color: widget.color,
      child: JobCardInk(
        onTap: widget.onTap,
        onPressedChanged: (v) => setState(() => _pressed = v),
        onFocusChanged: (v) => setState(() => _focused = v),
        child: widget.child,
      ),
    );
  }
}

/// The tap area inside a [JobPressSurface]: no splash and no highlight, so
/// the surface's darker fill is the only press feedback.
class JobCardInk extends StatelessWidget {
  const JobCardInk({
    super.key,
    required this.onTap,
    required this.onPressedChanged,
    required this.onFocusChanged,
    required this.child,
  });

  final VoidCallback? onTap;
  final ValueChanged<bool> onPressedChanged;
  final ValueChanged<bool> onFocusChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final none = context.sirati.cardFill.withValues(alpha: 0);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStatePropertyAll(none),
        onHighlightChanged: onPressedChanged,
        onFocusChange: onFocusChanged,
        child: child,
      ),
    );
  }
}
