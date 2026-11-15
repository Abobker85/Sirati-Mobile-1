import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Where a CV scan is, as the scan scene shows it.
enum ScanStage {
  /// The server is reading the CV: a beam passes over the paper and lights
  /// each line as it goes.
  reading,

  /// Scoring: keyword chips float off the lines toward the trailing side.
  scoring,

  /// Preparing the result: the beam fades and the outline of the score ring
  /// appears beside the paper.
  preparing,

  /// Done: the ring closes and carries a tick, handing over to the score on
  /// the result page.
  done,
}

/// The scan-waiting scene: a CV page being read by a light beam, telling the
/// story of the scan's real server stages. The beam runs only while the scan
/// runs and never longer than [maxScan]. Under reduced motion callers show
/// the plain checklist instead.
class ScanPaperScene extends StatefulWidget {
  const ScanPaperScene({super.key, required this.stage, this.slow = false});

  final ScanStage stage;

  /// After a long wait: the beam passes more slowly ([slowPass]), so a long
  /// scan feels calm rather than frantic.
  final bool slow;

  /// One pass of the beam over the paper.
  static const pass = Duration(milliseconds: 1600);

  /// One pass once the wait is long.
  static const slowPass = Duration(milliseconds: 2400);

  /// The beam stops after this even if the scan does not answer (the scan's
  /// own polling gives up at about this point).
  static const maxScan = Duration(seconds: 210);

  static const size = Size(150, 96);

  /// Key of the painted scene, for tests.
  static const paintKey = ValueKey('scan-paper-scene');

  @override
  State<ScanPaperScene> createState() => ScanPaperSceneState();
}

