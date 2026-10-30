import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ats_grade.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// "Updated 3 days ago", or the server label when there's no timestamp.
String cvUpdatedText(
  CvListItem item,
  AppLocalizations l10n, {
  required bool english,
}) {
  final at = item.updatedAt;
  if (at != null) return AppFormat.relativeTime(at, l10n);
  if (item.updatedLabel.isEmpty) return '';
  return AppFormat.digits(item.updatedLabel, english: english);
}

/// One saved CV: title, date, ATS score (or a scan prompt), an open button
/// and a "⋯" menu with edit / download / delete.
class CvDocumentCard extends StatelessWidget {
  const CvDocumentCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onDownload,
    required this.onScan,
  });

  static ValueKey<String> menuKey(int? id) => ValueKey('cv-card-menu-$id');
  static ValueKey<String> openKey(int? id) => ValueKey('cv-card-open-$id');
  static ValueKey<String> scanKey(int? id) => ValueKey('cv-card-scan-$id');

  final CvListItem item;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDownload;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final colors = context.sirati;
    final l = AppLocalizations.of(context);
    final updated =
        cvUpdatedText(item, AppLocalizations.of(context), english: english);
    final editable = item.id != null;
    final score = item.scoreTotal;

    return PressScale(
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: colors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DocumentIcon(muted: item.isDraft),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isEmpty
                            ? l.cvUntitled
                            : LocaleFormat.mixedTitle(
                                LocaleFormat.fixSampleTitle(item.title),
                                english: english,
                              ),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd(colors),
                      ),
                      if (updated.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          updated,
                          textAlign: TextAlign.start,
                          style: AppTextStyles.bodySm(colors),
                        ),
                      ],
                    ],
                  ),
                ),
                _CardMenu(
                  key: menuKey(item.id),
                  editable: editable,
                  canDownload: item.canDownload,
                  onEdit: onEdit,
                  onDownload: onDownload,
                  onDelete: onDelete,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Divider(height: 24, color: colors.border),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Row(
                children: [
                  Expanded(
                    child: score != null
                        ? Row(
                            children: [
                              // The line beside it already reads the score.
                              ExcludeSemantics(
                                child: _ScoreRing(score: score),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  l.cvCardScore(score),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.of(
                                    context,
                                    AppTypography.labelLg,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _NotScannedChip(label: l.cvCardNotScanned),
                              if (editable)
                                TextButton(
                                  key: scanKey(item.id),
                                  onPressed: onScan,
                                  style: TextButton.styleFrom(
                                    foregroundColor: colors.primaryInk,
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    textStyle: AppTypography.of(
                                      context,
                                      AppTypography.labelLg,
                                    ).copyWith(
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  child: Text(l.cvCardScanNow),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    key: openKey(item.id),
                    onPressed: editable ? onOpen : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primaryInk,
                      side: BorderSide(color: colors.primaryInk, width: 1.5),
                      minimumSize: const Size(76, 48),
                      shape: const StadiumBorder(),
                      textStyle: AppTypography.of(
                        context,
                        AppTypography.labelLg,
                      ),
                    ),
                    child: Text(l.cvCardOpen),
                  ),
                ],
              ),
            ),
            if (score != null && ScoreBand.of(score) == ScoreBand.weak) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _NeedsWorkBanner(label: l.cvCardNeedsWork),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon({required this.muted});

  /// Drafts still generating get a neutral tile.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: muted ? colors.surfaceLow : colors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.description_outlined,
        color: muted ? colors.textSecondary : colors.primaryInk,
      ),
    );
  }
}

enum _CardAction { edit, download, delete }

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    super.key,
    required this.editable,
    required this.canDownload,
    required this.onEdit,
    required this.onDownload,
    required this.onDelete,
  });

  final bool editable;
  final bool canDownload;
  final VoidCallback onEdit;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    final l = AppLocalizations.of(context);

    PopupMenuItem<_CardAction> entry(
      _CardAction value,
      IconData icon,
      String label, {
      required bool enabled,
      Color? color,
    }) =>
        PopupMenuItem(
          value: value,
          enabled: enabled,
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? colors.textPrimary),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        );

    return PopupMenuButton<_CardAction>(
      tooltip: l.cvCardMore,
      icon: Icon(Icons.more_horiz_rounded, color: colors.textSecondary),
      onSelected: (action) => switch (action) {
        _CardAction.edit => onEdit(),
        _CardAction.download => onDownload(),
        _CardAction.delete => onDelete(),
      },
      itemBuilder: (_) => [
        entry(_CardAction.edit, Icons.edit_outlined, l.cvCardEdit,
            enabled: editable),
        entry(_CardAction.download, Icons.download_rounded, l.cvCardDownload,
            enabled: canDownload),
        entry(_CardAction.delete, Icons.delete_outline_rounded, l.deleteItem,
            enabled: editable, color: colors.error),
      ],
    );
  }
}

/// Circular ATS score; the arc colour follows the score band, the number
/// stays on body ink so it holds AA in both themes.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    final arc = switch (ScoreBand.of(score)) {
      ScoreBand.excellent || ScoreBand.veryGood => colors.success,
      ScoreBand.fair => colors.warning,
      ScoreBand.weak => colors.error,
    };
    return SizedBox.square(
      dimension: 44,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            color: arc,
            backgroundColor: colors.surfaceLow,
          ),
          Center(
            child: Text(
              AppFormat.digits(
                '$score',
                english: AppLocale.isEnglish(context),
              ),
              style: AppTypography.of(context, AppTypography.labelLg),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotScannedChip extends StatelessWidget {
  const _NotScannedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radio_button_unchecked_rounded,
            size: 12,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.of(
                context,
                AppTypography.labelMd,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsWorkBanner extends StatelessWidget {
  const _NeedsWorkBanner({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.warningLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: colors.onWarningContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.of(
                context,
                AppTypography.bodySm,
                color: colors.onWarningContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
