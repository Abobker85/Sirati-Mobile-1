import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Tells the [LivelyIcon]s inside a card, row or button that it is being
/// pressed, so they squish and bounce back with it.
class IconPressScope extends InheritedNotifier<ValueNotifier<bool>> {
  const IconPressScope({
    super.key,
    required ValueNotifier<bool> pressed,
    required super.child,
  }) : super(notifier: pressed);

  /// The pressed state of the nearest pressable ancestor, if any.
  static ValueListenable<bool>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IconPressScope>()?.notifier;
}

/// A short move an icon makes on its own when it appears (or when its
/// [LivelyIcon.trigger] changes), played [LivelyIcon.plays] times and then
/// still. Nothing loops forever.
enum IconLife {
  /// Only reacts to presses.
  none,

  /// Bobs gently up and down.
  float,

  /// Rings like a bell: a quick swing that fades out.
  ring,

  /// Grows and turns a little, like a sparkle catching the light.
  twinkle,

  /// Nudges toward the trailing edge, as if pointing the way.
  nudge,
}

/// An [Icon] that feels alive: it squishes while its card is pressed and
/// springs back with a small bounce, and it can make a short [life] move when
/// it appears. With reduced motion it is a plain, still icon.
class LivelyIcon extends StatefulWidget {
  const LivelyIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.life = IconLife.none,
    this.plays = 2,
    this.trigger,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final IconLife life;

  /// How many times [life] plays each time it starts.
  final int plays;

  /// When this value changes, [life] plays again (e.g. the unread count).
  final Object? trigger;

  /// Clears the shared turns, so tests do not depend on each other's order.
  @visibleForTesting
  static void debugResetTurns() => _LifeBudget.reset();

  /// How long a queued move may wait for its turn before it is dropped.
  static const maxWait = _LifeBudget.maxWait;

  /// How small the icon gets while pressed.
  static const pressedScale = .82;

  /// One play of [life], including the short rest before it moves.
  static const lifeDuration = Duration(milliseconds: 1500);

  @override
  State<LivelyIcon> createState() => LivelyIconState();
}

@visibleForTesting
class LivelyIconState extends State<LivelyIcon> with TickerProviderStateMixin {
  /// 0 at rest, 1 fully pressed; may swing below 0 on release (the bounce).
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _life = AnimationController(
    vsync: this,
    duration: LivelyIcon.lifeDuration,
  )..addStatusListener(_onLifeStatus);

  ValueListenable<bool>? _scope;
  int _played = 0;

  /// [LivelyIcon.life] should play as soon as this icon may move.
  bool _pending = false;

  /// Whether this icon's subtree is visible and animating (an inactive tab
  /// is not).
  bool _tickersOn = true;

  /// Whether a move or a press is animating right now.
  @visibleForTesting
  bool get isMoving => _life.isAnimating || _press.isAnimating;

  /// Whether this icon is waiting for its turn to move.
  @visibleForTesting
  bool get isWaiting => _pending || _LifeBudget.isWaiting(this);

  bool get _reduce => MotionSettings.reduce(context);

  @override
  void initState() {
    super.initState();
    // Create both controllers now, never lazily in dispose.
    _press.value = 0;
    _life.value = 0;
    _pending = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = IconPressScope.maybeOf(context);
    if (scope != _scope) {
      _scope?.removeListener(_onPress);
      _scope = scope?..addListener(_onPress);
    }
    final on = TickerMode.valuesOf(context).enabled;
    if (on != _tickersOn) {
      _tickersOn = on;
      // Hidden mid-move: stop, free the turn and play again when shown.
      if (!on && _life.isAnimating) {
        _life.value = 0;
        _LifeBudget.release(this);
        _pending = true;
      }
    }
    _tryStart();
  }

