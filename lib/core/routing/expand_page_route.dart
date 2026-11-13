import 'package:flutter/material.dart';

/// Where on screen an expanding page starts: the tapped card's rectangle
/// inside its navigator, and that card's corner radius.
@immutable
class ExpandOrigin {
  const ExpandOrigin({required this.rect, this.radius = 16});

  final Rect rect;
  final double radius;

  /// Measures the widget built by [context]. Null when it is not laid out,
  /// in which case the caller pushes a standard page instead.
  static ExpandOrigin? of(BuildContext context, {double radius = 16}) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final host = Navigator.maybeOf(context)?.context.findRenderObject();
    final topLeft = box.localToGlobal(
      Offset.zero,
      ancestor: host is RenderBox ? host : null,
    );
    return ExpandOrigin(rect: topLeft & box.size, radius: radius);
  }

  @override
  bool operator ==(Object other) =>
      other is ExpandOrigin && other.rect == rect && other.radius == radius;

  @override
  int get hashCode => Object.hash(rect, radius);

  @override
  String toString() => 'ExpandOrigin($rect, radius: $radius)';
}

/// Route arguments asking the router for an [ExpandPageRoute].
///
/// Wraps the page's own [arguments] so a named route can both expand from a
/// card and still receive what it normally takes.
@immutable
class ExpandFrom {
  const ExpandFrom(this.origin, {this.arguments});

  final ExpandOrigin origin;
  final Object? arguments;

  /// The page's own arguments, whether or not they came wrapped.
  static Object? unwrap(Object? arguments) =>
      arguments is ExpandFrom ? arguments.arguments : arguments;
}

/// A page that grows out of the card that opened it and shrinks back onto it.
///
/// The page is laid out at full size from the first frame and revealed
/// through a rounded rectangle that travels from [origin] to the whole
/// screen, so its content never stretches. With "remove animations" on, the
/// page simply appears.
class ExpandPageRoute<T> extends MaterialPageRoute<T> {
  ExpandPageRoute({
    required this.origin,
    required super.builder,
    super.settings,
  });

  /// Expanding card timing from the Saudi DGA design system. Kept equal to
  /// `MotionDurations.slow` / `MotionCurves.standard` (core cannot import
  /// shared; a test holds the two together).
  static const duration = Duration(milliseconds: 280);
  static const curve = Cubic(0.4, 0, 0.2, 1);

  /// Key of the clip the page is revealed through, for tests.
  static const revealKey = ValueKey('expand-page-reveal');

  final ExpandOrigin origin;

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;

    final progress = CurvedAnimation(
      parent: animation,
      curve: curve,
      reverseCurve: curve.flipped,
    );
    // The page fades in over the card during the first half of the growth.
    final opacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      // The tree keeps one shape for the route's whole life, so the page's
      // state survives the end of the transition.
      builder: (context, page) => ClipRRect(
        key: revealKey,
        clipBehavior: animation.isCompleted ? Clip.none : Clip.antiAlias,
        clipper: _RevealClipper(origin: origin, progress: progress),
        child: page,
      ),
      child: FadeTransition(opacity: opacity, child: child),
    );
  }
}

class _RevealClipper extends CustomClipper<RRect> {
  _RevealClipper({required this.origin, required this.progress})
      : super(reclip: progress);

  final ExpandOrigin origin;
  final Animation<double> progress;

  @override
  RRect getClip(Size size) {
    final t = progress.value.clamp(0.0, 1.0);
    final screen = Offset.zero & size;
    // A card scrolled partly off screen starts from its visible part, so the
    // reveal only ever grows.
    final from = origin.rect.overlaps(screen)
        ? origin.rect.intersect(screen)
        : origin.rect;
    final rect = Rect.lerp(from, screen, t)!;
    return RRect.fromRectAndRadius(
      rect,
      Radius.circular(origin.radius * (1 - t)),
    );
  }

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      oldClipper.origin != origin || oldClipper.progress != progress;
}
