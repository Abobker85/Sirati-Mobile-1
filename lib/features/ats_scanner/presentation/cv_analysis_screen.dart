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

enum AnalysisCvSource { saved, upload, paste }

class CvAnalysisScreen extends ConsumerStatefulWidget {
  const CvAnalysisScreen({super.key, this.savedCvs, this.onRetrySaved});

  final AsyncValue<List<SavedAnalysisCv>>? savedCvs;
  final VoidCallback? onRetrySaved;

  @override
  ConsumerState<CvAnalysisScreen> createState() => _CvAnalysisScreenState();
}

class _CvAnalysisScreenState extends ConsumerState<CvAnalysisScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _resumeTextController = TextEditingController();
  final _keys = IdempotencyKeyRing(newIdempotencyKey);
  PlatformFile? _uploadedFile;
  bool _isLoading = false;
  bool _submitted = false;
  AnalysisCvSource _source = AnalysisCvSource.saved;
  int? _selectedCvId;

  /// Bumped on each submit/cancel so a late AI response cannot apply.
  int _aiRequestGen = 0;
  bool _pollingPaused = false;

  @override
  void initState() {
    super.initState();
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
    _resumeTextController.dispose();
    super.dispose();
  }

  AnalysisDraft get _draft => AnalysisDraft(
    jobTitle: _jobTitleController.text,
    jobDescription: _jobDescriptionController.text,
    resumeText: _source == AnalysisCvSource.saved
        ? (ref
                  .read(analysisSavedCvProvider(_selectedCvId!))
                  .value
                  ?.generatedMarkdown ??
              '')
        : _source == AnalysisCvSource.paste
        ? _resumeTextController.text
        : '',
    fileName: _source == AnalysisCvSource.upload ? _uploadedFile?.name : null,
    fileSize: _source == AnalysisCvSource.upload ? _uploadedFile?.size : null,
  );

  Future<void> _pickFile() async {
    final english = AppLocale.isEnglish(context);
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
          english
              ? 'File must be 5 MB or smaller.'
              : 'يجب أن يكون حجم الملف 5 ميغابايت أو أقل.',
        );
      case UploadRejection.unsupportedType:
        AppSnackBar.error(
          context,
          english
              ? 'Only PDF or TXT files are supported.'
              : 'يُدعم فقط ملف PDF أو TXT.',
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
    if (_source == AnalysisCvSource.saved &&
        (_selectedCvId == null ||
            ref
                    .read(analysisSavedCvProvider(_selectedCvId!))
                    .value
                    ?.generatedMarkdown
                    .trim()
                    .isNotEmpty !=
                true)) {
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
        english
            ? 'Paste resume text or upload a PDF/TXT file to start.'
            : 'الصق نص السيرة أو ارفع ملف PDF/TXT للبدء.',
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
        AppSnackBar.info(context, english ? 'Cancelled' : 'تم الإلغاء');
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
          english
              ? 'AI is still working. Your ATS score is ready, and you can retry the AI suggestions later.'
              : 'لا يزال الذكاء الاصطناعي يعمل. نتيجتك الأساسية جاهزة، ويمكنك إعادة محاولة التوصيات لاحقاً.',
        );
      } else if (aiFailed) {
        AppSnackBar.error(
          context,
          AiErrorMessage.suggestionsFailed(analysis.aiError, english: english),
          actionLabel: english ? 'Retry' : 'إعادة المحاولة',
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
          english
              ? 'An unexpected error occurred while analyzing the CV.'
              : 'حدث خطأ غير متوقع أثناء تحليل السيرة.',
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
    final selectedId = rows.any((cv) => cv.id == _selectedCvId)
        ? _selectedCvId
        : (rows.isEmpty ? null : rows.first.id);
    _selectedCvId = selectedId;
    final detail = _source == AnalysisCvSource.saved && selectedId != null
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
            style: TextStyle(fontWeight: FontWeight.w700, color: c.textPrimary),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(l.atsInputIntroduction, style: TextStyle(color: c.textSecondary)),
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
                              child: Text(switch (source) {
                                AnalysisCvSource.saved => l.atsInputSavedCv,
                                AnalysisCvSource.upload => l.atsInputUploadFile,
                                AnalysisCvSource.paste => l.atsInputPasteText,
                              }, textAlign: TextAlign.center),
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
                  if (_source == AnalysisCvSource.paste)
                    TextFormField(
                      key: const ValueKey('ats-input-resume-text'),
                      controller: _resumeTextController,
                      autovalidateMode: _autovalidate,
                      minLines: 8,
                      maxLines: null,
                      decoration: decoration(l.atsInputResumeTextHint),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? l.atsInputResumeTextRequired
                          : null,
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
                  AnalysisFieldError.tooLong => l.atsInputJobTitleTooLong,
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
                        : l.atsInputJobDescriptionTooLong,
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
            SubmitButton(
              label: l.atsInputAnalyze,
              loadingLabel: l.atsInputAnalyzing,
              isLoading: _isLoading,
              icon: Icons.analytics_outlined,
              onPressed: () => unawaited(_submit()),
            ),
            const SizedBox(height: 12),
            Text(
              l.atsInputPrivacy,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