@visibleForTesting
class ScanPaperSceneState extends State<ScanPaperScene>
    with TickerProviderStateMixin {
  late final AnimationController _beam = AnimationController(
    vsync: this,
    duration: ScanPaperScene.pass,
  );

  /// Eases each stage's look in, so stages blend instead of jumping.
  late final AnimationController _stage = AnimationController(
    vsync: this,
    duration: MotionDurations.slow,
    value: 1,
  );
  ScanStage _from = ScanStage.reading;

  /// Whether the beam is sweeping, for tests.
  @visibleForTesting
  bool get scanning => _beam.isAnimating;

  /// One beam pass now, for tests.
  @visibleForTesting
  Duration? get passDuration => _beam.duration;

  /// Time since the scene appeared, to keep the [ScanPaperScene.maxScan] cap
  /// when the pace changes.
  final _since = Stopwatch()..start();

  @override
  void initState() {
    super.initState();
    _from = widget.stage;
    _runBeam();
  }

  void _runBeam() {
    if (widget.stage == ScanStage.done) {
      _beam.stop();
      return;
    }
    if (_beam.isAnimating) return;
    final pass = widget.slow ? ScanPaperScene.slowPass : ScanPaperScene.pass;
    final left = ScanPaperScene.maxScan - _since.elapsed;
    final passes = left.inMilliseconds ~/ pass.inMilliseconds;
    if (passes <= 0) {
      _beam.stop();
      return;
    }
    _beam.duration = pass;
    _beam.repeat(count: passes);
  }

  @override
  void didUpdateWidget(ScanPaperScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slow != widget.slow && _beam.isAnimating) {
      // New pace from the next pass on.
      _beam.stop();
      _runBeam();
    }
    if (oldWidget.stage == widget.stage) return;
    // Two stages in quick succession: blend on from whichever look was
    // mostly showing, instead of jumping back.
    _from = _stage.isAnimating && _stage.value < .5 ? _from : oldWidget.stage;
    _stage.forward(from: 0);
    _runBeam();
  }

  @override
  void dispose() {
    _beam.dispose();
    _stage.dispose();
    super.dispose();
  }

  /// How much of [stage]'s look is showing now, 0 → 1.
  double _weight(ScanStage stage) {
    final t = MotionCurves.standard.transform(_stage.value);
    final now = widget.stage == stage ? 1.0 : 0.0;
    final before = _from == stage ? 1.0 : 0.0;
    return before + (now - before) * t;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_beam, _stage]),
          builder: (context, _) => CustomPaint(
            key: ScanPaperScene.paintKey,
            size: ScanPaperScene.size,
            painter: ScanPaperPainter(
              beam: _beam.value,
              // After its time limit the beam is gone, not parked at the
              // bottom edge.
              beamOn: _beam.isAnimating,
              reading: _weight(ScanStage.reading),
              scoring: _weight(ScanStage.scoring),
              preparing: _weight(ScanStage.preparing),
              done: _weight(ScanStage.done),
              rtl: rtl,
              paper: c.surface,
              edge: c.borderStrong,
              line: c.border,
              ink: c.primaryInk,
              light: c.primary,
              chip: c.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the paper, the beam, lit lines, floating chips and the score ring
/// outline. Each stage's look is weighted, so stages cross-fade.
@visibleForTesting
class ScanPaperPainter extends CustomPainter {
  ScanPaperPainter({
    required this.beam,
    this.beamOn = true,
    required this.reading,
    required this.scoring,
    required this.preparing,
    required this.done,
    required this.rtl,
    required this.paper,
    required this.edge,
    required this.line,
    required this.ink,
    required this.light,
    required this.chip,
  });

  /// Beam position in the current pass, 0 (top) → 1 (bottom).
  final double beam;

  /// Whether the beam is running (it stops for good after its time limit).
  final bool beamOn;
  final double reading;
  final double scoring;
  final double preparing;
  final double done;
  final bool rtl;
  final Color paper;
  final Color edge;
  final Color line;
  final Color ink;
  final Color light;
  final Color chip;

  static const lines = 5;
  static const paperSize = Size(64, 82);

  /// The paper's rectangle in a scene of [size].
  static Rect paperRect(Size size) => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: paperSize.width,
        height: paperSize.height,
      );

  /// Where the score ring outline sits: beside the paper, trailing side.
  static Offset ringCenter(Size size, {required bool rtl}) {
    final p = paperRect(size);
    return Offset(rtl ? p.left - 4 : p.right + 4, p.bottom - 14);
  }

  /// The beam's height in a scene of [size], or null when it is not drawn.
  double? beamY(Size size) {
    if (!beamOn) return null;
    final strength = 1 - math.max(preparing, done);
    if (strength <= 0) return null;
    final p = paperRect(size).deflate(6);
    return p.top + p.height * beam;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = paperRect(size);
    final page = RRect.fromRectAndRadius(p, const Radius.circular(8));
    canvas
      ..drawRRect(page, Paint()..color = paper)
      ..drawRRect(
        page,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = edge,
      );

    final inner = p.deflate(10);
    final gap = inner.height / (lines - 1);
    const widths = [1.0, .75, .9, .6, .8];
    final y = beamY(size);
    for (var i = 0; i < lines; i++) {
      final ly = inner.top + gap * i;
      final w = inner.width * widths[i];
      final x0 = rtl ? inner.right - w : inner.left;
      // Reading: a line lights up as the beam crosses it.
      final lit = y == null
          ? 0.0
          : (1 - ((ly - y).abs() / (gap * .9))).clamp(0.0, 1.0) * reading;
      canvas.drawLine(
        Offset(x0, ly),
        Offset(x0 + w, ly),
        Paint()
          ..strokeWidth = i == 0 ? 4 : 3
          ..strokeCap = StrokeCap.round
          ..color = Color.lerp(i == 0 ? ink : line, ink, lit)!,
      );
    }

    if (y != null) {
      final strength = 1 - math.max(preparing, done);
      final band = Rect.fromLTRB(p.left + 2, y - 7, p.right - 2, y + 7);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              light.withValues(alpha: 0),
              light.withValues(alpha: .28 * strength),
              light.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
    }

    // Scoring: three keyword chips float off the lines to the trailing side.
    if (scoring > 0) {
      for (var k = 0; k < 3; k++) {
        final t = (beam + k / 3) % 1;
        final from = Offset(
          rtl ? inner.left : inner.right,
          inner.top + gap * (1 + k),
        );
        final drift = (rtl ? -1 : 1) * (8 + 34 * t);
        final c = from + Offset(drift, -10 * t);
        final alpha = scoring * math.sin(math.pi * t);
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 18, height: 8),
          const Radius.circular(4),
        );
        canvas
          ..drawRRect(r, Paint()..color = chip.withValues(alpha: alpha))
          ..drawRRect(
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = ink.withValues(alpha: alpha * .6),
          );
      }
    }

    // Preparing and done: the score ring outline, then closed with a tick.
    final ring = math.max(preparing, done);
    if (ring > 0) {
      final center = ringCenter(size, rtl: rtl);
      const r = 14.0;
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawCircle(
            center, r + 1.5, Paint()..color = paper.withValues(alpha: ring))
        ..drawCircle(center, r, base..color = line.withValues(alpha: ring));
      if (done > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          -math.pi / 2,
          2 * math.pi * done,
          false,
          base..color = ink,
        );
        if (done >= 1) {
          final tick = Path()
            ..moveTo(center.dx - 6, center.dy)
            ..lineTo(center.dx - 2, center.dy + 4)
            ..lineTo(center.dx + 6, center.dy - 4);
          canvas.drawPath(tick, base..color = ink);
        }
      }
    }
  }

  @override
  bool shouldRepaint(ScanPaperPainter old) =>
      old.beam != beam ||
      old.beamOn != beamOn ||
      old.reading != reading ||
      old.scoring != scoring ||
      old.preparing != preparing ||
      old.done != done ||
      old.rtl != rtl ||
      old.ink != ink;
}
