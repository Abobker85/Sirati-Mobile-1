import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// The Home greeting, revealed once per app session: the whole line is
/// uncovered in reading direction (right to left in Arabic), then a small
/// sun or moon rises beside it. After that it is still.
///
/// The text is laid out whole and only masked, never split into letters, so
/// Arabic shaping is untouched. With reduced motion, or a screen reader on,
/// it simply shows.
class GreetingReveal extends StatefulWidget {
  const GreetingReveal({
    super.key,
    required this.text,
    required this.dayPart,
    this.style,
  });

  final String text;
  final DayPart dayPart;
  final TextStyle? style;

  /// The whole reveal: wipe, then the glyph.
  static const duration = Duration(milliseconds: 900);

  /// Wait after the header appears.
  static const delay = Duration(milliseconds: 250);

  /// Key of the sun / moon glyph, for tests.
  static const glyphKey = ValueKey('greeting-glyph');

  static bool _played = false;

  /// Whether the reveal already played in this app session, for tests.
  @visibleForTesting
  static bool get played => _played;

  @visibleForTesting
  static void resetSession() => _played = false;

  @override
  State<GreetingReveal> createState() => GreetingRevealState();
}

@visibleForTesting
class GreetingRevealState extends State<GreetingReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    // The wait is part of the timeline, so no timer is left behind.
    duration: GreetingReveal.delay + GreetingReveal.duration,
  );
  bool _decided = false;

  // 250 ms wait, then the wipe (about 630 ms), then the glyph overlapping
  // its end; as shares of the 1150 ms timeline.
  static const _wipe = Interval(.22, .77, curve: MotionCurves.enter);
  static const _glyph = Interval(.65, 1, curve: MotionCurves.settle);

  /// 0 → 1 while the line is uncovered.
  @visibleForTesting
  double get wipe => _wipe.transform(_c.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    final still = GreetingReveal._played ||
        MotionSettings.reduce(context) ||
        (MediaQuery.maybeAccessibleNavigationOf(context) ?? false);
    GreetingReveal._played = true;
    if (still) {
      _c.value = 1;
      return;
    }
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final evening = widget.dayPart == DayPart.evening;
    final text = Text(
      widget.text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final w = wipe;
        final g = _glyph.transform(_c.value);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: w >= 1
                  ? text
                  : RepaintBoundary(
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (rect) => LinearGradient(
                          begin: rtl
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          end: rtl
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          // A soft edge that runs from the reading start to
                          // past the end.
                          stops: [0, w * 1.2, (w * 1.2 + .2).clamp(0, 1), 1]
                              .map((s) => s.clamp(0.0, 1.0).toDouble())
                              .toList(),
                          // Only alpha matters to the mask.
                          colors: [
                            c.surface,
                            c.surface,
                            c.surface.withValues(alpha: 0),
                            c.surface.withValues(alpha: 0),
                          ],
                        ).createShader(rect),
                        child: text,
                      ),
                    ),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: Opacity(
                opacity: g.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, 6 * (1 - g)),
                  child: Icon(
                    evening ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    key: GreetingReveal.glyphKey,
                    size: 16,
                    color: evening ? c.primaryInk : c.amber,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
