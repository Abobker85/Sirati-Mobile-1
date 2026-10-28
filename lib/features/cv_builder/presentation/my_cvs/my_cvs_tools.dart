import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

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
    );
  }
}

class _BandBell extends StatelessWidget {
  const _BandBell({required this.unreadCount, required this.onTap});

  final int unreadCount;
  final VoidCallback onTap;

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
          key: MyCvsHeader.bellKey,
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
    final c = context.sirati;
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: c.softShadow,
      ),
      child: Column(
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
      ),
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
    const radius = BorderRadius.all(Radius.circular(16));

    return PressScale(
      child: Semantics(
        button: true,
        child: Material(
          color: primary ? c.brandSurface : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: primary ? BorderSide.none : BorderSide(color: c.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
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
    final c = context.sirati;
    final l = AppLocalizations.of(context);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );
    final buttonText = AppTypography.of(context, AppTypography.labelLg);

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ExcludeSemantics(child: _EmptyIllustration()),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l.cvListEmptyTitle,
            textAlign: TextAlign.center,
            style: AppTypography.of(context, AppTypography.titleLg),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.myCvsEmptyBody,
            textAlign: TextAlign.center,
            style: AppTypography.of(
              context,
              AppTypography.bodyMd,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: createKey,
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(l.myCvsEmptyCreate),
            style: FilledButton.styleFrom(
              backgroundColor: c.brandSurface,
              foregroundColor: c.onBrandSurface,
              minimumSize: const Size.fromHeight(52),
              shape: buttonShape,
              textStyle: buttonText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: uploadKey,
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_rounded, size: 20),
            label: Text(l.myCvsEmptyUpload),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.primaryInk,
              side: BorderSide(color: c.primaryInk, width: 1.5),
              minimumSize: const Size.fromHeight(52),
              shape: buttonShape,
              textStyle: buttonText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed document page with a plus badge and two sparkles.
class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration();

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return SizedBox(
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.borderStrong, width: 1.5),
            ),
          ),
          CustomPaint(
            size: const Size(78, 100),
            painter: _DashedPagePainter(
              border: c.primaryInk,
              fill: c.surface,
              lines: c.textHint,
            ),
          ),
          Positioned(
            bottom: 6,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: c.brandSurface,
                shape: BoxShape.circle,
                border: Border.all(color: c.surface, width: 3),
              ),
              child: Icon(Icons.add_rounded, size: 20, color: c.onBrandSurface),
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            top: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 22, color: c.primaryInk),
                const SizedBox(width: 172),
                Icon(Icons.auto_awesome, size: 22, color: c.primaryInk),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedPagePainter extends CustomPainter {
  _DashedPagePainter({
    required this.border,
    required this.fill,
    required this.lines,
  });

  final Color border;
  final Color fill;
  final Color lines;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.drawRRect(rect, Paint()..color = fill);
    final stroke = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), stroke);
      }
    }
    final line = Paint()
      ..color = lines
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (y, w) in [(20.0, 44.0), (32.0, 32.0), (44.0, 38.0)]) {
      final x = (size.width - w) / 2;
      canvas.drawLine(Offset(x, y), Offset(x + w, y), line);
    }
  }

  @override
  bool shouldRepaint(_DashedPagePainter old) =>
      old.border != border || old.fill != fill || old.lines != lines;
}
