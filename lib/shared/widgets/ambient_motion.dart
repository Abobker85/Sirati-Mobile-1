import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Motion that plays by itself, without the user doing anything: a short
/// move, then a long rest, again and again.
///
/// Every ambient move:
/// - runs only on the screen in front: not on a hidden tab, a covered page,
///   nor under a sheet or dialog ([ModalRoute.isCurrent], [TickerMode]);
/// - takes turns: one move at a time app-wide, with [AmbientConductor.gap]
///   of stillness between moves, so a screen is mostly at rest;
/// - goes by priority: a move that points at the next step goes before
///   decoration ([AmbientPriority]);
/// - calms down: each rest is longer than the one before, and a loop stops
///   after [AmbientLoop.maxPlays] moves until the next session;
/// - draws no frames while it rests (the rest is a timer, not an animation);
/// - stops while the app is in the background, while a screen reader is on,
///   with the phone's reduce-motion setting, and when the user turns
///   "Decorative motion" off in Settings ([enabled]);
/// - is off in widget tests (the test setup turns [enabled] off), so "wait
///   until everything is still" keeps working there.
abstract final class AmbientMotion {
  /// The user's "Decorative motion" setting (on by default).
  static final enabled = ValueNotifier<bool>(true);

  /// False while the app is in the background.
  static final foreground = ValueNotifier<bool>(true);

  static const _prefsKey = 'ambient_motion.enabled';
  static AppLifecycleListener? _lifecycle;

  /// Loads the saved setting. Called once at app start.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      // Keep the default.
    }
  }

  /// Turns decorative motion on or off and remembers the choice.
  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, value);
    } catch (_) {
      // Applies for this session even if it cannot be saved.
    }
  }

  /// Follows the app's lifecycle (once).
  static void _watchLifecycle() {
    _lifecycle ??= AppLifecycleListener(
      onStateChange: (state) =>
          foreground.value = state == AppLifecycleState.resumed,
    );
  }

  /// Whether ambient motion may run in [context] now.
  static bool allowed(BuildContext context) {
    _watchLifecycle();
    final route = ModalRoute.of(context);
    return enabled.value &&
        foreground.value &&
        !MotionSettings.reduce(context) &&
        !(MediaQuery.maybeAccessibleNavigationOf(context) ?? false) &&
        TickerMode.valuesOf(context).enabled &&
        (route?.isCurrent ?? true);
  }
}

/// How much an ambient move matters, which decides who goes first when
/// several are waiting for a turn.
enum AmbientPriority {
  /// Decoration: a twinkle, a float, a shine, a glow.
  decorative,

  /// Something new is waiting (an unread notification, fresh content).
  news,

  /// Points at the user's next useful step.
  nextStep,
}

/// Hands out turns to ambient moves: one plays at a time, and after each one
/// the app stays still for at least [gap] before the next.
///
/// When several moves wait, the one with the highest [AmbientPriority] goes
/// next (first come, first served within a priority). So the move that
/// points at the next step is not stuck behind decoration; a low-priority
/// move may wait a long time, which is intended.
abstract final class AmbientConductor {
  static const gap = Duration(seconds: 4);

  static Object? _playing;
  static bool _quiet = false;
  static Timer? _quietTimer;
  static final _queue = <(Object, VoidCallback, AmbientPriority)>[];

  /// Whether a move is playing, for tests.
  @visibleForTesting
  static bool get busy => _playing != null;

  /// Asks for a turn; [start] runs when it is [owner]'s turn.
  static void request(
    Object owner,
    VoidCallback start, {
    AmbientPriority priority = AmbientPriority.decorative,
  }) {
    if (_playing == owner || _queue.any((e) => e.$1 == owner)) return;
    if (_playing == null && !_quiet) {
      _playing = owner;
      start();
    } else {
      _queue.add((owner, start, priority));
    }
  }

  /// [owner]'s move has ended (or it stopped): be still for [gap], then
  /// hand the next turn on.
  static void done(Object owner) {
    _queue.removeWhere((e) => e.$1 == owner);
    if (_playing != owner) return;
    _playing = null;
    _quiet = true;
    _quietTimer?.cancel();
    _quietTimer = Timer(gap, () {
      _quiet = false;
      _next();
    });
  }

  static void _next() {
    if (_playing != null || _quiet || _queue.isEmpty) return;
    // Highest priority first; the earliest request wins a tie.
    var pick = 0;
    for (var i = 1; i < _queue.length; i++) {
      if (_queue[i].$3.index > _queue[pick].$3.index) pick = i;
    }
    final (owner, start, _) = _queue.removeAt(pick);
    _playing = owner;
    start();
  }

