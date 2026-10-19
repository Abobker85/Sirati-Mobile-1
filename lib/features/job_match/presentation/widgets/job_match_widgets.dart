import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sirati/core/utils/bidi_text_utils.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Text whose paragraph direction follows its own first strong character
/// (server content and keywords can be Arabic in an English UI and vice
/// versa). [text] is rendered unchanged — no direction marks are injected.
class JobMatchContentText extends StatelessWidget {
  const JobMatchContentText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? AppTypography.of(context, AppTypography.bodyMd),
      textAlign: textAlign,
      textDirection: BidiTextUtils.detectBaseDirection(
        text,
        fallback: Directionality.of(context),
      ),
    );
  }
}

/// Neutral surface card used for every result/form section.
class JobMatchSection extends StatelessWidget {
  const JobMatchSection({
    super.key,
    required this.child,
    this.title,
    this.highlighted = false,
  });

  final String? title;
  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: highlighted ? c.primaryInk : c.textSecondary,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: AppTypography.of(context, AppTypography.titleMd),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

enum JobMatchTone { info, success, warning, error }

/// A tinted message box. Text uses the tone's on-container ink, which holds
/// AA on the matching tint in both themes.
class JobMatchNotice extends StatelessWidget {
  const JobMatchNotice({
    super.key,
    required this.tone,
    required this.message,
    this.detail,
    this.actionLabel,
    this.onAction,
    this.busy = false,
  });

  final JobMatchTone tone;
  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final (bg, fg, icon) = switch (tone) {
      JobMatchTone.info => (c.infoLight, c.onInfoContainer, Icons.info_outline),
      JobMatchTone.success => (
          c.successLight,
          c.onSuccessContainer,
          Icons.check_circle_outline,
        ),
      JobMatchTone.warning => (
          c.warningLight,
          c.onWarningContainer,
          Icons.schedule_rounded,
        ),
      JobMatchTone.error => (
          c.errorLight,
          c.onErrorContainer,
          Icons.error_outline,
        ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: busy
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: AppTypography.of(
                      context,
                      AppTypography.bodySm,
                      color: fg,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      detail!,
                      style: AppTypography.of(
                        context,
                        AppTypography.labelMd,
                        color: fg,
                      ),
                    ),
                  ],
                  if (actionLabel != null && onAction != null)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: busy ? null : onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: fg,
                          disabledForegroundColor: fg,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(48, 40),
                        ),
                        child: Text(actionLabel!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Field label rendered outside the input (the theme's floating label ink
/// is a fill color that cannot carry text).
class JobMatchFieldLabel extends StatelessWidget {
  const JobMatchFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          text,
          style: AppTypography.of(context, AppTypography.titleSm),
        ),
      );
}

enum JobMatchKeywordKind { matched, missing, neutral }

/// One keyword pill. Direction follows the term itself so Latin terms such
/// as `C++` or `Node.js` keep their trailing punctuation in an Arabic UI.
class JobMatchKeywordChip extends StatelessWidget {
  const JobMatchKeywordChip(this.term, {super.key, required this.kind});

  final String term;
  final JobMatchKeywordKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final (bg, fg) = switch (kind) {
      JobMatchKeywordKind.matched => (c.successLight, c.onSuccessContainer),
      JobMatchKeywordKind.missing => (c.warningLight, c.onWarningContainer),
      JobMatchKeywordKind.neutral => (c.primaryLight, c.primaryInk),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs + 2,
        ),
        child: JobMatchContentText(
          term,
          style: AppTypography.of(context, AppTypography.labelMd, color: fg),
        ),
      ),
    );
  }
}

class JobMatchKeywordWrap extends StatelessWidget {
  const JobMatchKeywordWrap({
    super.key,
    required this.terms,
    required this.kind,
  });

  final List<String> terms;
  final JobMatchKeywordKind kind;

  @override
  Widget build(BuildContext context) {
    if (terms.isEmpty) {
      return Text(
        AppLocalizations.of(context).jobMatchNoKeywords,
        style: AppTypography.of(
          context,
          AppTypography.bodySm,
          color: context.sirati.textSecondary,
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final term in terms) JobMatchKeywordChip(term, kind: kind),
      ],
    );
  }
}

/// Circular 0–100 score.
class JobMatchScoreRing extends StatelessWidget {
  const JobMatchScoreRing({super.key, required this.score, this.size = 112});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l = AppLocalizations.of(context);
    final textScale =
        MediaQuery.textScalerOf(context).scale(AppTypography.displayMd.size) /
            AppTypography.displayMd.size;
    return Semantics(
      label: l.jobMatchScoreSemantics(score),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size * textScale.clamp(1.0, double.infinity),
        child: CustomPaint(
          painter: _RingPainter(
            progress: score.clamp(0, 100) / 100,
            track: c.borderStrong,
            arc: c.primaryInk,
          ),
          child: Center(
            child: Text(
              '$score',
              style: AppTypography.of(
                context,
                AppTypography.displayMd,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.arc,
  });

  final double progress;
  final Color track;
  final Color arc;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final ring = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      // Keep even a one-point remainder visible near a complete score.
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(ring, 0, math.pi * 2, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        ring,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        paint..color = arc,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.track != track || old.arc != arc;
}

/// Bulleted list of server-authored lines.
class JobMatchBulletList extends StatelessWidget {
  const JobMatchBulletList({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 6, color: c.textSecondary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: JobMatchContentText(item)),
              ],
            ),
          ),
      ],
    );
  }
}
