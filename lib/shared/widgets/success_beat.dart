import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Brief celebration (haptic and optional visual).
///
/// Reduced motion: haptic only.
/// Full motion + [fullOverlay]: the "CV created" scene ([CvCreatedScene]) in
/// an overlay that closes itself when the scene ends, or at once on a tap.
/// The haptic lands with the check stamp, and screen readers hear that the
/// CV was saved.
class SuccessBeat {
  SuccessBeat._();

  /// Length of the full "CV created" scene.
  static const sceneDuration = MotionDurations.celebration;

  /// Length of the scene once the user has seen it [fullPlays] times: the
  /// same moment, quicker, so it never becomes a wait.
  static const quickSceneDuration = MotionDurations.celebrationQuick;

  /// How many times the full scene plays before it switches to the quick one.
  static const fullPlays = 3;

  /// Where in the scene the stamp lands and the haptic fires.
  static const stampAt = .55;

  static const _playsKey = 'success_beat.plays';

  /// Haptic always; visual full-screen overlay when [fullOverlay] and motion OK.
  ///
  /// Returns as soon as the haptic fires when [fullOverlay] is false (or reduce
  /// motion), so score-bar completion stays snappy. Otherwise completes when
  /// the overlay has gone, however it went (ended, tapped or pushed aside).
  static Future<void> celebrate(
    BuildContext context, {
    bool fullOverlay = false,
  }) async {
    if (MotionSettings.reduce(context) || !fullOverlay) {
      await HapticFeedback.mediumImpact();
      return;
    }

    final duration = await _nextDuration();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final done = Completer<void>();
    final dialog = showGeneralDialog<void>(
      context: context,
      // A tap anywhere skips the rest of the scene.
      barrierDismissible: true,
      // The success itself is announced once below; the barrier is only
      // read as the way to dismiss.
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.18),
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SuccessBeatOverlay(
          duration: duration,
          announcement: l10n.cvSaved,
          onGone: () {
            if (!done.isCompleted) done.complete();
          },
        );
      },
    );
    unawaited(dialog.whenComplete(() {
      if (!done.isCompleted) done.complete();
    }));
    await done.future;
  }

  /// Full celebration used after CV generation (haptic + overlay).
  static Future<void> play(BuildContext context) =>
      celebrate(context, fullOverlay: true);

  /// The scene length for this play, counting plays on this install.
  static Future<Duration> _nextDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plays = prefs.getInt(_playsKey) ?? 0;
      await prefs.setInt(_playsKey, plays + 1);
      return plays < fullPlays ? sceneDuration : quickSceneDuration;
    } catch (_) {
      // No storage (tests, a broken prefs file): play the full scene.
      return sceneDuration;
    }
  }
}

class _SuccessBeatOverlay extends StatefulWidget {
  const _SuccessBeatOverlay({
    required this.duration,
    required this.announcement,
    required this.onGone,
  });

  final Duration duration;
  final String announcement;
  final VoidCallback onGone;

  @override
  State<_SuccessBeatOverlay> createState() => _SuccessBeatOverlayState();
}

