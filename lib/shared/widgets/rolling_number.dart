import 'package:flutter/material.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// A count that rolls to its new value instead of jumping: a higher number
/// rolls up into place, a lower one rolls down. Only a change rolls; the
/// first value just shows.
///
/// Always Latin digits, laid out left to right in both languages (so "12"
/// never reads "21" in Arabic). Above [cap] it shows "cap+" (e.g. "9+").
/// With reduced motion it is a plain [Text].
class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.value,
    this.style,
    this.cap,
    this.textAlign = TextAlign.center,
  });

  final int value;
  final TextStyle? style;
  final int? cap;
  final TextAlign textAlign;

  /// One roll.
  static const duration = MotionDurations.slow;

  /// What is shown for [value] with [cap].
  static String label(int value, {int? cap}) =>
      cap != null && value > cap ? '$cap+' : '$value';

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  /// +1 when the last change went up, -1 when it went down.
  int _direction = 1;

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _direction = widget.value > oldWidget.value ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = RollingNumber.label(widget.value, cap: widget.cap);
    final text = Text(
      label,
      key: ValueKey(label),
      textAlign: widget.textAlign,
      style: widget.style,
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MotionSettings.reduce(context)
          ? text
          : ClipRect(
              child: AnimatedSwitcher(
                duration: RollingNumber.duration,
                switchInCurve: MotionCurves.state,
                switchOutCurve: MotionCurves.exit,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(label);
                  // The new number comes from below when the count went up
                  // (from above when it went down); the old one leaves the
                  // other way.
                  final from = Offset(
                    0,
                    (incoming ? 1.0 : -1.0) * _direction,
                  );
                  return SlideTransition(
                    position:
                        Tween(begin: from, end: Offset.zero).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: text,
              ),
            ),
    );
  }
}
