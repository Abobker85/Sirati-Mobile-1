import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Pinned top of Home. At rest it is see-through, exactly like the page.
/// Once the page scrolls under it, a frosted glass pane fades in behind
/// [child] so the pill stays readable over the cards below.
///
/// With [collapseAfter], the header also tells [child] (through
/// [collapsedOf]) when the widget under that key, the large title placed
/// right after this header, has scrolled fully under it: the moment the
/// small title should show.
class HomeGlassHeader extends StatefulWidget {
  const HomeGlassHeader({super.key, required this.child, this.collapseAfter});

  final Widget child;

  /// The large title that scrolls in right after this header.
  final GlobalKey? collapseAfter;

  /// Key of the glass pane, for tests.
  static const glassKey = ValueKey('home-header-glass');

  /// Whether the large title has scrolled under the header. False outside
  /// a [HomeGlassHeader].
  static bool collapsedOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Collapsed>()?.value ?? false;

  @override
  State<HomeGlassHeader> createState() => _HomeGlassHeaderState();
}

class _HomeGlassHeaderState extends State<HomeGlassHeader> {
  ScrollPosition? _position;
  double _strength = 0;
  bool _collapsed = false;

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
    final collapsed = _titleScrolledUnder(p);
    if ((next - _strength).abs() > 0.005 ||
        (next == 0 && _strength != 0) ||
        (next == 1 && _strength != 1) ||
        collapsed != _collapsed) {
      setState(() {
        _strength = next;
        _collapsed = collapsed;
      });
    }
  }

  /// The title follows this pinned header in the scroll view, so it is
  /// fully under the header once the page has scrolled by its height.
  bool _titleScrolledUnder(ScrollPosition? p) {
    final title = widget.collapseAfter?.currentContext?.findRenderObject();
    if (p == null || !p.hasPixels || title is! RenderBox || !title.hasSize) {
      return false;
    }
    return p.pixels - p.minScrollExtent >= title.size.height;
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
                            color: c.glassShadow.first.color.withValues(
                                alpha: c.glassShadow.first.color.a * strength),
                            blurRadius:
                                c.glassShadow.first.blurRadius * strength,
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
          child: _Collapsed(value: _collapsed, child: widget.child),
        ),
      ],
    );
  }
}

class _Collapsed extends InheritedWidget {
  const _Collapsed({required this.value, required super.child});

  final bool value;

  @override
  bool updateShouldNotify(_Collapsed oldWidget) => value != oldWidget.value;
}
