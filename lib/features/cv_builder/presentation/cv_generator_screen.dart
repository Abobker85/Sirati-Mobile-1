import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/fade_through_page_route.dart';
import 'package:sirati/core/utils/ai_error_message.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/application/cv_draft_store.dart';
import 'package:sirati/features/cv_builder/application/cv_enhancement_controller.dart';
import 'package:sirati/features/cv_builder/application/cv_generation_controller.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/cv_form_controllers.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/draft_restore_banner.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/exit_dialogs.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/steps/education_step.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/steps/experience_step.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/steps/personal_step.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/steps/skills_step.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_footer.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_header.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/achievement_builder_sheet.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/premium/premium_feature.dart';
import 'package:sirati/shared/premium/premium_ui.dart';
import 'package:sirati/shared/services/in_app_review_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/services/notification_engagement_service.dart';
import 'package:sirati/shared/theme/page_surface.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/form_reveal.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/success_beat.dart';
import 'package:sirati/shared/widgets/word_write_in.dart';

/// Four-step CV wizard. Creates a CV, or edits [initialCv] when given.
///
/// This widget owns form/UI state (text controllers, step, validation,
/// dirty tracking, local draft). Network work lives in Riverpod controllers:
/// [CvGenerationController], [CvFieldEnhancer], [JobDescriptionEnhancer].
class CvGeneratorScreen extends ConsumerStatefulWidget {
  const CvGeneratorScreen({super.key, this.initialCv, this.targetJob});

  final GeneratedCv? initialCv;

  /// Job to tailor a new CV for (from a job post). Ignored when editing.
  final CvTargetJob? targetJob;

  @override
  ConsumerState<CvGeneratorScreen> createState() => _CvGeneratorScreenState();
}

class _CvGeneratorScreenState extends ConsumerState<CvGeneratorScreen> {
  static const _stepCount = 4;

  final _fields = CvFormControllers();
  final _stepFormKeys =
      List.generate(_stepCount, (_) => GlobalKey<FormState>());

  /// Whether the user tried to leave each step (drives live validation).
  final _stepSubmitted = List<bool>.filled(_stepCount, false);
  final _stepShowBanner = List<bool>.filled(_stepCount, false);

  /// Review panel data from the last successful enhancement, per field.
  final Map<String, Map<String, dynamic>> _fieldResults = {};

  /// AI text being written into a field, word by word, per field.
  final Map<String, WordWriteIn> _writeIns = {};

  /// UI-only completion pulse counters per field after AI enhancement.
  final Map<String, int> _enhanceBeats = {};

  // Captured in initState: ref cannot be used from dispose().
  late final CvDraftStore _draftStore;

  int _step = 0;

  /// +1 when advancing, -1 when going back (drives the slide direction).
  int _stepDirection = 1;
  String _language = 'ar';
  List<JobTitle> _jobTitles = const [];

  /// True after any user edit since the last save/generate/restore.
  bool _isDirty = false;

  /// Suppresses dirty tracking while the form is filled programmatically.
  bool _suppressDirtyTracking = false;
  Timer? _autosaveTimer;

  /// Create-mode draft offered by the restore banner, if any.
  SavedCvDraft? _pendingDraft;

  bool get _isEditMode => widget.initialCv != null;

  @override
  void initState() {
    super.initState();
    _draftStore = ref.read(cvDraftStoreProvider);

    final cv = widget.initialCv;
    if (cv != null) {
      final data = CvFormData.fromGeneratedCv(cv);
      _fillSilently(data);
      _language = data.language;
    } else if (widget.targetJob case final job?) {
      // Prefill only: a pre-filled form is not a user edit, so it must not
      // mark the draft dirty on its own.
      _suppressDirtyTracking = true;
      _fields.jobTitle.text = job.title;
      _fields.jobDescription.text = job.description;
      _suppressDirtyTracking = false;
    }

    _lastTexts = [for (final c in _fields.all) c.text];
    _fields.addListener(_onAnyFieldChanged);

    unawaited(
      AnalyticsService.logWizardStarted(mode: _isEditMode ? 'edit' : 'create'),
    );
    // Drafts are create-mode only; never offer one while editing a saved CV.
    if (!_isEditMode) unawaited(_loadDraftOffer());
    unawaited(_loadJobTitles());
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    for (final writer in _writeIns.values) {
      writer.cancel();
    }
    _autosaveTimer?.cancel();
    // Flush a pending create-mode draft so pop / background kill keeps data.
    // Read the form before the controllers are disposed below.
    if (!_isEditMode && _isDirty) {
      unawaited(
        _draftStore.save(_fields.read(language: _language), step: _step),
      );
    }
    _fields.removeListener(_onAnyFieldChanged);
    _fields.dispose();
    super.dispose();
  }

