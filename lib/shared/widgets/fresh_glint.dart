import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';

/// Which items the user has already been shown, so "new" means new since
/// they last looked. Kept on the device; ids are like `job:123`.
///
/// The very first session only records what is there: nothing is "new" to
/// someone who has never seen the app before.
abstract final class FreshSeen {
  static const _key = 'fresh_seen.ids';

  /// The oldest ids are dropped past this many.
  static const maxIds = 300;

  static List<String>? _ids;
  static bool _firstSession = false;
  static Future<void>? _loading;

  /// Loads the seen ids once.
  static Future<void> ensureLoaded() => _loading ??= _load();

  static Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_key);
      _firstSession = saved == null;
      _ids = [...?saved];
    } catch (_) {
      // Without storage nothing is ever "new", which is the quiet choice.
      _firstSession = true;
      _ids = [];
    }
  }

  /// Whether [id] is new to the user (only once loaded).
  static bool isNew(String id) =>
      _ids != null && !_firstSession && !_ids!.contains(id);

  /// Remembers that [id] has been shown.
  static void markSeen(String id) {
    final ids = _ids;
    if (ids == null || ids.contains(id)) return;
    ids.add(id);
    if (ids.length > maxIds) ids.removeRange(0, ids.length - maxIds);
    final snapshot = List<String>.of(ids);
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_key, snapshot);
      } catch (_) {
        // It may glint once more next time; harmless.
      }
    }());
  }

  /// Back to "not loaded", for tests.
  @visibleForTesting
  static void reset() {
    _ids = null;
    _firstSession = false;
    _loading = null;
  }
}

/// Marks [child] as new since the user last looked: once, a soft light runs
/// around its border (never over its text), and then it is remembered as
/// seen and never glints again.
///
/// It is an ambient move: it takes its turn through [AmbientConductor] as
/// news, and follows every ambient rule (Settings switch, reduce motion,
/// screen readers, sheets, background).
class FreshGlint extends StatefulWidget {
  const FreshGlint({
    super.key,
    required this.id,
    required this.child,
    this.radius = 16,
  });

  /// Stable id of the item, e.g. `job:123`.
  final String id;
  final Widget child;

  /// Corner radius of [child]'s border, which the light follows.
  final double radius;

  /// One trip of the light around the border.
  static const duration = Duration(milliseconds: 1400);

  /// Key of the light, for tests.
  static const glowKey = ValueKey('fresh-glint');

  @override
  State<FreshGlint> createState() => FreshGlintState();
}

@visibleForTesting
class FreshGlintState extends State<FreshGlint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: FreshGlint.duration);
  bool _requested = false;

  /// Whether the light is running, for tests.
  @visibleForTesting
  bool get glowing => _c.isAnimating;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    unawaited(FreshSeen.ensureLoaded().then((_) => _decide()));
  }

  void _decide() {
    if (!mounted || _requested) return;
    if (!FreshSeen.isNew(widget.id)) {
      // Already seen, or the first session: just remember it.
      FreshSeen.markSeen(widget.id);
      return;
    }
    // Not allowed now (reduced motion, switch off…): it stays new, and
    // glints the next time it is allowed.
    if (!AmbientMotion.allowed(context)) return;
    _requested = true;
    AmbientConductor.request(this, _play, priority: AmbientPriority.news);
  }

  void _play() {
    if (!mounted) {
      AmbientConductor.done(this);
      return;
    }
    _c.forward(from: 0).whenCompleteOrCancel(() {
      AmbientConductor.done(this);
      FreshSeen.markSeen(widget.id);
    });
  }

  @override
  void dispose() {
    AmbientConductor.done(this);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.sirati.primary;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => _c.isAnimating
                    ? CustomPaint(
                        key: FreshGlint.glowKey,
                        painter: _BorderGlintPainter(
                          t: _c.value,
                          radius: widget.radius,
                          color: color,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A short bright arc travelling once around a rounded border.
class _BorderGlintPainter extends CustomPainter {
  _BorderGlintPainter({
    required this.t,
    required this.radius,
    required this.color,
  });

  final double t;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(1),
      Radius.circular(radius),
    );
    // Fades in and out over the trip.
    final strength = math.sin(math.pi * t);
    final start = -math.pi / 2 + 2 * math.pi * t;
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: 0,
          endAngle: 2 * math.pi,
          transform: GradientRotation(start),
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: .9 * strength),
            color.withValues(alpha: 0),
            color.withValues(alpha: 0),
          ],
          stops: const [0, .08, .16, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BorderGlintPainter old) =>
      old.t != t || old.radius != radius || old.color != color;
}
