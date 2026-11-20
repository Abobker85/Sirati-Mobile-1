import 'package:flutter/material.dart';
import 'package:sirati/core/routing/edge_back_swipe.dart';

/// A page that replaces another of the same rank (Login ⇄ Register), the
/// whole app's root (signed in, signed out), or the same content in more
/// detail. It fades through instead of sliding, because it is not a step
/// deeper: the old page fades out first, then this one fades in and settles
/// from 98% to full size. No direction, so nothing "goes forward" forever
/// when the user switches back and forth.
///
/// Durations mirror `MotionDurations.slow` / `fast` and the curves
/// `MotionCurves.enter` / `exit` (core cannot import shared widgets; a test
/// keeps them equal). With reduced motion the page simply appears.
///
/// When it is not the first page it has the back swipe from the start edge
/// ([EdgeBackSwipe]): the page fades back out under the finger, and letting
/// go early brings it back. The page underneath only fades behind a veil of
/// the app background; it never slides.
class FadeThroughPageRoute<T> extends MaterialPageRoute<T> {
  FadeThroughPageRoute({required super.builder, super.settings});

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _veilBelow;

  /// What the page underneath does: it fades out behind the app background
  /// before this page fades in.
  static Widget? _veilBelow(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) =>
      child == null ? null : _veiled(context, secondaryAnimation, child);

  /// [child] covered by the app background as [secondaryAnimation] runs.
  static Widget _veiled(
    BuildContext context,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeOut = CurvedAnimation(
      parent: secondaryAnimation,
      curve: const Interval(0, fadeInStart, curve: Curves.easeInCubic),
      reverseCurve: const Interval(0, fadeInStart),
    );
    final background = Theme.of(context).scaffoldBackgroundColor;
    return AnimatedBuilder(
      animation: fadeOut,
      child: child,
      builder: (context, c) => Stack(
        fit: StackFit.passthrough,
        children: [
          c!,
          if (fadeOut.value > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: background.withValues(alpha: fadeOut.value),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Coming in.
  static const duration = Duration(milliseconds: 280);

  /// Going away (back).
  static const reverseDuration = Duration(milliseconds: 140);

  /// The incoming page waits for the old one to fade out first.
  static const fadeInStart = .35;

  static const enterCurve = Cubic(0.22, 1, 0.36, 1);

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => reverseDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return EdgeBackSwipe(route: this, child: child);
    }
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(fadeInStart, 1, curve: enterCurve),
      reverseCurve: Curves.easeInCubic,
    );
    final incoming = FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: .98, end: 1).animate(fade),
        child: child,
      ),
    );
    return EdgeBackSwipe(
      route: this,
      child: _veiled(context, secondaryAnimation, incoming),
    );
  }
}
