import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/home/home_glass_header.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/profile_photo.dart';
import 'package:sirati/shared/widgets/rolling_number.dart';

/// The pinned bar at the top of Home: a floating pill on the end side with
/// the profile and the notifications bell, and a small title (the greeting)
/// that fades in once the large title (HomeLargeTitle) has scrolled under
/// the bar (read from [HomeGlassHeader.collapsedOf]).
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.name,
    required this.unreadCount,
    required this.onNotifications,
    required this.onAvatarTap,
  });

  /// The profile button in the pill (one 48dp target).
  static const avatarKey = ValueKey('home-header-avatar');
  static const bellKey = ValueKey('home-header-bell');
  static const pillKey = ValueKey('home-header-pill');

  /// The small title's fade, for tests.
  static const compactTitleKey = ValueKey('home-header-compact-title');

  static const _pillPadding = 4.0;
  static const _pillWidth = AppTouchTarget.min * 2 + _pillPadding * 2;

  final String name;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final gutter = AppSpacing.pageGutter(MediaQuery.sizeOf(context).width);
    final collapsed = HomeGlassHeader.collapsedOf(context);
    final reduce = MotionSettings.reduce(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, AppSpacing.sm, gutter, 0),
        child: Row(
          children: [
            // Balances the pill, so the small title sits in the middle.
            const SizedBox(width: _pillWidth),
            Expanded(
              child: AnimatedOpacity(
                key: compactTitleKey,
                opacity: collapsed ? 1 : 0,
                duration: reduce ? Duration.zero : MotionDurations.medium,
                curve: MotionCurves.standard,
                // Hidden, it is not read: the large title is.
                child: ExcludeSemantics(
                  excluding: !collapsed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      AppLocale.timedGreeting(name, context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.of(context, AppTypography.headline),
                    ),
                  ),
                ),
              ),
            ),
            _Pill(
              name: name,
              unreadCount: unreadCount,
              onNotifications: onNotifications,
              onAvatarTap: onAvatarTap,
            ),
          ],
        ),
      ),
    );
  }
}

/// The floating white capsule: profile, then notifications.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.name,
    required this.unreadCount,
    required this.onNotifications,
    required this.onAvatarTap,
  });

  final String name;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      key: DashboardHomeHeader.pillKey,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.capsuleAll,
        boxShadow: c.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DashboardHomeHeader._pillPadding),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: l10n.homeProfileOpen,
              excludeSemantics: true,
              onTap: onAvatarTap,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: DashboardHomeHeader.avatarKey,
                  customBorder: const CircleBorder(),
                  onTap: onAvatarTap,
                  child: SizedBox.square(
                    dimension: AppTouchTarget.min,
                    child: Center(
                      child: ValueListenableBuilder<AuthUser?>(
                        valueListenable: SessionCache.instance.user,
                        builder: (context, user, _) => ProfilePhoto(
                          url: user?.avatarUrl,
                          name: name,
                          size: 34,
                          premium: user?.subscriptionStatus.isPremium ?? false,
                          background: c.primaryLight,
                          foreground: c.primaryInk,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: unreadCount > 0
                  ? l10n.dashboardHeaderNotificationsUnread(unreadCount)
                  : l10n.sharedNotifications,
              excludeSemantics: true,
              // The excluded InkWell's action, so screen readers can open it.
              onTap: onNotifications,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: DashboardHomeHeader.bellKey,
                  customBorder: const CircleBorder(),
                  onTap: onNotifications,
                  child: SizedBox.square(
                    dimension: AppTouchTarget.min,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          // Rings once when there is something new to read,
                          // never again while it waits.
                          child: UnreadBell(
                            unreadCount: unreadCount,
                            color: c.textPrimary,
                          ),
                        ),
                        if (unreadCount > 0)
                          PositionedDirectional(
                            top: 4,
                            end: 4,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.error,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  // Gated pair: onError on error.
                                  child: RollingNumber(
                                    value: unreadCount,
                                    cap: 9,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.of(
                                      context,
                                      AppTypography.labelSm,
                                      color: c.onError,
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
          ],
        ),
      ),
    );
  }
}

/// The notification bell: it rings once (two soft swings) when there is
/// unread news on arrival, and again only when the unread count goes *up*.
/// Reading notifications (the count going down) never rings it, and it does
/// not repeat by itself.
class UnreadBell extends StatefulWidget {
  const UnreadBell({super.key, required this.unreadCount, required this.color});

  final int unreadCount;
  final Color color;

  @override
  State<UnreadBell> createState() => UnreadBellState();
}

@visibleForTesting
class UnreadBellState extends State<UnreadBell> {
  /// How many times new news arrived since this bell appeared.
  int _rises = 0;

  /// The number of rings asked for, for tests.
  @visibleForTesting
  int get rises => _rises;

  @override
  void didUpdateWidget(UnreadBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > oldWidget.unreadCount) _rises++;
  }

  @override
  Widget build(BuildContext context) => LivelyIcon(
        Icons.notifications_none_rounded,
        color: widget.color,
        life: IconLife.ring,
        plays: widget.unreadCount > 0 ? 1 : 0,
        // Changes only when the count rises, so only a rise rings again.
        trigger: _rises,
      );
}
