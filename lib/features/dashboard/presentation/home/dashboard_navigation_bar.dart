import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    this.comingSoon = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool comingSoon;
}

const _items = {
  DashboardTab.home: _NavItem(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  DashboardTab.myCvs: _NavItem(
    icon: Icons.description_outlined,
    selectedIcon: Icons.description_rounded,
  ),
  DashboardTab.education: _NavItem(
    icon: Icons.school_outlined,
    selectedIcon: Icons.school_rounded,
    comingSoon: true,
  ),
  DashboardTab.jobNews: _NavItem(
    icon: Icons.work_outline_rounded,
    selectedIcon: Icons.work_rounded,
  ),
};

String _label(DashboardTab tab, AppLocalizations l10n) => switch (tab) {
      DashboardTab.home => l10n.dashboardNavHome,
      DashboardTab.myCvs => l10n.dashboardNavMyCvs,
      DashboardTab.education => l10n.dashboardNavEducation,
      DashboardTab.jobNews => l10n.dashboardNavJobNews,
    };

/// Bottom navigation of the authenticated shell: a floating glass capsule
/// above the page. Ambient Directionality places Home at the start (right in
/// Arabic, left in English).
///
/// A soft pill sits behind the selected icon. When the tab changes it slides
/// to the new one and stretches a little on the way, like a drop of glass.
/// While the page scrolls down the bar can go [compact]: labels fold away and
/// the capsule narrows; scrolling back up brings them back.
class DashboardNavigationBar extends StatefulWidget {
  const DashboardNavigationBar({
    super.key,
    required this.current,
    required this.onChanged,
    this.compact = false,
  });

  final DashboardTab current;
  final ValueChanged<DashboardTab> onChanged;

  /// Icons only, in a narrower capsule.
  final bool compact;

  /// Display order from the approved board: Home, My CVs, Jobs, then
  /// Learning (still "soon") last.
  static const order = [
    DashboardTab.home,
    DashboardTab.myCvs,
    DashboardTab.jobNews,
    DashboardTab.education,
  ];

  /// Size of the pill behind the selected icon at rest.
  static const pillSize = Size(56, 32);

  /// Extra width the pill gains halfway through a slide.
  static const pillStretch = 22.0;

  /// Gap between the capsule and the screen edges.
  static const margin = 16.0;

  /// Extra side inset of the capsule when [compact].
  static const compactInset = 40.0;

  /// Widest the capsule gets, so it stays a bar on tablets.
  static const maxWidth = 560.0;

  /// Key of the glass capsule, for tests.
  static const capsuleKey = ValueKey('dashboard-nav-capsule');

  /// Whether the bar should be [compact] after scroll event [n], given it is
  /// [current] now: it folds while the user scrolls a page down, opens when
  /// they scroll back up, and is always open at the top of a page. Sideways
  /// lists (chips, carousels) never change it.
  static bool compactAfter(ScrollNotification n, bool current) {
    if (n.metrics.axis != Axis.vertical) return current;
    return switch (n) {
      // Starting to scroll down folds it, even from the very top.
      UserScrollNotification(direction: ScrollDirection.reverse) => true,
      UserScrollNotification(direction: ScrollDirection.forward) => false,
      _ when n.metrics.pixels <= n.metrics.minScrollExtent => false,
      _ => current,
    };
  }

  @override
  State<DashboardNavigationBar> createState() => DashboardNavigationBarState();
}

@visibleForTesting
class DashboardNavigationBarState extends State<DashboardNavigationBar>
    with SingleTickerProviderStateMixin {
  final _pillPaintKey = GlobalKey();
  final _iconKeys = {
    for (final tab in DashboardNavigationBar.order) tab: GlobalKey(),
  };

  /// 0 → 1 while the pill slides to a newly selected tab. Drives only the
  /// pill's repaint, never a rebuild of the bar.
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: MotionDurations.navIndicator,
    value: 1,
  );

  /// Where the pill was when the current slide began, in the pill layer's
  /// coordinates; null when it should simply sit on its icon.
  Rect? _from;

  /// The pill as last painted, in the pill layer's coordinates.
  Rect? _painted;

  /// The pill as last painted, in global coordinates, for tests.
  @visibleForTesting
  Rect? get paintedPill {
    final rect = _painted;
    final box = _pillPaintKey.currentContext?.findRenderObject();
    if (rect == null || box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(rect.topLeft) & rect.size;
  }

  @override
  void didUpdateWidget(DashboardNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current == widget.current) return;
    if (MotionSettings.reduce(context) || _painted == null) {
      _from = null;
      _slide.value = 1;
      return;
    }
    // A new tab: slide from where the pill is drawn now.
    _from = Rect.fromCenter(
      center: _painted!.center,
      width: DashboardNavigationBar.pillSize.width,
      height: DashboardNavigationBar.pillSize.height,
    );
    _slide.forward(from: 0);
  }

  /// The pill's resting place on the selected icon, measured at paint time
  /// (after this frame's layout), so it is never a frame behind the icon,
  /// even while the capsule folds.
  Rect? _target() {
    final layer = _pillPaintKey.currentContext?.findRenderObject();
    final icon = _iconKeys[widget.current]?.currentContext?.findRenderObject();
    if (layer is! RenderBox || icon is! RenderBox) return null;
    if (!layer.hasSize || !icon.hasSize || !icon.attached) return null;
    return Rect.fromCenter(
      center: icon.localToGlobal(
        icon.size.center(Offset.zero),
        ancestor: layer,
      ),
      width: DashboardNavigationBar.pillSize.width,
      height: DashboardNavigationBar.pillSize.height,
    );
  }

  /// The pill to draw now: on its icon, or part way along a slide, a little
  /// stretched in the middle of it.
  Rect? _pillNow() {
    final to = _target();
    if (to == null) return null;
    final from = _from;
    final t = _slide.value;
    if (from == null || t >= 1) return to;
    final rect = Rect.lerp(from, to, MotionCurves.standard.transform(t))!;
    final stretch = DashboardNavigationBar.pillStretch * math.sin(math.pi * t);
    return Rect.fromCenter(
      center: rect.center,
      width: rect.width + stretch,
      height: rect.height,
    );
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.sirati;
    const order = DashboardNavigationBar.order;
    final reduce = MotionSettings.reduce(context);
    final duration = reduce ? Duration.zero : MotionDurations.medium;
    final compact = widget.compact;
    final width = MediaQuery.sizeOf(context).width;
    final side = DashboardNavigationBar.margin +
        math.max(0.0, (width - DashboardNavigationBar.maxWidth) / 2) +
        (compact ? DashboardNavigationBar.compactInset : 0);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: duration,
        curve: MotionCurves.standard,
        padding: EdgeInsets.fromLTRB(side, 0, side, AppSpacing.sm),
        child: GlassSurface(
          key: DashboardNavigationBar.capsuleKey,
          borderRadius: BorderRadius.circular(AppSpacing.xxl),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: IgnorePointer(
                    // The pill breathes a soft glow now and then.
                    child: AmbientLoop(
                      active: const Duration(milliseconds: 1200),
                      rest: const Duration(seconds: 12),
                      delay: const Duration(seconds: 5),
                      builder: (context, glow, _) => CustomPaint(
                        key: _pillPaintKey,
                        painter: _PillPainter(
                          bar: this,
                          color: colors.primaryLight,
                          glowColor: colors.primary,
                          glow: math.sin(math.pi * glow),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    for (final (i, tab) in order.indexed)
                      Expanded(
                        child: _NavButton(
                          label: _label(tab, l10n),
                          tabLabel: MaterialLocalizations.of(context).tabLabel(
                            tabIndex: i + 1,
                            tabCount: order.length,
                          ),
                          selected: widget.current == tab,
                          compact: compact,
                          duration: duration,
                          onTap: () => widget.onChanged(tab),
                          icon: _NavIconWithBadge(
                            showBadge: _items[tab]!.comingSoon,
                            badgeColor: colors.primary,
                            child: MotionNavIcon(
                              key: _iconKeys[tab],
                              icon: _items[tab]!.icon,
                              selectedIcon: _items[tab]!.selectedIcon,
                              selected: widget.current == tab,
                            ),
                          ),
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

/// Paints the pill behind the selected icon. It repaints on its own while
/// sliding, and whenever the bar's layout changes (folding), and reads the
/// icon's position at paint time, after layout, so it is always in step.
class _PillPainter extends CustomPainter {
  _PillPainter({
    required this.bar,
    required this.color,
    required this.glowColor,
    this.glow = 0,
  }) : super(repaint: bar._slide);

  final DashboardNavigationBarState bar;
  final Color color;
  final Color glowColor;

  /// Strength of the breathing glow around the pill, 0 → 1.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = bar._pillNow();
    bar._painted = rect;
    if (rect == null) return;
    if (glow > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(3),
          Radius.circular(rect.height / 2 + 3),
        ),
        Paint()
          ..color = glowColor.withValues(alpha: .35 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      Paint()..color = color,
    );
  }

  // The icon may have moved even when nothing here changed.
  @override
  bool shouldRepaint(_PillPainter old) => true;
}

/// One tab of the bar. No ripple or grey highlight on press: the sliding
/// pill is the only feedback, as on iOS tab bars.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.tabLabel,
    required this.selected,
    required this.compact,
    required this.duration,
    required this.onTap,
    required this.icon,
  });

  final String label;

  /// "Tab 2 of 4", read after the label by screen readers.
  final String tabLabel;
  final bool selected;
  final bool compact;
  final Duration duration;
  final VoidCallback onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    // Selected labels use the brand ink meant for neutral surfaces: it keeps
    // AA on glass in both themes (app_metrics_test).
    final ink = selected ? c.primaryInk : c.textPrimary;
    // Merged onto the inherited style so the app font stays.
    final style = DefaultTextStyle.of(context).style.merge(TextStyle(
          color: ink,
          fontSize: selected ? 12.5 : 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          height: 1.2,
        ));
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      // One choice out of the group of tabs.
      inMutuallyExclusiveGroup: true,
      label: '$label\n$tabLabel',
      excludeSemantics: true,
      // Its icon squishes under the finger and bounces back.
      child: IconPressListener(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
            child: AnimatedPadding(
              duration: duration,
              curve: MotionCurves.standard,
              padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme.merge(
                    data: IconThemeData(color: ink, size: 24),
                    child: icon,
                  ),
                  // Labels fold away in the compact bar.
                  ClipRect(
                    child: AnimatedAlign(
                      duration: duration,
                      curve: MotionCurves.standard,
                      alignment: Alignment.topCenter,
                      heightFactor: compact ? 0 : 1,
                      child: AnimatedOpacity(
                        duration: duration,
                        opacity: compact ? 0 : 1,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          // Size and weight ease with the pill instead of
                          // jumping when the tab is picked.
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            curve: MotionCurves.standard,
                            style: style,
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nav icon with an optional top-corner dot for "coming soon". A Stack
/// rather than a Material `Badge` so the pip has no text or semantics.
class _NavIconWithBadge extends StatelessWidget {
  const _NavIconWithBadge({
    required this.child,
    required this.showBadge,
    required this.badgeColor,
  });

  final Widget child;
  final bool showBadge;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: 0,
          end: 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: context.sirati.surface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