  // ── Form state ────────────────────────────────────────────────────────────

  void _fillSilently(CvFormData data) {
    _suppressDirtyTracking = true;
    _fields.fill(data);
    _suppressDirtyTracking = false;
  }

  void _setTextSilently(TextEditingController controller, String text) {
    _suppressDirtyTracking = true;
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
    _suppressDirtyTracking = false;
  }

  /// Field texts at the last notification; controllers also notify on
  /// caret/selection moves (e.g. just focusing a field), which are not edits.
  List<String> _lastTexts = const [];

  void _onAnyFieldChanged() {
    final texts = [for (final c in _fields.all) c.text];
    final changed = !listEquals(texts, _lastTexts);
    _lastTexts = texts;
    if (changed && !_suppressDirtyTracking) _markDirty();
  }

  void _markDirty() {
    if (_suppressDirtyTracking) return;
    if (!_isDirty || _pendingDraft != null) {
      setState(() {
        _isDirty = true;
        // Typing instead of restoring means the user declined the offer.
        _pendingDraft = null;
      });
    }
    if (!_isEditMode) _scheduleAutosave();
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_saveDraft());
    });
  }

  Future<void> _saveDraft() {
    if (_isEditMode) return Future.value();
    return _draftStore.save(_fields.read(language: _language), step: _step);
  }

  void _setLanguage(String code) {
    if (_language == code) return;
    setState(() => _language = code);
    _markDirty();
  }

  Future<void> _loadJobTitles() async {
    try {
      final titles = await ref.read(mobileContentServiceProvider).jobTitles();
      if (mounted) setState(() => _jobTitles = titles);
    } catch (_) {
      // Chip suggestions are optional; the free-text field still works.
    }
  }

  // ── Drafts ────────────────────────────────────────────────────────────────

  Future<void> _loadDraftOffer() async {
    final draft = await _draftStore.read(stepCount: _stepCount);
    if (!mounted || _isEditMode || draft == null) return;
    setState(() => _pendingDraft = draft);
  }

  void _restoreDraft() {
    final draft = _pendingDraft;
    if (draft == null) return;
    unawaited(AnalyticsService.logDraftRestored());
    _fillSilently(draft.data);
    setState(() {
      _language = draft.data.language;
      _stepDirection = 1;
      _step = draft.step;
      _isDirty = false;
      _pendingDraft = null;
    });
  }

  Future<void> _startFresh() async {
    await _draftStore.clear();
    if (mounted) setState(() => _pendingDraft = null);
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Waits for the keyboard to close before a step changes.
  Timer? _stepTimer;

  /// How long the keyboard gets to close before the step slides.
  static const keyboardCloseWait = Duration(milliseconds: 160);

  void _goToStep(int target) {
    if (target == _step || target < 0 || target >= _stepCount) return;
    // One movement at a time: if the keyboard is open, close it first and
    // let it go down, then slide the step (no three things moving at once).
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    FocusManager.instance.primaryFocus?.unfocus();
    _stepTimer?.cancel();
    if (keyboardOpen && !MotionSettings.reduce(context)) {
      _stepTimer = Timer(keyboardCloseWait, () {
        if (mounted) _showStep(target);
      });
    } else {
      _showStep(target);
    }
  }

  void _showStep(int target) {
    if (target == _step) return;
    setState(() {
      _stepDirection = target < _step ? -1 : 1;
      _step = target;
    });
    // Persist the step position immediately (create mode only).
    unawaited(_saveDraft());
  }

  bool _validateCurrentStep() {
    setState(() {
      _stepSubmitted[_step] = true;
      _stepShowBanner[_step] = false;
    });
    // Takes the user to the first field to fix (scroll + focus).
    final ok = validateAndReveal(_stepFormKeys[_step]);
    if (!ok) {
      setState(() => _stepShowBanner[_step] = true);
      unawaited(HapticFeedback.selectionClick());
    }
    return ok;
  }

  /// Footer Next/Generate, and keyboard Done on a step's last field.
  void _onPrimaryAction() {
    if (!_validateCurrentStep()) return;
    unawaited(AnalyticsService.logWizardStepCompleted(step: _step));
    if (_step < _stepCount - 1) {
      _goToStep(_step + 1);
    } else {
      unawaited(_submit());
    }
  }

  Future<void> _handleExitAttempt() async {
    if (!_isDirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_isEditMode) {
      final discard = await confirmDiscardEdits(context);
      if (discard && mounted) {
        unawaited(
          AnalyticsService.logWizardAbandoned(step: _step, dirty: _isDirty),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final action = await askSaveDraft(context);
    if (!mounted) return;
    switch (action) {
      case WizardExitAction.cancel:
        return;
      case WizardExitAction.discard:
        unawaited(
          AnalyticsService.logWizardAbandoned(step: _step, dirty: _isDirty),
        );
        _autosaveTimer?.cancel();
        // Discarded: dispose must not flush the form back as a draft.
        _isDirty = false;
        await _draftStore.clear();
        if (mounted) Navigator.of(context).pop();
      case WizardExitAction.saveDraft:
        _autosaveTimer?.cancel();
        await _saveDraft();
        if (!mounted) return;
        _isDirty = false;
        unawaited(AnalyticsService.logDraftSaved());
        AppSnackBar.info(context, AppLocalizations.of(context).cvDraftSaved);
        Navigator.of(context).pop();
    }
  }

  void _openAchievementBuilder(bool english) {
    AchievementBuilderSheet.show(
      context: context,
      english: english,
      onInsert: (bullet) {
        final updated = appendAchievement(_fields.experience.text, bullet);
        if (updated == null) {
          if (mounted) {
            AppSnackBar.info(
              context,
              AppLocalizations.of(context).cvAchievementDuplicate,
            );
          }
          return;
        }
        _fields.experience.text = updated;
        _markDirty();
        if (mounted) {
          AppSnackBar.success(
            context,
            AppLocalizations.of(context).cvAchievementAdded,
          );
        }
      },
    );
  }

  // ── Generate / update ─────────────────────────────────────────────────────

  Future<void> _submit() async {
    final english = AppLocale.isEnglish(context);
    final generation = ref.read(cvGenerationControllerProvider.notifier);
    final startedAt = DateTime.now();

    final progress = await AiProgressOverlay.show(
      context,
      kind: AiProgressKind.generation,
      english: english,
      onCancelled: () {
        generation.cancel();
        if (mounted) {
          AppSnackBar.info(
              context, AppLocalizations.of(context).cvGenerationCancelled);
        }
      },
    );

    final outcome = await generation.submit(
      data: _fields.read(language: _language),
      editingId: widget.initialCv?.id,
      isCancelled: () => progress.isCancelled,
      onStatus: (status) =>
          progress.setPhase(AiProgressPhase.fromAiStatus(status)),
    );

    switch (outcome) {
      case CvGenerationCancelled():
        // Form stays intact; create-mode autosave already covers the draft.
        await progress.dismiss();

      case CvGenerationFailed(:final error):
        await progress.dismiss();
        unawaited(AnalyticsService.logCvGenerationFailed(
          errorType: error is ApiException ? error.type.name : 'unknown',
        ));
        if (!mounted) return;
        if (error is ApiException) {
          AppSnackBar.fromException(
            context,
            error,
            retryLabel: AppLocalizations.of(context).cvRetryShort,
            onRetry: _submit,
          );
        } else {
          AppSnackBar.error(
            context,
            AppLocalizations.of(context).cvGenerationUnexpectedError,
          );
        }

      case CvGenerated(:final cv, :final timedOut, :final aiFailed):
        refreshUsageIfFree(ref);
        unawaited(AnalyticsService.logCvGenerated(
          templateId: 'default',
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
        ));
        if (!_isEditMode) {
          unawaited(NotificationEngagementService.instance
              .reportConversion('cv_generated'));
          // Successful create: drop the local draft so reopening is clean.
          _autosaveTimer?.cancel();
          await _draftStore.clear();
        }
        if (mounted) setState(() => _isDirty = false);

        // Finish the overlay on a resolved state before it closes.
        if (!timedOut && !aiFailed) await progress.complete();
        final handBack =
            !_isEditMode && (widget.targetJob?.handBackResult ?? false);
        // A new CV opens its own page: the overlay stays (under the
        // celebration) until that page is in place, so the filled form
        // never flashes in between. Every other ending closes it now.
        final opensResult = !_isEditMode && !handBack && !timedOut;
        if (!opensResult) await progress.dismiss();
        if (!mounted) {
          await progress.dismiss();
          return;
        }

        if (handBack) {
          // The opener (e.g. Job Match) continues with this CV and reports
          // its AI state itself; don't stack the preview on top of it.
          Navigator.of(context).pop<GeneratedCv>(cv);
          return;
        }

        if (timedOut) {
          AppSnackBar.warning(
            context,
            AppLocalizations.of(context).cvGenerationStillRunning,
          );
          return;
        }
        if (aiFailed) {
          AppSnackBar.error(
            context,
            AiErrorMessage.generationFailed(
                cv.aiError, AppLocalizations.of(context)),
            actionLabel: AppLocalizations.of(context).retry,
            onAction: _submit,
          );
        }
        // The full scene celebrates a new CV; saving an edit gets the haptic
        // only, so it never uses up the full plays or confetti for a tweak.
        await SuccessBeat.celebrate(context, fullOverlay: !_isEditMode);
        if (!mounted) {
          await progress.dismiss();
          return;
        }
        // Peak satisfaction: OS review prompt after SuccessBeat (create only).
        if (!_isEditMode) {
          unawaited(InAppReviewService.maybeRequestAfterCvGenerated());
        }
        if (_isEditMode) {
          // Hand the saved CV back: the screen that opened the editor shows
          // it, instead of stacking a second copy above a stale one.
          Navigator.of(context).pop<GeneratedCv>(cv);
          return;
        }
        unawaited(progress.handOff(
          Navigator.of(context),
          FadeThroughPageRoute<void>(
            builder: (_) => GeneratedCvScreen(generatedCv: cv),
          ),
        ));
    }
  }

  // ── AI enhancement ────────────────────────────────────────────────────────

  /// AI writing is Premium: a free account is offered Premium first and
  /// the rewrite runs if they come back subscribed.
  Future<bool> _aiWritingAllowed() async {
    if (!currentSubscription().aiWritingLocked) return true;
    return PremiumPromptSheet.show(context, PremiumFeature.aiWriting);
  }

  Future<void> _enhanceField(String field) async {
    if (!await _aiWritingAllowed() || !mounted) return;
    final english = AppLocale.isEnglish(context);
    final controller = _fields.forEnhanceableField(field);
    final draft = controller.text;
    final jobTitle = _fields.jobTitle.text.trim();

    final minimum =
        field == 'experience' ? CvFormData.minExperienceChars : null;
    if (!AiCvField.isSufficientForEnhancement(draft, customMinimum: minimum)) {
      return;
    }
    if (jobTitle.isEmpty) {
      AppSnackBar.warning(
        context,
        AppLocalizations.of(context).cvEnterTargetJobFirst,
      );
      return;
    }

    setState(() => _fieldResults.remove(field));
    final outcome = await ref.read(cvFieldEnhancerProvider.notifier).enhance(
          field: field,
          draft: draft,
          jobTitle: jobTitle,
          language: _language,
        );
    if (!mounted) return;

    switch (outcome) {
      case CvEnhanceStale():
        return;
      case CvEnhanceFailed(:final error):
        _showEnhanceError(
          error,
          english: english,
          onRetry: () => _enhanceField(field),
          fallback: AppLocalizations.of(context).cvEnhanceFieldFailed,
        );
      case CvEnhanced(:final text, :final details):
        // The AI's text writes itself in, a few words at a time.
        _writeIns.remove(field)?.cancel();
        _writeIns[field] = WordWriteIn.start(
          text: text,
          animate: !MotionSettings.reduce(context) &&
              !(MediaQuery.maybeAccessibleNavigationOf(context) ?? false),
          current: () => controller.text,
          write: (shown) {
            if (mounted) _setTextSilently(controller, shown);
          },
        );
        _markDirty();
        setState(() {
          _fieldResults[field] = details;
          _enhanceBeats[field] = (_enhanceBeats[field] ?? 0) + 1;
        });
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).cvFieldEnhanced,
          variant: AppSnackBarVariant.success,
          actionLabel: AppLocalizations.of(context).cvUndo,
          onAction: () {
            if (!mounted) return;
            _writeIns.remove(field)?.cancel();
            _setTextSilently(controller, draft);
            _markDirty();
            setState(() => _fieldResults.remove(field));
          },
        );
    }
  }

  Future<void> _enhanceJobDescription() async {
    if (!await _aiWritingAllowed() || !mounted) return;
    final english = AppLocale.isEnglish(context);
    final targetJobTitle = _fields.jobTitle.text.trim();

    if (targetJobTitle.isEmpty) {
      AppSnackBar.warning(
        context,
        AppLocalizations.of(context).cvEnterTargetJobFirst,
      );
      return;
    }
    if (!AiCvField.isSufficientForEnhancement(_fields.jobDescription.text)) {
      AppSnackBar.warning(
        context,
        AppLocalizations.of(context).cvJobDescriptionTooShort,
      );
      return;
    }

    final outcome =
        await ref.read(jobDescriptionEnhancerProvider.notifier).enhance(
              targetJobTitle: targetJobTitle,
              jobDescription: _fields.jobDescription.text,
              language: _language,
            );
    // The controllers are disposed once the screen is gone; never write
    // into them after an await without this check.
    if (!mounted) return;

    switch (outcome) {
      case CvEnhanceStale():
        return;
      case CvEnhanceFailed(:final error):
        _showEnhanceError(
          error,
          english: english,
          onRetry: _enhanceJobDescription,
          fallback: AppLocalizations.of(context).cvEnhanceJobDescriptionFailed,
        );
      case CvEnhanced(:final text):
        // A real edit: goes through dirty tracking and autosave.
        _fields.jobDescription.text = text;
        setState(() {
          _enhanceBeats['jobDescription'] =
              (_enhanceBeats['jobDescription'] ?? 0) + 1;
        });
        AppSnackBar.success(
          context,
          AppLocalizations.of(context).cvJobDescriptionEnhanced,
        );
    }
  }

  void _showEnhanceError(
    Object error, {
    required bool english,
    required VoidCallback onRetry,
    required String fallback,
  }) {
    if (error is ApiException) {
      AppSnackBar.fromException(
        context,
        error,
        retryLabel: AppLocalizations.of(context).cvRetryShort,
        onRetry: onRetry,
      );
    } else {
      AppSnackBar.error(context, fallback);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  WizardStepProps _propsFor(int step, bool english, String? enhancingField) {
    return WizardStepProps(
      english: english,
      formKey: _stepFormKeys[step],
      submitted: _stepSubmitted[step],
      showErrorBanner: _stepShowBanner[step],
      onDismissErrorBanner: () => setState(() => _stepShowBanner[step] = false),
      fields: _fields,
      enhancingField: enhancingField,
      fieldResults: _fieldResults,
      onEnhance: (field) => unawaited(_enhanceField(field)),
      onDismissResult: (field) => setState(() => _fieldResults.remove(field)),
      onPrimaryAction: _onPrimaryAction,
      enhanceBeats: _enhanceBeats,
    );
  }

  Widget _buildStep(bool english, String? enhancingField) {
    final props = _propsFor(_step, english, enhancingField);
    return switch (_step) {
      0 => PersonalStep(
          props: props,
          language: _language,
          onLanguageChanged: _setLanguage,
          isEnhancingJobDescription: ref.watch(jobDescriptionEnhancerProvider),
          onEnhanceJobDescription: () => unawaited(_enhanceJobDescription()),
        ),
      1 => SkillsStep(props: props, jobTitles: _jobTitles),
      2 => ExperienceStep(
          props: props,
          language: _language,
          onOpenAchievementBuilder: () => _openAchievementBuilder(english),
        ),
      _ => EducationStep(props: props, language: _language),
    };
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final isGenerating = ref.watch(cvGenerationControllerProvider);
    final enhancingField = ref.watch(cvFieldEnhancerProvider);
    final pendingDraft = _pendingDraft;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Clean form: back pops normally. Dirty: intercept and ask first.
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleExitAttempt());
      },
      // Forms sit on the grouped page (iOS 26 restyle).
      child: GroupedSurface(
        child: Scaffold(
          appBar: AppBar(
            title: Text(_isEditMode
                ? AppLocalizations.of(context).cvGeneratorEditTitle
                : AppLocalizations.of(context).cvGeneratorCreateTitle),
            actions: const [
              Padding(
                padding: EdgeInsetsDirectional.only(end: 12),
                child: LanguageToggle(),
              ),
            ],
          ),
          // Only the app bar, the step header and the footer are pinned; the
          // draft offer scrolls with the step, so a small phone with the
          // keyboard open still has room for the field being typed in.
          // Footer at the bottom, header on top with the room left over
          // (it folds its dot row when that room is short), the step in
          // between.
          body: CustomMultiChildLayout(
            delegate: _WizardLayout(),
            children: [
              LayoutId(
                id: _WizardSlot.header,
                child: WizardHeader(
                  step: _step,
                  english: english,
                  onStepTap: _goToStep,
                  // Read above the Scaffold, which hides the inset from its body.
                  keyboardOpen: keyboardOpen,
                ),
              ),
              LayoutId(
                id: _WizardSlot.content,
                child: MotionStepSwitcher(
                  stepKey: _step,
                  direction: _stepDirection,
                  // PageStorageKey: going back to a step returns to where
                  // the user was on it, not to the top.
                  child: ListView(
                    key: PageStorageKey('cv-step-$_step'),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      MotionExpandSlot(
                        child: pendingDraft != null && !_isEditMode
                            ? DraftRestoreBanner(
                                key: const ValueKey('draft-restore-banner'),
                                english: english,
                                savedAt: pendingDraft.savedAt,
                                onStartFresh: () => unawaited(_startFresh()),
                                onRestore: _restoreDraft,
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('draft-restore-empty'),
                              ),
                      ),
                      _buildStep(english, enhancingField),
                    ],
                  ),
                ),
              ),
              LayoutId(
                id: _WizardSlot.footer,
                child: WizardFooter(
                  keyboardOpen: keyboardOpen,
                  english: english,
                  step: _step,
                  stepCount: _stepCount,
                  isEditMode: _isEditMode,
                  isLoading: isGenerating,
                  onBack: () => _goToStep(_step - 1),
                  onPrimary: _onPrimaryAction,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _WizardSlot { header, content, footer }

/// Lays out the wizard: footer (natural height) at the bottom, header
/// (natural height, at most what the footer leaves) on top, the step's
/// scroll view filling the rest.
class _WizardLayout extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    final footer = layoutChild(
      _WizardSlot.footer,
      BoxConstraints.tightFor(width: size.width),
    );
    final header = layoutChild(
      _WizardSlot.header,
      BoxConstraints(
        minWidth: size.width,
        maxWidth: size.width,
        maxHeight: (size.height - footer.height).clamp(0.0, size.height),
      ),
    );
    final content =
        (size.height - header.height - footer.height).clamp(0.0, size.height);
    layoutChild(
      _WizardSlot.content,
      BoxConstraints.tightFor(width: size.width, height: content),
    );
    positionChild(_WizardSlot.header, Offset.zero);
    positionChild(_WizardSlot.content, Offset(0, header.height));
    positionChild(_WizardSlot.footer, Offset(0, size.height - footer.height));
  }

  @override
  bool shouldRelayout(_WizardLayout oldDelegate) => false;
}
