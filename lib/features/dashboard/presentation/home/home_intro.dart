import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// How one piece of Home enters during the launch intro.
enum HomeIntroMotion {
  /// Slides down into place (the profile row).
  drop,

  /// Rises up into place (sections lower on the page).
  rise,

  /// Grows from 94% (the large start cards).
  zoom,

  /// Pops from 85% with a small overshoot (the service tiles).
  pop,
}

/// Drives one piece of Home's launch intro from a shared [animation] (0 → 1
/// over [MotionDurations.homeIntro]). The piece moves inside its own slice
/// [begin]..[end] of that timeline, so the page builds up in order.
///
/// The widget tree is the same at every point of the timeline, so cards keep
/// their state while it plays.
class HomeIntroItem extends StatelessWidget {
  const HomeIntroItem({
    super.key,
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
    this.motion = HomeIntroMotion.rise,
  });

  final Animation<double> animation;
  final double begin;
  final double end;
  final HomeIntroMotion motion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Movement may overshoot (pop); the fade never does, so it always runs
    // smoothly from 0 to 1 across the whole slice.
    final move = Interval(
      begin,
      end,
      curve:
          motion == HomeIntroMotion.pop ? MotionCurves.pop : MotionCurves.enter,
    );
    final fade = Interval(begin, end, curve: MotionCurves.enter);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = move.transform(animation.value);
        final shown = fade.transform(animation.value);
        final moved = switch (motion) {
          HomeIntroMotion.drop => Transform.translate(
              offset: Offset(0, -18 * (1 - t)),
              child: child,
            ),
          HomeIntroMotion.rise => Transform.translate(
              offset: Offset(0, 22 * (1 - t)),
              child: child,
            ),
          HomeIntroMotion.zoom => Transform.scale(
              scale: .94 + .06 * t,
              child: child,
            ),
          HomeIntroMotion.pop => Transform.scale(
              scale: .85 + .15 * t,
              child: child,
            ),
        };
        return Opacity(opacity: shown, child: moved);
      },
    );
  }
}

/// A single flash of light that sweeps across [child] once, from the leading
/// edge to the trailing edge (right to left in Arabic), inside the slice
/// [begin]..[end] of the intro [animation].
class HomeIntroSweep extends StatelessWidget {
  const HomeIntroSweep({
    super.key,
    required this.animation,
    required this.begin,
    required this.end,
    required this.radius,
    required this.child,
  });

  final Animation<double> animation;
  final double begin;
  final double end;

  /// Corner radius of the card underneath, so the light stays inside it.
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final interval = Interval(begin, end, curve: MotionCurves.standard);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The light is the card's own on-colour, so it reads in light and dark.
    final light = context.sirati.onBrandSurface;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = interval.transform(animation.value);
                if (t <= 0 || t >= 1) return const SizedBox.shrink();
                // Band centre travels from 1.6 past the leading edge to 1.6
                // past the trailing one, in Alignment units.
                final x = rtl ? 1.6 - 3.2 * t : -1.6 + 3.2 * t;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(x - .55, -1),
                        end: Alignment(x + .55, 1),
                        colors: [
                          light.withValues(alpha: 0),
                          light.withValues(alpha: .38),
                          light.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
