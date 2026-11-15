import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Sirati's pull-to-refresh. Material's refresh logic (thresholds, semantics,
/// the refresh call) with the app's own mark:
///
/// - While pulling, a ring fills with the pull distance.
/// - At the point where letting go will refresh, it pops and gives a light
///   click.
/// - While refreshing, the ring sweeps (only until the refresh ends, at most
///   [maxSpin]).
/// - When done, a tick draws in, then the mark shrinks away.
///
/// With reduced motion the ring fills and shows a steady arc while loading,
/// with no pop, spin or tick animation.
class SiratiRefreshIndicator extends StatefulWidget {
  const SiratiRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  /// Distance of the mark from the top; the safe area plus a small gap by
  /// default.
  final double? edgeOffset;

  /// Size of the round mark.
  static const size = 40.0;

  /// The sweep never runs longer than this, even if a refresh hangs.
  static const maxSpin = Duration(seconds: 10);

  /// Key of the mark, for tests.
  static const markKey = ValueKey('sirati-refresh-mark');

  @override
  State<SiratiRefreshIndicator> createState() => SiratiRefreshIndicatorState();
}

@visibleForTesting
class SiratiRefreshIndicatorState extends State<SiratiRefreshIndicator>
    with TickerProviderStateMixin {
  RefreshIndicatorStatus? _status;
  double _drag = 0;
  double _viewport = 1;

  /// One turn per second while refreshing.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  /// The pop at the refresh point.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: MotionDurations.medium,
  );

  /// The tick, then the shrink away.
  late final AnimationController _done = AnimationController(
    vsync: this,
    duration: MotionDurations.morph,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() {});
    });

  /// Whether it is loading (Material only reports "snap" for this).
  @visibleForTesting
  bool get loading =>
      _status == RefreshIndicatorStatus.snap ||
      _status == RefreshIndicatorStatus.refresh;

  /// Current refresh state, for tests.
  @visibleForTesting
  RefreshIndicatorStatus? get status => _status;

  /// How full the ring is from pulling, 0 → 1 (1 = letting go refreshes).
  @visibleForTesting
  double get fill => _status == RefreshIndicatorStatus.drag ||
          _status == RefreshIndicatorStatus.armed
      ? (_drag / (_viewport * .25) * 1.5).clamp(0.0, 1.0)
      : 1;

  bool get _reduce => MotionSettings.reduce(context);

  void _onStatus(RefreshIndicatorStatus? status) {
    final was = _status;
    setState(() => _status = status);
    switch (status) {
      case RefreshIndicatorStatus.drag:
        _drag = 0;
        _done.value = 0;
        _pop.value = 0;
      case RefreshIndicatorStatus.armed:
        if (was != RefreshIndicatorStatus.armed) {
          HapticFeedback.selectionClick();
          if (!_reduce) _pop.forward(from: 0);
        }
      // Material reports "snap" when the refresh starts and never reports
      // "refresh" itself, so both mean loading.
      case RefreshIndicatorStatus.snap:
      case RefreshIndicatorStatus.refresh:
        if (!_reduce && !_spin.isAnimating) {
          // Bounded: stops after maxSpin even if the refresh never returns.
          _spin.repeat(count: SiratiRefreshIndicator.maxSpin.inSeconds);
        }
      case RefreshIndicatorStatus.done:
        _spin.stop();
        if (_reduce) {
          _done.value = 1;
        } else {
          _done.forward(from: 0);
        }
      case RefreshIndicatorStatus.canceled:
      case null:
        _spin.stop();
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    _viewport = n.metrics.viewportDimension;
    final pulling = _status == RefreshIndicatorStatus.drag ||
        _status == RefreshIndicatorStatus.armed;
    if (!pulling) return false;
    final down = n.metrics.axisDirection == AxisDirection.down;
    if (n is ScrollUpdateNotification &&
        n.dragDetails != null &&
        n.metrics.pixels <= n.metrics.minScrollExtent) {
      final delta = n.scrollDelta ?? 0;
      setState(() => _drag = math.max(0, _drag + (down ? -delta : delta)));
    } else if (n is OverscrollNotification && n.dragDetails != null) {
      final delta = n.overscroll;
      setState(() => _drag = math.max(0, _drag + (down ? -delta : delta)));
    }
    return false;
  }

  @override
  void dispose() {
    _spin.dispose();
    _pop.dispose();
    _done.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final top =
        widget.edgeOffset ?? MediaQuery.paddingOf(context).top + AppSpacing.sm;
    final status = _status;
    // Shown while pulling and loading, and after "done" only while the tick
    // plays (Material does not always report the status clearing).
    final visible = status == RefreshIndicatorStatus.drag ||
        status == RefreshIndicatorStatus.armed ||
        loading ||
        _done.isAnimating;

    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: _onStatus,
          semanticsLabel:
              MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ),
        if (visible)
          PositionedDirectional(
            start: 0,
            end: 0,
            top: top,
            // Material's own spinner would say "Refresh"; this mark says it
            // instead, as a live region while loading.
            child: Semantics(
              label: MaterialLocalizations.of(context)
                  .refreshIndicatorSemanticLabel,
              liveRegion: loading,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_spin, _pop, _done]),
                    builder: (context, _) {
                      final pulling = status == RefreshIndicatorStatus.drag ||
                          status == RefreshIndicatorStatus.armed;
                      // Comes down with the finger, then rests.
                      final drop = pulling ? -12 * (1 - fill) : 0.0;
                      final popScale = 1 + .18 * math.sin(math.pi * _pop.value);
                      final done = _done.value;
                      // Tick in the first half, shrink away in the second.
                      final away = const Interval(.6, 1, curve: Curves.easeIn)
                          .transform(done);
                      return Transform.translate(
                        offset: Offset(0, drop),
                        child: Transform.scale(
                          scale: (pulling ? .6 + .4 * fill : 1) *
                              popScale *
                              (1 - away),
                          child: Opacity(
                            opacity: pulling ? fill.clamp(.2, 1) : 1,
                            child: CustomPaint(
                              key: SiratiRefreshIndicator.markKey,
                              size: const Size.square(
                                  SiratiRefreshIndicator.size),
                              painter: RefreshMarkPainter(
                                fill: fill,
                                spinning: loading,
                                turn: _spin.value,
                                tick: done > 0
                                    ? const Interval(0, .5,
                                            curve: MotionCurves.standard)
                                        .transform(done)
                                    : 0,
                                ink: c.primaryInk,
                                track: c.primaryLight,
                                surface: c.surface,
                                shadow: AppShadows.of(c, elevation: 2),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The round refresh mark: a surface bubble with a ring that fills, sweeps
/// or carries a tick.
@visibleForTesting
class RefreshMarkPainter extends CustomPainter {
  RefreshMarkPainter({
    required this.fill,
    required this.spinning,
    required this.turn,
    required this.tick,
    required this.ink,
    required this.track,
    required this.surface,
    required this.shadow,
  });

  final double fill;
  final bool spinning;
  final double turn;

  /// How much of the done tick is drawn, 0 → 1.
  final double tick;
  final Color ink;
  final Color track;
  final Color surface;
  final List<BoxShadow> shadow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (final s in shadow) {
      canvas.drawCircle(center + s.offset, r + s.spreadRadius, s.toPaint());
    }
    canvas.drawCircle(center, r, Paint()..color = surface);
    final ring = Rect.fromCircle(center: center, radius: r * .55);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ring, 0, 2 * math.pi, false, stroke..color = track);
    if (tick > 0) {
      canvas.drawArc(ring, 0, 2 * math.pi, false, stroke..color = ink);
      // A tick drawn from its short arm to the end of its long arm.
      final a = center + Offset(-r * .22, 0);
      final b = center + Offset(-r * .06, r * .16);
      final e = center + Offset(r * .24, -r * .18);
      final path = Path()..moveTo(a.dx, a.dy);
      final firstLeg = (tick / .4).clamp(0.0, 1.0);
      path.lineTo(
          a.dx + (b.dx - a.dx) * firstLeg, a.dy + (b.dy - a.dy) * firstLeg);
      if (tick > .4) {
        final second = ((tick - .4) / .6).clamp(0.0, 1.0);
        path.lineTo(
            b.dx + (e.dx - b.dx) * second, b.dy + (e.dy - b.dy) * second);
      }
      canvas.drawPath(path, stroke..color = ink);
      return;
    }
    if (spinning) {
      canvas.drawArc(ring, -math.pi / 2 + 2 * math.pi * turn, math.pi * .6,
          false, stroke..color = ink);
      return;
    }
    if (fill > 0) {
      canvas.drawArc(
          ring, -math.pi / 2, 2 * math.pi * fill, false, stroke..color = ink);
    }
  }

  @override
  bool shouldRepaint(RefreshMarkPainter old) =>
      old.fill != fill ||
      old.spinning != spinning ||
      old.turn != turn ||
      old.tick != tick ||
      old.ink != ink;
}
