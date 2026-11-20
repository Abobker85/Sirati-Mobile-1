import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_apply_actions.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_card.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_format.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_title_display.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/app_list_tile.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// One posting: facts, how to apply, the text, and where it came from. The
/// bottom bar's primary action is the real application (link or email);
/// without one, tailoring the CV is primary and nothing pretends to apply.
class JobNewsDetailScreen extends StatefulWidget {
  final JobNews item;

  const JobNewsDetailScreen({super.key, required this.item});

  @override
  State<JobNewsDetailScreen> createState() => _JobNewsDetailScreenState();
}

class _JobNewsDetailScreenState extends State<JobNewsDetailScreen> {
  final _scrollController = ScrollController();
  bool _barElevated = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncBarElevation);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBarElevation());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncBarElevation)
      ..dispose();
    super.dispose();
  }

  void _syncBarElevation() {
    if (!mounted || !_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final elevated = pos.maxScrollExtent > 0 && pos.extentAfter > 4;
    if (elevated != _barElevated) {
      setState(() => _barElevated = elevated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final english = AppLocale.isEnglish(context);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final destination = ApplyDestination.of(item);
    final published =
        jobPublishedText(item, AppLocalizations.of(context), english: english);
    final deadline = jobValidUntilText(item, english: english);

    return GroupedSurface(
        child: Scaffold(
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
      bottomNavigationBar: _ActionBar(
        item: item,
        destination: destination,
        elevated: _barElevated,
      ),
      body: SelectionArea(
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            MotionReveal(
              order: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ],
              ),
            ),
            const SizedBox(height: 20),
            MotionReveal(
              order: 1,
              child: AppListSection(
                children: [
                  if ((item.company ?? '').trim().isNotEmpty)
                    _FactTile(
                      icon: Icons.apartment_rounded,
                      text: LocaleFormat.mixedTitle(item.company!.trim(),
                          english: english),
                    ),
                  if ((item.location ?? '').trim().isNotEmpty)
                    _FactTile(
                        icon: Icons.location_on_outlined,
                        text: item.location!.trim()),
                  if (item.isRemote)
                    _FactTile(
                        icon: Icons.laptop_mac_rounded, text: l.jobsRemoteChip),
                  if ((item.salaryRange ?? '').isNotEmpty)
                    _FactTile(
                      icon: Icons.payments_outlined,
                      text: item.salaryRange!,
                      highlight: true,
                    ),
                  if (published.isNotEmpty)
                    _FactTile(icon: Icons.schedule_rounded, text: published),
                  if (deadline.isNotEmpty)
                    _FactTile(
                      icon: Icons.event_rounded,
                      text: deadline,
                      highlight: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: _sectionGap),
            MotionReveal(
              order: 2,
              child: AppListSection(
                header: l.jobsHowToApply,
                children: [
                  _HowToApplyRow(item: item, destination: destination),
                ],
              ),
            ),
            MotionReveal(
              order: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (item.skillsRequired.isNotEmpty) ...[
                    const SizedBox(height: _sectionGap),
                    AppListSection(
                      header: l.jobsSkillsRequired,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(_sectionInset),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final skill in item.skillsRequired)
                                JobChip(label: skill, fill: c.cardFill),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: _sectionGap),
                  AppListSection(
                    header: l.jobsDescriptionTitle,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(_sectionInset),
                        // The server stores the language the post is written
                        // in; aggregated posts show in both apps, so the body
                        // follows the post, not the app.
                        child: Text(
                          LocaleFormat.mixedBody(item.body,
                              english:
                                  AppLocale.baseLanguageOf(item.language) ==
                                      'en'),
                          textDirection: AppLocale.directionOf(item.language),
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 15.5,
                              height: 1.8,
                              color: c.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  if ((item.sourceName ?? '').isNotEmpty ||
                      parseSafeExternalUrl(item.url) != null) ...[
                    const SizedBox(height: _sectionGap),
                    AppListSection(children: [_SourceRow(item: item)]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Future<void> _share(BuildContext context, ApplyDestination destination) {
    final item = widget.item;
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

/// Space between grouped sections.
const _sectionGap = 24.0;

/// Inner padding of a section that holds free content, not tiles.
const _sectionInset = AppListSection.rowPadding;

/// One fact (employer, place, pay, dates) as a value-only row. [highlight]
/// puts the value in primary ink (pay and deadline).
class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.icon,
    required this.text,
    this.highlight = false,
  });

  final IconData icon;
  final String text;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return AppListTile(
      leadingIcon: icon,
      leadingIconColor: highlight ? c.primaryInk : null,
      title: text,
      titleColor: highlight ? c.primaryInk : null,
      showChevron: false,
    );
  }
}

class _HowToApplyRow extends StatefulWidget {
  const _HowToApplyRow({required this.item, required this.destination});

  final JobNews item;
  final ApplyDestination destination;

  @override
  State<_HowToApplyRow> createState() => _HowToApplyRowState();
}

class _HowToApplyRowState extends State<_HowToApplyRow> {
  bool _copied = false;
  Timer? _copyResetTimer;

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  void _handleCopyEmail(String address) {
    unawaited(copyApplicationEmail(context, address));
    if (!MotionSettings.reduce(context)) {
      unawaited(HapticFeedback.lightImpact());
    }
    setState(() => _copied = true);
    _copyResetTimer?.cancel();
    _copyResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final destination = widget.destination;
    final item = widget.item;

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

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          _sectionInset, 14, _sectionInset, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                              ? c.textSecondary
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
                onPressed: () => _handleCopyEmail(address),
                icon: MotionMorph(
                  morphKey: _copied,
                  child: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                  ),
                ),
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

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
          _sectionInset, 4, _sectionInset / 2, 4),
      child: Row(
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
                final opened =
                    await launchSafeExternalUrl(sourceUri.toString());
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
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.item,
    required this.destination,
    this.elevated = false,
  });

  final JobNews item;
  final ApplyDestination destination;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);

    void tailorCv() => unawaited(Navigator.of(context).pushNamed(
          AppRoutes.createCv,
          // Carries this post into the generator so the CV is actually
          // tailored to it (target title + description).
          arguments: CvTargetJob(title: item.title, description: item.body),
        ));

    // Teal capsule for the real action, grey capsule for tailoring.
    final primaryStyle = jobApplyButtonStyle(c).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
    );
    final secondaryStyle =
        AppTheme.secondaryButtonStyle(c, PageSurface.fillOf(context)).copyWith(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
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

    return AnimatedContainer(
      duration: reduce ? Duration.zero : MotionDurations.fast,
      curve: MotionCurves.state,
      decoration: BoxDecoration(
        // The bar continues the grouped page, above a hairline.
        color: PageSurface.pageColor(c, PageSurface.of(context)),
        border: Border(top: BorderSide(color: c.separator, width: 0.5)),
        boxShadow: elevated
            ? AppShadows.of(c, elevation: AppElevation.raised)
            : const [],
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
