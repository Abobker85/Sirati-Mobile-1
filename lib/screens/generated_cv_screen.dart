import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../app_locale.dart';
import '../models/cv_template.dart';
import '../models/ai_status.dart';
import '../models/generated_cv.dart';
import '../services/cv_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/safe_url.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/language_toggle.dart';
import '../widgets/motion.dart';
import '../widgets/template_preview.dart';
import 'cv_generator_screen.dart';

class GeneratedCvScreen extends StatelessWidget {
  final GeneratedCv generatedCv;

  const GeneratedCvScreen({super.key, required this.generatedCv});

  Future<void> _downloadPdf(BuildContext context) async {
    final english = AppLocale.isEnglish(context);
    final service = CvApiService();
    final selection = (generatedCv.templatePdfUrl?.isNotEmpty ?? false)
        ? await _chooseTemplate(context, service, english)
        : const _TemplateSelection.useDefault();
    if (!context.mounted || !selection.shouldDownload) return;

    final pdfUrl =
        service.pdfUrlForTemplate(generatedCv, selection.template?.slug);
    if (pdfUrl.isEmpty) {
      _showMessage(
          context,
          english
              ? 'PDF link is not available yet.'
              : 'رابط PDF غير متاح حالياً.');
      return;
    }

    final launched = await launchSafeExternalUrl(pdfUrl);
    if (!launched && context.mounted) {
      _showMessage(context,
          english ? 'Could not open the PDF link.' : 'تعذر فتح رابط PDF.');
    }
  }

  Future<_TemplateSelection> _chooseTemplate(
    BuildContext context,
    CvApiService service,
    bool english,
  ) async {
    try {
      final templates = await service.listCvTemplates(english: english);
      if (!context.mounted) return const _TemplateSelection.cancelled();
      if (templates.isEmpty) return const _TemplateSelection.useDefault();

      final selectedTemplate = await showModalBottomSheet<CvTemplate>(
        context: context,
        showDragHandle: true,
        builder: (context) => _CvTemplatePicker(
          templates: templates,
          english: english,
        ),
      );

      if (selectedTemplate == null) return const _TemplateSelection.cancelled();
      return _TemplateSelection(template: selectedTemplate);
    } catch (_) {
      if (context.mounted) {
        _showMessage(
          context,
          english
              ? 'Could not load CV designs. Default design will be used.'
              : 'تعذر تحميل التصاميم. سيتم استخدام التصميم الافتراضي.',
        );
      }
      return const _TemplateSelection.useDefault();
    }
  }

  void _shareCv() {
    Share.share(
        '${generatedCv.fullName}\n${generatedCv.targetJobTitle}\n\n${generatedCv.generatedMarkdown}');
  }

