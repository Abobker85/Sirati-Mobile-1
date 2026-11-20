import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show CupertinoFullscreenDialogTransition, CupertinoPageTransition;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:sirati/core/routing/edge_back_swipe.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';

class MotionDurations {
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 280);

  /// Press feedback (scale down while a finger is on a card or button).
  static const press = Duration(milliseconds: 150);

  /// Bottom sheets sliding up (DGA design system: 300ms).
  static const sheet = Duration(milliseconds: 300);

  /// The bottom bar's selection pill sliding between tabs.
  static const navIndicator = Duration(milliseconds: 280);

  /// Home's one-time entrance after launch (header, start cards, services…).
  static const homeIntro = Duration(milliseconds: 1400);

  /// A result revealed as a moment (the ATS score climbing and landing).
  static const reveal = Duration(milliseconds: 1500);

  /// The "CV created" celebration, the first few times.
  static const celebration = Duration(milliseconds: 1300);

  /// The same celebration once the user has seen it a few times.
  static const celebrationQuick = Duration(milliseconds: 750);

  /// A short "no" shake on a field or form error.
  static const shake = Duration(milliseconds: 360);

  /// A control changing into its result (a button turning into a tick).
  static const morph = Duration(milliseconds: 600);

  /// Moving forward to the next step of a flow.
  static const step = Duration(milliseconds: 280);

  /// Soft pulse for skeleton placeholders (single shared loop feel).
  /// Skeleton pulse: slow, near a calm breath, so long loads feel quiet.
  static const skeleton = Duration(milliseconds: 1700);

  /// Max staggered reveal delay across a screen (order * step, capped).
  static const maxRevealDelay = Duration(milliseconds: 120);
  static const revealStep = Duration(milliseconds: 24);
}

class MotionCurves {
  static const enter = Cubic(0.22, 1, 0.36, 1);
  static const state = Cubic(0.25, 1, 0.5, 1);
  static const exit = Curves.easeInCubic;
  static const skeleton = Curves.easeInOut;

  /// Material standard curve, used by the Saudi DGA design system for
  /// moving things that stay on screen (indicators, sheets, expanding cards).
  static const standard = Cubic(0.4, 0, 0.2, 1);

  /// A small overshoot (about 3%), kept for rewards only: CV created,
  /// Premium unlocked, the score change chip.
  static const pop = Cubic(0.3, 1.18, 0.5, 1);

  /// Arrives quickly and settles softly, with no overshoot: for everything
  /// that appears or responds but is not a reward (tiles, icons, marks).
  static const settle = Cubic(0.2, 0.9, 0.3, 1);
}

/// Haptic rules (sound-free feedback), so the phone's feel is predictable:
///
/// - `selectionClick`: a choice (tab, chip, plan, step dot, band crossing,
///   reorder detent) and a blocked submit (once, with one field shaking).
/// - `lightImpact`: something lands (pill, check, ring, chip) or a step is
///   completed.
/// - `mediumImpact`: a milestone (stamp, Premium unlocked).
/// - Never: per keystroke, on blur, or from ambient (self-playing) motion.
/// - With reduced motion, only success and error feedback remain.
class MotionSettings {
  /// Accessibility only: OS "remove animations" / disableAnimations.
  ///
  /// Use for any motion that should fully stop (transitions, shimmer, press
  /// scale, etc.). Screen size is intentionally **not** part of this gate.
  static bool reduce(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return false;
    return mediaQuery.disableAnimations;
  }

  /// Perf tuning for stacked list reveals: a11y reduce **or** large screens
  /// (shortestSide ≥ 700). Use only to skip/shorten [MotionReveal] stagger
  /// delays — not to disable global motion.
  static bool limitStagger(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return false;
    if (mediaQuery.disableAnimations) return true;
    return mediaQuery.size.shortestSide >= 700;
  }
}

/// Direction-aware horizontal offsets for enter/exit motion.
///
/// [direction] is +1 for forward (push / next step) and -1 for back.
/// Forward motion enters from the **end** edge (right in LTR, left in RTL).
class MotionAxis {
  MotionAxis._();

  static double endSign(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
  }

  static Offset slideIn({
    required BuildContext context,
    double distance = 0.04,
    int direction = 1,
  }) {
    return Offset(endSign(context) * distance * direction, 0);
  }
}

