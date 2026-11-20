import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Where a CV generation job is, as [CvDraftingScene] shows it.
enum DraftStage {
  /// Queued: the miniature page awaits a worker with a gentle header pulse.
  queued,

  /// Working: a drafting cursor sweeps across lines, sketching CV sections.
  working,

  /// Finalizing: lines are complete and a finish badge outline appears.
  finalizing,

  /// Done: the badge closes and draws a crisp checkmark.
  done,
}

/// Companion to [ScanPaperScene] for AI CV generation: a miniature CV page
/// sketching sections across [DraftStage]s. Bounded to [maxDraft] and gated
/// by [TickerMode] and [MotionSettings.reduce].
class CvDraftingScene extends StatefulWidget {
  const CvDraftingScene({
    super.key,
    required this.stage,
    this.slow = false,
  });

  final DraftStage stage;

  /// Slows the drafting pass after a long wait so the scene stays calm.
  final bool slow;

  static const pass = Duration(milliseconds: 1600);
  static const slowPass = Duration(milliseconds: 2400);
  static const maxDraft = Duration(seconds: 210);
  static const size = Size(150, 96);
  static const paintKey = ValueKey('cv-drafting-scene');

  @override
  State<CvDraftingScene> createState() => CvDraftingSceneState();
}

@visibleForTesting
class CvDraftingSceneState extends State<CvDraftingScene>
    with TickerProviderStateMixin {
  late final AnimationController _pen = AnimationController(
    vsync: this,
    duration: CvDraftingScene.pass,
  );
  late final AnimationController _stage = AnimationController(
    vsync: this,
    duration: MotionDurations.slow,
    value: 1,
  );
  DraftStage _from = DraftStage.queued;
  final _since = Stopwatch()..start();

  @visibleForTesting
  bool get drafting => _pen.isAnimating;

  @visibleForTesting
  Duration? get passDuration => _pen.duration;

  @override
  void initState() {
    super.initState();
    _from = widget.stage;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoop();
  }

  void _syncLoop() {
    final reduce = MotionSettings.reduce(context);
    final tickersOn = TickerMode.valuesOf(context).enabled;
    if (reduce || !tickersOn || widget.stage == DraftStage.done) {
      _pen.stop();
      if (reduce) {
        _pen.value = 1;
        _stage.value = 1;
      }
      return;
    }
    if (_pen.isAnimating) return;
    final pass = widget.slow ? CvDraftingScene.slowPass : CvDraftingScene.pass;
    final left = CvDraftingScene.maxDraft - _since.elapsed;
    final passes = left.inMilliseconds ~/ pass.inMilliseconds;
    if (passes <= 0) {
      _pen.stop();
      return;
    }
    _pen.duration = pass;
    _pen.repeat(count: passes);
  }

  @override
  void didUpdateWidget(CvDraftingScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slow != widget.slow && _pen.isAnimating) {
      _pen.stop();
      _syncLoop();
    }
    if (oldWidget.stage == widget.stage) return;
    _from = _stage.isAnimating && _stage.value < .5 ? _from : oldWidget.stage;
    if (MotionSettings.reduce(context)) {
      _stage.value = 1;
    } else {
      _stage.forward(from: 0);
    }
    _syncLoop();
  }

  @override
  void dispose() {
    _pen.dispose();
    _stage.dispose();
    super.dispose();
  }

  double _weight(DraftStage stage) {
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
          animation: Listenable.merge([_pen, _stage]),
          builder: (context, _) => CustomPaint(
            key: CvDraftingScene.paintKey,
            size: CvDraftingScene.size,
            painter: CvDraftingPainter(
              pen: _pen.value,
              penActive: _pen.isAnimating,
              queued: _weight(DraftStage.queued),
              working: _weight(DraftStage.working),
              finalizing: _weight(DraftStage.finalizing),
              done: _weight(DraftStage.done),
              rtl: rtl,
              paper: c.surface,
              edge: c.borderStrong,
              line: c.border,
              ink: c.primaryInk,
              accent: c.primary,
              chip: c.primaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the miniature CV page, drafting cursor, section lines, and finish badge.
@visibleForTesting
class CvDraftingPainter extends CustomPainter {
  CvDraftingPainter({
    required this.pen,
    this.penActive = true,
    required this.queued,
    required this.working,
    required this.finalizing,
    required this.done,
    required this.rtl,
    required this.paper,
    required this.edge,
    required this.line,
    required this.ink,
    required this.accent,
    required this.chip,
  });

  final double pen;
  final bool penActive;
  final double queued;
  final double working;
  final double finalizing;
  final double done;
  final bool rtl;
  final Color paper;
  final Color edge;
  final Color line;
  final Color ink;
  final Color accent;
  final Color chip;

  static const lines = 5;
  static const paperSize = Size(64, 82);

  static Rect paperRect(Size size) => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: paperSize.width,
        height: paperSize.height,
      );

  static Offset badgeCenter(Size size, {required bool rtl}) {
    final p = paperRect(size);
    return Offset(rtl ? p.left - 4 : p.right + 4, p.bottom - 14);
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
    const widths = [.55, .95, .75, .9, .65];

    // Header pill pulses subtly while queued; becomes solid once working+.
    final headerAlpha = queued > 0 && penActive
        ? 0.45 + 0.55 * (0.5 + 0.5 * math.sin(2 * math.pi * pen))
        : 1.0;

    for (var i = 0; i < lines; i++) {
      final ly = inner.top + gap * i;
      final fullW = inner.width * widths[i];
      final startX = rtl ? inner.right : inner.left;
      final dir = rtl ? -1.0 : 1.0;

      // Placeholder track under each CV section line.
      canvas.drawLine(
        Offset(startX, ly),
        Offset(startX + dir * fullW, ly),
        Paint()
          ..strokeWidth = i == 0 ? 4.5 : 3
          ..strokeCap = StrokeCap.round
          ..color = i == 0
              ? ink.withValues(alpha: 0.25 * headerAlpha)
              : line,
      );

      // Sketch fill during working, full during finalizing/done.
      double fillShare = 0;
      if (finalizing > 0 || done > 0) {
        fillShare = math.max(finalizing, done);
      }
      if (working > 0) {
        final wave = (pen * lines - i).clamp(0.0, 1.0);
        fillShare = math.max(fillShare, wave * working);
      }
      if (i == 0 && queued > 0) {
        fillShare = math.max(fillShare, queued * 0.4);
      }

      if (fillShare > 0) {
        final activeEnd = Offset(startX + dir * fullW * fillShare, ly);
        canvas.drawLine(
          Offset(startX, ly),
          activeEnd,
          Paint()
            ..strokeWidth = i == 0 ? 4.5 : 3
            ..strokeCap = StrokeCap.round
            ..color = i == 0 ? ink : Color.lerp(line, ink, 0.72)!,
        );

        // Glowing pen nib at the active tip while sketching.
        if (working > 0 && penActive && fillShare > 0 && fillShare < 1) {
          canvas
            ..drawCircle(
              activeEnd,
              4.5,
              Paint()..color = accent.withValues(alpha: 0.28 * working),
            )
            ..drawCircle(
              activeEnd,
              2.2,
              Paint()..color = ink.withValues(alpha: working),
            );
        }
      }
    }

    // Trailing-side finish badge during finalizing & done.
    final badge = math.max(finalizing, done);
    if (badge > 0) {
      final center = badgeCenter(size, rtl: rtl);
      const r = 13.0;
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawCircle(
          center,
          r + 1.5,
          Paint()..color = paper.withValues(alpha: badge),
        )
        ..drawCircle(
          center,
          r,
          base..color = line.withValues(alpha: badge),
        );
      if (done > 0) {
        canvas.drawCircle(
          center,
          r - 1.5,
          Paint()..color = chip.withValues(alpha: done),
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          -math.pi / 2,
          2 * math.pi * done,
          false,
          base..color = ink,
        );
        if (done >= 1) {
          final tick = Path()
            ..moveTo(center.dx - 5.5, center.dy)
            ..lineTo(center.dx - 1.5, center.dy + 4)
            ..lineTo(center.dx + 5.5, center.dy - 4);
          canvas.drawPath(tick, base..color = ink);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CvDraftingPainter old) =>
      old.pen != pen ||
      old.penActive != penActive ||
      old.queued != queued ||
      old.working != working ||
      old.finalizing != finalizing ||
      old.done != done ||
      old.rtl != rtl ||
      old.ink != ink;
}
