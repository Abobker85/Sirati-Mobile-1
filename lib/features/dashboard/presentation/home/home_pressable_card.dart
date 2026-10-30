import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// A Home card that is one tap target, with the board's states: pressed
/// turns the surface a step darker and the border to the selected colour;
/// keyboard focus draws a 2dp ring outside the card.
class HomePressableCard extends StatefulWidget {
  const HomePressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.inkKey,
    this.radius = 22,
    this.color,
    this.pressedColor,
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Key on the tappable area, for tests and deep links.
  final Key? inkKey;
  final double radius;

  /// Resting fill; the surface by default.
  final Color? color;
  final Color? pressedColor;

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

    Widget card = AnimatedContainer(
      duration: MotionSettings.reduce(context)
          ? Duration.zero
          : const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: _pressed
            ? (widget.pressedColor ?? c.surfaceContainer)
            : (widget.color ?? c.surface),
        borderRadius: radius,
        border: Border.all(color: _pressed ? c.primary : c.border),
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
          // The pressed surface and border are the feedback.
          overlayColor: WidgetStatePropertyAll(c.surface.withValues(alpha: 0)),
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onFocusChange: (v) => setState(() => _focused = v),
          child: widget.child,
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

    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticsLabel,
      excludeSemantics: widget.semanticsLabel != null,
      child: card,
    );
  }
}
