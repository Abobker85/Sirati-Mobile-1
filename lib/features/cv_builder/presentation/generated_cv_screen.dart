import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/ai_error_message.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/bidi_text_utils.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/cv_builder/application/my_cvs_controller.dart';
import 'package:sirati/features/cv_builder/domain/cv_markdown.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv/cv_document_view.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_template_picker.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/ai_status.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Reading direction for a CV: its declared language, else detected.
TextDirection cvContentDirection(GeneratedCv cv) => switch (cv.language) {
      'en' => TextDirection.ltr,
      'ar' => TextDirection.rtl,
      _ => BidiTextUtils.detectBaseDirection(
          cv.generatedMarkdown,
          fallback: TextDirection.rtl,
        ),
    };

/// Whether the CV can be handed to an employer (AI finished or not used).
bool isCvReadyToSend(GeneratedCv cv) =>
    !AiStatus.isPending(cv.aiStatus) && cv.aiStatus != AiStatus.failed;

class GeneratedCvScreen extends ConsumerStatefulWidget {
  const GeneratedCvScreen({super.key, required this.generatedCv});

  final GeneratedCv generatedCv;

  static const previewKey = ValueKey('cv-hub-preview');
  static const previewToggleKey = ValueKey('cv-hub-preview-toggle');
  static const atsScoreKey = ValueKey('cv-hub-ats-score');
  static const downloadKey = ValueKey('cv-hub-download');
  static const shareKey = ValueKey('cv-hub-share');
  static const atsStepKey = ValueKey('cv-hub-step-ats');
  static const jobMatchStepKey = ValueKey('cv-hub-step-job-match');
  static const editStepKey = ValueKey('cv-hub-step-edit');

  @override
  ConsumerState<GeneratedCvScreen> createState() => _GeneratedCvScreenState();
}

class _GeneratedCvScreenState extends ConsumerState<GeneratedCvScreen> {
  /// The CV on screen; replaced when the user edits it.
  late GeneratedCv _cv = widget.generatedCv;
  late List<CvBlock> _blocks = parseCvMarkdown(_cv.generatedMarkdown);
  bool _isDownloading = false;
  bool _previewExpanded = false;

