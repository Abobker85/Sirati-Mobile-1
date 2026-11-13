import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Pinned top of Home. At rest it is see-through, exactly like the page.
/// Once the page scrolls under it, a frosted glass pane fades in behind
/// [child] so the profile row stays readable over the cards below.
class HomeGlassHeader extends StatefulWidget {
  const HomeGlassHeader({super.key, required this.child});

  final Widget child;

  /// Key of the glass pane, for tests.
  static const glassKey = ValueKey('home-header-glass');

  @override
  State<HomeGlassHeader> createState() => _HomeGlassHeaderState();
}

class _HomeGlassHeaderState extends State<HomeGlassHeader> {
  ScrollPosition? _position;
  bool _scrolled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position == _position) return;
    _position?.removeListener(_onScroll);
    _position = position?..addListener(_onScroll);
    _onScroll();
  }

  void _onScroll() {
    final p = _position;
    final scrolled = p != null &&
        p.hasPixels &&
        p.hasContentDimensions &&
        p.pixels > p.minScrollExtent + .5;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              key: HomeGlassHeader.glassKey,
              opacity: _scrolled ? 1 : 0,
              duration: MotionSettings.reduce(context)
                  ? Duration.zero
                  : MotionDurations.medium,
              curve: MotionCurves.standard,
              child: const GlassSurface(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.xl),
                ),
                child: SizedBox.expand(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: widget.child,
        ),
      ],
    );
  }
}
