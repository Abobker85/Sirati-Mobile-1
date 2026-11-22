import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// A Home card that is one tap target, in the iOS 26 style: a grey,
/// shadowless fill with 18dp corners. Pressing darkens the fill and springs
/// the card down to [pressedScale], then back on release (no scale with
/// reduced motion; the fill still darkens). Keyboard focus draws a 2dp ring
/// outside the card.
class HomePressableCard extends StatefulWidget {
  const HomePressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.inkKey,
    this.radius = AppRadius.card,
    this.color,
    this.semanticsLabel,
  });

  /// How far a held card shrinks.
  static const pressedScale = .96;

  final Widget child;
  final VoidCallback? onTap;

  /// Key on the tappable area, for tests and deep links.
  final Key? inkKey;
  final double radius;

  /// Resting fill; the card fill by default. The pressed fill is derived
  /// from it, so every card darkens by the same rule.
  final Color? color;

  /// Read instead of the card's text, when the text alone is not enough.
  final String? semanticsLabel;

  @override
  State<HomePressableCard> createState() => _HomePressableCardState();
}

class _HomePressableCardState extends State<HomePressableCard> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final radius = BorderRadius.circular(widget.radius);
    final enabled = widget.onTap != null;
    final reduce = MotionSettings.reduce(context);
    final fill = widget.color ?? c.cardFill;

    Widget card = AnimatedContainer(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: _pressed ? c.pressed(fill) : fill,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: widget.inkKey,
          onTap: widget.onTap,
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          // The darker fill is the feedback.
          overlayColor: WidgetStatePropertyAll(fill.withValues(alpha: 0)),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onFocusChange: (v) => setState(() => _focused = v),
          // Icons inside squish and bounce back with the card.
          child: IconPressHost(pressed: _pressed, child: widget.child),
        ),
      ),
    );

    // The ring sits outside the card, so focus never shifts the layout.
    card = Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        card,
        if (_focused)
          Positioned(
            left: -4,
            top: -4,
            right: -4,
            bottom: -4,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius + 4),
                  border: Border.all(color: c.primary, width: 2),
                ),
              ),
            ),
          ),
      ],
    );

    // Press: down quickly, back with a small spring overshoot.
    card = AnimatedScale(
      scale: _pressed && !reduce ? HomePressableCard.pressedScale : 1,
      duration: _pressed ? MotionDurations.press : MotionDurations.medium,
      curve: _pressed ? MotionCurves.standard : MotionCurves.pop,
      child: card,
    );

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      child: card,
    );
  }
}
