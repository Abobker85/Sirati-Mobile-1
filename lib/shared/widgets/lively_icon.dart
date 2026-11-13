import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  bool _started = false;

  /// Whether a move or a press is animating right now.
  @visibleForTesting
  bool get isMoving => _life.isAnimating || _press.isAnimating;

  bool get _reduce => MotionSettings.reduce(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = IconPressScope.maybeOf(context);
    if (scope != _scope) {
      _scope?.removeListener(_onPress);
      _scope = scope?..addListener(_onPress);
    }
    if (!_started) {
      _started = true;
      _startLife();
    }
  }

  @override
  void didUpdateWidget(LivelyIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger ||
        oldWidget.life != widget.life ||
        oldWidget.plays != widget.plays) {
      _startLife();
    }
  }

  void _startLife() {
    _played = 0;
    if (widget.life == IconLife.none || widget.plays <= 0 || _reduce) {
      _life.value = 0;
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
    }
  }

  void _onPress() {
    if (_reduce) return;
    if (_scope!.value) {
      _press.animateTo(
        1,
        duration: MotionDurations.press,
        curve: MotionCurves.standard,
      );
    } else {
      // Spring back past rest and settle: the bounce.
      _press.animateTo(
        0,
        duration: MotionDurations.slow + MotionDurations.press,
        curve: MotionCurves.pop,
      );
    }
  }

  @override
  void dispose() {
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
        final t = const Interval(.3, 1).transform(_life.value);
        final wave = math.sin(2 * math.pi * t);
        final fade = 1 - t;
        var scale = 1 - (1 - LivelyIcon.pressedScale) * _press.value;
        var angle = 0.0;
        var offset = Offset.zero;
        var alignment = Alignment.center;
        switch (widget.life) {
          case IconLife.none:
            break;
          case IconLife.float:
            offset = Offset(0, -3 * math.sin(math.pi * t));
          case IconLife.ring:
            angle = .35 * math.sin(4 * 2 * math.pi * t) * fade;
            alignment = Alignment.topCenter;
          case IconLife.twinkle:
            final glow = math.sin(math.pi * t);
            scale *= 1 + .28 * glow;
            angle = .5 * glow;
          case IconLife.nudge:
            final dx = 4 * math.max(0.0, wave) * fade;
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
