import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sirati/core/routing/edge_back_swipe.dart';

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
/// Back: the button, the system back, or the swipe from the start edge
/// (the right in Arabic, [EdgeBackSwipe]), which shrinks the page onto its
/// card under the finger and can be cancelled by letting go early. The page
/// underneath stays still while this one grows or shrinks over it, so the
/// card it grows from never moves away.
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

  /// Key of the zoom applied to the page while it grows, for tests.
  static const zoomKey = ValueKey('expand-page-zoom');

  /// How small the page content starts, as it zooms out of the card.
  static const zoomFrom = .92;

  /// Share of the growth after which the content is at full size.
  static const zoomEndsAt = .85;

  final ExpandOrigin origin;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _stayStill;

  /// What the page underneath does: nothing.
  static Widget? _stayStill(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) =>
      child;

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
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return EdgeBackSwipe(route: this, child: child);
    }

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

    final clipper = _RevealClipper(origin: origin, progress: progress);
    final shadow = Theme.of(context).colorScheme.shadow;
    // The content zooms out of the card: it starts a little smaller, scaled
    // around the card's centre, so the card seems to become the page.
    final size = MediaQuery.sizeOf(context);
    final focus = Alignment(
      size.width == 0 ? 0 : origin.rect.center.dx / size.width * 2 - 1,
      size.height == 0 ? 0 : origin.rect.center.dy / size.height * 2 - 1,
    );

    final reveal = AnimatedBuilder(
      animation: animation,
      // The tree keeps one shape for the route's whole life, so the page's
      // state survives the end of the transition.
      builder: (context, page) {
        final t = progress.value.clamp(0.0, 1.0);
        final moving = !animation.isCompleted && !animation.isDismissed;
        return CustomPaint(
          // The growing card is lifted off the page by a soft shadow that is
          // deepest halfway and gone at both ends.
          painter: moving
              ? _RevealShadowPainter(
                  clipper: clipper,
                  color: shadow,
                  lift: math.sin(math.pi * t),
                )
              : null,
          child: ClipRRect(
            key: revealKey,
            clipBehavior: moving ? Clip.antiAlias : Clip.none,
            clipper: clipper,
            child: Transform.scale(
              key: zoomKey,
              // Full size a little before the reveal fills the screen, so
              // the page under it never peeks round a not-yet-full page.
              scale: zoomFrom + (1 - zoomFrom) * math.min(1.0, t / zoomEndsAt),
              alignment: focus,
              child: page,
            ),
          ),
        );
      },
      // The page is drawn once into its own layer and then only clipped,
      // scaled and faded while it grows, not redrawn every frame.
      child: FadeTransition(
        opacity: opacity,
        child: RepaintBoundary(child: child),
      ),
    );
    return EdgeBackSwipe(route: this, child: reveal);
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

/// Paints the soft shadow under the growing card.
class _RevealShadowPainter extends CustomPainter {
  _RevealShadowPainter({
    required this.clipper,
    required this.color,
    required this.lift,
  });

  final _RevealClipper clipper;
  final Color color;

  /// 0 (flat) to 1 (highest).
  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    if (lift <= 0) return;
    final path = Path()..addRRect(clipper.getClip(size));
    canvas.drawShadow(path, color.withValues(alpha: .5), 24 * lift, false);
  }

  @override
  bool shouldRepaint(_RevealShadowPainter old) =>
      old.lift != lift || old.color != color;
}