/// Sirati's page transition, on every platform: the page slides in across
/// the full width from the end edge (from the left in Arabic, from the right
/// in English) while the page underneath moves a third of the way toward
/// the start edge; back is the mirror.
///
/// Every page also has the back swipe ([EdgeBackSwipe]): drag from the start
/// edge (the right in Arabic) and the page follows the finger; let go early
/// and it settles back. With reduced motion pages simply appear and go, and
/// the swipe still works.
class SiratiPageTransitionsBuilder extends PageTransitionsBuilder {
  const SiratiPageTransitionsBuilder();

  /// Push and back take the same time.
  static const duration = Duration(milliseconds: 350);

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.fullscreenDialog) {
      if (MotionSettings.reduce(context)) return child;
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: route.popGestureInProgress,
        child: child,
      );
    }
    final swipe = EdgeBackSwipe(route: route, child: child);
    if (MotionSettings.reduce(context)) return swipe;
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      // While the finger drives it the page tracks the finger exactly.
      linearTransition: route.popGestureInProgress,
      child: swipe,
    );
  }
}

class MotionTabStack extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;

  const MotionTabStack({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  /// A tab left for at least this long has its content arrive again when it
  /// is opened (fresh look); quicker switches keep it as it was.
  static const staleAfter = Duration(minutes: 1);

  @override
  State<MotionTabStack> createState() => _MotionTabStackState();
}

class _MotionTabStackState extends State<MotionTabStack> {
  late int _renderedIndex = widget.currentIndex;

  /// How many times each tab has been opened after being away for at
  /// least [MotionTabStack.staleAfter]; content inside arrives again then.
  /// Quick back-and-forth switches never replay anything.
  late final List<int> _visits = List.filled(widget.children.length, 0);

  /// When each tab was last left (frame time).
  late final List<Duration?> _leftAt =
      List.filled(widget.children.length, null);

  @override
  void didUpdateWidget(covariant MotionTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
      if (oldWidget.currentIndex < _leftAt.length) {
        _leftAt[oldWidget.currentIndex] = now;
      }
      _renderedIndex = widget.currentIndex;
      final left =
          _renderedIndex < _leftAt.length ? _leftAt[_renderedIndex] : null;
      if (left != null && now - left >= MotionTabStack.staleAfter) {
        _visits[_renderedIndex]++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // IndexedStack paints only the active tab, so inactive tabs never leak
    // or overlap, while every tab stays mounted to keep its scroll and form
    // state. Switching is instant, as on iOS tab bars: the new tab is simply
    // there. Hidden tabs keep their state but do not animate: their tickers
    // are off until the tab is shown again.
    final reduce = MotionSettings.reduce(context);
    return IndexedStack(
      index: _renderedIndex,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          TickerMode(
            key: ValueKey('tab-$index'),
            enabled: index == _renderedIndex,
            child: TabVisitScope(
              // Nothing replays under reduced motion.
              visit: reduce || index >= _visits.length ? 0 : _visits[index],
              child: widget.children[index],
            ),
          ),
      ],
    );
  }
}

/// Gives [child] a short, soft "no" shake, with a selection tick, whenever a
/// new error appears: [errorKey] going from null to a value, or to a
/// different value (a different message). The same error staying put never
/// shakes again. Reduced motion shows the error without the shake or the
/// tick.
///
/// Only one field shakes at a time: when a submit finds several errors at
/// once, the first of them (top-most, as it is built first) shakes and buzzes;
/// the others just show their message. One "here, fix this" instead of a
/// storm of vibrations.
class ErrorShake extends StatefulWidget {
  const ErrorShake({super.key, required this.errorKey, required this.child});

  /// Null while there is no error; usually the error message.
  final Object? errorKey;
  final Widget child;

  /// Widest sideways swing.
  static const amplitude = 3.0;

  /// When the last shake started (frame time), shared by every field.
  static Duration? _lastShakeAt;

  /// Forget the last shake, for tests.
  @visibleForTesting
  static void reset() => _lastShakeAt = null;

  @override
  State<ErrorShake> createState() => ErrorShakeState();
}

@visibleForTesting
class ErrorShakeState extends State<ErrorShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: MotionDurations.shake,
  );

  /// Whether it is shaking now, for tests.
  @visibleForTesting
  bool get shaking => _shake.isAnimating;

  @override
  void didUpdateWidget(ErrorShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = widget.errorKey;
    if (error == null || error == oldWidget.errorKey) return;
    if (MotionSettings.reduce(context)) return;
    // Another field already shook for this same submit: stay still.
    final now = SchedulerBinding.instance.currentFrameTimeStamp;
    final last = ErrorShake._lastShakeAt;
    if (last != null && now - last < MotionDurations.shake) return;
    ErrorShake._lastShakeAt = now;
    unawaited(HapticFeedback.selectionClick());
    _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _shake,
        child: widget.child,
        builder: (context, child) {
          final t = _shake.value;
          if (t == 0 || t == 1) return child!;
          // Two soft swings, the second smaller.
          final dx =
              ErrorShake.amplitude * math.sin(2 * 2 * math.pi * t) * (1 - t);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}

/// Builds [builder] with `settled: false` while the page it is on is still
/// coming in (and while it is first built off screen), then once more with
/// `settled: true`. Count-ups and reveals start from there, so they are seen
/// whole instead of under a half-faded page.
class RouteSettled extends StatefulWidget {
  const RouteSettled({super.key, required this.builder});

  final Widget Function(BuildContext context, bool settled) builder;

  @override
  State<RouteSettled> createState() => _RouteSettledState();
}

class _RouteSettledState extends State<RouteSettled> {
  ModalRoute<Object?>? _route;
  Animation<double>? _animation;
  bool _settled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_settled) return;
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (route == null || animation == null) {
      _settled = true;
      return;
    }
    if (_animation != animation) {
      _animation?.removeStatusListener(_onStatus);
      _route = route;
      _animation = animation..addStatusListener(_onStatus);
    }
    _onStatus(animation.status);
  }

  void _onStatus(AnimationStatus status) {
    final route = _route;
    if (_settled || route == null) return;
    // A new page is first built offstage, where it already reads complete.
    if (status != AnimationStatus.completed || route.offstage) return;
    _animation?.removeStatusListener(_onStatus);
    if (mounted) setState(() => _settled = true);
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_onStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _settled);
}

