import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_band_style.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// The big ATS score on the analysis result.
///
/// Right after a scan ([reveal]) it is revealed like a moment:
///
/// 1. The arc climbs from 0 to [score] with a glowing head, warming from the
///    grey track colour into the score's own colour, while the number counts
///    up.
/// 2. It lands: a ring of light pulses out, the number pops once and the
///    phone gives a light tap.
///
/// While it climbs, the arc takes on each band's colour as it reaches that
/// band, and the phone ticks once at every band boundary it passes, so a
/// better score is felt step by step.
///
/// With a [previousScore] (the last scan of the same CV for the same job), a
/// faint arc marks the old score, the new arc climbs past it (or stops short
/// of it), and a "+12" / "−4" chip pops in under the number as it lands.
///
/// Reopening a saved result, or with "remove animations" on, shows the final
/// score at once: the reveal is a reward for scanning, not a wait on every
/// visit.
class AnimatedScoreRing extends StatefulWidget {
  const AnimatedScoreRing({
    super.key,
    required this.score,
    required this.scoreColor,
    this.reveal = false,
    this.previousScore,
  });

  final int score;
  final Color scoreColor;

  /// The last scan's score for the same CV and job, if any.
  final int? previousScore;

  /// Play the reveal: only right after a scan. Off by default, so a new use
  /// of the ring never replays it on every visit.
  final bool reveal;

  /// The whole reveal: climb, then land.
  static const duration = MotionDurations.reveal;

  /// Share of [duration] spent climbing; the rest is the landing.
  static const climbShare = .7;

  static const size = 116.0;
  static const stroke = 10.0;

  /// Key of the painted ring, for tests.
  static const ringKey = ValueKey('score-ring-paint');

  /// Key of the change chip, for tests.
  static const deltaKey = ValueKey('score-ring-delta');

  /// Scores where the band changes, from the band rules themselves.
  static final List<int> bandBoundaries = [
    for (var s = 1; s <= 100; s++)
      if (ScoreBand.of(s) != ScoreBand.of(s - 1)) s,
  ];

  /// The band boundaries a climb from 0 to [score] passes: one tick each.
  static List<int> crossingsTo(int score) => [
        for (final b in bandBoundaries)
          if (b <= score.clamp(0, 100)) b
      ];

  /// The arc blends into a band's colour over this many points just below
  /// the band's boundary, so it has fully turned when the tick comes.
  static const blendPoints = 4;

  /// The change since [previousScore], or null when there is none to show.
  static int? deltaOf(int score, int? previousScore) {
    if (previousScore == null) return null;
    final delta = score.clamp(0, 100) - previousScore.clamp(0, 100);
    return delta == 0 ? null : delta;
  }

  /// "+12", or "−4" with a true minus sign; always Latin digits.
  static String deltaLabel(int delta) =>
      delta > 0 ? '+$delta' : '\u2212${delta.abs()}';

  @override
  State<AnimatedScoreRing> createState() => AnimatedScoreRingState();
}