  @override
  void didUpdateWidget(covariant GeneratedCvScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.generatedCv, widget.generatedCv)) {
      _show(widget.generatedCv);
    }
  }

  void _show(GeneratedCv cv) {
    _cv = cv;
    _blocks = parseCvMarkdown(cv.generatedMarkdown);
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<GeneratedCv>(
      MaterialPageRoute(builder: (_) => CvGeneratorScreen(initialCv: _cv)),
    );
    if (updated != null && mounted) setState(() => _show(updated));
  }

  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    final english = AppLocale.isEnglish(context);
    if (!isCvReadyToSend(_cv)) {
      AppSnackBar.warning(
        context,
        english
            ? 'This CV is not ready to send to an employer yet.'
            : 'هذه السيرة غير جاهزة للإرسال إلى جهة التوظيف بعد.',
      );
      return;
    }
    final api = ref.read(cvApiServiceProvider);
    setState(() => _isDownloading = true);
    try {
      String? slug;
      if (_cv.templatePdfUrl?.isNotEmpty ?? false) {
        final choice = await _chooseTemplate(english);
        if (choice == null || !mounted) return; // cancelled
        slug = choice.template?.slug;
      }
      AppSnackBar.info(
        context,
        english ? 'Opening PDF download...' : 'جارٍ فتح رابط تنزيل الـ PDF...',
      );
      final url = await resolveCvPdfUrl(
        api,
        id: _cv.id,
        storedUrl: (_cv.templatePdfUrl?.isNotEmpty ?? false)
            ? _cv.templatePdfUrl!
            : (_cv.pdfUrl ?? ''),
        templateSlug: slug,
      );
      if (!mounted) return;
      if (url.isEmpty) {
        AppSnackBar.warning(
          context,
          english
              ? 'PDF link is not available yet.'
              : 'رابط PDF غير متاح حالياً.',
        );
        return;
      }
      final launched = await launchSafeExternalUrl(url);
      if (!launched && mounted) {
        AppSnackBar.warning(
          context,
          english ? 'Could not open the PDF link.' : 'تعذر فتح رابط PDF.',
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  /// Null when the user dismissed the picker; a null template means "use
  /// the default design".
  Future<({CvTemplate? template})?> _chooseTemplate(bool english) async {
    try {
      final templates = await ref
          .read(cvApiServiceProvider)
          .listCvTemplates(english: english);
      if (!mounted) return null;
      if (templates.isEmpty) return (template: null);
      final picked = await showModalBottomSheet<CvTemplate>(
        context: context,
        showDragHandle: true,
        builder: (_) =>
            CvTemplatePicker(templates: templates, english: english),
      );
      return picked == null ? null : (template: picked);
    } catch (_) {
      if (mounted) {
        AppSnackBar.warning(
          context,
          english
              ? 'Could not load CV designs. Default design will be used.'
              : 'تعذر تحميل التصاميم. سيتم استخدام التصميم الافتراضي.',
        );
      }
      return (template: null);
    }
  }

  void _share() {
    final text = cvPlainText(
      fullName: _cv.fullName,
      headline: displayHeadline(_cv.targetJobTitle, language: _cv.language),
      markdown: _cv.generatedMarkdown,
    );
    if (text.isEmpty) return;
    unawaited(Share.share(text));
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final aiError = _cv.aiError;
    final scored = _cv.aiStatus == AiStatus.completed ||
        _cv.aiStatus == AiStatus.notConfigured;
    final ready = isCvReadyToSend(_cv);
    final atsCheck = GeneratedCvHubLinks.atsCheck;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(ready ? l.cvHubTitle : l.cvHubAppBar),
        actions: [
          const LanguageToggle(),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: english ? 'Edit CV' : 'تعديل السيرة',
            onPressed: () => unawaited(_edit()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            if (scored) ...[
              CvStatusBanner.success(
                margin: EdgeInsets.zero,
                message: l.cvHubReady,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_cv.aiStatus == AiStatus.failed && aiError != null) ...[
              CvStatusBanner.warning(
                margin: EdgeInsets.zero,
                message:
                    AiErrorMessage.localFallback(aiError, english: english),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            MotionReveal(child: _preview(context)),
            if (scored) ...[
              const SizedBox(height: AppSpacing.md),
              _AtsScoreCard(score: _cv.scoreTotal, grade: _cv.grade),
            ],
            const SizedBox(height: AppSpacing.lg),
            PressScale(
              child: ElevatedButton.icon(
                key: GeneratedCvScreen.downloadKey,
                // Busy state keeps a readable label (AA pair).
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: c.surface,
                  disabledForegroundColor: c.textSecondary,
                ),
                onPressed:
                    _isDownloading ? null : () => unawaited(_downloadPdf()),
                icon: _isDownloading
                    ? SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.primaryInk,
                        ),
                      )
                    : const Icon(Icons.download_outlined, size: 20),
                label: Text(
                  _isDownloading ? l.cvHubPreparing : l.cvHubDownload,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PressScale(
              child: OutlinedButton.icon(
                key: GeneratedCvScreen.shareKey,
                style: OutlinedButton.styleFrom(
                  disabledForegroundColor: c.textSecondary,
                  side: BorderSide(color: c.textSecondary),
                ),
                onPressed: _blocks.isEmpty ? null : _share,
                icon: const Icon(Icons.share_outlined, size: 20),
                label: Text(l.cvHubShare),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l.cvHubNextSteps,
              style: AppTypography.of(context, AppTypography.titleLg),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (atsCheck != null) ...[
              _NextStepCard(
                key: GeneratedCvScreen.atsStepKey,
                icon: Icons.fact_check_outlined,
                title: l.cvHubCheckAts,
                body: l.cvHubCheckAtsBody,
                tag: l.cvHubRecommended,
                onTap: () => unawaited(atsCheck(context, _cv)),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _NextStepCard(
              key: GeneratedCvScreen.jobMatchStepKey,
              icon: Icons.work_outline_rounded,
              title: l.cvHubMatchJob,
              body: l.cvHubMatchJobBody,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.jobMatch,
                arguments: _cv.id,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NextStepCard(
              key: GeneratedCvScreen.editStepKey,
              icon: Icons.edit_note_rounded,
              title: l.cvHubEdit,
              body: l.cvHubEditBody,
              onTap: () => unawaited(_edit()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final contact = [_cv.email, _cv.phone]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    final document = Directionality(
      textDirection: cvContentDirection(_cv),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _cv.fullName,
            style: AppTypography.of(
              context,
              AppTypography.headlineMd,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            displayHeadline(_cv.targetJobTitle, language: _cv.language),
            style: AppTypography.of(
              context,
              AppTypography.titleSm,
              color: c.primaryInk,
            ),
          ),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              contact,
              textDirection: TextDirection.ltr,
              style: AppTypography.of(
                context,
                AppTypography.bodySm,
                color: c.textSecondary,
              ),
            ),
          ],
          Divider(height: AppSpacing.xl, color: c.textSecondary),
          if (_blocks.isEmpty)
            Text(
              l.cvHubEmpty,
              style: AppTypography.of(
                context,
                AppTypography.bodySm,
                color: c.textSecondary,
              ),
            )
          else
            CvDocumentBlocks(blocks: _blocks),
        ],
      ),
    );

    return DecoratedBox(
      key: GeneratedCvScreen.previewKey,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.textSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.description_outlined, size: 20, color: c.primaryInk),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l.cvHubPreview,
                    style: AppTypography.of(
                      context,
                      AppTypography.labelLg,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _CollapsiblePreview(
              expanded: _previewExpanded,
              onToggle: () =>
                  setState(() => _previewExpanded = !_previewExpanded),
              child: document,
            ),
          ],
        ),
      ),
    );
  }
}

/// Destinations owned by other features, wired by the app composition root
/// so this feature does not import them.
abstract final class GeneratedCvHubLinks {
  /// Opens a new detailed ATS check. The step is hidden while unset.
  static Future<void> Function(BuildContext, GeneratedCv)? atsCheck;
}

/// Shows the document clipped to [collapsedHeight] until expanded. The
/// whole document stays in the tree either way; the toggle only appears
/// when the content is actually taller than the collapsed height.
class _CollapsiblePreview extends StatefulWidget {
  const _CollapsiblePreview({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  static const collapsedHeight = 320.0;

  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  State<_CollapsiblePreview> createState() => _CollapsiblePreviewState();
}

class _CollapsiblePreviewState extends State<_CollapsiblePreview> {
  bool _overflows = false;

  bool _onMetrics(ScrollMetricsNotification notification) {
    final overflows = notification.metrics.maxScrollExtent > 0;
    if (overflows != _overflows) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _overflows = overflows);
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final showToggle = widget.expanded || _overflows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.expanded)
          widget.child
        else
          NotificationListener<ScrollMetricsNotification>(
            onNotification: _onMetrics,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: _CollapsiblePreview.collapsedHeight,
              ),
              child: SingleChildScrollView(
                primary: false,
                physics: const NeverScrollableScrollPhysics(),
                child: widget.child,
              ),
            ),
          ),
        if (showToggle)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: GeneratedCvScreen.previewToggleKey,
              onPressed: widget.onToggle,
              icon: Icon(
                widget.expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(
                widget.expanded ? l.cvHubShowLess : l.cvHubShowFull,
              ),
            ),
          ),
      ],
    );
  }
}

class _AtsScoreCard extends StatelessWidget {
  const _AtsScoreCard({required this.score, required this.grade});

  final int score;
  final String grade;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final value = score.clamp(0, 100);
    final ringSize = 64.0 *
        (MediaQuery.textScalerOf(context).scale(16) / 16)
            .clamp(1.0, double.infinity);
    final hasGrade = grade.trim().isNotEmpty && grade.trim() != '-';
    return DecoratedBox(
      key: GeneratedCvScreen.atsScoreKey,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.textSecondary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Semantics(
              label: '${l.cvHubAtsLabel} ${l.cvHubAtsScore(value)}',
              excludeSemantics: true,
              child: SizedBox.square(
                key: const ValueKey('cv-hub-score-ring'),
                dimension: ringSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value / 100,
                      strokeWidth: 6,
                      color: c.primaryInk,
                      backgroundColor: c.borderStrong,
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Text(
                          l.cvHubAtsScore(value),
                          textDirection: TextDirection.ltr,
                          style: AppTypography.of(
                            context,
                            AppTypography.titleMd,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.cvHubAtsLabel,
                    style: AppTypography.of(context, AppTypography.titleMd),
                  ),
                  if (hasGrade) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l.cvHubGrade(grade.trim()),
                      style: AppTypography.of(
                        context,
                        AppTypography.bodySm,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.tag,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Semantics(
      button: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: c.textSecondary),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.primaryLight,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: Icon(icon, size: 22, color: c.primaryInk),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              title,
                              style: AppTypography.of(
                                context,
                                AppTypography.titleSm,
                              ),
                            ),
                            if (tag != null)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.primaryLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    tag!,
                                    style: AppTypography.of(
                                      context,
                                      AppTypography.labelSm,
                                      color: c.primaryInk,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          body,
                          style: AppTypography.of(
                            context,
                            AppTypography.bodySm,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