/// Smoothly replaces loading, error, empty, and data states without delaying
/// interaction. The caller supplies a stable [stateKey] for each state.
/// A control changing into its result (a button label turning into a
/// confirmation, an icon into a tick): the old one fades out while the new
/// one fades in and, with [pop], grows from 60% with a small overshoot.
/// Reduced motion swaps at once.
class MotionMorph extends StatelessWidget {
  const MotionMorph({
    super.key,
    required this.morphKey,
    required this.child,
    this.pop = true,
  });

  /// Changes when the control changes state.
  final Object morphKey;
  final Widget child;
  final bool pop;

  @override
  Widget build(BuildContext context) {
    final keyed = KeyedSubtree(key: ValueKey(morphKey), child: child);
    if (MotionSettings.reduce(context)) return keyed;
    return AnimatedSwitcher(
      duration: MotionDurations.morph,
      reverseDuration: MotionDurations.fast,
      switchInCurve: const Interval(.2, 1),
      transitionBuilder: (child, animation) {
        final faded = FadeTransition(opacity: animation, child: child);
        if (!pop) return faded;
        return ScaleTransition(
          scale: Tween<double>(begin: .6, end: 1).animate(
            CurvedAnimation(parent: animation, curve: MotionCurves.settle),
          ),
          child: faded,
        );
      },
      child: keyed,
    );
  }
}

/// Swaps the content of a multi-step flow: the new step fades in while
/// sliding along the reading axis according to [direction] (`+1` forward,
/// `-1` back). Forward enters from the reading end (left in Arabic, right in
/// English) while the outgoing step exits toward the start; back reverses
/// both. Reduced motion swaps at once.
class MotionStepSwitcher extends StatelessWidget {
  const MotionStepSwitcher({
    super.key,
    required this.stepKey,
    required this.child,
    this.direction = 1,
  });

  /// Changes when the step changes.
  final Object stepKey;
  final Widget child;

  /// `+1` for forward navigation, `-1` for backward navigation.
  final int direction;

  /// How far the new step slides in, as a share of its width.
  static const slide = .05;