  /// Back to the starting state, for tests.
  @visibleForTesting
  static void reset() {
    _playing = null;
    _quiet = false;
    _quietTimer?.cancel();
    _queue.clear();
  }
}

/// Plays a [active]-long move, rests for [rest], and repeats, starting after
/// [delay]. [builder] gets the move's progress `t`, 0 → 1, and 0 while
/// resting or not allowed (so the child is at rest).
///
/// A rest is always at least [restRatio] times the move, so motion stays
/// the exception on screen.
class AmbientLoop extends StatefulWidget {
  const AmbientLoop({
    super.key,
    required this.active,
    required this.rest,
    required this.builder,
    this.delay = Duration.zero,
    this.enabled = true,
    this.priority = AmbientPriority.decorative,
    this.child,
  });

  final Duration active;

  /// The rest after the first move. Each later rest is [decay] times the
  /// one before, so the loop is lively at first and calmer the longer the
  /// screen stays open. Read at each rest.
  final Duration rest;

  /// Who goes first when moves wait for a turn ([AmbientConductor]).
  final AmbientPriority priority;

  /// Read when the loop (re)starts.
  final Duration delay;

  /// Lets a caller switch this loop off (e.g. the bell when nothing is
  /// unread).
  final bool enabled;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  /// Minimum rest, as a multiple of the move.
  static const restRatio = 5;

  /// Each rest is this many times the one before.
  static const decay = 1.5;

  /// After this many moves the loop stays still until the app comes back
  /// from the background (a new session) or the loop is rebuilt.
  static const maxPlays = 6;

  /// The rest after move number [plays] (1 = the first move).
  static Duration restAfter(Duration rest, int plays) =>
      rest * math.pow(decay, math.max(0, plays - 1)).toDouble();

  @override
  State<AmbientLoop> createState() => AmbientLoopState();
}

@visibleForTesting
class AmbientLoopState extends State<AmbientLoop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: widget.active,
  );
  Timer? _wait;
  bool _allowed = false;
  int _plays = 0;

  /// How many moves have played this session, for tests.
  @visibleForTesting
  int get plays => _plays;

  /// Whether a move is playing right now, for tests.
  @visibleForTesting
  bool get moving => _move.isAnimating;

  /// Whether the loop is running (moving, waiting or resting), for tests.
  @visibleForTesting
  bool get running => _allowed;

  @override
  void initState() {
    super.initState();
    assert(
      widget.rest >= widget.active * AmbientLoop.restRatio,
      'An ambient rest must be at least ${AmbientLoop.restRatio}x its move '
      '(${widget.active} move, ${widget.rest} rest).',
    );
    AmbientMotion.enabled.addListener(_recheck);
    AmbientMotion.foreground.addListener(_onForeground);
  }

  /// Coming back from the background starts a new session: the loop is
  /// lively again.
  void _onForeground() {
    if (AmbientMotion.foreground.value) _plays = 0;
    _recheck();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recheck();
  }

  @override
  void didUpdateWidget(AmbientLoop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _move.duration = widget.active;
    if (oldWidget.enabled != widget.enabled) _recheck();
  }

  void _recheck() {
    if (!mounted) return;
    final allowed = widget.enabled && AmbientMotion.allowed(context);
    if (allowed == _allowed) return;
    _allowed = allowed;
    _wait?.cancel();
    _wait = null;
    if (allowed) {
      if (_plays < AmbientLoop.maxPlays) _schedule(widget.delay);
    } else {
      _move
        ..stop()
        ..value = 0;
      AmbientConductor.done(this);
    }
  }

  void _schedule(Duration after) {
    _wait?.cancel();
    _wait = Timer(after, () {
      _wait = null;
      if (!mounted || !_allowed) return;
      AmbientConductor.request(this, _play, priority: widget.priority);
    });
  }

  void _play() {
    if (!mounted || !_allowed) {
      AmbientConductor.done(this);
      return;
    }
    _plays++;
    _move.forward(from: 0).whenCompleteOrCancel(() {
      AmbientConductor.done(this);
      if (!mounted || !_allowed) return;
      _move.value = 0;
      if (_plays >= AmbientLoop.maxPlays) return;
      _schedule(AmbientLoop.restAfter(widget.rest, _plays));
    });
  }

  @override
  void dispose() {
    AmbientMotion.enabled.removeListener(_recheck);
    AmbientMotion.foreground.removeListener(_onForeground);
    _wait?.cancel();
    AmbientConductor.done(this);
    _move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _move,
        builder: (context, child) =>
            widget.builder(context, _move.isAnimating ? _move.value : 0, child),
        child: widget.child,
      );
}

