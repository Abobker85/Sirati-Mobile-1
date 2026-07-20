import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/api_exception.dart';
import '../services/cv_api_service.dart';
import '../services/in_app_review_service.dart';
import '../services/mobile_content_service.dart';
import '../services/preference_store.dart';
import '../app_locale.dart';
import '../models/generated_cv.dart';
import '../services/notification_engagement_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/form_fields.dart';
import '../widgets/language_toggle.dart';
import '../widgets/loading/ai_field_loading_overlay.dart';
import '../widgets/loading/ai_progress_overlay.dart';
import '../widgets/motion.dart';
import '../widgets/submit_button.dart';
import '../widgets/success_beat.dart';
import 'generated_cv_screen.dart';

class CvGeneratorScreen extends StatefulWidget {
  final GeneratedCv? initialCv;

  const CvGeneratorScreen({super.key, this.initialCv});

  @override
  State<CvGeneratorScreen> createState() => _CvGeneratorScreenState();
}

class _CvGeneratorScreenState extends State<CvGeneratorScreen> {
  int _step = 0;

  /// +1 when advancing a step, -1 when going back (drives slide direction).
  int _stepDirection = 1;
  bool _isLoading = false;
  bool _isEnhancingJobDescription = false;
  String _language = 'ar';
  final _apiService = CvApiService();
  final _prefs = const PreferenceStore();

  /// Bumped on each submit/cancel so a late AI response cannot apply.
  int _aiRequestGen = 0;

  /// True after any user edit since last successful save/generate or restore.
  bool _isDirty = false;

  /// Suppresses dirty/autosave while programmatically filling controllers.
  bool _suppressDirtyTracking = false;

  Timer? _autosaveTimer;

  /// Pending create-mode draft (non-trivial) offered via restore banner.
  Map<String, dynamic>? _pendingDraft;
  DateTime? _pendingDraftSavedAt;
  bool _showDraftBanner = false;

  // Per-step form keys so validate() only checks fields on the current step.
  final _stepFormKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // Whether the user has attempted to advance from the current step —
  // controls autovalidateMode and the top banner.
  final _stepSubmitted = List<bool>.filled(4, false);
  final _stepShowBanner = List<bool>.filled(4, false);

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _jobDescriptionCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _educationCtrl = TextEditingController();
  final _certsCtrl = TextEditingController();

  static const _steps = ['الشخصية', 'المهارات', 'الخبرات', 'التعليم'];

  bool get _isEditMode => widget.initialCv != null;

  List<TextEditingController> get _allControllers => [
        _nameCtrl,
        _emailCtrl,
        _phoneCtrl,
        _linkedinCtrl,
        _locationCtrl,
        _jobTitleCtrl,
        _jobDescriptionCtrl,
        _summaryCtrl,
        _skillsCtrl,
        _experienceCtrl,
        _educationCtrl,
        _certsCtrl,
      ];

  @override
  void initState() {
    super.initState();
    final cv = widget.initialCv;
    if (cv != null) {
      _suppressDirtyTracking = true;
      _nameCtrl.text = cv.fullName;
      _emailCtrl.text = cv.email ?? '';
      _phoneCtrl.text = cv.phone ?? '';
      _linkedinCtrl.text = cv.linkedin ?? '';
      _locationCtrl.text = cv.location ?? '';
      _jobTitleCtrl.text = cv.targetJobTitle;
      _jobDescriptionCtrl.text = cv.jobDescriptionInput ?? '';
      _language = cv.language;
      _summaryCtrl.text = cv.summaryInput ?? '';
      _skillsCtrl.text = cv.skillsInput;
      _experienceCtrl.text = cv.experienceInput;
      _educationCtrl.text = cv.educationInput;
      _certsCtrl.text = cv.certificationsInput ?? '';
      _suppressDirtyTracking = false;
    }

    for (final c in _allControllers) {
      c.addListener(_onAnyFieldChanged);
    }

    AnalyticsService.logWizardStarted(
      mode: _isEditMode ? 'edit' : 'create',
    );

    // Draft restore only in create mode — never touch drafts while editing.
    if (!_isEditMode) {
      _loadDraftBanner();
    }
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    // Flush pending create-mode draft so a background kill / pop still keeps data.
    if (!_isEditMode && _isDirty) {
      unawaited(_persistDraft());
    }
    for (final c in _allControllers) {
      c.removeListener(_onAnyFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  void _onAnyFieldChanged() {
    if (_suppressDirtyTracking) return;
    _markDirty();
  }

  void _markDirty() {
    if (_suppressDirtyTracking) return;
    final hideBanner = _showDraftBanner;
    if (!_isDirty || hideBanner) {
      setState(() {
        _isDirty = true;
        if (hideBanner) {
          // User chose to type instead of restoring — drop the offer.
          _showDraftBanner = false;
          _pendingDraft = null;
          _pendingDraftSavedAt = null;
        }
      });
    } else {
      _isDirty = true;
    }
    if (!_isEditMode) {
      _scheduleAutosave();
    }
  }

  void _scheduleAutosave() {
    if (_isEditMode) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_persistDraft());
    });
  }

