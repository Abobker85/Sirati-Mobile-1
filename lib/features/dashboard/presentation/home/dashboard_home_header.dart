import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/home/home_pressable_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/profile_photo.dart';

/// Profile row at the top of Home (approved board, option 3): one card that
/// opens the profile (avatar, greeting, hint, chevron), with the
/// notifications bell as its own button beside it.
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.unreadCount,
    required this.onNotifications,
    required this.onAvatarTap,
  });

  /// The whole profile card (one 64dp target).
  static const avatarKey = ValueKey('home-header-avatar');
  static const bellKey = ValueKey('home-header-bell');

  static const _radius = 22.0;

  final String name;
  final String subtitle;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageGutter(MediaQuery.sizeOf(context).width),
          AppSpacing.md,
          AppSpacing.pageGutter(MediaQuery.sizeOf(context).width),
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: l10n.homeProfileOpen,
                child: HomePressableCard(
                  inkKey: avatarKey,
                  onTap: onAvatarTap,
                  radius: _radius,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        8,
                        8,
                        8,
                      ),
                      child: Row(
                        children: [
                          ValueListenableBuilder<AuthUser?>(
                            valueListenable: SessionCache.instance.user,
                            builder: (context, user, _) => ProfilePhoto(
                              url: user?.avatarUrl,
                              name: name,
                              size: 44,
                              background: c.primaryLight,
                              foreground: c.primaryInk,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppLocale.greeting(name, context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (subtitle.trim().isNotEmpty)
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.textSecondary,
                                      fontSize: 12.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: c.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Semantics(
              button: true,
              label: unreadCount > 0
                  ? l10n.dashboardHeaderNotificationsUnread(unreadCount)
                  : l10n.sharedNotifications,
              excludeSemantics: true,
              // The excluded InkWell's action, so screen readers can open it.
              onTap: onNotifications,
              child: Material(
                color: c.surface,
                shape: CircleBorder(side: BorderSide(color: c.border)),
                child: InkWell(
                  key: bellKey,
                  customBorder: const CircleBorder(),
                  onTap: onNotifications,
                  child: SizedBox.square(
                    dimension: AppTouchTarget.min,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
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
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
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