/// Ready-made ambient moves for one widget.
enum AmbientKind {
  /// Bobs up and back down.
  float,

  /// Grows and turns a little, like a sparkle catching the light.
  twinkle,

  /// Swings like a bell, fading out.
  ring,

  /// Swells slightly and settles.
  pulse,

  /// Nudges toward the trailing edge, as if pointing the way.
  nudge,
}

/// Moves [child] by itself every [rest] (after [delay]), using [kind].
class AmbientMove extends StatelessWidget {
  const AmbientMove({
    super.key,
    required this.kind,
    required this.child,
    this.rest = const Duration(seconds: 10),
    this.delay = const Duration(seconds: 2),
    this.active,
    this.enabled = true,
    this.priority = AmbientPriority.decorative,
  });

  final AmbientKind kind;
  final AmbientPriority priority;
  final Widget child;
  final Duration rest;
  final Duration delay;
  final Duration? active;
  final bool enabled;

  static Duration defaultActive(AmbientKind kind) => switch (kind) {
        AmbientKind.float => const Duration(milliseconds: 1600),
        AmbientKind.twinkle => const Duration(milliseconds: 1200),
        AmbientKind.ring => const Duration(milliseconds: 900),
        AmbientKind.pulse => const Duration(milliseconds: 900),
        AmbientKind.nudge => const Duration(milliseconds: 900),
      };

  @override
  Widget build(BuildContext context) {
    // Its own layer: a moving piece never repaints the card around it.
    return RepaintBoundary(
      child: AmbientLoop(
        active: active ?? defaultActive(kind),
        rest: rest,
        delay: delay,
        enabled: enabled,
        priority: priority,
        child: child,
        builder: (context, t, child) {
          if (t == 0) return child!;
          final wave = math.sin(math.pi * t);
          return switch (kind) {
            AmbientKind.float => Transform.translate(
                offset: Offset(0, -3 * math.sin(2 * math.pi * t)),
                child: child,
              ),
            // About 10 degrees and 10%: a glint, not a spin.
            AmbientKind.twinkle => Transform.rotate(
                angle: .17 * wave,
                child: Transform.scale(scale: 1 + .1 * wave, child: child),
              ),
            AmbientKind.ring => Transform.rotate(
                angle: .3 * math.sin(4 * 2 * math.pi * t) * (1 - t),
                alignment: Alignment.topCenter,
                child: child,
              ),
            AmbientKind.pulse =>
              Transform.scale(scale: 1 + .05 * wave, child: child),
            AmbientKind.nudge => Transform.translate(
                offset: Offset(
                  (Directionality.of(context) == TextDirection.rtl ? -1 : 1) *
                      4 *
                      math.max(0.0, math.sin(2 * math.pi * t)) *
                      (1 - t),
                  0,
                ),
                child: child,
              ),
          };
        },
      ),
    );
  }
}

/// A band of light across [child] at progress [t] (0 = none), moving from
/// the leading edge to the trailing edge (right to left in Arabic).
class LightSweep extends StatelessWidget {
  const LightSweep({
    super.key,
    required this.t,
    required this.radius,
    required this.color,
    required this.child,
    this.strength = .38,
  });

  final double t;
  final double radius;
  final Color color;
  final double strength;
  final Widget child;