@visibleForTesting
class AnimatedScoreRingState extends State<AnimatedScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AnimatedScoreRing.duration,
  );
  bool _started = false;
  bool _landed = false;
  int _ticks = 0;

  /// How many band ticks have played, for tests.
  @visibleForTesting
  int get bandTicks => _ticks;

  late List<int> _crossings = AnimatedScoreRing.crossingsTo(widget.score);

  static const _climb = Interval(
    0,
    AnimatedScoreRing.climbShare,
    curve: Cubic(0.2, 0.7, 0.2, 1),
  );
  static const _land = Interval(AnimatedScoreRing.climbShare, 1);

  /// 0 → 1 while the arc climbs.
  @visibleForTesting
  double get climb => _climb.transform(_reveal.value);

  /// 0 → 1 while it lands; 0 before.
  @visibleForTesting
  double get land => _land.transform(_reveal.value);

  /// The share of the full circle the arc covers right now.
  @visibleForTesting
  double get shownValue => widget.score.clamp(0, 100) / 100 * climb;

  @override
  void initState() {
    super.initState();
    _reveal.addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.reveal || MotionSettings.reduce(context)) {
      _landed = true;
      _ticks = _crossings.length;
      _reveal.value = 1;
      return;
    }
    // Start once the page has finished coming in, so the climb is seen
    // whole instead of under a half-transparent page. A new page is first
    // built offstage (for measuring), where its animation already reads as
    // complete, so "complete" only counts once it is on screen.
    final route = ModalRoute.of(context);
    final coming = route?.animation;
    if (route == null || coming == null) {
      _reveal.forward();
      return;
    }
    _route = route;
    _routeIn = coming;
    coming.addStatusListener(_onRouteStatus);
    _onRouteStatus(coming.status);
  }

  ModalRoute<Object?>? _route;
  Animation<double>? _routeIn;

  void _onRouteStatus(AnimationStatus status) {
    final route = _route;
    if (status != AnimationStatus.completed || route == null) return;
    if (route.offstage) return;
    _routeIn?.removeStatusListener(_onRouteStatus);
    _routeIn = null;
    _route = null;
    if (mounted) _reveal.forward();
  }

  @override
  void didUpdateWidget(AnimatedScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score == widget.score) return;
    _crossings = AnimatedScoreRing.crossingsTo(widget.score);
    if (widget.reveal && !MotionSettings.reduce(context)) {
      _landed = false;
      _ticks = 0;
      _reveal.forward(from: 0);
    } else {
      _ticks = _crossings.length;
    }
  }

  void _onTick() {
    final shown = (shownValue * 100).round();
    while (_ticks < _crossings.length && shown >= _crossings[_ticks]) {
      _ticks++;
      HapticFeedback.selectionClick();
    }
    if (!_landed && land > 0) {
      _landed = true;
      HapticFeedback.lightImpact();
    }
  }

  /// The arc's colour when it shows [points]: the colour of the band it is
  /// in, blending into the next band over [AnimatedScoreRing.blendPoints]
  /// just below that band's boundary. Only bands the climb will reach take
  /// part, so the arc always ends exactly on [AnimatedScoreRing.scoreColor].
  @visibleForTesting
  Color bandColor(SiratiColors c, double points) {
    final finalBand = ScoreBand.of(widget.score.clamp(0, 100));
    Color colorOf(ScoreBand band) =>
        band == finalBand ? widget.scoreColor : band.onContainer(c);
    var color = colorOf(ScoreBand.of(0));
    for (final b in _crossings) {
      const blend = AnimatedScoreRing.blendPoints;
      final t = ((points - (b - blend)) / blend).clamp(0.0, 1.0);
      if (t == 0) break;
      color = Color.lerp(color, colorOf(ScoreBand.of(b)), t)!;
    }
    return color;
  }

  @override
  void dispose() {
    _routeIn?.removeStatusListener(_onRouteStatus);
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);

    // RepaintBoundary keeps the per-frame reveal from repainting the rest of
    // the score card.
    return Semantics(
      label: l10n.compatibilityScoreLabel,
      value: l10n.compatibilityScoreValue(widget.score),
      excludeSemantics: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _reveal,
          builder: (context, _) {
            final climb = this.climb;
            final land = this.land;
            final value = shownValue;
            final display = (value * 100).round();
            // The pop is the number swelling once as the score lands.
            final pop = 1 + .14 * math.sin(math.pi * land);
            final delta = AnimatedScoreRing.deltaOf(
              widget.score,
              widget.previousScore,
            );
            // The old score's arc fades in at the start of the reveal.
            final ghost = (_reveal.value / .1).clamp(0.0, 1.0);
            // The change chip pops in as the score lands.
            final chip = const Interval(0, .6).transform(land);
            return SizedBox.square(
              dimension: AnimatedScoreRing.size,
              child: CustomPaint(
                key: AnimatedScoreRing.ringKey,
                painter: ScoreRingPainter(
                  value: value,
                  track: c.border,
                  // Warms from the grey track into each band's colour in
                  // turn, ending on the score's own colour.
                  color: Color.lerp(
                    c.borderStrong,
                    bandColor(c, value * 100),
                    Curves.easeIn.transform(climb),
                  )!,
                  ghost: delta == null
                      ? 0
                      : widget.previousScore!.clamp(0, 100) / 100,
                  ghostColor: c.textSecondary.withValues(alpha: .35 * ghost),
                  head: climb > 0 && climb < 1,
                  land: land < 1 ? land : 0,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Transform.scale(
                        scale: pop,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$display',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                // The ring carries the band colour; the
                                // number stays in a text tone (primary is
                                // ~2.9:1).
                                color: c.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 12,
                                color: c.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            if (delta != null && chip > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Opacity(
                                  opacity: chip,
                                  child: Transform.scale(
                                    scale: MotionCurves.pop.transform(chip),
                                    child: _DeltaChip(delta: delta),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The change since the last scan: "+12" on the success tint, or a quiet
/// grey drop. A drop is information, not an alarm.
class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final int delta;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final up = delta > 0;
    return Container(
      key: AnimatedScoreRing.deltaKey,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: up
          ? BoxDecoration(
              color: c.successLight,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      // Latin digits with the sign before them, in both languages.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          AnimatedScoreRing.deltaLabel(delta),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: up ? c.onSuccessContainer : c.textSecondary,
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

/// Track, arc, glowing head and landing pulse, all from one geometry, so the
/// head always sits exactly on the end of the arc.
@visibleForTesting
class ScoreRingPainter extends CustomPainter {
  ScoreRingPainter({
    required this.value,
    required this.track,
    required this.color,
    required this.head,
    required this.land,
    this.ghost = 0,
    this.ghostColor,
  });

  /// Share of the circle covered, 0 → 1.
  final double value;

  /// Share of the circle the previous score covered (0 = none), drawn
  /// faintly under the arc in [ghostColor] (none without one).
  final double ghost;
  final Color? ghostColor;
  final Color track;
  final Color color;

  /// Draw the glowing head (while climbing).
  final bool head;

  /// Landing pulse progress, 0 (none) → 1.
  final double land;

  /// The arc starts at 12 o'clock and runs clockwise.
  static const start = -math.pi / 2;

  static double radiusFor(Size size) =>
      (size.shortestSide - AnimatedScoreRing.stroke) / 2;

  /// Where the arc ends, which is where the head is drawn.
  static Offset endOf(Size size, double value) {
    final angle = start + 2 * math.pi * value;
    return size.center(Offset.zero) +
        Offset(math.cos(angle), math.sin(angle)) * radiusFor(size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = radiusFor(size);
    const stroke = AnimatedScoreRing.stroke;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final ghostColor = this.ghostColor;
    if (ghost > 0 && ghostColor != null && ghostColor.a > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * math.pi * ghost,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = ghostColor,
      );
    }
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        2 * math.pi * value,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
    if (head && value > 0) {
      final end = endOf(size, value);
      canvas
        ..drawCircle(
          end,
          stroke,
          Paint()
            ..color = color.withValues(alpha: .35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        )
        ..drawCircle(end, stroke * .45, Paint()..color = color);
    }
    if (land > 0) {
      final pulse = Curves.easeOut.transform(land);
      canvas.drawCircle(
        center,
        radius + stroke / 2 + 16 * pulse,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - pulse) + .5
          ..color = color.withValues(alpha: .45 * (1 - pulse)),
      );
    }
  }

  @override
  bool shouldRepaint(ScoreRingPainter old) =>
      old.value != value ||
      old.track != track ||
      old.color != color ||
      old.head != head ||
      old.land != land ||
      old.ghost != ghost ||
      old.ghostColor != ghostColor;
}
