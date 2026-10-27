import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/profile_photo.dart';

/// Brand band at the top of Home (Salem review, element 1): avatar initial,
/// greeting and a one-line hint, with the notifications bell opposite.
/// Brand-surface tokens keep the white ink AA across the whole gradient in
/// both themes.
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.unreadCount,
    required this.onNotifications,
    required this.onAvatarTap,
    this.bottomInset = 0,
  });

  static const avatarKey = ValueKey('home-header-avatar');
  static const bellKey = ValueKey('home-header-bell');

  final String name;
  final String subtitle;
  final int unreadCount;
  final VoidCallback onNotifications;
  final VoidCallback onAvatarTap;

  /// Extra brand-coloured space below the text, for content that overlaps
  /// the band.
  final double bottomInset;

  /// The band's fill. Horizontal, so a strip continuing it below (behind the
  /// overlapping hero) lines up without a seam.
  static BoxDecoration brandBand(BuildContext context, {double radius = 0}) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            context.sirati.brandSurfaceDeep,
            context.sirati.brandSurface
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final ink = c.onBrandSurface;

    return DecoratedBox(
      decoration: brandBand(context),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg + bottomInset,
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: l10n.settings,
                child: InkResponse(
                  key: avatarKey,
                  onTap: onAvatarTap,
                  radius: 28,
                  child: ValueListenableBuilder<AuthUser?>(
                    valueListenable: SessionCache.instance.user,
                    builder: (context, user, _) => ProfilePhoto(
                      url: user?.avatarUrl,
                      name: name,
                      size: AppTouchTarget.min,
                      background: c.surface,
                      foreground: c.primaryInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
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
                        color: ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle.trim().isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink.withValues(alpha: .9),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: unreadCount > 0
                    ? l10n.dashboardHeaderNotificationsUnread(unreadCount)
                    : l10n.sharedNotifications,
                excludeSemantics: true,
                child: Material(
                  color: ink.withValues(alpha: .16),
                  shape: const CircleBorder(),
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
                              color: ink,
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
      ),
    );
  }
}