  void _showMessage(BuildContext context, String message) {
    AppSnackBar.warning(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final contact = [generatedCv.email, generatedCv.phone]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    final english = AppLocale.isEnglish(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(english ? 'Generated CV' : 'السيرة الذاتية'),
        actions: [
          const LanguageToggle(),
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CvGeneratorScreen(initialCv: generatedCv)))),
        ],
      ),
      body: Column(
        children: [
          if (generatedCv.aiStatus == AiStatus.completed ||
              generatedCv.aiStatus == AiStatus.notConfigured)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.sirati.tealLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: context.sirati.teal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      english
                          ? 'CV generated · ATS score: '
                          : 'تم إنشاء السيرة · درجة ATS: ',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.sirati.tealDark,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text('${generatedCv.scoreTotal}',
                      style: TextStyle(
                          fontSize: 13,
                          color: context.sirati.tealDark,
                          fontWeight: FontWeight.w700)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.sirati.tealLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: context.sirati.teal.withValues(alpha: .4)),
                    ),
                    child: Text(generatedCv.grade,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: context.sirati.tealDark)),
                  ),
                ],
              ),
            ),
          if (generatedCv.aiStatus == AiStatus.failed &&
              generatedCv.aiError != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: context.sirati.amberLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: context.sirati.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      english
                          ? 'A local version was created because AI generation did not complete: ${generatedCv.aiError}'
                          : 'تم إنشاء نسخة محلية لأن الذكاء الاصطناعي لم يكتمل: ${generatedCv.aiError}',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.sirati.amber,
                          height: 1.4),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: MotionReveal(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.sirati.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.sirati.border),
                ),
                child: ListView(
                  children: [
                    Text(generatedCv.fullName,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.sirati.primaryDark)),
                    const SizedBox(height: 4),
                    Text(generatedCv.targetJobTitle,
                        style: TextStyle(
                            fontSize: 14,
                            color: context.sirati.primary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    if (contact.isNotEmpty)
                      Text(contact,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.sirati.textSecondary)),
                    Divider(height: 24, color: context.sirati.border),
                    if (generatedCv.generatedMarkdown.trim().isEmpty)
                      Text(
                          english
                              ? 'No CV content is available yet.'
                              : 'لا يوجد محتوى للسيرة حالياً.',
                          style: TextStyle(
                              fontSize: 13,
                              color: context.sirati.textSecondary))
                    else
                      ..._buildMarkdownSections(
                        context,
                        generatedCv.generatedMarkdown,
                        english,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: PressScale(
                    child: OutlinedButton.icon(
                      onPressed: _shareCv,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: Text(english ? 'Share' : 'مشاركة'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressScale(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadPdf(context),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: Text(english ? 'Download PDF' : 'تنزيل PDF'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMarkdownSections(
    BuildContext context,
    String markdown,
    bool english,
  ) {
    final direction = Directionality.of(context);
    final widgets = <Widget>[];
    for (final line in markdown.trim().split('\n')) {
      final raw = line.trim();
      if (raw.isEmpty || raw == '---') {
        continue;
      }

      if (raw.startsWith('## ') ||
          raw.startsWith('### ') ||
          raw.startsWith('#### ')) {
        final title = raw
            .replaceFirst(RegExp(r'^#{2,4}\s*'), '')
            .replaceAll('**', '')
            .trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            title,
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.sirati.textPrimary,
                letterSpacing: 0.3),
          ),
        ));
        widgets.add(Divider(height: 1, color: context.sirati.border));
        widgets.add(const SizedBox(height: 6));
      } else if (raw.startsWith('**') && raw.endsWith('**')) {
        final cleaned = raw.replaceAll('**', '').trim();
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(cleaned,
              textAlign: TextAlign.start,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.sirati.textPrimary)),
        ));
      } else if (raw.startsWith('- ') || raw.startsWith('* ')) {
        final bulletText = raw.replaceFirst(RegExp(r'^[-*]\s+'), '');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: direction,
            children: [
              Text('• ',
                  style:
                      TextStyle(fontSize: 12, color: context.sirati.primary)),
              Expanded(
                  child: Text(bulletText,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          fontSize: 12,
                          color: context.sirati.textPrimary,
                          height: 1.5))),
            ],
          ),
        ));
      } else {
        final cleaned = raw.replaceAll('**', '');
        final isContactLine = cleaned.contains('@') ||
            cleaned.contains('Email:') ||
            cleaned.contains('Phone:') ||
            cleaned.contains('|');
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            cleaned,
            textDirection: isContactLine ? TextDirection.ltr : direction,
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 12, color: context.sirati.textPrimary, height: 1.6),
          ),
        ));
      }
    }
    return widgets;
  }
}

class _TemplateSelection {
  final CvTemplate? template;
  final bool shouldDownload;

  const _TemplateSelection({this.template}) : shouldDownload = true;
  const _TemplateSelection.useDefault()
      : template = null,
        shouldDownload = true;
  const _TemplateSelection.cancelled()
      : template = null,
        shouldDownload = false;
}

class _CvTemplatePicker extends StatelessWidget {
  final List<CvTemplate> templates;
  final bool english;

  const _CvTemplatePicker({required this.templates, required this.english});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        shrinkWrap: true,
        children: [
          Text(
            english ? 'Choose CV design' : 'اختر تصميم السيرة',
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.sirati.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in templates.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MotionReveal(
                order: entry.key,
                child: PressScale(
                  child: ListTile(
                    onTap: () => Navigator.pop(context, entry.value),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: context.sirati.border),
                    ),
                    leading: TemplatePreview(
                      imageUrl: entry.value.previewImageUrl,
                      errorFallback: Icon(
                        Icons.description_outlined,
                        color: context.sirati.primary,
                      ),
                    ),
                    title: Text(
                      entry.value.name,
                      textAlign: TextAlign.start,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      entry.value.isDefault
                          ? (english ? 'Default template' : 'القالب الافتراضي')
                          : entry.value.slug,
                      textAlign: TextAlign.start,
                    ),
                    trailing: const Icon(Icons.download_rounded),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
