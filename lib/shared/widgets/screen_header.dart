import 'package:flutter/material.dart';

import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Shared top bar for the four main tabs so the notification button, language
/// and title all render identically across screens.
///
/// Layout is direction-aware via ambient [Directionality]:
/// - Avatar + title cluster at **start** (right in RTL, left in LTR)
/// - Notification bell at **end** (left in RTL, right in LTR)
class ScreenHeader extends StatelessWidget {
  final bool english;

  /// Primary line — a greeting ("Hello, …" / neutral "Welcome") or a screen title.
  final String title;

  /// Optional secondary line under the title.
  final String? subtitle;

  /// Optional short status shown as a subtle chip (used on Home only).
  final String? status;

  /// Unread notification count for the bell badge. 0 hides the badge.
  final int unreadCount;

  /// Opens the notifications screen. Required so the bell is always actionable.
  final VoidCallback onNotifications;

  /// Opens Settings when the avatar is tapped.
  final VoidCallback? onAvatarTap;

  final double titleSize;
  final String? avatarLabel;
  final IconData? icon;

  const ScreenHeader({
    super.key,
    required this.english,
    required this.title,
    required this.onNotifications,
    this.subtitle,
    this.status,
    this.unreadCount = 0,
    this.titleSize = 20,
    this.avatarLabel,
    this.icon,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasStatus = status != null && status!.trim().isNotEmpty;
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;

        // The title may be a greeting in any language: never parse a name
        // out of it. Without a caller-given label the avatar shows an icon.
        final avatar = ProfileAvatar(
          icon: icon,
          label: avatarLabel,
          onTap: onAvatarTap,
          english: english,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: AppTypography.of(
                      context,
                      compact || titleSize < AppTypography.headlineMd.size
                          ? AppTypography.titleLg
                          : titleSize >= AppTypography.headlineLg.size
                              ? AppTypography.headlineLg
                              : AppTypography.headlineMd,
                    ),
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      style: AppTypography.of(
                        context,
                        AppTypography.bodySm,
                        color: context.sirati.textSecondary,
                      ),
                    ),
                  ],
                  if (hasStatus) ...[
                    const SizedBox(height: 6),
                    _StatusDotChip(label: status!),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            NotificationBellButton(
              unreadCount: unreadCount,
              onTap: onNotifications,
              english: english,
            ),
          ],
        );
      },
    );
  }
}

/// Circular notification button with an unread badge — actionable on every tab.
class NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;
  final bool english;

  const NotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.onTap,
    this.english = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final baseLabel = l10n.sharedNotifications;
    final semanticsLabel = unreadCount > 0
        ? l10n.sharedNotificationsUnread(unreadCount)
        : baseLabel;

    return Tooltip(
      message: baseLabel,
      child: Semantics(
        button: true,
        label: semanticsLabel,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: context.sirati.surface,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: AppTouchTarget.min,
                  height: AppTouchTarget.min,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.sirati.border),
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: context.sirati.textPrimary,
                    size: 21,
                  ),
                ),
              ),
            ),
            if (unreadCount > 0)
              PositionedDirectional(
                top: -2,
                end: -2,
                child: ExcludeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.sirati.error,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      // Gated pair: onError on error.
                      style: AppTypography.of(
                        context,
                        AppTypography.labelSm,
                        color: context.sirati.onError,
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

/// Consistent profile avatar used in every tab header.
class ProfileAvatar extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double size;
  final bool english;
  final String? semanticLabel;

  const ProfileAvatar({
    super.key,
    this.label,
    this.icon,
    this.onTap,
    this.size = 46,
    this.english = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content;
    final text = label?.trim() ?? '';
    if (icon != null || text.isEmpty) {
      content = Icon(
        icon ?? Icons.person_rounded,
        size: size * 0.52,
        color: context.sirati.onBrandSurface,
      );
    } else {
      content = FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            // Initials share the fixed avatar face; keep scaling within it.
            textScaler: MediaQuery.textScalerOf(context).clamp(
              maxScaleFactor: 1.3,
            ),
            style: AppTypography.of(
              context,
              AppTypography.titleMd,
              color: context.sirati.onBrandSurface,
            ).copyWith(fontSize: size * 0.35),
          ),
        ),
      );
    }

    final face = ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            // Gated pair across the whole gradient: onBrandSurface on both
            // brandSurface and brandSurfaceDeep is >= 4.5:1.
            colors: [
              context.sirati.brandSurface,
              context.sirati.brandSurfaceDeep,
            ],
          ),
        ),
        child: Center(child: content),
      ),
    );

    if (onTap == null) {
      return Semantics(
        label: semanticLabel ?? AppLocalizations.of(context).sharedProfile,
        child: face,
      );
    }

    final actionLabel = semanticLabel ?? AppLocalizations.of(context).settings;
    return Tooltip(
      message: actionLabel,
      child: Semantics(
        button: true,
        label: actionLabel,
        child: PressScale(
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: AppTouchTarget.min,
                  minHeight: AppTouchTarget.min,
                ),
                child: Center(widthFactor: 1, heightFactor: 1, child: face),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDotChip extends StatelessWidget {
  final String label;

  const _StatusDotChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.sirati.amberLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: context.sirati.amberAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.of(
                context,
                AppTypography.bodySm,
                color: context.sirati.onWarningContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
