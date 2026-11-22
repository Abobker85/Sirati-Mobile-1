import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// A small compass for "page not found": on arrival the needle swings, as if
/// searching, and settles pointing straight down, at the way out below it.
/// It moves once; with reduced motion it is already settled.
class CompassNeedle extends StatefulWidget {
  const CompassNeedle({super.key, this.size = 40});

  final double size;

  /// The swing, including a short wait before it starts.
  static const duration = Duration(milliseconds: 1400);

  /// Where the needle rests: pointing down.
  static const restAngle = math.pi;

  /// The needle's angle at swing progress [t] (0 → 1): it starts turned
  /// away, swings past the rest angle a few times with shrinking swings, and
  /// ends exactly on [restAngle].
  static double angleAt(double t) {
    const wait = .2;
    if (t <= wait) return restAngle - 2.2;
    if (t >= 1) return restAngle;
    final s = (t - wait) / (1 - wait);
    final envelope = math.exp(-4.5 * s) * (1 - s);
    return restAngle - 2.2 * envelope * math.cos(3 * math.pi * s);
  }

  /// Key of the painted compass, for tests.
  static const paintKey = ValueKey('compass-needle');

  @override
  State<CompassNeedle> createState() => CompassNeedleState();
}

@visibleForTesting
class CompassNeedleState extends State<CompassNeedle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: CompassNeedle.duration);
  bool _started = false;

  /// The needle's angle now.
  @visibleForTesting
  double get angle => CompassNeedle.angleAt(_c.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MotionSettings.reduce(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            key: CompassNeedle.paintKey,
            size: Size.square(widget.size),
            painter: _CompassPainter(
              angle: angle,
              ring: c.primaryInk,
              head: c.primaryInk,
              tail: c.borderStrong,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.angle,
    required this.ring,
    required this.head,
    required this.tail,
  });

  final double angle;
  final Color ring;
  final Color head;
  final Color tail;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
      center,
      r - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ring,
    );
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      // 0 = pointing up; positive turns clockwise.
      ..rotate(angle);
    final len = r * .68;
    final half = r * .2;
    canvas
      ..drawPath(
        Path()
          ..moveTo(0, -len)
          ..lineTo(half, 0)
          ..lineTo(-half, 0)
          ..close(),
        Paint()..color = head,
      )
      ..drawPath(
        Path()
          ..moveTo(0, len)
          ..lineTo(half, 0)
          ..lineTo(-half, 0)
          ..close(),
        Paint()..color = tail,
      )
      ..drawCircle(Offset.zero, 2.5, Paint()..color = ring)
      ..restore();
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.angle != angle ||
      old.ring != ring ||
      old.head != head ||
      old.tail != tail;
}
