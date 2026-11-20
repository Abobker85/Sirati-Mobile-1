import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Shared animated circular score ring (0–100) for result and summary cards.
///
/// Supports custom [arcColor], [trackColor], [strokeWidth], [strokeCap],
/// [size], configurable [duration], optional [RouteSettled] deferral via
/// [waitForRoute], and instant settlement under [MotionSettings.reduce].
class AnimatedScoreRing extends StatelessWidget {
  const AnimatedScoreRing({
    super.key,
    required this.score,
    this.size = 112,
    this.strokeWidth = 10,
    this.strokeCap = StrokeCap.round,
    this.arcColor,
    this.trackColor,
    this.duration = defaultDuration,
    this.curve = MotionCurves.enter,
    this.waitForRoute = true,
    this.animate = true,
    this.scaleWithText = false,
    this.semanticLabel,
    this.semanticValue,
    this.centerBuilder,
  });

  /// Score from 0 to 100.
  final int score;
  final double size;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final Color? arcColor;
  final Color? trackColor;

  /// Reveal duration (defaults to 420ms so screen settle checks stay snappy).
  final Duration duration;
  final Curve curve;

  /// When true, defers starting the reveal until [RouteSettled] reports the
  /// enclosing route transition is complete and onscreen.
  final bool waitForRoute;

  /// Allows callers to suppress animation even when OS animations are enabled.
  final bool animate;

  /// Scales the ring diameter with display text scaling (minimum 1.0x).
  final bool scaleWithText;

  final String? semanticLabel;
  final String? semanticValue;

  /// Optional custom center widget receiving the current animated score.
  final Widget Function(BuildContext context, int animatedScore)? centerBuilder;

  static const defaultDuration = Duration(milliseconds: 420);
  static const ringKey = ValueKey('shared-animated-score-ring');

  @override
  Widget build(BuildContext context) {
    final reduce = !animate || MotionSettings.reduce(context);
    if (!waitForRoute || reduce) {
      return _AnimatedScoreRingBody(
        score: score,
        size: size,
        strokeWidth: strokeWidth,
        strokeCap: strokeCap,
        arcColor: arcColor,
        trackColor: trackColor,
        duration: duration,
        curve: curve,
        settled: true,
        reduce: reduce,
        scaleWithText: scaleWithText,
        semanticLabel: semanticLabel,
        semanticValue: semanticValue,
        centerBuilder: centerBuilder,
      );
    }

    return RouteSettled(
      builder: (context, settled) => _AnimatedScoreRingBody(
        score: score,
        size: size,
        strokeWidth: strokeWidth,
        strokeCap: strokeCap,
        arcColor: arcColor,
        trackColor: trackColor,
        duration: duration,
        curve: curve,
        settled: settled,
        reduce: false,
        scaleWithText: scaleWithText,
        semanticLabel: semanticLabel,
        semanticValue: semanticValue,
        centerBuilder: centerBuilder,
      ),
    );
  }
}

class _AnimatedScoreRingBody extends StatefulWidget {
  const _AnimatedScoreRingBody({
    required this.score,
    required this.size,
    required this.strokeWidth,
    required this.strokeCap,
    required this.arcColor,
    required this.trackColor,
    required this.duration,
    required this.curve,
    required this.settled,
    required this.reduce,
    required this.scaleWithText,
    required this.semanticLabel,
    required this.semanticValue,
    required this.centerBuilder,
  });

  final int score;
  final double size;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final Color? arcColor;
  final Color? trackColor;
  final Duration duration;
  final Curve curve;
  final bool settled;
  final bool reduce;
  final bool scaleWithText;
  final String? semanticLabel;
  final String? semanticValue;
  final Widget Function(BuildContext context, int animatedScore)? centerBuilder;

  @override
  State<_AnimatedScoreRingBody> createState() => _AnimatedScoreRingBodyState();
}

class _AnimatedScoreRingBodyState extends State<_AnimatedScoreRingBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  double _from = 0;
  double _to = 0;
  bool _started = false;

  double get _target => widget.score.clamp(0, 100) / 100;

  double get _currentProgress {
    final t = widget.curve.transform(_controller.value);
    return _from + (_to - _from) * t;
  }

  @override
  void initState() {
    super.initState();
    _sync(initial: true);
  }

  @override
  void didUpdateWidget(_AnimatedScoreRingBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    _sync(
      initial: false,
      scoreChanged: oldWidget.score != widget.score,
      settledNow: !oldWidget.settled && widget.settled,
      reduceChanged: oldWidget.reduce != widget.reduce,
    );
  }

  void _sync({
    required bool initial,
    bool scoreChanged = false,
    bool settledNow = false,
    bool reduceChanged = false,
  }) {
    final target = _target;
    if (widget.reduce) {
      _controller.stop();
      _from = target;
      _to = target;
      _controller.value = 1;
      _started = true;
      return;
    }

    if (!widget.settled) {
      _from = 0;
      _to = target;
      _controller.value = 0;
      return;
    }

    if ((initial && !_started) || settledNow || reduceChanged) {
      _started = true;
      _from = 0;
      _to = target;
      _controller.forward(from: 0);
      return;
    }

    if (scoreChanged) {
      _from = _currentProgress;
      _to = target;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final track = widget.trackColor ?? c.borderStrong;
    final arc = widget.arcColor ?? c.primaryInk;
    final textScale = widget.scaleWithText
        ? (MediaQuery.textScalerOf(context).scale(AppTypography.displayMd.size) /
                AppTypography.displayMd.size)
            .clamp(1.0, double.infinity)
        : 1.0;
    final dimension = widget.size * textScale;

    final painted = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress =
              widget.reduce ? _target : _currentProgress.clamp(0.0, 1.0);
          final shownScore = (progress * 100).round().clamp(0, 100);
          return SizedBox.square(
            dimension: dimension,
            child: CustomPaint(
              key: AnimatedScoreRing.ringKey,
              painter: AnimatedScoreRingPainter(
                progress: progress,
                strokeWidth: widget.strokeWidth,
                strokeCap: widget.strokeCap,
                trackColor: track,
                arcColor: arc,
              ),
              child: Center(
                child: widget.centerBuilder != null
                    ? widget.centerBuilder!(context, shownScore)
                    : Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          AppFormat.digits('$shownScore', english: true),
                          style: AppTypography.of(
                            context,
                            AppTypography.displayMd,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.semanticLabel == null) return painted;
    return Semantics(
      label: widget.semanticLabel,
      value: widget.semanticValue,
      excludeSemantics: true,
      child: painted,
    );
  }
}

/// Paints the ring track and arc for [AnimatedScoreRing].
@visibleForTesting
class AnimatedScoreRingPainter extends CustomPainter {
  AnimatedScoreRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.strokeCap,
    required this.trackColor,
    required this.arcColor,
  });

  final double progress;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final Color trackColor;
  final Color arcColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ring = rect.deflate(strokeWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = strokeCap;
    canvas.drawArc(ring, 0, math.pi * 2, false, paint..color = trackColor);
    if (progress > 0) {
      canvas.drawArc(
        ring,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = arcColor,
      );
    }
  }

  @override
  bool shouldRepaint(AnimatedScoreRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.strokeCap != strokeCap ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.arcColor != arcColor;
}