  Future<void> _persistDraft() async {
    if (_isEditMode) return;
    final draft = _serializeDraft();
    // Avoid keeping empty/trivial drafts after the user clears the form.
    if (!_draftIsNonTrivial(draft)) {
      await _clearStoredDraft();
      return;
    }
    try {
      await _prefs.saveCvDraft(draft);
    } catch (_) {
      // Best-effort local persistence — never block the wizard.
    }
  }

  Map<String, dynamic> _serializeDraft() {
    return {
      'schemaVersion': PreferenceStore.cvDraftSchemaVersion,
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'step': _step,
      'language': _language,
      'full_name': _nameCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
      'linkedin': _linkedinCtrl.text,
      'location': _locationCtrl.text,
      'target_job_title': _jobTitleCtrl.text,
      'job_description_input': _jobDescriptionCtrl.text,
      'summary_input': _summaryCtrl.text,
      'skills_input': _skillsCtrl.text,
      'experience_input': _experienceCtrl.text,
      'education_input': _educationCtrl.text,
      'certifications_input': _certsCtrl.text,
    };
  }

  Future<void> _clearStoredDraft() async {
    try {
      await _prefs.clearCvDraft();
    } catch (_) {}
  }

  bool _draftIsNonTrivial(Map<String, dynamic> draft) {
    const fieldKeys = [
      'full_name',
      'email',
      'phone',
      'linkedin',
      'location',
      'target_job_title',
      'job_description_input',
      'summary_input',
      'skills_input',
      'experience_input',
      'education_input',
      'certifications_input',
    ];
    for (final key in fieldKeys) {
      final v = draft[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) return true;
    }
    return false;
  }

  Future<void> _loadDraftBanner() async {
    final draft = await _prefs.readCvDraft();
    if (!mounted || _isEditMode) return;
    if (draft == null || !_draftIsNonTrivial(draft)) return;

    DateTime? savedAt;
    final raw = draft['savedAt']?.toString();
    if (raw != null && raw.isNotEmpty) {
      savedAt = DateTime.tryParse(raw)?.toLocal();
    }

    setState(() {
      _pendingDraft = draft;
      _pendingDraftSavedAt = savedAt;
      _showDraftBanner = true;
    });
  }

  void _restoreDraft() {
    final draft = _pendingDraft;
    if (draft == null) return;

    AnalyticsService.logDraftRestored();

    _suppressDirtyTracking = true;
    _nameCtrl.text = draft['full_name']?.toString() ?? '';
    _emailCtrl.text = draft['email']?.toString() ?? '';
    _phoneCtrl.text = draft['phone']?.toString() ?? '';
    _linkedinCtrl.text = draft['linkedin']?.toString() ?? '';
    _locationCtrl.text = draft['location']?.toString() ?? '';
    _jobTitleCtrl.text = draft['target_job_title']?.toString() ?? '';
    _jobDescriptionCtrl.text = draft['job_description_input']?.toString() ?? '';
    _summaryCtrl.text = draft['summary_input']?.toString() ?? '';
    _skillsCtrl.text = draft['skills_input']?.toString() ?? '';
    _experienceCtrl.text = draft['experience_input']?.toString() ?? '';
    _educationCtrl.text = draft['education_input']?.toString() ?? '';
    _certsCtrl.text = draft['certifications_input']?.toString() ?? '';

    final lang = draft['language']?.toString();
    if (lang == 'en' || lang == 'ar') {
      _language = lang!;
    }

    final stepRaw = draft['step'];
    final step = stepRaw is int
        ? stepRaw
        : int.tryParse(stepRaw?.toString() ?? '') ?? 0;
    final clamped = step.clamp(0, _steps.length - 1);

    setState(() {
      _stepDirection = 1;
      _step = clamped;
      _isDirty = false;
      _showDraftBanner = false;
      _pendingDraft = null;
      _pendingDraftSavedAt = null;
    });
    _suppressDirtyTracking = false;
  }

