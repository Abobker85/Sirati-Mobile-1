import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_locale.dart';
import '../models/cv_template.dart';
import '../services/api_exception.dart';
import '../services/cv_api_service.dart';
import '../services/mobile_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_format.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading/app_async_body.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/motion.dart';
import '../widgets/offline_cache_banner.dart';
import '../widgets/screen_header.dart';
import '../widgets/template_preview.dart';
import '../services/session_cache.dart';
import 'cv_generator_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class MyCvsScreen extends StatefulWidget {
  const MyCvsScreen({super.key});

  @override
  State<MyCvsScreen> createState() => _MyCvsScreenState();
}

class _MyCvsScreenState extends State<MyCvsScreen> {
  final _contentService = MobileContentService();
  final _cvService = CvApiService();
  late Future<Map<String, dynamic>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _contentService.myCvs(AppLocale.isEnglish(context));
  }

  Future<void> _refresh() async {
    final next =
        _contentService.myCvs(AppLocale.isEnglish(context), force: true);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // FutureBuilder shows error; pull-to-refresh still settles.
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = constraints.maxWidth >= 1100
                  ? 920.0
                  : constraints.maxWidth >= 780
                      ? 760.0
                      : constraints.maxWidth;
              final horizontalPadding =
                  AppSpacing.pageGutter(constraints.maxWidth);

              Widget shell(Widget child) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: child,
                    ),
                  );

              return AppAsyncBody<Map<String, dynamic>>(
                snapshot: snapshot,
                english: english,
                onRetry: _refresh,
                fallbackOnEmptyError: _fallback(english),
                errorMessage: (error) => error is ApiException
                    ? error.displayMessage
                    : (english
                        ? 'Could not load your CVs.'
                        : 'تعذر تحميل السير الذاتية.'),
                loading: shell(
                  CvListSkeleton(horizontalPadding: horizontalPadding),
                ),
                builder: (data) {
                  final items = _list(data['items']);
                  final offline = MobileContentService.isOfflinePayload(data);
                  // index 0 = header; then empty-state OR items; optional create CTA.
                  final itemCount = items.isEmpty
                      ? 2
                      : items.length + 2; // header + cards + dashed create

                  return shell(
                    RefreshIndicator(
                      color: context.sirati.primary,
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(horizontalPadding, 18,
                            horizontalPadding, AppSpacing.scrollBottomNavFab),
                        itemCount: itemCount,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ScreenHeader(
                                  english: english,
                                  title: _text(data['title'],
                                      english ? 'My CVs' : 'سيرتي الذاتية'),
                                  avatarLabel: english ? 'M' : 'س',
                                  unreadCount:
                                      SessionCache.instance.unreadCount,
                                  onNotifications: () =>
                                      Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen()),
                                  ),
                                  onAvatarTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const SettingsScreen()),
                                  ),
                                ),
                                if (offline) ...[
                                  SizedBox(height: AppSpacing.sm),
                                  OfflineCacheBanner(
                                    english: english,
                                    surface: 'cvs',
                                  ),
                                ],
                                SizedBox(height: AppSpacing.lg),
                                Text(
                                  _summaryLabel(
                                      english, items.length, data['summary']),
                                  textAlign: TextAlign.start,
                                  style: AppTextStyles.bodySm(),
                                ),
                                SizedBox(height: AppSpacing.md),
                              ],
                            );
                          }

                          if (items.isEmpty) {
                            return AppEmptyState(
                              icon: Icons.description_outlined,
                              title: english
                                  ? 'No CVs yet'
                                  : 'لا توجد سير ذاتية بعد',
                              subtitle: english
                                  ? 'Create your first ATS-ready CV in a few steps.'
                                  : 'أنشئ أول سيرة ذاتية متوافقة مع ATS بخطوات بسيطة.',
                              actionLabel: english
                                  ? 'Create New CV'
                                  : 'إنشاء سيرة جديدة',
                              onAction: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const CvGeneratorScreen()),
                              ),
                              scrollable: false,
                            );
                          }

                          if (index == items.length + 1) {
                            return _CreateCvDashedCard(
                              english: english,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const CvGeneratorScreen()),
                              ),
                            );
                          }

                          final item = items[index - 1];
                          // order > maxStaggerIndex → no reveal controller.
                          final order = index - 1;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: MotionReveal(
                              order: order,
                              child: _CvDocumentCard(
                                id: _int(item['id']),
                                title: _text(item['title'], ''),
                                updatedAt: _cvUpdatedText(item, english),
                                badge: _text(item['badge'], ''),
                                isDraft: _bool(item['is_draft']),
                                canDownload:
                                    _bool(item['can_download'], fallback: true),
                                onEdit: () => _editCv(_int(item['id'])),
                                onDelete: () => _deleteCv(_int(item['id'])),
                                onDownload: () => _download(
                                  pdfUrl: _text(item['pdf_url'], ''),
                                  templatePdfUrl:
                                      _text(item['template_pdf_url'], ''),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editCv(int? id) async {
    if (id == null) return;
    try {
      final cv = await _cvService.getGeneratedCv(id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CvGeneratorScreen(initialCv: cv)),
      );
      _refresh();
    } on ApiException catch (exception) {
      _message(exception.displayMessage, exception: exception);
    }
  }

  Future<void> _deleteCv(int? id) async {
    if (id == null) return;
    final english = AppLocale.isEnglish(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(english ? 'Delete CV?' : 'حذف السيرة؟'),
        content: Text(english
            ? 'This action cannot be undone.'
            : 'لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(english ? 'Cancel' : 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(english ? 'Delete' : 'حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _cvService.deleteGeneratedCv(id);
      MobileContentService.invalidateCvRelated();
      _refresh();
    } on ApiException catch (exception) {
      _message(exception.displayMessage, exception: exception);
    }
  }

  Future<void> _download(
      {required String pdfUrl, required String templatePdfUrl}) async {
    final url = templatePdfUrl.isNotEmpty ? templatePdfUrl : pdfUrl;
    if (url.isEmpty) return;
    final english = AppLocale.isEnglish(context);
    final selection = templatePdfUrl.isNotEmpty
        ? await _chooseTemplate(english)
        : const _TemplateSelection.useDefault();
    if (!mounted || !selection.shouldDownload) return;
    final launchUrlText = _urlForTemplate(url, selection.template?.slug);
    final launched = await launchUrl(Uri.parse(launchUrlText),
        mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!launched) {
      _message(english ? 'Could not open PDF.' : 'تعذر فتح ملف PDF.');
    }
  }

  Future<_TemplateSelection> _chooseTemplate(bool english) async {
    try {
      final templates = await _cvService.listCvTemplates(english: english);
      if (!mounted) return const _TemplateSelection.cancelled();
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
    } on ApiException catch (exception) {
      _message(exception.displayMessage, exception: exception);
      return const _TemplateSelection.useDefault();
    } catch (_) {
      _message(english
          ? 'Could not load CV designs. Default design will be used.'
          : 'تعذر تحميل التصاميم. سيتم استخدام التصميم الافتراضي.');
      return const _TemplateSelection.useDefault();
    }
  }

  String _urlForTemplate(String url, String? templateSlug) {
    if (templateSlug == null || templateSlug.isEmpty) return url;
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'template': templateSlug,
    }).toString();
  }

  void _message(String message, {ApiException? exception}) {
    if (!mounted) return;
    if (exception != null) {
      AppSnackBar.fromException(context, exception);
      return;
    }
    AppSnackBar.error(context, message);
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

/// Shell only when the list cannot be loaded — never invent CV rows or counts.
Map<String, dynamic> _fallback(bool english) => {
      'title': english ? 'My CVs' : 'سيرتي الذاتية',
      'summary': LocaleFormat.cvFilesSummary(0, english: english),
      'items': const <Map<String, dynamic>>[],
    };

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};
List<Map<String, dynamic>> _list(dynamic value) =>
    value is List ? value.map(_map).toList() : const [];
String _text(dynamic value, String fallback) =>
    (value?.toString().isNotEmpty ?? false) ? value.toString() : fallback;
bool _bool(dynamic value, {bool fallback = false}) =>
    value is bool ? value : fallback;
int? _int(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

String _cvUpdatedText(Map<String, dynamic> item, bool english) {
  final at = DateTime.tryParse(
      item['updated_at']?.toString() ?? item['created_at']?.toString() ?? '');
  if (at != null) {
    return AppFormat.relativeTime(at, english: english);
  }
  final label = _text(item['updated_label'], '');
  if (label.isEmpty) return '';
  return AppFormat.digits(label, english: english);
}

String _summaryLabel(bool english, int count, dynamic apiSummary) {
  // Prefer computed plural forms so AR grammar stays correct even when the
  // API returns a fixed template string.
  if (count == 0 ||
      apiSummary == null ||
      apiSummary.toString().trim().isEmpty) {
    return LocaleFormat.cvFilesSummary(count, english: english);
  }
  // If API summary looks like a hard-coded English/Arabic template with a
  // wrong plural, still recompute from count.
  return LocaleFormat.cvFilesSummary(count, english: english);
}

class _CvDocumentCard extends StatelessWidget {
  final int? id;
  final String title;
  final String updatedAt;
  final String badge;
  final bool isDraft;
  final bool canDownload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _CvDocumentCard({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.badge,
    required this.isDraft,
    required this.canDownload,
    required this.onEdit,
    required this.onDelete,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final color = isDraft ? context.sirati.textHint : context.sirati.primary;

    return PressScale(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.sirati.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.sirati.border),
          boxShadow: context.sirati.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DocumentIcon(color: color),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isEmpty
                            ? (english ? 'Untitled CV' : 'سيرة بلا عنوان')
                            : LocaleFormat.mixedTitle(
                                LocaleFormat.fixSampleTitle(title),
                                english: english,
                              ),
                        textAlign: TextAlign.start,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd(),
                      ),
                      if (updatedAt.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          updatedAt,
                          textAlign: TextAlign.start,
                          style: AppTextStyles.bodySm().copyWith(
                            color: context.sirati.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (badge.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _StatusBadge(
                            label:
                                LocaleFormat.atsBadge(badge, english: english),
                            isDraft: isDraft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined, size: 16),
                    label: Text(english ? 'Edit' : 'تعديل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.sirati.primaryLight,
                      foregroundColor: context.sirati.primaryDark,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                _CircleActionButton(
                  icon: Icons.download_rounded,
                  label: english ? 'Download' : 'تنزيل',
                  iconColor: canDownload
                      ? context.sirati.primary
                      : context.sirati.textHint,
                  borderColor: canDownload
                      ? context.sirati.borderStrong
                      : context.sirati.border,
                  onTap: canDownload ? onDownload : null,
                ),
                SizedBox(width: 8),
                _CircleActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: english ? 'Delete' : 'حذف',
                  iconColor: context.sirati.red,
                  borderColor: context.sirati.red.withValues(alpha: .18),
                  fillColor: context.sirati.redLight,
                  onTap: id == null ? null : onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CvTemplatePicker extends StatelessWidget {
  final List<CvTemplate> templates;
  final bool english;

  const _CvTemplatePicker({required this.templates, required this.english});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        shrinkWrap: true,
        itemCount: templates.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                SizedBox(height: 12),
              ],
            );
          }
          final template = templates[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => Navigator.pop(context, template),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: context.sirati.border),
              ),
              leading: TemplatePreview(
                imageUrl: template.previewImageUrl,
                errorFallback: const SiratiMark(size: 22),
              ),
              title: Text(
                template.name,
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                template.isDefault
                    ? (english ? 'Default template' : 'القالب الافتراضي')
                    : template.slug,
                textAlign: TextAlign.start,
              ),
              trailing: Icon(Icons.download_rounded),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentIcon extends StatelessWidget {
  final Color color;

  const _DocumentIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: SiratiMark(size: 22)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isDraft;

  const _StatusBadge({required this.label, required this.isDraft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isDraft ? context.sirati.surfaceLow : context.sirati.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: isDraft
              ? context.sirati.textSecondary
              : context.sirati.primaryDark,
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color borderColor;
  final Color? fillColor;
  final VoidCallback? onTap;

  const _CircleActionButton(
      {required this.icon,
      required this.label,
      required this.iconColor,
      required this.borderColor,
      this.fillColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fill = fillColor ?? context.sirati.surface;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        enabled: onTap != null,
        child: Material(
          color: fill,
          shape: CircleBorder(side: BorderSide(color: borderColor, width: 1.5)),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, color: iconColor, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateCvDashedCard extends StatelessWidget {
  final bool english;
  final VoidCallback onTap;

  const _CreateCvDashedCard({required this.english, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.sirati.surface,
            border: Border.all(
              color: context.sirati.primary.withValues(alpha: .35),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 18, color: context.sirati.primary),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  english ? 'Create New CV' : 'إنشاء سيرة جديدة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: context.sirati.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
