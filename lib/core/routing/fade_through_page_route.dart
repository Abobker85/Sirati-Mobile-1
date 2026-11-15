import 'package:flutter/material.dart';

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
class FadeThroughPageRoute<T> extends MaterialPageRoute<T> {
  FadeThroughPageRoute({required super.builder, super.settings});

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
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(fadeInStart, 1, curve: enterCurve),
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: .98, end: 1).animate(fade),
        child: child,
      ),
    );
  }
}
