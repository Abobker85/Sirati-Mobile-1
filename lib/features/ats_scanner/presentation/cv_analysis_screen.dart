import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/ai_error_message.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/idempotency_key.dart';
import 'package:sirati/features/ats_scanner/application/saved_analysis_cvs.dart';
import 'package:sirati/features/ats_scanner/domain/analysis_draft.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result_screen.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis/analysis_form_sections.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/notification_engagement_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Polling waits while the app is not in the foreground; background time
/// doesn't count toward the poll timeout.
bool pausesPolling(AppLifecycleState state) =>
    state == AppLifecycleState.paused ||
    state == AppLifecycleState.hidden ||
    state == AppLifecycleState.detached;

enum AnalysisCvSource { saved, upload }

class CvAnalysisScreen extends ConsumerStatefulWidget {
  const CvAnalysisScreen({
    super.key,
    this.savedCvs,
    this.onRetrySaved,
    this.initialCvId,
    this.initialMarkdown,
    this.initialJobTitle,
    this.initialJobDescription,
    this.initialSource = AnalysisCvSource.saved,
  });

  final AsyncValue<List<SavedAnalysisCv>>? savedCvs;
  final VoidCallback? onRetrySaved;
  final int? initialCvId;

  /// Text supplied for [initialCvId]. Blank text uses the saved-CV fetch path.
  final String? initialMarkdown;

  /// Prefill for the target job title / description (e.g. from the CV hub).
  final String? initialJobTitle;
  final String? initialJobDescription;

  /// Source tab selected on open (the upload tile opens on [AnalysisCvSource.upload]).
  final AnalysisCvSource initialSource;

  @override
  ConsumerState<CvAnalysisScreen> createState() => _CvAnalysisScreenState();
}

