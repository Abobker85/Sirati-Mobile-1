import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// The back swipe of every page in the app: a drag that starts on the
/// reading start edge (the right in Arabic, the left in English) pulls the
/// page off with the finger. Let go past half way, or flick toward the end
/// edge, and the page goes back; otherwise it settles in again (cancelled).
///
/// It drives the route's own animation through the public back-gesture hooks
/// of [TransitionRoute], so the same swipe works whatever the route draws:
/// the standard slide, a card shrinking back, or a fade. A screen that blocks
/// going back ([PopScope] with `canPop: false`, an open form) refuses it,
/// because [ModalRoute.popGestureEnabled] says so.
class EdgeBackSwipe extends StatefulWidget {
  const EdgeBackSwipe({super.key, required this.route, required this.child});

  final PageRoute<dynamic> route;
  final Widget child;

  /// Width of the strip along the start edge where a swipe can begin.
  static const edgeWidth = 20.0;

  /// A flick at least this fast (screen widths per second) decides the
  /// outcome on its own, whichever side of half way the page is.
  static const minFlingVelocity = 1.0;

  @override
  State<EdgeBackSwipe> createState() => _EdgeBackSwipeState();
}

class _EdgeBackSwipeState extends State<EdgeBackSwipe> {
  late final HorizontalDragGestureRecognizer _recognizer =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _start
        ..onUpdate = _update
        ..onEnd = _end
        ..onCancel = _cancel;

  /// How much of the page is still on screen during a swipe, 1 → 0; null
  /// when no swipe is running.
  double? _shown;
  NavigatorState? _navigator;

  PageRoute<dynamic> get _route => widget.route;

  /// Turns a drag toward the end edge into a positive number.
  double _logical(double dx) =>
      Directionality.of(context) == TextDirection.rtl ? -dx : dx;

  void _pointerDown(PointerDownEvent event) {
    if (_route.popGestureEnabled) _recognizer.addPointer(event);
  }

  void _start(DragStartDetails _) {
    if (!_route.isCurrent) return;
    _navigator = _route.navigator;
    _shown = 1;
    _route.handleStartBackGesture(progress: 1);
  }

  void _update(DragUpdateDetails details) {
    final shown = _shown;
    if (shown == null) return;
    final width = context.size?.width ?? 0;
    if (width <= 0) return;
    _shown = (shown - _logical(details.primaryDelta!) / width).clamp(0.0, 1.0);
    _route.handleUpdateBackGestureProgress(progress: _shown!);
  }

  void _end(DragEndDetails details) {
    final width = context.size?.width ?? 0;
    final velocity = width <= 0
        ? 0.0
        : _logical(details.velocity.pixelsPerSecond.dx) / width;
    _finish(velocity);
  }

  void _cancel() => _finish(0);

  void _finish(double velocity) {
    final shown = _shown;
    final navigator = _navigator;
    _shown = null;
    _navigator = null;
    if (shown == null || navigator == null) return;
    final goBack = velocity.abs() >= EdgeBackSwipe.minFlingVelocity
        ? velocity > 0
        : shown < .5;
    if (!goBack || !_route.isCurrent) {
      // Settles back in, and ends the gesture when it is there.
      _route.handleCancelBackGesture();
      return;
    }
    // The route plays the rest of its exit from where the finger left it.
    navigator.pop();
    final animation = _route.animation;
    if (animation == null || !animation.isAnimating) {
      navigator.didStopUserGesture();
      return;
    }
    late final AnimationStatusListener done;
    done = (status) {
      if (status.isAnimating) return;
      animation.removeStatusListener(done);
      if (navigator.mounted) navigator.didStopUserGesture();
    };
    animation.addStatusListener(done);
  }

  @override
  void dispose() {
    _recognizer.dispose();
    // Disposed mid-swipe: never leave the navigator thinking a finger is down.
    final navigator = _navigator;
    if (_shown != null && navigator != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigator.mounted && navigator.userGestureInProgress) {
          navigator.didStopUserGesture();
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A notch on the start side widens the strip to clear it.
    final padding = MediaQuery.paddingOf(context);
    final notch = Directionality.of(context) == TextDirection.rtl
        ? padding.right
        : padding.left;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          top: 0,
          bottom: 0,
          width:
              notch > EdgeBackSwipe.edgeWidth ? notch : EdgeBackSwipe.edgeWidth,
          child: Listener(
            onPointerDown: _pointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}
