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
  double _strength = 0;

  /// Scroll distance over which the glass header reaches full strength.
  static const _scrollRamp = 24.0;

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
    final next = (p == null || !p.hasPixels || !p.hasContentDimensions)
        ? 0.0
        : ((p.pixels - p.minScrollExtent) / _scrollRamp).clamp(0.0, 1.0);
    if ((next - _strength).abs() > 0.005 || (next == 0 && _strength != 0) || (next == 1 && _strength != 1)) {
      setState(() => _strength = next);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            // The glass itself fades in (tint and blur together); an opacity
            // over a blur would show tint first and pop the blur on at the end.
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: _strength),
              duration: MotionSettings.reduce(context)
                  ? Duration.zero
                  : MotionDurations.medium,
              curve: MotionCurves.standard,
              builder: (context, strength, _) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.xl),
                  ),
                  boxShadow: strength > 0
                      ? [
                          BoxShadow(
                            color: c.glassShadow.first.color
                                .withValues(alpha: c.glassShadow.first.color.a * strength),
                            blurRadius: c.glassShadow.first.blurRadius * strength,
                            offset: c.glassShadow.first.offset * strength,
                          ),
                        ]
                      : null,
                ),
                child: GlassSurface(
                  key: HomeGlassHeader.glassKey,
                  strength: strength,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSpacing.xl),
                  ),
                  child: const SizedBox.expand(),
                ),
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