class _CvAnalysisScreenState extends ConsumerState<CvAnalysisScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _keys = IdempotencyKeyRing(newIdempotencyKey);
  PlatformFile? _uploadedFile;
  bool _isLoading = false;
  bool _submitted = false;
  late AnalysisCvSource _source = widget.initialSource;
  int? _selectedCvId;

  /// Bumped on each submit/cancel so a late AI response cannot apply.
  int _aiRequestGen = 0;
  bool _pollingPaused = false;

  @override
  void initState() {
    super.initState();
    _selectedCvId = widget.initialCvId;
    _jobTitleController.text = widget.initialJobTitle?.trim() ?? '';
    _jobDescriptionController.text = widget.initialJobDescription?.trim() ?? '';
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _pollingPaused = pausesPolling(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  String? get _selectedInitialMarkdown {
    final markdown = widget.initialMarkdown;
    return _selectedCvId != null &&
            _selectedCvId == widget.initialCvId &&
            markdown?.trim().isNotEmpty == true
        ? markdown
        : null;
  }

  String get _savedResumeText {
    final supplied = _selectedInitialMarkdown;
    if (supplied != null) return supplied;
    final id = _selectedCvId;
    return id == null
        ? ''
        : ref.read(analysisSavedCvProvider(id)).value?.resumeText ?? '';
  }

  AnalysisDraft get _draft => AnalysisDraft(
        jobTitle: _jobTitleController.text,
        jobDescription: _jobDescriptionController.text,
        resumeText: _source == AnalysisCvSource.saved ? _savedResumeText : '',
        fileName:
            _source == AnalysisCvSource.upload ? _uploadedFile?.name : null,
        fileSize:
            _source == AnalysisCvSource.upload ? _uploadedFile?.size : null,
      );

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AnalysisLimits.allowedExtensions,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    switch (AnalysisRules.upload(name: file.name, size: file.size)) {
      case UploadRejection.tooLarge:
        AppSnackBar.error(
          context,
          AppLocalizations.of(context)
              .atsFileTooLarge(AnalysisLimits.maxUploadBytes ~/ (1024 * 1024)),
        );
      case UploadRejection.unsupportedType:
        AppSnackBar.error(
          context,
          AppLocalizations.of(context).atsUnsupportedFileType,
        );
      case null:
        setState(() => _uploadedFile = file);
    }
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    final english = AppLocale.isEnglish(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      unawaited(HapticFeedback.selectionClick());
      return;
    }
    final AsyncValue<List<SavedAnalysisCv>> saved =
        widget.savedCvs ?? ref.read(analysisSavedCvsProvider(english));
    if (_source == AnalysisCvSource.saved &&
        (_selectedCvId == null ||
            saved.value?.any((cv) => cv.id == _selectedCvId) != true ||
            _savedResumeText.trim().isEmpty)) {
      AppSnackBar.error(
        context,
        AppLocalizations.of(context).atsInputSelectSourceRequired,
      );
      return;
    }
    final draft = _draft;
    if (!draft.hasResume) {
      AppSnackBar.error(
        context,
        AppLocalizations.of(context).atsResumeRequired,
      );
      return;
    }
    final api = ref.read(cvApiServiceProvider);
    final requestId = ++_aiRequestGen;
    final idempotencyKey = _keys.keyFor(draft);
    setState(() => _isLoading = true);
    final startedAt = DateTime.now();
    unawaited(AnalyticsService.logAnalysisStarted());

    final progress = await AiProgressOverlay.show(
      context,
      kind: AiProgressKind.analysis,
      english: english,
      onCancelled: () {
        if (_aiRequestGen == requestId) _aiRequestGen++;
        if (!mounted) return;
        setState(() => _isLoading = false);
        AppSnackBar.info(context, AppLocalizations.of(context).atsCancelled);
      },
    );
    bool stale() =>
        !mounted || progress.isCancelled || requestId != _aiRequestGen;

    try {
      final resumeFile = await _multipartFile();
      if (stale()) return;

      var analysis = await api.submitAnalysis(
        targetJobTitle: draft.jobTitle.trim(),
        jobDescription: draft.jobDescription,
        resumeText: draft.resumeText,
        resumeFile: resumeFile,
        idempotencyKey: idempotencyKey,
      );
      progress.setPhase(AiProgressPhase.fromAiStatus(analysis.aiStatus));

      final poll = await api.pollAnalysis(
        analysis,
        isCancelled: () => progress.isCancelled || requestId != _aiRequestGen,
        isPaused: () => _pollingPaused,
        onProgress: (value) =>
            progress.setPhase(AiProgressPhase.fromAiStatus(value.aiStatus)),
      );
      analysis = poll.value;
      if (poll.cancelled || stale()) return;

      // The server has a result for this draft; an identical resubmit is
      // now a new analysis.
      _keys.consume();
      unawaited(
        AnalyticsService.logAnalysisCompleted(
          // Bucketed by the service — never the exact score.
          score: analysis.scoreTotal,
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
        ),
      );
      final aiFailed = analysis.aiStatus == AiStatus.failed;
      if (!poll.timedOut && !aiFailed) await progress.complete();
      await progress.dismiss();
      if (!mounted || stale()) return;

      if (poll.timedOut) {
        AppSnackBar.warning(
          context,
          AppLocalizations.of(context).atsAiStillWorkingAnalysis,
        );
      } else if (aiFailed) {
        AppSnackBar.error(
          context,
          AiErrorMessage.suggestionsFailed(
              analysis.aiError, AppLocalizations.of(context)),
          actionLabel: AppLocalizations.of(context).retry,
          onAction: () => unawaited(_submit()),
        );
      }
      unawaited(HapticFeedback.lightImpact());
      unawaited(
        NotificationEngagementService.instance.reportConversion(
          'analysis_completed',
        ),
      );
      final warning = analysis.classificationWarning;
      if (warning != null) {
        AppSnackBar.warning(
          context,
          english
              ? 'This file may not be a resume. Analysis results may not be accurate.'
              : warning,
        );
      }
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(analysis: analysis),
          ),
        ),
      );
    } on ApiException catch (exception) {
      if (progress.isCancelled || requestId != _aiRequestGen) return;
      unawaited(
        AnalyticsService.logAnalysisFailed(errorType: exception.type.name),
      );
      if (mounted) AppSnackBar.fromException(context, exception);
    } catch (_) {
      if (progress.isCancelled || requestId != _aiRequestGen) return;
      unawaited(AnalyticsService.logAnalysisFailed(errorType: 'unknown'));
      if (mounted) {
        AppSnackBar.error(
          context,
          AppLocalizations.of(context).atsAnalyzeUnexpectedError,
        );
      }
    } finally {
      await progress.dismiss();
      if (mounted && requestId == _aiRequestGen && !progress.isCancelled) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<http.MultipartFile?> _multipartFile() async {
    final file = _source == AnalysisCvSource.upload ? _uploadedFile : null;
    if (file == null) return null;
    final bytes = file.bytes;
    if (bytes != null) {
      return http.MultipartFile.fromBytes(
        'resume_file',
        bytes,
        filename: file.name,
      );
    }
    final path = file.path;
    if (path != null) {
      return http.MultipartFile.fromPath(
        'resume_file',
        path,
        filename: file.name,
      );
    }
    return null;
  }

  AutovalidateMode get _autovalidate => _submitted
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final AsyncValue<List<SavedAnalysisCv>> saved =
        widget.savedCvs ?? ref.watch(analysisSavedCvsProvider(english));
    final rows = saved.value ?? const <SavedAnalysisCv>[];
    // An explicit CV must never silently fall back to a different record.
    _selectedCvId ??=
        widget.initialCvId ?? (rows.isEmpty ? null : rows.first.id);
    final selectedId =
        rows.any((cv) => cv.id == _selectedCvId) ? _selectedCvId : null;
    final detail = _source == AnalysisCvSource.saved &&
            selectedId != null &&
            _selectedInitialMarkdown == null
        ? ref.watch(analysisSavedCvProvider(selectedId))
        : null;
    final file = _uploadedFile;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.textSecondary),
    );
    InputDecoration decoration(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: c.surface,
          enabledBorder: fieldBorder,
          focusedBorder: fieldBorder.copyWith(
            borderSide: BorderSide(color: c.primaryInk, width: 2),
          ),
          hintStyle: TextStyle(color: c.textSecondary),
        );
    Widget section(String title, Widget child) => AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        );
    void retry() {
      widget.onRetrySaved?.call();
      ref.invalidate(analysisSavedCvsProvider(english));
      if (selectedId != null) {
        ref.invalidate(analysisSavedCvProvider(selectedId));
      }
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight:
            56 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
        title: Text(l.atsInputTitle),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SubmitButton(
              key: const ValueKey('ats-input-docked-analyze'),
              label: l.atsInputAnalyze,
              loadingLabel: l.atsInputAnalyzing,
              isLoading: _isLoading,
              icon: Icons.analytics_outlined,
              onPressed: () => unawaited(_submit()),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.atsInputIntroduction,
                style: TextStyle(color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              section(
                l.atsInputCvSource,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked =
                            MediaQuery.textScalerOf(context).scale(14) > 21;
                        final buttons = [
                          for (final source in AnalysisCvSource.values)
                            Semantics(
                              selected: _source == source,
                              child: OutlinedButton(
                                key: ValueKey(source),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  backgroundColor: _source == source
                                      ? c.primaryLight
                                      : c.surface,
                                  foregroundColor: _source == source
                                      ? c.primaryInk
                                      : c.textSecondary,
                                  side: BorderSide(
                                    color: _source == source
                                        ? c.primaryInk
                                        : c.textSecondary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () => setState(() => _source = source),
                                child: Text(
                                    switch (source) {
                                      AnalysisCvSource.saved =>
                                        l.atsInputSavedCv,
                                      AnalysisCvSource.upload =>
                                        l.atsInputUploadFile,
                                    },
                                    textAlign: TextAlign.center),
                              ),
                            ),
                        ];
                        return stacked
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: buttons,
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < buttons.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 6),
                                    Expanded(child: buttons[i]),
                                  ],
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_source == AnalysisCvSource.saved) ...[
                      if (saved.isLoading) Text(l.savedCvsLoading),
                      if (saved.hasError) ...[
                        Text(l.atsInputSavedCvsError),
                        TextButton(onPressed: retry, child: Text(l.retry)),
                      ] else if (!saved.isLoading && rows.isEmpty)
                        Text(l.atsInputNoSavedCvs),
                      if (rows.isNotEmpty) ...[
                        DropdownButtonFormField<int>(
                          key: ValueKey(selectedId),
                          initialValue: selectedId,
                          isExpanded: true,
                          itemHeight: null,
                          decoration: decoration(l.atsInputSelectCv),
                          items: [
                            for (final cv in rows)
                              DropdownMenuItem(
                                value: cv.id,
                                child: Text(
                                  cv.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _isLoading
                              ? null
                              : (id) => setState(() => _selectedCvId = id),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.atsInputSavedCvHint,
                          style: TextStyle(color: c.textSecondary),
                        ),
                        if (detail?.isLoading == true) Text(l.savedCvsLoading),
                        if (detail?.hasError == true) ...[
                          Text(l.atsInputSavedCvsError),
                          TextButton(onPressed: retry, child: Text(l.retry)),
                        ] else if (detail?.value?.generatedMarkdown
                                .trim()
                                .isEmpty ==
                            true)
                          Text(l.atsInputCvTextUnavailable),
                      ],
                    ],
                    if (_source == AnalysisCvSource.upload)
                      if (file == null)
                        UploadDropZone(onTap: () => unawaited(_pickFile()))
                      else
                        SelectedFileTile(
                          fileName: file.name,
                          onRemove: () => setState(() => _uploadedFile = null),
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              section(
                l.atsInputJobTitle,
                TextFormField(
                  key: const ValueKey('ats-input-job-title'),
                  controller: _jobTitleController,
                  autovalidateMode: _autovalidate,
                  textInputAction: TextInputAction.next,
                  decoration: decoration(l.atsInputJobTitleHint),
                  validator: (v) => switch (AnalysisRules.jobTitle(v)) {
                    AnalysisFieldError.required => l.atsInputJobTitleRequired,
                    AnalysisFieldError.tooLong => l.atsInputJobTitleTooLong(
                        AnalysisLimits.jobTitleMax,
                      ),
                    null => null,
                  },
                ),
              ),
              const SizedBox(height: 16),
              section(
                l.atsInputJobDescription,
                Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('ats-input-job-description'),
                      controller: _jobDescriptionController,
                      minLines: 5,
                      maxLines: null,
                      autovalidateMode: _autovalidate,
                      decoration: decoration(l.atsInputJobDescriptionHint),
                      onChanged: (_) => setState(() {}),
                      validator: (v) => AnalysisRules.jobDescription(v) == null
                          ? null
                          : l.atsInputJobDescriptionTooLong(
                              AnalysisLimits.jobDescriptionMax,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(
                        '${_jobDescriptionController.text.length} / ${AnalysisLimits.jobDescriptionMax}',
                        style: TextStyle(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 12),
              Text(
                l.atsInputPrivacy,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
