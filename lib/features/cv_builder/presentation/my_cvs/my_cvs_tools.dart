import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/rolling_number.dart';

/// Top of My CVs (iOS 26 large title, the Home pattern): the title in the
/// large title style on the plain page, the one-line hint under it and the
/// notifications bell on the end side. It scrolls with the list; once its
/// top row leaves, [MyCvsSlimHeader] shows the same title in the bar.
class MyCvsHeader extends StatelessWidget {
  const MyCvsHeader({
    super.key,
    required this.title,
    required this.unreadCount,
    required this.onNotifications,
  });

  static const bellKey = ValueKey('my-cvs-header-bell');

  /// Space above the title row (and the bell), below the status bar.
  static const topPadding = AppSpacing.md;

  final String title;
  final int unreadCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final gutter = AppSpacing.pageGutter(MediaQuery.sizeOf(context).width);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(gutter, topPadding, gutter, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.of(
                        context,
                        AppTypography.largeTitle,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.myCvsHeaderSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.of(
                      context,
                      AppTypography.bodyMd,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _HeaderBell(
              unreadCount: unreadCount,
              onTap: onNotifications,
            ),
          ],
        ),
      ),
    );
  }
}

/// The bar at the top of My CVs once the large title's top row has scrolled
/// out: the same title as a small centred title, and the bell. Its fill is
/// the app bar's scrolled-under fill (glass tint over the page), opaque so
/// the title keeps its contrast whatever scrolls under it.
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

  /// The large title's top row (title and bell) starts to leave the screen
  /// once the list has scrolled past its top padding; the bar takes over
  /// from there.
  static const showAfter = MyCvsHeader.topPadding;

  final String title;
  final int unreadCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final gutter = AppSpacing.pageGutter(MediaQuery.sizeOf(context).width);
    return ColoredBox(
      color: Color.alphaBlend(c.glassFill, PageSurface.fillOf(context)),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: barHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Row(
              children: [
                // Balances the bell, so the title sits in the middle.
                const SizedBox(width: AppTouchTarget.min),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.of(
                          context,
                          AppTypography.headline,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                _HeaderBell(
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

class _HeaderBell extends StatelessWidget {
  const _HeaderBell({
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
    final ink = c.textPrimary;
    return Semantics(
      button: true,
      label: unreadCount > 0
          ? l10n.sharedNotificationsUnread(unreadCount)
          : l10n.sharedNotifications,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
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
