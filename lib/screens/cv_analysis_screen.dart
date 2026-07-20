import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../app_locale.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';
import '../services/api_exception.dart';
import '../services/cv_api_service.dart';
import '../services/notification_engagement_service.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/form_fields.dart';
import '../widgets/loading/ai_progress_overlay.dart';
import '../widgets/submit_button.dart';
import 'analysis_result_screen.dart';

class CvAnalysisScreen extends StatefulWidget {
  const CvAnalysisScreen({super.key});

  @override
  State<CvAnalysisScreen> createState() => _CvAnalysisScreenState();
}

class _CvAnalysisScreenState extends State<CvAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _resumeTextController = TextEditingController();
  final _apiService = CvApiService();
  PlatformFile? _uploadedFile;
  bool _isLoading = false;
  bool _submitted = false;

  /// Bumped on each submit/cancel so a late AI response cannot apply.
  int _aiRequestGen = 0;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _resumeTextController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _uploadedFile = result.files.single);
  }

  void _clearFile() => setState(() => _uploadedFile = null);

  Future<void> _submit() async {
    final english = AppLocale.isEnglish(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }
    if (_uploadedFile == null && _resumeTextController.text.trim().isEmpty) {
      _showError(english
          ? 'Paste resume text or upload a PDF/TXT file to start.'
          : 'الصق نص السيرة أو ارفع ملف PDF/TXT للبدء.');
      return;
    }
    final requestId = ++_aiRequestGen;
    setState(() => _isLoading = true);
    final startedAt = DateTime.now();
    AnalyticsService.logAnalysisStarted();

    final progress = await AiProgressOverlay.show(
      context,
      kind: AiProgressKind.analysis,
      english: english,
      onCancelled: () {
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
      final analysis = await _apiService.submitAnalysis(
        targetJobTitle: _jobTitleController.text.trim(),
        resumeText: _resumeTextController.text,
        resumeFile: await _multipartFile(),
      );

      if (!mounted ||
          progress.isCancelled ||
          requestId != _aiRequestGen) {
        return;
      }

      final durationMs =
          DateTime.now().difference(startedAt).inMilliseconds;
      // Bucket only — never the exact score.
      AnalyticsService.logAnalysisCompleted(
        score: analysis.scoreTotal,
        durationMs: durationMs,
      );
      await progress.dismiss();
      if (!mounted || requestId != _aiRequestGen) return;
      HapticFeedback.lightImpact();
      // Fire-and-forget conversion for smart-notification measurement.
      NotificationEngagementService.instance
          .reportConversion('analysis_completed');
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(analysis: analysis)),
      );
    } on ApiException catch (exception) {
      if (progress.isCancelled || requestId != _aiRequestGen) return;
      AnalyticsService.logAnalysisFailed(errorType: exception.type.name);
      if (mounted) AppSnackBar.fromException(context, exception);
    } catch (_) {
      if (progress.isCancelled || requestId != _aiRequestGen) return;
      AnalyticsService.logAnalysisFailed(errorType: 'unknown');
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
      if (mounted &&
          requestId == _aiRequestGen &&
          !progress.isCancelled) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<http.MultipartFile?> _multipartFile() async {
    final file = _uploadedFile;
    if (file == null) return null;

    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        'resume_file',
        file.bytes!,
        filename: file.name,
      );
    }

    if (file.path != null) {
      return http.MultipartFile.fromPath(
        'resume_file',
        file.path!,
        filename: file.name,
      );
    }

    return null;
  }

  void _showError(String msg) {
    AppSnackBar.error(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(english ? 'CV Analysis' : 'تحليل السيرة الذاتية'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    english ? 'Target job title' : 'المسمى الوظيفي المستهدف',
                    textAlign: TextAlign.start,
                    style: AppTextStyles.titleSm(),
                  ),
                  SizedBox(height: 10),
                  AppTextFormField(
                    controller: _jobTitleController,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    textAlign: TextAlign.start,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).nextFocus(),
                    hintText: english
                        ? 'e.g. Laravel Backend Developer'
                        : 'مثال: مطوّر Laravel Backend',
                    prefixIcon: Icon(Icons.work_outline_rounded),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? (english
                            ? 'Please enter a target job title'
                            : 'يرجى إدخال المسمى الوظيفي المستهدف')
                        : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    english ? 'Upload resume file' : 'رفع ملف السيرة الذاتية',
                    textAlign: TextAlign.start,
                    style: AppTextStyles.titleSm(),
                  ),
                  SizedBox(height: 12),
                  if (_uploadedFile == null)
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: context.sirati.primaryMid,
                              width: 1.5,
                              style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(14),
                          color:
                              context.sirati.primaryLight.withValues(alpha: .5),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                  color: context.sirati.primaryLight,
                                  shape: BoxShape.circle),
                              child: Icon(Icons.cloud_upload_outlined,
                                  size: 28, color: context.sirati.primary),
                            ),
                            SizedBox(height: 12),
                            Text(
                              english
                                  ? 'Tap to upload PDF or TXT'
                                  : 'اضغط لرفع ملف PDF أو TXT',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.sirati.primary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              english
                                  ? 'Maximum size 5 MB'
                                  : 'الحد الأقصى 5 ميجابايت',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.sirati.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.sirati.tealLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: context.sirati.teal.withValues(alpha: .4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file_outlined,
                              color: context.sirati.tealDark, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              BidiText.isolateLtr(_uploadedFile!.name),
                              textAlign: TextAlign.start,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.sirati.tealDark),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                size: 18, color: context.sirati.red),
                            onPressed: _clearFile,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Divider(color: context.sirati.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: context.sirati.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.sirati.border)),
                    child: Text(
                      english ? 'OR' : 'أو',
                      style: TextStyle(
                          fontSize: 12, color: context.sirati.textSecondary),
                    ),
                  ),
                ),
                Expanded(child: Divider(color: context.sirati.border)),
              ],
            ),
            SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    english ? 'Paste resume text' : 'لصق نص السيرة الذاتية',
                    textAlign: TextAlign.start,
                    style: AppTextStyles.titleSm(),
                  ),
                  SizedBox(height: 10),
                  AppTextFormField(
                    controller: _resumeTextController,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    textAlign: TextAlign.start,
                    maxLines: 8,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    hintText: english
                        ? 'Paste the full resume text here...'
                        : 'الصق نص السيرة الذاتية كاملاً هنا...',
                    validator: (value) {
                      if (_uploadedFile != null) return null;
                      if (value == null || value.trim().isEmpty) {
                        return english
                            ? 'Paste resume text or upload a PDF/TXT file.'
                            : 'الصق نص السيرة أو ارفع ملف PDF/TXT.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: english ? 'Analyze CV' : 'تحليل السيرة الذاتية',
              loadingLabel: english ? 'Analyzing...' : 'جارٍ التحليل...',
              isLoading: _isLoading,
              icon: Icons.analytics_outlined,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