class _SuccessBeatOverlayState extends State<_SuccessBeatOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  ModalRoute<void>? _route;
  bool _stamped = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTick);
    _controller.forward().whenCompleteOrCancel(_close);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read every time: this also tells us when a page covers the overlay.
    final route = ModalRoute.of(context);
    if (_route != null) {
      // Covered by another page, the scene would sit paused out of sight:
      // end it now.
      if (route != null && !route.isCurrent) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      }
      return;
    }
    _route = route as ModalRoute<void>?;
    unawaited(SemanticsService.sendAnnouncement(
      View.of(context),
      widget.announcement,
      Directionality.of(context),
    ));
  }

  void _onTick() {
    if (_stamped || _controller.value < SuccessBeat.stampAt) return;
    _stamped = true;
    // The thud comes with the stamp, not before the paper appears.
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Removes this overlay only, even if another page was pushed on top of it
  /// while the scene played.
  void _close() {
    final route = _route;
    if (!mounted || route == null || !route.isActive) return;
    final navigator = route.navigator!;
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.onGone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: ExcludeSemantics(
          child: SizedBox.square(
            dimension: 260,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) =>
                  CvCreatedScene(progress: _controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "CV created" scene at [progress] (0 → 1):
///
/// - 0.00–0.30: a paper sheet pops up.
/// - 0.15–0.55: its lines write themselves, in reading direction.
/// - 0.45–0.70: a green check stamps onto its corner with a bounce.
/// - 0.50–1.00: confetti bursts out and falls; the scene fades at the end.
@visibleForTesting
class CvCreatedScene extends StatelessWidget {
  const CvCreatedScene({super.key, required this.progress});

  final double progress;

  static const _paper = Interval(0, .3, curve: MotionCurves.pop);
  static const _lines = Interval(.15, .55, curve: MotionCurves.standard);
  static const _stamp = Interval(.45, .7, curve: MotionCurves.pop);
  static const _burst = Interval(.5, 1);
  static const _fadeOut = Interval(.85, 1, curve: Curves.easeIn);

  /// How many lines the paper has.
  static const lineCount = 4;

  /// Key of the check stamp, for tests.
  static const stampKey = ValueKey('cv-created-stamp');

  /// Key of line [i] on the paper, for tests.
  static ValueKey<String> lineKey(int i) => ValueKey('cv-created-line-$i');

  /// Key of the confetti layer, for tests.
  static const confettiKey = ValueKey('cv-created-confetti');

  /// How much of line [i] is written at [progress], 0 → 1. The lines are
  /// written one after another.
  static double lineWritten(double progress, int i) =>
      (_lines.transform(progress) * lineCount - i).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final paper = _paper.transform(progress);
    final stamp = _stamp.transform(progress);
    final burst = _burst.transform(progress);
    final fade = 1 - _fadeOut.transform(progress);
    const widths = [.9, .7, .8, .5];

    return Opacity(
      opacity: fade.clamp(0.0, 1.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: confettiKey,
                painter: _ConfettiPainter(
                  progress: burst,
                  colors: [c.primary, c.amber, c.tertiary, c.success, c.info],
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: .6 + .4 * paper,
            child: Opacity(
              opacity: (paper * 2).clamp(0.0, 1.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 120,
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                      boxShadow: c.glassShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < lineCount; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            // Lines grow from the start edge: right in
                            // Arabic, left in English.
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              // Scaled, not resized: drawing a line in is
                              // paint-only, no layout every frame.
                              child: FractionallySizedBox(
                                widthFactor: widths[i],
                                child: Transform(
                                  alignment: AlignmentDirectional.centerStart,
                                  transform: Matrix4.diagonal3Values(
                                    lineWritten(progress, i),
                                    1,
                                    1,
                                  ),
                                  child: Container(
                                    key: lineKey(i),
                                    height: i == 0 ? 6 : 4,
                                    decoration: BoxDecoration(
                                      color: i == 0 ? c.primaryInk : c.border,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    end: -18,
                    bottom: -14,
                    child: Opacity(
                      opacity: stamp > 0 ? 1 : 0,
                      child: Transform.rotate(
                        angle: -.2 * (1 - stamp),
                        // Drops from big onto the paper, overshooting a
                        // little as it lands.
                        child: Transform.scale(
                          key: stampKey,
                          scale: 1.8 - .8 * stamp,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: c.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.surface, width: 3),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 30,
                              color: c.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A burst of small paper bits that fly out from the centre, tumble and fall.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  static const _count = 28;

  /// The same pieces every time: a fixed seed keeps the scene stable.
  static final _pieces = () {
    final random = math.Random(7);
    return [
      for (var i = 0; i < _count; i++)
        (
          angle: (i / _count) * 2 * math.pi + random.nextDouble() * .3,
          // Flight plus fall stays inside the scene's box (half 130).
          speed: 55 + random.nextDouble() * 40,
          spin: (random.nextDouble() - .5) * 12,
          size: 5 + random.nextDouble() * 4,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final out = Curves.easeOutCubic.transform(progress);
    final fall = 35 * progress * progress;
    final paint = Paint();
    for (final (i, p) in _pieces.indexed) {
      final position = center +
          Offset(math.cos(p.angle), math.sin(p.angle)) * p.speed * out +
          Offset(0, fall);
      paint.color = colors[i % colors.length].withValues(alpha: 1 - progress);
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(p.spin * progress)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * .55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
