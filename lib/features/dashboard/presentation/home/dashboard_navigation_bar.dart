import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/theme/app_theme.dart';
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

/// Bottom navigation of the authenticated shell. Ambient Directionality
/// places Home at the start (right in Arabic, left in English).
class DashboardNavigationBar extends StatelessWidget {
  const DashboardNavigationBar({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final DashboardTab current;
  final ValueChanged<DashboardTab> onChanged;

  /// Display order from the approved board: Home, My CVs, Jobs, then
  /// Learning (still "soon") last.
  static const order = [
    DashboardTab.home,
    DashboardTab.myCvs,
    DashboardTab.jobNews,
    DashboardTab.education,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.sirati;

    return Material(
      color: colors.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: order.indexOf(current),
            onTap: (i) => onChanged(order[i]),
            backgroundColor: colors.surface,
            selectedItemColor: colors.primaryDark,
            unselectedItemColor: colors.textPrimary,
            selectedFontSize: 12.5,
            unselectedFontSize: 11.5,
            iconSize: 24,
            showUnselectedLabels: true,
            items: [
              for (final tab in order)
                BottomNavigationBarItem(
                  // A small "soon" pip on the icon keeps the label clean so
                  // the slot doesn't overflow into its neighbours (SIRATI-95).
                  icon: _NavIconWithBadge(
                    showBadge: _items[tab]!.comingSoon,
                    badgeColor: colors.primary,
                    child: MotionNavIcon(
                      icon: _items[tab]!.icon,
                      selectedIcon: _items[tab]!.selectedIcon,
                      selected: current == tab,
                      selectedBackgroundColor: colors.primaryLight,
                    ),
                  ),
                  label: _label(tab, l10n),
                ),
            ],
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