  /// Key of the light band, for tests.
  static const bandKey = ValueKey('light-sweep-band');

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      children: [
        // The card is drawn once; only the light over it repaints.
        RepaintBoundary(child: child),
        if (t > 0 && t < 1)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: ClipRRect(
                  key: bandKey,
                  borderRadius: BorderRadius.circular(radius),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_x(rtl) - .55, -1),
                        end: Alignment(_x(rtl) + .55, 1),
                        colors: [
                          color.withValues(alpha: 0),
                          color.withValues(alpha: strength),
                          color.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Band centre, from 1.6 past the leading edge to 1.6 past the trailing
  /// one, in Alignment units.
  double _x(bool rtl) => rtl ? 1.6 - 3.2 * t : -1.6 + 3.2 * t;
}

/// A [LightSweep] that passes over [child] by itself every [rest].
class AmbientShine extends StatelessWidget {
  const AmbientShine({
    super.key,
    required this.radius,
    required this.color,
    required this.child,
    this.rest = const Duration(seconds: 7),
    this.delay = const Duration(seconds: 6),
    this.strength = .38,
  });

  final double radius;
  final Color color;
  final Duration rest;
  final Duration delay;
  final double strength;
  final Widget child;

  static const pass = Duration(milliseconds: 1100);

  @override
  Widget build(BuildContext context) {
    return AmbientLoop(
      active: pass,
      rest: rest,
      delay: delay,
      child: child,
      builder: (context, t, child) => LightSweep(
        t: MotionCurves.standard.transform(t),
        radius: radius,
        color: color,
        strength: strength,
        child: child!,
      ),
    );
  }
}

/// Counts how many times the tab holding it has been opened, so content
/// inside can arrive again on every visit.
class TabVisitScope extends InheritedWidget {
  const TabVisitScope({super.key, required this.visit, required super.child});

  final int visit;

  /// The visit count of the enclosing tab, or null outside a tab.
  static int? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabVisitScope>()?.visit;

  @override
  bool updateShouldNotify(TabVisitScope oldWidget) => oldWidget.visit != visit;
}

/// After [idle] with no touch anywhere on screen, [child] pulses softly to
/// hint that it is the screen's next step. It hints at most [maxHints] times
/// while it is shown, and a touch always restarts the wait.
class IdleNudge extends StatefulWidget {
  const IdleNudge({
    super.key,
    required this.child,
    this.idle = const Duration(seconds: 6),
    this.maxHints = 1,
    this.activity,
  });

  final Widget child;
  final Duration idle;
  final int maxHints;

  /// Anything else that counts as the user being busy (e.g. a text
  /// controller of the screen's form).
  final Listenable? activity;

  /// The pulse.
  static const pulse = Duration(milliseconds: 700);

  @override
  State<IdleNudge> createState() => IdleNudgeState();
}

@visibleForTesting
class IdleNudgeState extends State<IdleNudge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: IdleNudge.pulse,
  );
  Timer? _wait;
  int _hints = 0;
  bool _allowed = false;

  /// Hints given so far, for tests.
  @visibleForTesting
  int get hints => _hints;

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    // Typing on the soft keyboard sends no pointer events: key presses and
    // focus moves count as activity too.
    HardwareKeyboard.instance.addHandler(_onKey);
    FocusManager.instance.addListener(_restart);
    widget.activity?.addListener(_onActivity);
    AmbientMotion.enabled.addListener(_recheck);
    AmbientMotion.foreground.addListener(_recheck);
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  /// Text typed into a field also restarts the wait (soft keyboards do not
  /// always send key events). Call from a field's onChanged, or pass
  /// [IdleNudge.activity].
  void _onActivity() => _restart();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recheck();
  }

  void _recheck() {
    if (!mounted) return;
    final allowed = AmbientMotion.allowed(context);
    if (allowed == _allowed) return;
    _allowed = allowed;
    if (allowed) {
      _restart();
    } else {
      _wait?.cancel();
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) _restart();
  }

  void _restart() {
    _wait?.cancel();
    if (!_allowed || _hints >= widget.maxHints) return;
    _wait = Timer(widget.idle, () {
      if (!mounted || !_allowed) return;
      _hints++;
      _pulse.forward(from: 0).whenCompleteOrCancel(() {
        if (mounted) _restart();
      });
    });
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    HardwareKeyboard.instance.removeHandler(_onKey);
    FocusManager.instance.removeListener(_restart);
    widget.activity?.removeListener(_onActivity);
    AmbientMotion.enabled.removeListener(_recheck);
    AmbientMotion.foreground.removeListener(_recheck);
    _wait?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _pulse,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: 1 + .05 * math.sin(math.pi * _pulse.value),
          child: child,
        ),
      );
}

/// Makes a brand header band breathe: every few seconds a soft, darker glow
/// drifts slowly across it, from the leading edge to the trailing one, and
/// fades. It only ever darkens the band, so white text on it keeps (or
/// gains) contrast.
class BreathingBand extends StatelessWidget {
  const BreathingBand({
    super.key,
    required this.deep,
    required this.child,
    this.delay = const Duration(seconds: 2),
  });

  /// The band's darkest colour; the glow is made of it.
  final Color deep;
  final Widget child;
  final Duration delay;

  static const drift = Duration(seconds: 3);
  static const rest = Duration(seconds: 15);

  /// Key of the glow, for tests.
  static const glowKey = ValueKey('breathing-band-glow');

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // Band and glow on separate layers: the glow never repaints the band's
    // text, icons or pattern.
    return Stack(
      children: [
        RepaintBoundary(child: child),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AmbientLoop(
                active: drift,
                rest: rest,
                delay: delay,
                builder: (context, t, _) {
                  if (t == 0) return const SizedBox.shrink();
                  final eased = Curves.easeInOut.transform(t);
                  final x = (rtl ? 1 - 2 * eased : -1 + 2 * eased) * 1.2;
                  return DecoratedBox(
                    key: glowKey,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(x, 0),
                        radius: 1.1,
                        colors: [
                          deep.withValues(alpha: .45 * math.sin(math.pi * t)),
                          deep.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
