import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/bidi_text_utils.dart';
import 'package:sirati/features/job_match/application/job_match_controller.dart';
import 'package:sirati/features/job_match/domain/job_match_entitlement.dart';
import 'package:sirati/features/job_match/domain/job_match_failure.dart';
import 'package:sirati/features/job_match/domain/job_match_input.dart';
import 'package:sirati/features/job_match/presentation/job_match_messages.dart';
import 'package:sirati/features/job_match/presentation/job_match_result_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';

/// Job Match entry: server-gated (paywall / quota / unavailable), then job
/// details + CV choice → match → [JobMatchResultScreen].
class JobMatchScreen extends ConsumerStatefulWidget {
  const JobMatchScreen({super.key, this.initialCvId});

  final int? initialCvId;

  static const titleFieldKey = ValueKey('jm-title');
  static const descriptionFieldKey = ValueKey('jm-description');
  static const submitKey = ValueKey('jm-submit');
  static const createTailoredKey = ValueKey('jm-create-tailored');
  static Key cvOptionKey(int id) => ValueKey('jm-cv-$id');

  @override
  ConsumerState<JobMatchScreen> createState() => _JobMatchScreenState();
}

class _JobMatchScreenState extends ConsumerState<JobMatchScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  late int? _selectedCvId = widget.initialCvId;
  JobMatchInputError? _inputError;
  bool _pickError = false;
  bool _cvPreparing = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entitlement = ref.watch(jobMatchEntitlementProvider);
    // Keeps the match alive while the result screen is on top.
    final submitting = ref.watch(
      jobMatchControllerProvider.select((s) => s.submitting),
    );
    final hasResult = ref.watch(
      jobMatchControllerProvider.select((s) => s.match != null),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.jobMatchTitle)),
      body: entitlement.when(
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _GateView(
          icon: Icons.cloud_off_rounded,
          title: l.jobMatchEntitlementLoadFailed,
          actionLabel: l.jobMatchRetry,
          onAction: _refreshEntitlement,
        ),
        data: (access) => switch (access.access) {
          JobMatchAccess.allowed =>
            _form(context, access, submitting, hasResult),
          JobMatchAccess.subscriptionRequired => _GateView(
              icon: Icons.workspace_premium_outlined,
              title: l.jobMatchPaywallTitle,
              body: l.jobMatchPaywallBody,
              detail: access.trialDays > 0
                  ? l.jobMatchPaywallTrial(access.trialDays)
                  : null,
              benefits: [
                l.premiumGateJobMatchBenefitScore,
                l.premiumGateJobMatchBenefitKeywords,
                l.premiumGateJobMatchBenefitEdits,
              ],
              primaryLabel: l.premiumGateJobMatchSeePlans,
              onPrimary: _openPlans,
              actionLabel: l.jobMatchPaywallRefresh,
              onAction: _refreshEntitlement,
            ),
          JobMatchAccess.quotaReached => _GateView(
              icon: Icons.hourglass_bottom_rounded,
              title: l.jobMatchQuotaTitle,
              body: l.jobMatchQuotaBody,
              actionLabel: l.jobMatchRetry,
              onAction: _refreshEntitlement,
            ),
          JobMatchAccess.unavailable => _GateView(
              icon: Icons.lock_outline_rounded,
              title: l.jobMatchUnavailableTitle,
              body: l.jobMatchUnavailableBody,
              actionLabel: l.jobMatchRetry,
              onAction: _refreshEntitlement,
            ),
        },
      ),
    );
  }

  void _refreshEntitlement() => ref.invalidate(jobMatchEntitlementProvider);

  /// The plans screen never grants access locally; the server is re-asked
  /// when the user comes back.
  Future<void> _openPlans() async {
    await Navigator.of(context).pushNamed(AppRoutes.premium);
    if (mounted) _refreshEntitlement();
  }

  Widget _form(
    BuildContext context,
    JobMatchEntitlement access,
    bool submitting,
    bool hasResult,
  ) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final cvs = ref.watch(jobMatchSavedCvsProvider);
    final hasCvs = cvs.value?.isNotEmpty ?? false;
    final remaining = access.remaining;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        if (hasResult && !submitting) ...[
          OutlinedButton.icon(
            key: const ValueKey('jm-resume'),
            onPressed: _openResult,
            icon: const Icon(Icons.assessment_outlined),
            label: Text(l.jobMatchResultTitle),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        JobMatchSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.jobMatchEntryTitle,
                style: AppTypography.of(context, AppTypography.headlineMd),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                l.jobMatchEntrySubtitle,
                style: AppTypography.of(
                  context,
                  AppTypography.bodyMd,
                  color: c.textSecondary,
                ),
              ),
              if (remaining != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.jobMatchQuotaRemaining(remaining),
                  style: AppTypography.of(
                    context,
                    AppTypography.labelMd,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        JobMatchSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JobMatchFieldLabel(l.jobMatchJobTitleLabel),
              _BidiField(
                fieldKey: JobMatchScreen.titleFieldKey,
                controller: _title,
                hint: l.jobMatchJobTitleHint,
                onChanged: _clearInputError,
              ),
              _CharCounter(controller: _title, max: JobMatchInput.titleMax),
              const SizedBox(height: AppSpacing.sm),
              JobMatchFieldLabel(l.jobMatchDescriptionLabel),
              _BidiField(
                fieldKey: JobMatchScreen.descriptionFieldKey,
                controller: _description,
                hint: l.jobMatchDescriptionHint,
                multiline: true,
                onChanged: _clearInputError,
              ),
              _CharCounter(
                controller: _description,
                max: JobMatchInput.descriptionMax,
              ),
              if (_inputError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                JobMatchNotice(
                  key: const ValueKey('jm-input-error'),
                  tone: JobMatchTone.error,
                  message: l.jobMatchInputMessage(_inputError!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        cvs.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => JobMatchNotice(
            tone: JobMatchTone.error,
            message: l.jobMatchCvsLoadFailed,
            actionLabel: l.jobMatchRetry,
            onAction: () => ref.invalidate(jobMatchSavedCvsProvider),
          ),
          data: (list) => list.isEmpty
              ? _noCvCard(context, submitting)
              : _cvPicker(context, list),
        ),
        if (_cvPreparing) ...[
          const SizedBox(height: AppSpacing.sm),
          JobMatchNotice(
            tone: JobMatchTone.info,
            message: l.jobMatchCvStillPreparing,
          ),
        ],
        if (hasCvs) ...[
          const SizedBox(height: AppSpacing.lg),
          if (submitting)
            _BusyRow(label: l.jobMatchSubmitting)
          else
            ElevatedButton(
              key: JobMatchScreen.submitKey,
              onPressed: _submit,
              child: Text(l.jobMatchSubmit),
            ),
        ] else if (submitting) ...[
          const SizedBox(height: AppSpacing.lg),
          _BusyRow(label: l.jobMatchSubmitting),
        ],
      ],
    );
  }

  Widget _noCvCard(BuildContext context, bool submitting) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return JobMatchSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.jobMatchNoCvTitle,
            style: AppTypography.of(context, AppTypography.titleMd),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l.jobMatchNoCvBody,
            style: AppTypography.of(
              context,
              AppTypography.bodySm,
              color: c.textSecondary,
            ),
          ),
          if (!submitting) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              key: JobMatchScreen.createTailoredKey,
              onPressed: _createTailoredCv,
              child: Text(l.jobMatchCreateTailoredCv),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cvPicker(BuildContext context, List<GeneratedCv> list) {
    final l = AppLocalizations.of(context);
    final selected = _effectiveCvId(list);
    return JobMatchSection(
      title: l.jobMatchPickCvTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final cv in list)
            _CvOption(
              key: JobMatchScreen.cvOptionKey(cv.id),
              cv: cv,
              selected: cv.id == selected,
              onTap: () => setState(() {
                _selectedCvId = cv.id;
                _pickError = false;
                _cvPreparing = false;
              }),
            ),
          if (_pickError)
            JobMatchNotice(
              key: const ValueKey('jm-pick-error'),
              tone: JobMatchTone.error,
              message: l.jobMatchPickCvRequired,
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: JobMatchScreen.createTailoredKey,
              onPressed: _createTailoredCv,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l.jobMatchOrCreateTailored),
            ),
          ),
        ],
      ),
    );
  }

  /// The chosen CV, or the only one when there is a single saved CV.
  int? _effectiveCvId(List<GeneratedCv> list) {
    final chosen = _selectedCvId;
    if (chosen != null) {
      return list.any((cv) => cv.id == chosen) ? chosen : null;
    }
    return list.length == 1 ? list.single.id : null;
  }

  void _clearInputError(String _) {
    if (_inputError != null) setState(() => _inputError = null);
  }

  /// Validates before any request or [CvTargetJob] exists: [CvTargetJob]
  /// would silently clip an over-long description.
  bool _validateInput() {
    final error = JobMatchInput.validate(
      description: _description.text,
      title: _title.text,
    );
    setState(() => _inputError = error);
    return error == null;
  }

  Future<void> _submit({int? cvId}) async {
    if (ref.read(jobMatchControllerProvider).submitting) return;
    if (!_validateInput()) return;
    final saved = ref.read(jobMatchSavedCvsProvider).value ?? const [];
    final id = cvId ?? _effectiveCvId(saved);
    if (id == null) {
      setState(() => _pickError = true);
      return;
    }
    setState(() {
      _pickError = false;
      _cvPreparing = false;
    });

    final failure = await ref.read(jobMatchControllerProvider.notifier).submit(
          generatedCvId: id,
          jobDescription: _description.text,
          targetJobTitle: _title.text,
        );
    if (!mounted) return;
    if (failure == null) {
      if (ref.read(jobMatchControllerProvider).match == null) return;
      await _openResult();
      return;
    }
    if (failure.affectsEntitlement ||
        failure.kind == JobMatchFailureKind.limitReached) {
      _refreshEntitlement();
    }
    AppSnackBar.error(
      context,
      AppLocalizations.of(context).jobMatchFailureMessage(failure),
    );
  }

  Future<void> _openResult() => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const JobMatchResultScreen()),
      );

  /// Opens the CV generator prefilled with this job; when it hands the new
  /// CV back, selects it and runs the match.
  Future<void> _createTailoredCv() async {
    if (ref.read(jobMatchControllerProvider).submitting) return;
    if (!_validateInput()) return;
    final result = await Navigator.of(context).pushNamed<Object?>(
      AppRoutes.createCv,
      arguments: CvTargetJob(
        title: _title.text,
        description: _description.text,
        handBackResult: true,
      ),
    );
    if (!mounted || result is! GeneratedCv) return;
    ref.invalidate(jobMatchSavedCvsProvider);
    final ready = !AiStatus.isPending(result.aiStatus);
    setState(() {
      _selectedCvId = result.id;
      _pickError = false;
      _cvPreparing = !ready;
    });
    if (ready) await _submit(cvId: result.id);
  }
}

