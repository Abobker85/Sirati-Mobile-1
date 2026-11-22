import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

class _NavItem {
  const _NavItem({required this.icon, this.comingSoon = false});

  /// Filled glyph, shown whether or not the tab is selected (iOS tab bars).
  final IconData icon;
  final bool comingSoon;
}

const _items = {
  DashboardTab.home: _NavItem(icon: Icons.home_rounded),
  DashboardTab.myCvs: _NavItem(icon: Icons.description_rounded),
  DashboardTab.education: _NavItem(
    icon: Icons.school_rounded,
    comingSoon: true,
  ),
  DashboardTab.jobNews: _NavItem(icon: Icons.work_rounded),
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
/// Every tab shows a filled icon and its label in the primary text colour;
/// the selected one is brand ink on a light grey pill inside the capsule.
/// Switching is instant: the pill and the colours move in the same frame,
/// nothing slides or eases. While the page scrolls down the bar can go
/// [compact]: labels fold away and the capsule narrows; scrolling back up
/// brings them back.
class DashboardNavigationBar extends StatelessWidget {
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

  /// Gap between the capsule and the screen edges.
  static const margin = 16.0;

  /// Extra side inset of the capsule when [compact].
  static const compactInset = 40.0;

  /// Widest the capsule gets, so it stays a bar on tablets.
  static const maxWidth = 560.0;

  /// Space between the capsule's edge and the pill.
  static const pillInset = 4.0;

  /// Key of the glass capsule, for tests.
  static const capsuleKey = ValueKey('dashboard-nav-capsule');

  /// Key of the grey pill behind the selected tab, for tests.
  static const pillKey = ValueKey('dashboard-nav-pill');

  /// Fill of the pill behind the selected tab: the theme's pressed state of
  /// the surface, a light grey in light mode and a lifted grey in dark.
  static Color pillFill(SiratiColors c) => c.pressed(c.surface);

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.sirati;
    // Folding is the only motion left in the bar; reduced motion skips it.
    final duration =
        MotionSettings.reduce(context) ? Duration.zero : MotionDurations.medium;
    final width = MediaQuery.sizeOf(context).width;
    final side = margin +
        math.max(0.0, (width - maxWidth) / 2) +
        (compact ? compactInset : 0);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: duration,
        curve: MotionCurves.standard,
        padding: EdgeInsets.fromLTRB(side, 0, side, AppSpacing.sm),
        child: GlassSurface(
          key: capsuleKey,
          borderRadius: AppRadius.capsuleAll,
          child: Padding(
            padding: const EdgeInsets.all(pillInset),
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
                      selected: current == tab,
                      compact: compact,
                      duration: duration,
                      onTap: () => onChanged(tab),
                      icon: _NavIconWithBadge(
                        showBadge: _items[tab]!.comingSoon,
                        badgeColor: colors.primary,
                        child: SizedBox(
                          width: 44,
                          height: 28,
                          child: Center(child: LivelyIcon(_items[tab]!.icon)),
                        ),
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

/// One tab of the bar. No ripple or highlight on press: the icon squishes
/// under the finger and the pill marks the selected tab, as on iOS tab bars.
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
    // Brand ink is the teal meant for neutral surfaces: it keeps AA on the
    // pill in both themes (dashboard_tab_bar_test).
    final ink = selected ? c.primaryInk : c.textPrimary;
    // Merged onto the inherited style so the app font stays. One size for
    // both states, so picking a tab never moves the labels.
    final style = DefaultTextStyle.of(context).style.merge(TextStyle(
          color: ink,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          height: 1.2,
        ));
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      // One choice out of the group of tabs.
      inMutuallyExclusiveGroup: true,
      label: '$label\n$tabLabel',
      // excludeSemantics drops the child's tap action; declare it here so
      // assistive tech can activate the tab.
      onTap: onTap,
      excludeSemantics: true,
      // Its icon squishes under the finger and bounces back.
      child: IconPressListener(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            key: selected ? DashboardNavigationBar.pillKey : null,
            decoration: BoxDecoration(
              color: selected
                  ? DashboardNavigationBar.pillFill(c)
                  : null,
              borderRadius: AppRadius.capsuleAll,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
              child: AnimatedPadding(
                duration: duration,
                curve: MotionCurves.standard,
                padding: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
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
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: style,
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
