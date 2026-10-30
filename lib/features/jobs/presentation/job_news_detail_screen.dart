import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_apply_actions.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_common.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_format.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_title_display.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';

/// One posting: facts, how to apply, the text, and where it came from. The
/// bottom bar's primary action is the real application (link or email);
/// without one, tailoring the CV is primary and nothing pretends to apply.
class JobNewsDetailScreen extends StatelessWidget {
  final JobNews item;

  const JobNewsDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final destination = ApplyDestination.of(item);
    final published =
        jobPublishedText(item, AppLocalizations.of(context), english: english);
    final deadline = jobValidUntilText(item, english: english);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.jobsDetailTitle),
        actions: [
          IconButton(
            tooltip: l.jobsShare,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => unawaited(_share(context, destination)),
          ),
        ],
      ),
      bottomNavigationBar: _ActionBar(item: item, destination: destination),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (jobSourceTypeLabel(l, item) case final label?) ...[
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: JobChip(
                  label: label,
                  icon: jobSourceTypeIcon(item),
                  emphasis: true,
                ),
              ),
              const SizedBox(height: 12),
            ],
            JobTitleDisplay(
              title: item.title,
              language: item.language,
              maxLines: null,
              style: TextStyle(
                fontSize: 24,
                height: 1.4,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if ((item.company ?? '').trim().isNotEmpty)
                  MetaChip(
                    icon: Icons.apartment_rounded,
                    text: LocaleFormat.mixedTitle(item.company!.trim(),
                        english: english),
                  ),
                if ((item.location ?? '').trim().isNotEmpty)
                  MetaChip(
                      icon: Icons.location_on_outlined,
                      text: item.location!.trim()),
                if (item.isRemote)
                  MetaChip(
                      icon: Icons.laptop_mac_rounded, text: l.jobsRemoteChip),
                if ((item.salaryRange ?? '').isNotEmpty)
                  MetaChip(
                    icon: Icons.payments_outlined,
                    text: item.salaryRange!,
                    highlight: true,
                  ),
                if (published.isNotEmpty)
                  MetaChip(icon: Icons.schedule_rounded, text: published),
                if (deadline.isNotEmpty)
                  MetaChip(
                    icon: Icons.event_rounded,
                    text: deadline,
                    highlight: true,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _HowToApplyCard(item: item, destination: destination),
            if (item.skillsRequired.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(l.jobsSkillsRequired, style: AppTextStyles.titleMd(c)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final skill in item.skillsRequired)
                    JobChip(label: skill),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text(l.jobsDescriptionTitle, style: AppTextStyles.titleMd(c)),
            const SizedBox(height: 8),
            // The server stores the language the post is written in;
            // aggregated posts show in both apps, so the body follows the
            // post, not the app.
            Text(
              LocaleFormat.mixedBody(item.body,
                  english: AppLocale.baseLanguageOf(item.language) == 'en'),
              textDirection: AppLocale.directionOf(item.language),
              textAlign: TextAlign.start,
              style:
                  TextStyle(fontSize: 15.5, height: 1.8, color: c.textPrimary),
            ),
            if ((item.sourceName ?? '').isNotEmpty ||
                parseSafeExternalUrl(item.url) != null) ...[
              const SizedBox(height: 20),
              Divider(color: c.border, height: 1),
              const SizedBox(height: 8),
              _SourceRow(item: item),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, ApplyDestination destination) {
    final english = AppLocale.isEnglish(context);
    final meta = jobMetaLine(item, english: english);
    final link = switch (destination) {
      ApplyLink(:final uri) => uri.toString(),
      ApplyEmail(:final address) => address,
      // The source post (e.g. Telegram) is not an application link.
      ApplyNone() => '',
    };
    final text = [item.title, meta, link].where((s) => s.isNotEmpty).join('\n');
    return Share.share(text, subject: item.title);
  }
}

class _HowToApplyCard extends StatelessWidget {
  const _HowToApplyCard({required this.item, required this.destination});

  final JobNews item;
  final ApplyDestination destination;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;

    final (icon, headline, detail) = switch (destination) {
      ApplyLink(:final displayHost) => (
          Icons.link_rounded,
          l.jobsApplyMethodLink,
          l.jobsApplyOpensHost(ltrIsolate(displayHost)),
        ),
      ApplyEmail(:final address) => (
          Icons.mail_outline_rounded,
          l.jobsApplyEmailHint,
          address,
        ),
      ApplyNone() => (
          Icons.info_outline_rounded,
          l.jobsNoDirectApply,
          item.applyInstructions ?? l.jobsNoDirectApplyHint,
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: destination is ApplyNone ? c.surfaceLow : c.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: destination is ApplyNone ? c.border : c.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.jobsHowToApply,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: c.textSecondary)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: c.primaryInk),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      // A bare email is all Latin: lay it out left-to-right.
                      // The host sentence mixes scripts and isolates the
                      // host itself (ltrIsolate).
                      textDirection:
                          destination is ApplyEmail ? TextDirection.ltr : null,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: destination is ApplyNone
                              ? c.textPrimary
                              : c.primaryInk),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (destination case ApplyEmail(:final address)) ...[
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: () =>
                    unawaited(copyApplicationEmail(context, address)),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: Text(l.jobsCopyEmail),
                style: TextButton.styleFrom(
                  foregroundColor: c.primaryInk,
                  minimumSize: const Size(48, 48),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Where the post was found. Opening it is labelled as viewing the original
/// post, never as applying.
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.item});

  final JobNews item;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final sourceUri = parseSafeExternalUrl(item.url);

    return Row(
      children: [
        Icon(Icons.campaign_outlined, size: 18, color: c.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            (item.sourceName ?? '').isNotEmpty
                ? l.jobsSourceName(item.sourceName!)
                : '',
            style: TextStyle(fontSize: 13, color: c.textSecondary),
          ),
        ),
        if (sourceUri != null)
          TextButton(
            onPressed: () async {
              final opened = await launchSafeExternalUrl(sourceUri.toString());
              if (!opened && context.mounted) {
                AppSnackBar.error(context, l.somethingWentWrong);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: c.primaryInk,
              minimumSize: const Size(48, 48),
            ),
            child: Text(l.jobsViewSourcePost),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.item, required this.destination});

  final JobNews item;
  final ApplyDestination destination;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;

    void tailorCv() => unawaited(Navigator.of(context).pushNamed(
          AppRoutes.createCv,
          // Carries this post into the generator so the CV is actually
          // tailored to it (target title + description).
          arguments: CvTargetJob(title: item.title, description: item.body),
        ));

    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: c.brandSurface,
      foregroundColor: c.onBrandSurface,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    final secondaryStyle = OutlinedButton.styleFrom(
      foregroundColor: c.primaryInk,
      side: BorderSide(color: c.borderStrong),
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    final primary = switch (destination) {
      ApplyLink() => FilledButton.icon(
          onPressed: () =>
              unawaited(openJobApplication(context, item, destination)),
          icon: const Icon(Icons.open_in_new_rounded),
          label: Text(l.jobsApplyNow),
          style: primaryStyle,
        ),
      ApplyEmail() => FilledButton.icon(
          onPressed: () =>
              unawaited(openJobApplication(context, item, destination)),
          icon: const Icon(Icons.mail_outline_rounded),
          label: Text(l.jobsApplyByEmail),
          style: primaryStyle,
        ),
      ApplyNone() => FilledButton.icon(
          onPressed: tailorCv,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(l.jobsTailorCv),
          style: primaryStyle,
        ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              if (destination is! ApplyNone) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: tailorCv,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(l.jobsTailorCv),
                  style: secondaryStyle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
