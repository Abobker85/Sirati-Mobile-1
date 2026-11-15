import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// The round mark at the top of the purchase result.
///
/// When Premium is confirmed it plays "Premium unlocked" once:
///
/// - 0.00–0.35: the lock opens (its shackle lifts).
/// - 0.35–0.60: the lock gives way and the Premium crown stamps in, on a
///   warm tint, with one firm haptic as it lands.
/// - 0.50–1.00: a ring of sparkles flies out and fades (no confetti: that is
///   for "CV created").
///
/// The first [fullPlays] times it plays at full length, then quicker. While
/// the purchase still waits for the server it shows an hourglass that swings
/// once, and no celebration. Reduced motion shows the final mark.
class PremiumUnlockedMark extends StatefulWidget {
  const PremiumUnlockedMark({super.key, required this.confirmed});

  /// Premium is active on the server (not just paid at the store).
  final bool confirmed;

  static const size = 88.0;

  /// The mark's box, with room for the sparkles; the same in every state.
  static const outer = size + 48;

  /// Full scene, the first few times.
  static const duration = Duration(milliseconds: 1400);

  /// Once the user has seen it [fullPlays] times (restores, re-subscribes).
  static const quickDuration = Duration(milliseconds: 800);
  static const fullPlays = 1;

  /// Where in the scene the crown lands and the haptic fires.
  static const stampAt = .5;

  /// Sparkles in the ring.
  static const sparkles = 8;

  static const _playsKey = 'premium_unlocked.plays';

  /// Key of the painted sparkles, for tests.
  static const sparklesKey = ValueKey('premium-unlocked-sparkles');

  @override
  State<PremiumUnlockedMark> createState() => PremiumUnlockedMarkState();
}

@visibleForTesting
class PremiumUnlockedMarkState extends State<PremiumUnlockedMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scene = AnimationController(
    vsync: this,
    duration: PremiumUnlockedMark.duration,
  );
  bool _stamped = false;
  bool _started = false;

  /// Scene progress, for tests.
  @visibleForTesting
  double get progress => _scene.value;

  @override
  void initState() {
    super.initState();
    _scene.addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.confirmed) unawaited(_play());
  }

  @override
  void didUpdateWidget(PremiumUnlockedMark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.confirmed && !oldWidget.confirmed) unawaited(_play());
  }

  Future<void> _play() async {
    if (MotionSettings.reduce(context)) {
      // Counted as stamped first, so jumping to the end buzzes only once.
      _stamped = true;
      _scene.value = 1;
      unawaited(HapticFeedback.mediumImpact());
      return;
    }
    _stamped = false;
    _scene.duration = await _nextDuration();
    if (!mounted) return;
    unawaited(_scene.forward(from: 0));
  }

  static Future<Duration> _nextDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plays = prefs.getInt(PremiumUnlockedMark._playsKey) ?? 0;
      await prefs.setInt(PremiumUnlockedMark._playsKey, plays + 1);
      return plays < PremiumUnlockedMark.fullPlays
          ? PremiumUnlockedMark.duration
          : PremiumUnlockedMark.quickDuration;
    } catch (_) {
      return PremiumUnlockedMark.duration;
    }
  }

  void _onTick() {
    if (_stamped || _scene.value < PremiumUnlockedMark.stampAt) return;
    _stamped = true;
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  void dispose() {
    _scene.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    if (!widget.confirmed) {
      // Paid, waiting for the server: calm, no celebration.
      // Same box as the celebration, so nothing below jumps when the
      // confirmation arrives.
      return ExcludeSemantics(
        child: SizedBox.square(
          dimension: PremiumUnlockedMark.outer,
          child: Center(
            child: _Disc(
              color: c.primaryLight,
              child: LivelyIcon(
                Icons.hourglass_top_rounded,
                size: 48,
                color: c.primaryInk,
                life: IconLife.ring,
                plays: 1,
              ),
            ),
          ),
        ),
      );
    }
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _scene,
        builder: (context, _) {
          final t = _scene.value;
          final open =
              const Interval(0, .35, curve: MotionCurves.standard).transform(t);
          final swap = const Interval(.35, .6).transform(t);
          final stamp =
              const Interval(.35, .6, curve: MotionCurves.pop).transform(t);
          final burst = const Interval(.5, 1).transform(t);
          final tint = Color.lerp(c.primaryLight, c.amberLight, swap)!;
          final unlocked = swap >= 1;
          return SizedBox.square(
            dimension: PremiumUnlockedMark.outer,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (burst > 0 && burst < 1)
                  CustomPaint(
                    key: PremiumUnlockedMark.sparklesKey,
                    size: const Size.square(PremiumUnlockedMark.outer),
                    painter: _SparkleRing(
                      progress: burst,
                      colors: [c.amber, c.amberAccent, c.primary],
                    ),
                  ),
                _Disc(
                  color: tint,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!unlocked)
                        Opacity(
                          opacity: 1 - swap,
                          child: Transform.translate(
                            // The shackle lifts as it opens.
                            offset: Offset(0, -4 * open),
                            child: Icon(
                              open < .5
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 48,
                              color: c.primaryInk,
                            ),
                          ),
                        ),
                      if (swap > 0)
                        Opacity(
                          opacity: swap.clamp(0.0, 1.0),
                          child: Transform.rotate(
                            angle: -.2 * (1 - stamp),
                            child: Transform.scale(
                              // Drops from big onto the disc.
                              scale: 1.8 - .8 * stamp,
                              child: Icon(
                                Icons.workspace_premium_rounded,
                                size: 48,
                                color: c.onWarningContainer,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: PremiumUnlockedMark.size,
      height: PremiumUnlockedMark.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }
}

/// Small four-point sparkles flying out from the disc's edge and fading.
class _SparkleRing extends CustomPainter {
  _SparkleRing({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final out = Curves.easeOutCubic.transform(progress);
    const from = PremiumUnlockedMark.size / 2;
    final reach = from + 20 * out;
    const n = PremiumUnlockedMark.sparkles;
    for (var i = 0; i < n; i++) {
      final angle = -math.pi / 2 + 2 * math.pi * i / n;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * reach;
      final r = 5 * (1 - progress) + 1;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: 1 - progress);
      final star = Path()
        ..moveTo(p.dx, p.dy - r)
        ..lineTo(p.dx + r * .3, p.dy - r * .3)
        ..lineTo(p.dx + r, p.dy)
        ..lineTo(p.dx + r * .3, p.dy + r * .3)
        ..lineTo(p.dx, p.dy + r)
        ..lineTo(p.dx - r * .3, p.dy + r * .3)
        ..lineTo(p.dx - r, p.dy)
        ..lineTo(p.dx - r * .3, p.dy - r * .3)
        ..close();
      canvas.drawPath(star, paint);
    }
  }

  @override
  bool shouldRepaint(_SparkleRing old) => old.progress != progress;
}