  @override
  void didUpdateWidget(LivelyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger ||
        oldWidget.life != widget.life ||
        oldWidget.plays != widget.plays) {
      _life.value = 0;
      _LifeBudget.release(this);
      _pending = true;
      _tryStart();
    }
  }

  /// Plays [LivelyIcon.life] when it is due, visible and it is this icon's
  /// turn: only a couple of icons move at once, so a screen full of them
  /// takes turns instead of all moving together.
  void _tryStart() {
    if (!_pending || !_tickersOn) return;
    if (widget.life == IconLife.none || widget.plays <= 0 || _reduce) {
      _pending = false;
      return;
    }
    _pending = false;
    _played = 0;
    if (_LifeBudget.request(this)) _begin();
  }

  /// Called by [_LifeBudget] when this icon's turn comes.
  void _begin() {
    if (!mounted) {
      _LifeBudget.release(this);
      return;
    }
    if (!_tickersOn) {
      // Hidden before its turn came: give the turn back, play when shown.
      _LifeBudget.release(this);
      _pending = true;
      return;
    }
    _life.forward(from: 0);
  }

  void _onLifeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _played++;
    if (_played < widget.plays && !_reduce) {
      _life.forward(from: 0);
    } else {
      _life.value = 0;
      _LifeBudget.release(this);
    }
  }

  /// How fast the icon squishes when pressed.
  static const pressIn = Duration(milliseconds: 90);

  /// Starting speed of the release spring, toward rest and past it.
  static const releaseKick = -12.0;

  /// Press-release spring: under-damped, so the icon swings a few percent
  /// past its size and settles.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 700,
    ratio: .4,
  );

  /// Stop once the swing is too small to see, and land exactly at rest.
  static const _springTolerance = Tolerance(distance: .01, velocity: .5);

  void _onPress() {
    if (_reduce) return;
    if (_scope!.value) {
      // Quick enough that even a fast tap squishes most of the way.
      _press.animateTo(
        1,
        duration: pressIn,
        curve: MotionCurves.standard,
      );
    } else {
      // Spring back past rest and settle: the bounce.
      _press.animateWith(
        SpringSimulation(
          _spring,
          _press.value,
          0,
          // A small push back out, so a quick tap still bounces visibly.
          releaseKick,
          tolerance: _springTolerance,
          snapToEnd: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _LifeBudget.release(this);
    _scope?.removeListener(_onPress);
    _press.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      widget.icon,
      size: widget.size,
      color: widget.color,
      semanticLabel: widget.semanticLabel,
    );
    if (_reduce) return icon;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: Listenable.merge([_press, _life]),
      child: icon,
      builder: (context, child) {
        // Each play rests a moment, then moves.
        // Eased, so each move starts and ends at rest.
        final t = Curves.easeInOutSine
            .transform(const Interval(.3, 1).transform(_life.value));
        final fade = 1 - t;
        var scale = 1 - (1 - LivelyIcon.pressedScale) * _press.value;
        var angle = 0.0;
        var offset = Offset.zero;
        var alignment = Alignment.center;
        switch (widget.life) {
          case IconLife.none:
            break;
          case IconLife.float:
            offset = Offset(0, -2 * math.sin(math.pi * t));
          case IconLife.ring:
            // Two soft swings that fade out.
            angle = .18 * math.sin(2 * 2 * math.pi * t) * fade;
            alignment = Alignment.topCenter;
          case IconLife.twinkle:
            final glow = math.sin(math.pi * t);
            scale *= 1 + .14 * glow;
            angle = .25 * glow;
          case IconLife.nudge:
            // One push toward the trailing edge and back.
            final dx = 3 * math.sin(math.pi * t);
            offset = Offset(rtl ? -dx : dx, 0);
        }
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            alignment: alignment,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
    );
  }
}

/// Provides an [IconPressScope] driven by [pressed] for a subtree; a helper
/// for pressable widgets that keep their own pressed flag.
class IconPressHost extends StatefulWidget {
  const IconPressHost({super.key, required this.pressed, required this.child});

  final bool pressed;
  final Widget child;

  @override
  State<IconPressHost> createState() => _IconPressHostState();
}

class _IconPressHostState extends State<IconPressHost> {
  late final _notifier = ValueNotifier<bool>(widget.pressed);

  @override
  void didUpdateWidget(IconPressHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _notifier.value = widget.pressed;
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      IconPressScope(pressed: _notifier, child: widget.child);
}

/// Makes the [LivelyIcon]s in [child] squish while a pointer is down on it,
/// for tappable widgets that do not track their own pressed state.
class IconPressListener extends StatefulWidget {
  const IconPressListener({super.key, required this.child});

  final Widget child;

  @override
  State<IconPressListener> createState() => _IconPressListenerState();
}

class _IconPressListenerState extends State<IconPressListener> {
  final _pressed = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _pressed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _pressed.value = true,
      onPointerUp: (_) => _pressed.value = false,
      onPointerCancel: (_) => _pressed.value = false,
      child: IconPressScope(pressed: _pressed, child: widget.child),
    );
  }
}

/// Turns for [LivelyIcon] moves: at most [max] icons move at once; the rest
/// wait in order and start as others finish.
/// Turns for [LivelyIcon] moves: at most [max] icons move at once; the rest
/// wait in order and start as others finish. A move that has waited longer
/// than [maxWait] is dropped: starting long after the page appeared would
/// look random.
abstract final class _LifeBudget {
  static const max = 2;
  static const maxWait = Duration(seconds: 3);
  static final _active = <LivelyIconState>{};
  static final _waiting = <LivelyIconState, Duration>{};

  static Duration get _now => SchedulerBinding.instance.currentFrameTimeStamp;

  static bool isWaiting(LivelyIconState icon) => _waiting.containsKey(icon);

  /// True when [icon] may move now; otherwise it is queued.
  static bool request(LivelyIconState icon) {
    if (_active.contains(icon)) return true;
    if (_active.length < max) {
      _active.add(icon);
      return true;
    }
    _waiting.putIfAbsent(icon, () => _now);
    return false;
  }

  static void release(LivelyIconState icon) {
    _waiting.remove(icon);
    if (!_active.remove(icon)) return;
    while (_active.length < max && _waiting.isNotEmpty) {
      final next = _waiting.keys.first;
      final queuedAt = _waiting.remove(next)!;
      if (!next.mounted || _now - queuedAt > maxWait) continue;
      _active.add(next);
      // Release can happen mid-build (a tab hiding, an icon disposing):
      // start the next one just after this frame, never during it.
      SchedulerBinding.instance.addPostFrameCallback((_) => next._begin());
    }
  }

  static void reset() {
    _active.clear();
    _waiting.clear();
  }
}