  @override
  Widget build(BuildContext context) {
    final keyed = KeyedSubtree(key: ValueKey(stepKey), child: child);
    if (MotionSettings.reduce(context)) return keyed;
    final end = MotionAxis.endSign(context);
    final dir = direction >= 0 ? 1.0 : -1.0;
    return AnimatedSwitcher(
      duration: MotionDurations.step,
      reverseDuration: MotionDurations.fast,
      switchInCurve: MotionCurves.standard,
      switchOutCurve: MotionCurves.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [
          // The step on its way out cannot be tapped (no double send).
          for (final old in previous) IgnorePointer(child: old),
          if (current != null) current,
        ],
      ),
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == keyed.key;
        final offsetX = (isIncoming ? 1.0 : -1.0) * end * dir * slide;
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(offsetX, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: keyed,
    );
  }
}

/// Smoothly expands/collapses and cross-fades conditional slot content.
///
/// Uses [AnimatedSize] (`MotionDurations.medium`, top-start aligned) wrapping
/// [AnimatedSwitcher] (`MotionDurations.fast`), collapsing both to
/// [Duration.zero] under [MotionSettings.reduce].
class MotionExpandSlot extends StatelessWidget {
  const MotionExpandSlot({
    super.key,
    required this.child,
    this.alignment = AlignmentDirectional.topCenter,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final reduce = MotionSettings.reduce(context);
    if (reduce) return child;
    return AnimatedSize(
      duration: MotionDurations.medium,
      curve: MotionCurves.enter,
      alignment: alignment,
      child: AnimatedSwitcher(
        duration: MotionDurations.fast,
        switchInCurve: MotionCurves.enter,
        switchOutCurve: MotionCurves.exit,
        child: child,
      ),
    );
  }
}

/// One selectable option in a [MotionSegmentedPill].
@immutable
class MotionSegmentOption<T> {
  const MotionSegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });

  final T value;
  final String label;
  final IconData? icon;
  final Key? key;
}

/// Direction-aware segmented selector with a sliding pill indicator.
///
/// Enforces `>= 48dp` touch targets, avoids `FontWeight` interpolation
/// (fixed shipped `w700` via [AppTypography.labelLg]), maintains WCAG AA
/// contrast in light and dark modes, and snaps under [MotionSettings.reduce].
class MotionSegmentedPill<T> extends StatelessWidget {
  const MotionSegmentedPill({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.enabled = true,
  }) : assert(options.length >= 2, 'MotionSegmentedPill requires >= 2 options');

