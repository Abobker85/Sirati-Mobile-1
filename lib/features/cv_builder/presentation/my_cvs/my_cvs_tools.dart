import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/rolling_number.dart';

/// Brand band at the top of My CVs (design/cv-tab): title, one-line hint and
/// the notifications bell. Brand-surface tokens keep the ink AA across the
/// gradient in both themes.
class MyCvsHeader extends StatelessWidget {
  const MyCvsHeader({
    super.key,
    required this.title,
    required this.unreadCount,
    required this.onNotifications,
    this.bottomInset = 0,
  });

  static const bellKey = ValueKey('my-cvs-header-bell');

  final String title;
  final int unreadCount;
  final VoidCallback onNotifications;

  /// Extra band below the text, for the tools card that overlaps it.
  final double bottomInset;

  /// Horizontal, so the strip continued behind the tools card has no seam.
  static BoxDecoration brandBand(BuildContext context) => BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.centerStart,
          end: AlignmentDirectional.centerEnd,
          colors: [
            context.sirati.brandSurfaceDeep,
            context.sirati.brandSurface,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final ink = c.onBrandSurface;

    // The band breathes: a soft darker glow drifts across now and then.
    return BreathingBand(
      deep: c.brandSurfaceDeep,
      child: DecoratedBox(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.of(
                          context,
                          AppTypography.headlineMd,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.myCvsHeaderSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.of(
                          context,
                          AppTypography.bodySm,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _BandBell(
                  unreadCount: unreadCount,
                  onTap: onNotifications,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim copy of the brand band that stays at the top of My CVs once its top
/// row scrolls out: the title and the notifications bell, nothing else.
class MyCvsSlimHeader extends StatelessWidget {
  const MyCvsSlimHeader({
    super.key,
    required this.title,
    required this.unreadCount,
    required this.onNotifications,
  });

  static const bellKey = ValueKey('my-cvs-slim-header-bell');

  /// Height below the status bar.
  static const barHeight = 56.0;

  /// The band's top row (title and bell) starts to leave the screen once the
  /// list has scrolled past the band's top padding; the slim header takes
  /// over from there.
  static const showAfter = AppSpacing.md;

  final String title;
  final int unreadCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return DecoratedBox(
      decoration:
          MyCvsHeader.brandBand(context).copyWith(boxShadow: c.softShadow),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: barHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.of(
                        context,
                        AppTypography.titleLg,
                        color: c.onBrandSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _BandBell(
                  bellKey: bellKey,
                  unreadCount: unreadCount,
                  onTap: onNotifications,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BandBell extends StatelessWidget {
  const _BandBell({
    required this.unreadCount,
    required this.onTap,
    this.bellKey = MyCvsHeader.bellKey,
  });

  final int unreadCount;
  final VoidCallback onTap;
  final Key bellKey;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final ink = c.onBrandSurface;
    return Semantics(
      button: true,
      label: unreadCount > 0
          ? l10n.sharedNotificationsUnread(unreadCount)
          : l10n.sharedNotifications,
      excludeSemantics: true,
      child: Material(
        color: ink.withValues(alpha: .16),
        shape: const CircleBorder(),
        child: InkWell(
          key: bellKey,
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: AppTouchTarget.min,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(Icons.notifications_none_rounded, color: ink),
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
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
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
    );
  }
}

/// "Tools" card: create (the primary tile), scan, upload and target a job.
class MyCvsToolsCard extends StatelessWidget {
  const MyCvsToolsCard({
    super.key,
    required this.onCreate,
    required this.onScan,
    required this.onUpload,
    required this.onTarget,
  });

  static const createKey = ValueKey('my-cvs-tool-create');
  static const scanKey = ValueKey('my-cvs-tool-scan');
  static const uploadKey = ValueKey('my-cvs-tool-upload');
  static const targetKey = ValueKey('my-cvs-tool-target');

  final VoidCallback onCreate;
  final VoidCallback onScan;
  final VoidCallback onUpload;
  final VoidCallback onTarget;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    Widget pair(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: b),
            ],
          ),
        );

    // iOS 26: a section title on the page and borderless grey tiles, like
    // the support-tools grid; no card around them.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.myCvsToolsTitle,
          style: AppTypography.of(context, AppTypography.titleMd),
        ),
        const SizedBox(height: AppSpacing.md),
        pair(
          _ToolTile(
            key: createKey,
            icon: Icons.note_add_outlined,
            title: l.myCvsToolCreateTitle,
            body: l.myCvsToolCreateBody,
            primary: true,
            onTap: onCreate,
          ),
          _ToolTile(
            key: scanKey,
            icon: Icons.document_scanner_outlined,
            title: l.myCvsToolScanTitle,
            body: l.myCvsToolScanBody,
            onTap: onScan,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        pair(
          _ToolTile(
            key: uploadKey,
            icon: Icons.upload_file_rounded,
            title: l.myCvsToolUploadTitle,
            body: l.myCvsToolUploadBody,
            onTap: onUpload,
          ),
          _ToolTile(
            key: targetKey,
            icon: Icons.track_changes_rounded,
            title: l.myCvsToolTargetTitle,
            body: l.myCvsToolTargetBody,
            onTap: onTarget,
          ),
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  /// Brand-filled tile; uses the brand-surface pair so white ink stays AA.
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final ink = primary ? c.onBrandSurface : c.textPrimary;
    final muted = primary ? c.onBrandSurface : c.textSecondary;
    final iconInk = primary ? c.onBrandSurface : c.primaryInk;
    final iconFill =
        primary ? c.onBrandSurface.withValues(alpha: .16) : c.primaryLight;
    const radius = BorderRadius.all(Radius.circular(AppRadius.card));
    final fill = primary ? c.brandSurface : c.cardFill;

    return PressScale(
      child: Semantics(
        button: true,
        child: Material(
          color: fill,
          shape: const RoundedRectangleBorder(borderRadius: radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            highlightColor: c.pressOverlay(fill),
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md - 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 22, color: iconInk),
                      ),
                      const Spacer(),
                      DirectionalIcon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.of(
                      context,
                      AppTypography.titleSm,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.of(
                      context,
                      AppTypography.bodySm,
                      color: muted,
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

/// "My CVs" heading above the list, with how many CVs there are.
class MyCvsListHeading extends StatelessWidget {
  const MyCvsListHeading({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l.myCvsListTitle,
            style: AppTypography.of(context, AppTypography.titleLg),
          ),
        ),
        if (count > 0)
          Text(
            l.cvCount(count),
            style: AppTypography.of(
              context,
              AppTypography.bodySm,
              color: c.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// No saved CVs yet: illustration, a create button and an upload button.
class MyCvsEmptyCard extends StatelessWidget {
  const MyCvsEmptyCard({
    super.key,
    required this.onCreate,
    required this.onUpload,
  });

  static const createKey = ValueKey('my-cvs-empty-create');
  static const uploadKey = ValueKey('my-cvs-empty-upload');

  final VoidCallback onCreate;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The shared calm state. Create and upload are the two equal ways to a
    // first CV, so upload stays as the quieter second action.
    return AppEmptyState(
      icon: Icons.description_outlined,
      title: l.cvListEmptyTitle,
      subtitle: l.myCvsEmptyBody,
      actionKey: createKey,
      actionLabel: l.myCvsEmptyCreate,
      onAction: onCreate,
      actionIcon: Icons.add_rounded,
      secondaryActionKey: uploadKey,
      secondaryActionLabel: l.myCvsEmptyUpload,
      onSecondaryAction: onUpload,
      secondaryActionIcon: Icons.upload_file_rounded,
      scrollable: false,
    );
  }
}