/// Server gate (paywall / quota / unavailable / load failure).
///
/// [actionLabel] always re-asks the server (`jm-gate-action`). The paywall
/// adds benefits and a primary [primaryLabel] that opens the plans screen.
class _GateView extends StatelessWidget {
  const _GateView({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.body,
    this.detail,
    this.benefits = const [],
    this.primaryLabel,
    this.onPrimary,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? detail;
  final List<String> benefits;
  final String actionLabel;
  final VoidCallback onAction;
  final String? primaryLabel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final hasPrimary = primaryLabel != null && onPrimary != null;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        JobMatchSection(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Icon(icon, size: 32, color: c.primaryInk),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.of(context, AppTypography.headlineMd),
              ),
              if (body != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(
                    context,
                    AppTypography.bodyMd,
                    color: c.textSecondary,
                  ),
                ),
              ],
              if (benefits.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final benefit in benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: c.primaryInk,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            benefit,
                            style: AppTypography.of(
                              context,
                              AppTypography.bodyMd,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (detail != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail!,
                  textAlign: TextAlign.center,
                  style: AppTypography.of(
                    context,
                    AppTypography.labelLg,
                    color: c.primaryInk,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (hasPrimary) ...[
                ElevatedButton(
                  key: const ValueKey('jm-gate-plans'),
                  onPressed: onPrimary,
                  child: Text(primaryLabel!),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  key: const ValueKey('jm-gate-action'),
                  onPressed: onAction,
                  child: Text(actionLabel, textAlign: TextAlign.center),
                ),
              ] else
                ElevatedButton(
                  key: const ValueKey('jm-gate-action'),
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Input whose direction follows what was typed or pasted (an English job ad
/// in the Arabic UI reads left-to-right). Label and errors live outside.
class _BidiField extends StatelessWidget {
  const _BidiField({
    required this.fieldKey,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.multiline = false,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final ambient = Directionality.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        key: fieldKey,
        controller: controller,
        onChanged: onChanged,
        textDirection: BidiTextUtils.detectBaseDirection(
          value.text,
          fallback: ambient,
        ),
        minLines: multiline ? 6 : 1,
        maxLines: multiline ? 14 : 1,
        keyboardType: multiline ? TextInputType.multiline : TextInputType.text,
        textInputAction:
            multiline ? TextInputAction.newline : TextInputAction.next,
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}

class _CharCounter extends StatelessWidget {
  const _CharCounter({required this.controller, required this.max});

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final count = value.text.trim().length;
        final over = count > max;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Text(
            l.jobMatchCharCount(count, max),
            textAlign: TextAlign.end,
            style: AppTypography.of(
              context,
              over ? AppTypography.labelLg : AppTypography.labelMd,
              color: over ? c.textPrimary : c.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _CvOption extends StatelessWidget {
  const _CvOption({
    super.key,
    required this.cv,
    required this.selected,
    required this.onTap,
  });

  final GeneratedCv cv;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final jobTitle = cv.targetJobTitle.trim();
    final name = cv.fullName.trim();
    final title = jobTitle.isNotEmpty
        ? jobTitle
        : (name.isNotEmpty ? name : l.jobMatchUntitledCv);
    final subtitle = jobTitle.isNotEmpty && name.isNotEmpty ? name : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: selected ? c.primaryInk : c.textSecondary,
              width: selected ? 2 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: AppRadius.mdAll,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selected ? c.primaryInk : c.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          JobMatchContentText(
                            title,
                            style: AppTypography.of(
                              context,
                              AppTypography.titleSm,
                            ),
                          ),
                          if (subtitle != null)
                            JobMatchContentText(
                              subtitle,
                              style: AppTypography.of(
                                context,
                                AppTypography.bodySm,
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BusyRow extends StatelessWidget {
  const _BusyRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.sirati.primaryInk,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.of(context, AppTypography.labelLg)),
      ],
    );
  }
}