  Future<void> _startFresh() async {
    await _clearStoredDraft();
    if (!mounted) return;
    setState(() {
      _showDraftBanner = false;
      _pendingDraft = null;
      _pendingDraftSavedAt = null;
    });
  }

  void _goToStep(int target) {
    if (target == _step || target < 0 || target >= _steps.length) return;
    setState(() {
      _stepDirection = target < _step ? -1 : 1;
      _step = target;
    });
    if (!_isEditMode) {
      // Persist step position immediately (create mode only).
      unawaited(_persistDraft());
    }
  }

  Future<void> _handleExitAttempt() async {
    if (!_isDirty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final english = AppLocale.isEnglish(context);
    final c = context.sirati;

    if (_isEditMode) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.surface,
          title: Text(
            english ? 'Discard changes?' : 'تجاهل التعديلات؟',
            style: TextStyle(color: c.textPrimary),
          ),
          content: Text(
            english
                ? 'Your unsaved edits will be lost.'
                : 'ستُفقد تعديلاتك غير المحفوظة.',
            style: TextStyle(color: c.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(english ? 'Cancel' : 'إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: c.red),
              child: Text(english ? 'Discard' : 'تجاهل'),
            ),
          ],
        ),
      );
      if (discard == true && mounted) {
        AnalyticsService.logWizardAbandoned(step: _step, dirty: _isDirty);
        Navigator.of(context).pop();
      }
      return;
    }

    // Create mode: offer draft save.
    final action = await showDialog<_ExitAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(
          english ? 'Save your progress?' : 'حفظ تقدمك؟',
          style: TextStyle(color: c.textPrimary),
        ),
        content: Text(
          english
              ? 'A draft will be kept on this device so you can continue later.'
              : 'سيتم الاحتفاظ بمسودة على هذا الجهاز لتتمكن من المتابعة لاحقاً.',
          style: TextStyle(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.cancel),
            child: Text(english ? 'Cancel' : 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.discard),
            style: TextButton.styleFrom(foregroundColor: c.red),
            child: Text(english ? 'Discard' : 'تجاهل'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _ExitAction.saveDraft),
            child: Text(english ? 'Save draft' : 'حفظ مسودة'),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == _ExitAction.cancel) return;

