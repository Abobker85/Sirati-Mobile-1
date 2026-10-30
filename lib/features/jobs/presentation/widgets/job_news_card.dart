import 'package:flutter/material.dart';
import 'package:sirati/core/utils/locale_format.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/features/jobs/domain/job_news_feed.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_format.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_title_display.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// One posting (approved board): title, employer, then 📍 place · age on one
/// line; the full list adds factual chips (source type, how to apply,
/// remote, new). The whole card opens the details.
class JobNewsCard extends StatelessWidget {
  final JobNews item;
  final bool english;
  final VoidCallback onTap;

  /// Home's "latest jobs" shows the card without chips.
  final bool compact;

  /// Clock for the "new" marker; tests pin it.
  final DateTime? now;

  const JobNewsCard({
    super.key,
    required this.item,
    required this.english,
    required this.onTap,
    this.compact = false,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final company = (item.company ?? '').trim();
    final where = [
      if ((item.location ?? '').trim().isNotEmpty) item.location!.trim(),
      jobPublishedText(item, AppLocalizations.of(context), english: english),
    ].where((s) => s.isNotEmpty).join(' · ');
    final destination = ApplyDestination.of(item);

    final chips = <Widget>[
      if (!compact) ...[
        if (jobSourceTypeLabel(l, item) case final label?)
          JobChip(label: label, icon: jobSourceTypeIcon(item)),
        if (destination is ApplyLink)
          JobChip(label: l.jobsApplyMethodLink, icon: Icons.link_rounded)
        else if (destination is ApplyEmail)
          JobChip(
              label: l.jobsApplyMethodEmail, icon: Icons.mail_outline_rounded),
        if (item.isRemote)
          JobChip(label: l.jobsRemoteChip, icon: Icons.laptop_mac_rounded),
        if (isFreshJob(item, now ?? DateTime.now()))
          JobChip(label: l.jobsNewBadge, emphasis: true),
      ],
    ];
    final meta = TextStyle(fontSize: 12.5, height: 1.4, color: c.textSecondary);

    return PressScale(
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(_radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                JobTitleDisplay(
                  title: item.title,
                  language: item.language,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                if (company.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    LocaleFormat.mixedTitle(company, english: english),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: meta,
                  ),
                ],
                if (where.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 15, color: c.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          where,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: meta,
                        ),
                      ),
                    ],
                  ),
                ],
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: chips),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _radius = 18.0;
}

/// "Employer · Place", skipping whichever is unknown.
String jobMetaLine(JobNews item, {required bool english}) => [
      if ((item.company ?? '').trim().isNotEmpty)
        LocaleFormat.mixedTitle(item.company!.trim(), english: english),
      if ((item.location ?? '').trim().isNotEmpty) item.location!.trim(),
    ].join(' · ');

/// Label for curated source types only; general aggregated posts have none.
String? jobSourceTypeLabel(AppLocalizations l, JobNews item) {
  if (item.isGov) return l.jobsPresetGov;
  if (item.isTamheer) return l.jobsTamheerBadge;
  if (item.isEnterprise) return l.jobsPresetEnterprise;
  return null;
}

IconData jobSourceTypeIcon(JobNews item) => item.isGov
    ? Icons.account_balance_rounded
    : item.isTamheer
        ? Icons.school_rounded
        : Icons.apartment_rounded;

/// Small factual chip. [emphasis] = brand tint (used for "new").
class JobChip extends StatelessWidget {
  const JobChip(
      {super.key, required this.label, this.icon, this.emphasis = false});

  final String label;
  final IconData? icon;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final fg = emphasis ? c.primaryInk : c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasis ? c.primaryLight : c.surfaceLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: emphasis ? c.borderStrong : c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