  final List<MotionSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);
    final count = options.length;
    final found = options.indexWhere((o) => o.value == value);
    final selectedIndex = found < 0 ? 0 : found;
    final alignX = -1.0 + (2.0 * selectedIndex / (count - 1));
    final duration = reduce ? Duration.zero : MotionDurations.medium;

    final pill = FractionallySizedBox(
      widthFactor: 1 / count,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: c.primaryInk),
          boxShadow: AppShadows.of(
            c,
            elevation: AppElevation.raised,
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceLow,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: c.outline),
        ),
        padding: const EdgeInsets.all(AppSpacing.xxs),
        child: LayoutBuilder(
          builder: (context, _) => Stack(
            children: [
              Positioned.fill(
                child: reduce
                    ? Align(
                        alignment: AlignmentDirectional(alignX, 0),
                        child: pill,
                      )
                    : AnimatedAlign(
                        duration: duration,
                        curve: MotionCurves.state,
                        alignment: AlignmentDirectional(alignX, 0),
                        child: pill,
                      ),
              ),
              Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: _MotionSegmentButton<T>(
                          option: options[i],
                          selected: i == selectedIndex,
                          enabled: enabled,
                          reduce: reduce,
                          onTap: () {
                            if (options[i].value != value) {
                              unawaited(HapticFeedback.selectionClick());
                              onChanged(options[i].value);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotionSegmentButton<T> extends StatelessWidget {
  const _MotionSegmentButton({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.reduce,
    required this.onTap,
  });

  final MotionSegmentOption<T> option;
  final bool selected;
  final bool enabled;
  final bool reduce;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final fg = selected ? c.primaryInk : c.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: option.label,
      excludeSemantics: true,
      child: InkWell(
        key: option.key,
        borderRadius: AppRadius.mdAll,
        splashFactory: reduce ? NoSplash.splashFactory : null,
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: 18, color: fg),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.of(
                      context,
                      AppTypography.labelLg,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MotionStateSwitcher extends StatelessWidget {
  final Object stateKey;
  final Widget child;

  const MotionStateSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final keyedChild = KeyedSubtree(key: ValueKey(stateKey), child: child);
    if (MotionSettings.reduce(context)) return keyedChild;

    return AnimatedSwitcher(
      duration: MotionDurations.medium,
      reverseDuration: MotionDurations.fast,
      switchInCurve: MotionCurves.enter,
      switchOutCurve: MotionCurves.exit,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.passthrough,
        alignment: Alignment.topCenter,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, .012),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: keyedChild,
    );
  }
}

/// Animated selection treatment for bottom-navigation icons.
///
/// The capsule clarifies the active destination while the icon swap and
/// slight scale acknowledge the tab change. Reduced motion keeps the same
/// selected styling without interpolation.
class MotionNavIcon extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;

  const MotionNavIcon({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
  });

  @override
  State<MotionNavIcon> createState() => _MotionNavIconState();
}

class _MotionNavIconState extends State<MotionNavIcon>
    with SingleTickerProviderStateMixin {
  /// 0 → 1 as a newly selected icon settles in from 85%.
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: MotionDurations.navIndicator,
    value: 1,
  );

  @override
  void didUpdateWidget(MotionNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected &&
        !oldWidget.selected &&
        !MotionSettings.reduce(context)) {
      _settle.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // One icon for the whole life of the tab, so a press bounce that is
    // still playing is not cut when the tab becomes selected.
    return SizedBox(
      width: 44,
      height: 32,
      child: Center(
        child: AnimatedBuilder(
          animation: _settle,
          builder: (context, child) => Transform.scale(
            scale: .85 + .15 * MotionCurves.settle.transform(_settle.value),
            child: child,
          ),
          child:
              LivelyIcon(widget.selected ? widget.selectedIcon : widget.icon),
        ),
      ),
    );
  }
}

class MotionReveal extends StatefulWidget {
  final Widget child;
  final int order;
  final Offset offset;
  final Duration duration;

  /// Stagger only the first N items in a list for scroll perf.
  static const maxStaggerIndex = 5;

  const MotionReveal({
    super.key,
    required this.child,
    this.order = 0,
    this.offset = const Offset(0, .025),
    this.duration = MotionDurations.medium,
  });

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _opacity;
  Animation<Offset>? _slide;
  Timer? _timer;
  bool _skipMotion = false;
  int? _visit;

  @override
  void initState() {
    super.initState();
    // Long lists: skip controllers beyond the first few items.
    if (widget.order > MotionReveal.maxStaggerIndex) {
      _skipMotion = true;
      return;
    }
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _controller!, curve: MotionCurves.enter);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide =
        Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_skipMotion) return;
    final controller = _controller;
    if (controller == null) return;

    // Full a11y reduce: snap visible, no entrance motion.
    if (MotionSettings.reduce(context)) {
      controller.value = 1;
      return;
    }

    // Opening the tab again: arrive again.
    final visit = TabVisitScope.maybeOf(context);
    final revisit = _visit != null && visit != _visit;
    _visit = visit;
    if (revisit && AmbientMotion.enabled.value) {
      _timer?.cancel();
      _timer = null;
      controller.value = 0;
    }

    if (controller.status == AnimationStatus.dismissed && _timer == null) {
      // Tablets (and reduce) skip stagger delays to limit stacked-list jank;
      // the fade/slide still runs when animations are allowed.
      final delayMs = MotionSettings.limitStagger(context)
          ? 0
          : math.min(
              widget.order * MotionDurations.revealStep.inMilliseconds,
              MotionDurations.maxRevealDelay.inMilliseconds,
            );
      if (delayMs == 0) {
        controller.forward();
      } else {
        _timer = Timer(Duration(milliseconds: delayMs), () {
          if (mounted) controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_skipMotion || MotionSettings.reduce(context)) return widget.child;
    final opacity = _opacity;
    final slide = _slide;
    if (opacity == null || slide == null) return widget.child;

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: widget.child),
    );
  }
}

class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double pressedScale;

  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = .97,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !widget.enabled) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (MotionSettings.reduce(context) || !widget.enabled) return widget.child;

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: MotionDurations.press,
        curve: MotionCurves.standard,
        child: IconPressHost(pressed: _pressed, child: widget.child),
      ),
    );
  }
}