    if (action == _ExitAction.discard) {
      AnalyticsService.logWizardAbandoned(step: _step, dirty: _isDirty);
      _autosaveTimer?.cancel();
      await _clearStoredDraft();
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Save draft
    _autosaveTimer?.cancel();
    await _persistDraft();
    if (!mounted) return;
    _isDirty = false;
    AnalyticsService.logDraftSaved();
    AppSnackBar.info(
      context,
      english ? 'Draft saved' : 'تم حفظ المسودة',
    );
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    final english = AppLocale.isEnglish(context);
    final requestId = ++_aiRequestGen;
    setState(() => _isLoading = true);
    final startedAt = DateTime.now();

    final progress = await AiProgressOverlay.show(
      context,
      kind: AiProgressKind.generation,
      english: english,
      onCancelled: () {
        // Invalidate this request so a late response is ignored.
        if (_aiRequestGen == requestId) _aiRequestGen++;
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppSnackBar.info(
          context,
          english ? 'Cancelled' : 'تم الإلغاء',
        );
      },
    );

    try {
      final payload = {
        'full_name': _nameCtrl.text.trim(),
        'email': _nullable(_emailCtrl.text),
        'phone': _nullable(_phoneCtrl.text),
        'linkedin': _nullable(_linkedinCtrl.text),
        'location': _nullable(_locationCtrl.text),
        'target_job_title': _jobTitleCtrl.text.trim(),
        'job_description_input': _nullable(_jobDescriptionCtrl.text),
        'language': _language,
        'summary_input': _nullable(_summaryCtrl.text),
        'skills_input': _skillsCtrl.text.trim(),
        'experience_input': _experienceCtrl.text.trim(),
        'education_input': _educationCtrl.text.trim(),
        'certifications_input': _nullable(_certsCtrl.text),
      };

      final generatedCv = _isEditMode
          ? await _apiService.updateGeneratedCv(widget.initialCv!.id, payload)
          : await _apiService.generateCv(payload);

      // Cancelled or superseded — form stays intact (draft autosave covers create).
      if (!mounted ||
          progress.isCancelled ||
          requestId != _aiRequestGen) {
        return;
      }

      final durationMs =
          DateTime.now().difference(startedAt).inMilliseconds;
      AnalyticsService.logCvGenerated(
        templateId: 'default',
        durationMs: durationMs,
      );
      MobileContentService.invalidateCvRelated();
      if (!_isEditMode) {
        NotificationEngagementService.instance.reportConversion('cv_generated');
        // Successful generate: drop local draft so reopen has no banner.
        _autosaveTimer?.cancel();
        await _clearStoredDraft();
        if (!mounted ||
            progress.isCancelled ||
            requestId != _aiRequestGen) {
          return;
        }
        _isDirty = false;
      } else {
        _isDirty = false;
      }
      // Success check + haptic, then navigate (instant when reduced motion).
      await progress.dismiss();
      if (!mounted || requestId != _aiRequestGen) return;
      await SuccessBeat.play(context);
      if (!mounted || requestId != _aiRequestGen) return;
      // Peak satisfaction: OS review after SuccessBeat (create mode only).
      // Fire-and-forget — never block navigation or show a custom rate dialog.
      if (!_isEditMode) {
        unawaited(InAppReviewService.maybeRequestAfterCvGenerated());
      }
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => GeneratedCvScreen(generatedCv: generatedCv)),
      );
    } on ApiException catch (exception) {
      if (progress.isCancelled || requestId != _aiRequestGen) return;
      AnalyticsService.logCvGenerationFailed(
        errorType: exception.type.name,
      );
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: english ? 'Retry' : 'إعادة',
          onRetry: _submit,
        );
      }
    } catch (_) {
      if (progress.isCancelled || requestId != _aiRequestGen) return;
      AnalyticsService.logCvGenerationFailed(errorType: 'unknown');
      if (mounted) {
        _showError(english
            ? 'An unexpected error occurred while generating the CV.'
            : 'حدث خطأ غير متوقع أثناء توليد السيرة.');
      }
    } finally {
      await progress.dismiss();
      if (mounted &&
          requestId == _aiRequestGen &&
          !progress.isCancelled) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _enhanceJobDescription() async {
    final english = AppLocale.isEnglish(context);
    final targetJobTitle = _jobTitleCtrl.text.trim();

    if (targetJobTitle.isEmpty) {
      AppSnackBar.warning(
        context,
        english
            ? 'Enter the target job title first.'
            : 'أدخل المسمى الوظيفي المستهدف أولاً.',
      );
      return;
    }

    setState(() => _isEnhancingJobDescription = true);

    try {
      final data = await _apiService.enhanceJobDescription(
        targetJobTitle: targetJobTitle,
        jobDescription: _jobDescriptionCtrl.text.trim(),
        language: _language,
      );
      final enhanced = data['enhanced_description']?.toString() ?? '';
      if (enhanced.isEmpty) return;
      _jobDescriptionCtrl.text = enhanced;
      if (mounted) {
        AppSnackBar.success(
          context,
          english ? 'Job description enhanced.' : 'تم تحسين الوصف الوظيفي.',
        );
      }
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: english ? 'Retry' : 'إعادة',
          onRetry: _enhanceJobDescription,
        );
      }
    } finally {
      if (mounted) setState(() => _isEnhancingJobDescription = false);
    }
  }

  bool _validateCurrentStep() {
    setState(() {
      _stepSubmitted[_step] = true;
      _stepShowBanner[_step] = false;
    });

    final formState = _stepFormKeys[_step].currentState;
    final ok = formState?.validate() ?? true;
    if (!ok) {
      setState(() => _stepShowBanner[_step] = true);
      HapticFeedback.selectionClick();
    }
    return ok;
  }

  /// Footer Next/Generate and keyboard Done on the last field of a step.
  void _onPrimaryAction() {
    if (!_validateCurrentStep()) return;
    if (_step < _steps.length - 1) {
      AnalyticsService.logWizardStepCompleted(step: _step);
      _goToStep(_step + 1);
    } else {
      AnalyticsService.logWizardStepCompleted(step: _step);
      _submit();
    }
  }

  void _focusNext() {
    FocusScope.of(context).nextFocus();
  }

  void _showError(String message) {
    AppSnackBar.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    // canPop when clean: system / AppBar back pop normally.
    // When dirty, intercept and show exit dialog (does not affect Home PopScope).
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_handleExitAttempt());
      },
      child: Scaffold(
        appBar: AppBar(
          // System back (auto-mirrors in RTL) when this screen is pushed.
          title: Text(_isEditMode
              ? (english ? 'Edit CV' : 'تعديل السيرة')
              : (english ? 'Create CV' : 'إنشاء سيرة ذاتية')),
          actions: const [
            Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: LanguageToggle(),
            ),
          ],
        ),
        // resizeToAvoidBottomInset (default true) keeps the footer above the keyboard.
        body: Column(
          children: [
            Builder(builder: (context) {
              final steps = english
                  ? ['Personal', 'Skills', 'Experience', 'Education']
                  : _steps;
              final progress = (_step + 1) / steps.length;

              return Container(
                color: context.sirati.background,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          english
                              ? 'Step ${_step + 1} of ${steps.length}'
                              : 'خطوة ${_step + 1} من ${steps.length}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.sirati.primary,
                          ),
                        ),
                        Text(
                          steps[_step],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.sirati.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _WizardProgressBar(progress: progress),
                    SizedBox(height: 14),
                    Row(
                      children: List.generate(steps.length * 2 - 1, (i) {
                        if (i.isOdd) {
                          final done = i ~/ 2 < _step;
                          return Expanded(
                              child: Container(
                                  height: 2,
                                  color: done
                                      ? context.sirati.primaryContainer
                                      : context.sirati.surfaceHigh));
                        }
                        final idx = i ~/ 2;
                        final done = idx < _step;
                        final active = idx == _step;
                        final canJump = idx <= _step;
                        return PressScale(
                          enabled: canJump,
                          child: GestureDetector(
                            onTap: canJump && idx != _step
                                ? () => _goToStep(idx)
                                : null,
                            child: AnimatedContainer(
                              duration: MotionSettings.reduce(context)
                                  ? Duration.zero
                                  : MotionDurations.medium,
                              curve: MotionCurves.state,
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: done
                                    ? context.sirati.primaryContainer
                                    : active
                                        ? context.sirati.amberAccent
                                        : context.sirati.surfaceHigh,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: done
                                    ? Icon(Icons.check_rounded,
                                        size: 16, color: Colors.white)
                                    : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text('${idx + 1}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: active
                                                    ? context.sirati.primaryDark
                                                    : context.sirati.textHint)),
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: steps
                          .asMap()
                          .entries
                          .map((e) => Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: e.key <= _step
                                      ? context.sirati.primary
                                      : context.sirati.textHint,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              );
            }),

            if (_showDraftBanner && !_isEditMode) _buildDraftRestoreBanner(english),

            // ── Step content (buttons live in the fixed footer below) ──
            Expanded(
              child: AnimatedSwitcher(
              duration: MotionSettings.reduce(context)
                  ? Duration.zero
                  : MotionDurations.slow,
              switchInCurve: MotionCurves.enter,
              switchOutCurve: MotionCurves.exit,
              transitionBuilder: (child, animation) {
                if (MotionSettings.reduce(context)) return child;
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: MotionCurves.enter,
                  reverseCurve: MotionCurves.exit,
                );

                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: MotionAxis.slideIn(
                        context: context,
                        distance: 0.05,
                        direction: _stepDirection,
                      ),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
              child: ListView(
                key: ValueKey('cv-step-$_step'),
                // Footer is outside the scroll view — modest bottom inset only.
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  if (_step == 0) _buildStep0(english),
                  if (_step == 1) _buildStep1(english),
                  if (_step == 2) _buildStep2(english),
                  if (_step == 3) _buildStep3(english),
                ],
              ),
            ),
          ),

          // ── Fixed CTA bar (stable across step transitions) ──
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                color: context.sirati.surface,
                border: Border(
                  top: BorderSide(color: context.sirati.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(
                      child: PressScale(
                        child: OutlinedButton.icon(
                          onPressed: () => _goToStep(_step - 1),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                          ),
                          label: Text(english ? 'Back' : 'السابق'),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: SubmitButton(
                      label: _step == _steps.length - 1
                          ? (_isEditMode
                              ? (english ? 'Update CV' : 'تحديث السيرة')
                              : (english ? 'Generate CV' : 'توليد السيرة'))
                          : (english ? 'Next' : 'التالي'),
                      loadingLabel:
                          english ? 'Generating...' : 'جارٍ التوليد...',
                      isLoading: _isLoading,
                      icon: _step == _steps.length - 1
                          ? Icons.auto_awesome
                          : Icons.arrow_forward_rounded,
                      onPressed: _onPrimaryAction,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildDraftRestoreBanner(bool english) {
    final c = context.sirati;
    final savedAt = _pendingDraftSavedAt;
    final relative = savedAt != null
        ? LocaleFormat.relativeSavedAt(savedAt, english: english)
        : (english ? 'Draft available' : 'مسودة متاحة');

    return Material(
      color: c.infoLight,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.info.withValues(alpha: .28)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: c.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        english
                            ? 'Continue where you left off?'
                            : 'المتابعة من حيث توقفت؟',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        relative,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => unawaited(_startFresh()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.textSecondary,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(english ? 'Start fresh' : 'البدء من جديد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _restoreDraft,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(english ? 'Restore' : 'استعادة'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldGroup(String label, Widget field, bool english) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(label,
              textAlign: TextAlign.start,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.sirati.textSecondary)),
        ),
        SizedBox(height: 6),
        field,
      ],
    );
  }

  /// Autovalidate mode derived from whether the user has attempted to
  /// advance the given step. Fields validate on every keystroke *after*
  /// the first Next tap, so the UI feels responsive without being noisy
  /// on initial focus.
  AutovalidateMode _autoValidateFor(int step) => _stepSubmitted[step]
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  /// Localised copy for the sticky "please fix the errors below" banner
  /// shown when a step fails validation.
  String _bannerCopy(bool english) => english
      ? 'Please review the highlighted fields before continuing.'
      : 'يرجى مراجعة الحقول المميزة قبل المتابعة.';

  Widget _buildStep0(bool english) {
    return Form(
      key: _stepFormKeys[0],
      autovalidateMode: _autoValidateFor(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            text: english ? 'Personal Information' : 'المعلومات الشخصية',
            english: english,
          ),
          SizedBox(height: 18),
          if (_stepShowBanner[0])
            AppFormErrorBanner(
              message: _bannerCopy(english),
              onDismiss: () => setState(() => _stepShowBanner[0] = false),
            ),
          _fieldGroup(
              english ? 'Full Name *' : 'الاسم الكامل *',
              AppTextFormField(
                controller: _nameCtrl,
                textAlign: TextAlign.start,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusNext(),
                hintText: english ? 'Salem Sayer' : 'سالم سيار',
                prefixIcon: Icon(Icons.person_outline),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? (english
                        ? 'Full name is required.'
                        : 'الاسم الكامل مطلوب.')
                    : null,
              ),
              english),
          SizedBox(height: 14),
          _fieldGroup(
              english ? 'Email' : 'البريد الإلكتروني',
              AppTextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusNext(),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                hintText: 'salem@example.com',
                prefixIcon: Icon(Icons.email_outlined),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return null; // optional
                  if (!email.contains('@')) {
                    return english
                        ? 'Enter a valid email address.'
                        : 'أدخل بريداً إلكترونياً صحيحاً.';
                  }
                  return null;
                },
              ),
              english),
          SizedBox(height: 14),
          _fieldGroup(
              english ? 'Phone' : 'رقم الهاتف',
              AppTextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusNext(),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                hintText: '+966 5X XXX XXXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              english),
          SizedBox(height: 14),
          _fieldGroup(
              english ? 'LinkedIn URL' : 'رابط LinkedIn',
              AppTextFormField(
                controller: _linkedinCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusNext(),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                hintText: 'linkedin.com/in/username',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              english),
          SizedBox(height: 14),
          _fieldGroup(
              english ? 'Target Job Title *' : 'المسمى الوظيفي المستهدف *',
              AppTextFormField(
                controller: _jobTitleCtrl,
                textAlign: TextAlign.start,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusNext(),
                hintText: english
                    ? 'Laravel Backend Developer'
                    : 'مطوّر Laravel Backend',
                prefixIcon: Icon(Icons.work_outline_rounded),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? (english
                        ? 'Target job title is required.'
                        : 'المسمى الوظيفي المستهدف مطلوب.')
                    : null,
              ),
              english),
          SizedBox(height: 14),
          _fieldGroup(
              english
                  ? 'Job Description (optional)'
                  : 'الوصف الوظيفي (اختياري)',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AiFieldLoadingOverlay(
                    isLoading: _isEnhancingJobDescription,
                    statusMessages:
                        AiFieldLoadingOverlay.defaultStatusMessages(
                      english: english,
                    ),
                    semanticsLabel: english
                        ? 'Enhancing job description'
                        : 'جارٍ تحسين الوصف الوظيفي',
                    child: AppTextFormField(
                      controller: _jobDescriptionCtrl,
                      textAlign: TextAlign.start,
                      maxLines: 5,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onPrimaryAction(),
                      enabled: !_isEnhancingJobDescription,
                      hintText: english
                          ? 'Paste the job description or let Sirati complete it from the role...'
                          : 'الصق الوصف الوظيفي أو دع سيرتي يكمله من المسمى...',
                      prefixIcon: Icon(Icons.assignment_outlined),
                    ),
                  ),
                  SizedBox(height: 10),
                  SubmitButton(
                    label: english ? 'Enhance' : 'تحسين',
                    loadingLabel: english ? 'Enhancing...' : 'جارٍ التحسين...',
                    isLoading: _isEnhancingJobDescription,
                    outlined: true,
                    height: 44,
                    icon: Icons.auto_fix_high_rounded,
                    onPressed: _isEnhancingJobDescription
                        ? null
                        : _enhanceJobDescription,
                  ),
                ],
              ),
              english),
          SizedBox(height: 18),
          _FieldLabel(
            text: english ? 'CV Language' : 'لغة السيرة الذاتية',
            english: english,
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.sirati.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.sirati.border),
            ),
            child: Row(
              children: [
                Expanded(
                    child: _LangOption(
                        label: 'English',
                        value: 'en',
                        selected: _language == 'en',
                        onTap: () => _setCvLanguage('en'))),
                Expanded(
                    child: _LangOption(
                        label: 'العربية',
                        value: 'ar',
                        selected: _language == 'ar',
                        onTap: () => _setCvLanguage('ar'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _setCvLanguage(String code) {
    if (_language == code) return;
    setState(() => _language = code);
    _markDirty();
  }

  Widget _buildStep1(bool english) {
    return Form(
      key: _stepFormKeys[1],
      autovalidateMode: _autoValidateFor(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            text: english ? 'Skills & Summary' : 'المهارات والملخص',
            english: english,
          ),
          SizedBox(height: 6),
          _HelperText(
            text: english
                ? 'Enter skills separated by commas'
                : 'أدخل مهاراتك مفصولة بفاصلة',
            english: english,
          ),
          SizedBox(height: 18),
          if (_stepShowBanner[1])
            AppFormErrorBanner(
              message: _bannerCopy(english),
              onDismiss: () => setState(() => _stepShowBanner[1] = false),
            ),
          _fieldGroup(
              english ? 'Core Skills *' : 'المهارات الأساسية *',
              AppTextFormField(
                controller: _skillsCtrl,
                textAlign: TextAlign.start,
                maxLines: 4,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusNext(),
                hintText: english
                    ? 'PHP, Laravel, API, SQL, Git, Agile, Docker'
                    : 'PHP، Laravel، API، SQL، Git، Agile، Docker',
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? (english
                        ? 'Core skills are required.'
                        : 'المهارات الأساسية مطلوبة.')
                    : null,
              ),
              english),
          SizedBox(height: 14),
          _fieldGroup(
              english
                  ? 'Professional Summary (optional)'
                  : 'الملخص المهني (اختياري، سيُولَّد تلقائياً)',
              AppTextFormField(
                controller: _summaryCtrl,
                textAlign: TextAlign.start,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onPrimaryAction(),
                hintText: english
                    ? 'Briefly describe your experience and achievements...'
                    : 'نبذة مختصرة عن خبرتك وإنجازاتك...',
              ),
              english),
        ],
      ),
    );
  }

  Widget _buildStep2(bool english) {
    return Form(
      key: _stepFormKeys[2],
      autovalidateMode: _autoValidateFor(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            text: english ? 'Work Experience' : 'الخبرات العملية',
            english: english,
          ),
          SizedBox(height: 6),
          _HelperText(
            text: english
                ? 'Include title, company, dates, and measurable achievements'
                : 'اذكر المسمى، الشركة، التاريخ، والإنجازات بأرقام',
            english: english,
          ),
          SizedBox(height: 18),
          if (_stepShowBanner[2])
            AppFormErrorBanner(
              message: _bannerCopy(english),
              onDismiss: () => setState(() => _stepShowBanner[2] = false),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: context.sirati.primaryLight,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        english
                            ? 'Numbers like 35% or 20 users improve your ATS score.'
                            : 'كلما ذكرت أرقاماً (35%، 20 مستخدم)، زادت درجة ATS',
                        style: TextStyle(
                            fontSize: 12, color: context.sirati.primaryDark),
                        textAlign: TextAlign.start)),
                SizedBox(width: 8),
                Icon(Icons.tips_and_updates_outlined,
                    color: context.sirati.primary, size: 20),
              ],
            ),
          ),
          SizedBox(height: 12),
          AppTextFormField(
            controller: _experienceCtrl,
            textAlign: TextAlign.start,
            maxLines: 10,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onPrimaryAction(),
            hintText: english
                ? 'Backend developer, Company X, 2021–2025\n- Built APIs used by 25 internal teams\n- Improved SQL performance by 35%\n- Integrated APIs that cut data entry by 20%'
                : 'مطور Backend، شركة X، 2021–2025\n- طورت APIs تستخدمها 25 فرقة داخلية\n- حسّنت أداء SQL بنسبة 35%\n- بنيت تكاملات API خفّضت الإدخال 20%',
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.length < 80) {
                return english
                    ? 'Write at least 80 characters about your experience.'
                    : 'اكتب الخبرات العملية بتفاصيل لا تقل عن 80 حرفاً.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(bool english) {
    return Form(
      key: _stepFormKeys[3],
      autovalidateMode: _autoValidateFor(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            text: english ? 'Education & Certifications' : 'التعليم والشهادات',
            english: english,
          ),
          SizedBox(height: 18),
          if (_stepShowBanner[3])
            AppFormErrorBanner(
              message: _bannerCopy(english),
              onDismiss: () => setState(() => _stepShowBanner[3] = false),
            ),
          _fieldGroup(
              english ? 'Education *' : 'التعليم *',
              AppTextFormField(
                controller: _educationCtrl,
                textAlign: TextAlign.start,
                maxLines: 4,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusNext(),
                hintText: english
                    ? 'BSc Computer Science, King Abdulaziz University, 2020'
                    : 'بكالوريوس علوم الحاسب، جامعة الملك عبدالعزيز، 2020',
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? (english ? 'Education is required.' : 'التعليم مطلوب.')
                    : null,
              ),
              english),
          SizedBox(height: 14),
          _fieldGroup(
              english
                  ? 'Certifications & Courses (optional)'
                  : 'الشهادات والدورات (اختياري)',
              AppTextFormField(
                controller: _certsCtrl,
                textAlign: TextAlign.start,
                maxLines: 4,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onPrimaryAction(),
                hintText: english
                    ? 'AWS Certified Cloud Practitioner, 2023\nGoogle Cloud Associate, 2022'
                    : 'AWS Certified Cloud Practitioner، 2023\nGoogle Cloud Associate، 2022',
              ),
              english),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;
  final bool english;

  const _SectionHeading({required this.text, required this.english});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.sirati.primaryDark),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool english;

  const _FieldLabel({required this.text, required this.english});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.sirati.textSecondary),
      ),
    );
  }
}

/// Thin wizard progress fill — grows from the start edge (LTR left / RTL right).
class _WizardProgressBar extends StatefulWidget {
  final double progress;

  const _WizardProgressBar({required this.progress});

  @override
  State<_WizardProgressBar> createState() => _WizardProgressBarState();
}

class _WizardProgressBarState extends State<_WizardProgressBar> {
  /// Stable tween so rebuilds do not restart; begin tracks last settled value.
  late Tween<double> _tween =
      Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0));

  @override
  void didUpdateWidget(covariant _WizardProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.progress.clamp(0.0, 1.0);
    final prev = oldWidget.progress.clamp(0.0, 1.0);
    if (next != prev) {
      _tween = Tween<double>(begin: prev, end: next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.progress.clamp(0.0, 1.0);
    final reduce = MotionSettings.reduce(context);

    Widget fill(double factor) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: factor,
          heightFactor: 1,
          child: ColoredBox(color: context.sirati.primary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: ColoredBox(
          color: context.sirati.border,
          child: reduce
              ? fill(target)
              : TweenAnimationBuilder<double>(
                  // Key forces a new controller when the target step changes.
                  key: ValueKey(target),
                  tween: _tween,
                  duration: MotionDurations.slow,
                  curve: MotionCurves.state,
                  builder: (context, value, _) => fill(value),
                ),
        ),
      ),
    );
  }
}

class _HelperText extends StatelessWidget {
  final String text;
  final bool english;

  const _HelperText({required this.text, required this.english});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(fontSize: 13, color: context.sirati.textSecondary),
      ),
    );
  }
}

enum _ExitAction { cancel, discard, saveDraft }

class _LangOption extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? context.sirati.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? Colors.white : context.sirati.textSecondary,
          ),
        ),
      ),
    );
  }
}
