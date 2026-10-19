import 'package:flutter/material.dart';
import 'package:sirati/features/jobs/domain/job_news_feed.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_format.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_title_display.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

class JobNewsCard extends StatelessWidget {
  final JobNews item;
  final bool english;
  final bool isNew;
  final VoidCallback onTap;

  const JobNewsCard({
    super.key,
    required this.item,
    required this.english,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [item.company ?? '', item.location ?? '']
        .where((value) => value.isNotEmpty)
        .join(' · ');

    final hasMatch = item.matchScore != null;
    final highMatch = isHighMatch(item.matchScore);

    return PressScale(
      child: Material(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: highMatch
                    ? context.sirati.primary.withValues(alpha: 0.35)
                    : context.sirati.border,
                width: highMatch ? 1.4 : 1.0,
              ),
              boxShadow: context.sirati.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Badges (Verified / Tamheer / Match Score / New)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (item.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.sirati.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isGov
                                  ? Icons.account_balance_rounded
                                  : item.isEnterprise
                                      ? Icons.business_rounded
                                      : Icons.verified_rounded,
                              size: 14,
                              color: context.sirati.primaryInk,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.sourceBadge ??
                                    (english ? 'Verified' : 'موثقة'),
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.sirati.primaryInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.isTamheer)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.sirati.amberLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          english ? 'Tamheer' : 'تمهير 🇸🇦',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.sirati.onWarningContainer,
                          ),
                        ),
                      ),
                    if (hasMatch)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: highMatch
                              ? context.sirati.successLight
                              : context.sirati.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 14,
                              color: highMatch
                                  ? context.sirati.onSuccessContainer
                                  : context.sirati.primaryInk,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${item.matchScore}% ${english ? 'Match' : 'تطابق'}',
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: highMatch
                                      ? context.sirati.onSuccessContainer
                                      : context.sirati.primaryInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isNew)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.sirati.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          english ? 'New' : 'جديد',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.sirati.primaryInk,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title Display
                JobTitleDisplay(
                  title: item.title,
                  primaryStyle: AppTextStyles.titleMd(context.sirati),
                  secondaryStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.sirati.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),

                // Company and location
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: context.sirati.textSecondary,
                    ),
                  ),

                // Match reason snippet if available
                if (item.matchReasons.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.sirati.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: context.sirati.primaryInk,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.matchReasons.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.sirati.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Required skills chips
                if (item.skillsRequired.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.skillsRequired.take(3).map((skill) {
                      final isMatched = item.matchedSkills.any((m) =>
                          m.toLowerCase() == skill.toLowerCase() ||
                          skill.toLowerCase().contains(m.toLowerCase()));
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? context.sirati.primaryLight
                              : context.sirati.surfaceLow,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isMatched
                                ? context.sirati.primary.withValues(alpha: 0.3)
                                : context.sirati.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isMatched ? FontWeight.w700 : FontWeight.w400,
                            color: isMatched
                                ? context.sirati.primaryInk
                                : context.sirati.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 10),
                // Bottom row: Salary + Published time + Details
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.salaryRange != null && item.salaryRange!.isNotEmpty)
                      Text(
                        item.salaryRange!,
                        softWrap: true,
                        style: AppTypography.of(context, AppTypography.bodySm,
                            color: context.sirati.primaryInk),
                      ),
                    Text(
                      jobPublishedText(item, english: english),
                      softWrap: true,
                      style: AppTypography.of(context, AppTypography.bodySm,
                          color: context.sirati.textSecondary),
                    ),
                    Text(
                      english ? 'Details →' : 'التفاصيل ←',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.sirati.primaryInk,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
