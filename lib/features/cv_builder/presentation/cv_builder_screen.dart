import 'package:flutter/material.dart';

import 'package:sirati/core/logging/app_log.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components.dart';
import 'package:sirati/features/cv_builder/controllers/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/presentation/cv_live_preview_pane.dart';
import 'package:sirati/features/cv_builder/presentation/experience_education_editor.dart';
import 'package:sirati/features/cv_builder/presentation/personal_details_editor.dart';
import 'package:sirati/features/cv_builder/presentation/skills_languages_editor.dart';

/// Interactive CV Builder Screen (SIRATI-36, 37, 38, 39, 40, 42).
class CvBuilderScreen extends StatefulWidget {
  final String? cvId;
  final CvDocument? initialDocument;
  final CvRepository? repository;

  const CvBuilderScreen({
    super.key,
    this.cvId,
    this.initialDocument,
    this.repository,
  });

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final CvRepository _repository;
  CvBuilderController? _controller;
  late final TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;
  bool _showPreviewPane = false;
  final CvTemplate _selectedTemplate = const CvTemplate(
    id: 1,
    slug: 'ats-classic-professional',
    name: 'كلاسيكي احترافي',
    nameAr: 'كلاسيكي احترافي',
    nameEn: 'ATS Classic Professional',
    previewImageUrl: null,
    languageDirection: 'both',
    supportedLanguages: ['ar', 'en'],
    supportedSections: [],
    isDefault: true,
    isPremium: false,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _repository = widget.repository ?? LocalCvRepository();
    _initializeDocument();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (_controller != null && _controller!.isDirty) {
        _controller!.saveImmediately();
      }
    }
  }

  Future<void> _initializeDocument() async {
    try {
      CvDocument doc;
      if (widget.initialDocument != null) {
        doc = widget.initialDocument!;
      } else if (widget.cvId != null) {
        final existing = await _repository.getCv(widget.cvId!);
        doc = existing ?? CvDocument.createEmpty(id: widget.cvId);
      } else {
        doc = CvDocument.createEmpty();
      }

      final controller = CvBuilderController(
        initialDocument: doc,
        repository: _repository,
      );

      setState(() {
        _controller = controller;
        _isLoading = false;
      });

      // Crash / uncommitted draft recovery check (SIRATI-42)
      if (doc.id != null) {
        final draft = await CvBuilderController.checkDraftRecovery(
          doc.id!,
          doc.updatedAt,
        );
        if (draft != null && mounted) {
          _showRecoveryPrompt(draft);
        }
      }
    } catch (e, stack) {
      AppLog.event(
        AppLogEvent.cvLoadFailed,
        level: AppLogLevel.error,
        data: {'phase': 'builder_init'},
        error: e,
        stackTrace: stack,
      );
      setState(() {
        _isLoading = false;
        _errorMessage = mounted
            ? AppLocalizations.of(context).cvLoadFailed
            : 'cv_load_failed';
      });
    }
  }

  void _showRecoveryPrompt(CvDocument draft) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final c = context.sirati;
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Row(
            children: [
              Icon(Icons.restore, color: c.primary, size: 24),
              const SizedBox(width: AppSpacing.xs),
              Text(l10n.recoverDraftTitle),
            ],
          ),
          content: Text(l10n.recoverDraftBody),
          actions: [
            TextButton(
              onPressed: () {
                if (draft.id != null) {
                  CvBuilderController.clearDraft(draft.id!);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(
                l10n.discardDraft,
                style: TextStyle(color: c.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
              ),
              onPressed: () {
                _controller?.updateDocument(draft);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.draftRestored)),
                );
              },
              child: Text(l10n.restoreDraft),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cvEditorTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandedLoader(),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.preparingEditor,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: c.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cvEditorTitle)),
        body: Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: l10n.loadErrorTitle,
            subtitle: _errorMessage ?? l10n.cvLoadFailed,
            actionLabel: l10n.retry,
            onAction: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _initializeDocument();
            },
            scrollable: false,
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_controller != null && _controller!.isDirty) {
          await _controller!.saveImmediately();
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: ListenableBuilder(
        listenable: _controller!,
        builder: (context, _) {
          final doc = _controller!.document;
          final isSaving = _controller!.isSaving;
          final isDirty = _controller!.isDirty;

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    doc.title ?? l10n.cvEditorTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  // Autosave Status Badge (SIRATI-42)
                  Row(
                    children: [
                      if (isSaving) ...[
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          l10n.autosaving,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: c.textSecondary,
                                    fontSize: 11,
                                  ),
                        ),
                      ] else if (isDirty) ...[
                        Icon(Icons.edit_note, size: 12, color: c.warning),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          l10n.unsavedEdits,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: c.warning,
                                    fontSize: 11,
                                  ),
                        ),
                      ] else ...[
                        Icon(Icons.check_circle, size: 12, color: c.primary),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          l10n.saved,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: c.primary,
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(_showPreviewPane
                      ? Icons.edit_note
                      : Icons.visibility_outlined),
                  tooltip:
                      _showPreviewPane ? l10n.backToEdit : l10n.livePreview,
                  onPressed: () {
                    setState(() {
                      _showPreviewPane = !_showPreviewPane;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.save_outlined),
                  tooltip: l10n.saveNow,
                  onPressed: () async {
                    await _controller!.saveImmediately();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.cvSaved),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(icon: const Icon(Icons.person), text: l10n.tabPersonal),
                  Tab(icon: const Icon(Icons.work), text: l10n.tabExperience),
                  Tab(icon: const Icon(Icons.psychology), text: l10n.tabSkills),
                  Tab(
                      icon: const Icon(Icons.format_line_spacing),
                      text: l10n.tabOrder),
                ],
              ),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final editorWidget = TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: PersonalDetailsEditor(controller: _controller!),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child:
                          ExperienceEducationEditor(controller: _controller!),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SkillsLanguagesEditor(controller: _controller!),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _SectionReorderTab(controller: _controller!),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(flex: 3, child: editorWidget),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: c.surfaceLow,
                          child: CvLivePreviewPane(
                            controller: _controller!,
                            template: _selectedTemplate,
                            scale: 0.85,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (_showPreviewPane) {
                  return Container(
                    color: c.surfaceLow,
                    child: CvLivePreviewPane(
                      controller: _controller!,
                      template: _selectedTemplate,
                    ),
                  );
                }

                return editorWidget;
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Section Reorder Tab (SIRATI-40) ─────────────────────────────────────────

class _SectionReorderTab extends StatelessWidget {
  final CvBuilderController controller;

  const _SectionReorderTab({required this.controller});

  static String _sectionLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'personal' => l10n.sectionPersonal,
      'summary' => l10n.sectionSummary,
      'experience' => l10n.sectionExperience,
      'education' => l10n.sectionEducation,
      'skills' => l10n.sectionSkills,
      'languages' => l10n.sectionLanguages,
      'certifications' => l10n.sectionCertifications,
      'projects' => l10n.sectionProjects,
      'custom_sections' => l10n.sectionCustom,
      _ => key,
    };
  }

  static const _sectionIcons = {
    'personal': Icons.person_outline,
    'summary': Icons.article_outlined,
    'experience': Icons.work_outline,
    'education': Icons.school_outlined,
    'skills': Icons.psychology_outlined,
    'languages': Icons.translate_outlined,
    'certifications': Icons.verified_outlined,
    'projects': Icons.rocket_launch_outlined,
    'custom_sections': Icons.dashboard_customize_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final order =
        controller.document.sectionOrder ?? CvDocument.defaultSectionOrder;

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_line_spacing, color: c.primary, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.sectionOrderTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.sectionOrderHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c.textSecondary,
                ),
          ),
          const Divider(height: AppSpacing.lg),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.length,
            // ignore: deprecated_member_use
            onReorder: (oldIdx, newIdx) =>
                controller.reorderSections(oldIdx, newIdx),
            itemBuilder: (context, index) {
              final sectionKey = order[index];
              final label = _sectionLabel(l10n, sectionKey);
              final icon = _sectionIcons[sectionKey] ?? Icons.folder_open;
              final isFirst = index == 0;
              final isLast = index == order.length - 1;

              return Container(
                key: ValueKey(sectionKey),
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.xs),
                        child: Icon(Icons.drag_indicator, size: 20),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(icon, size: 20, color: c.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: c.textPrimary,
                            ),
                      ),
                    ),
                    // Accessible Up/Down Buttons
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 18),
                      tooltip: l10n.moveUp,
                      onPressed: isFirst
                          ? null
                          : () => controller.reorderSections(index, index - 1),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 18),
                      tooltip: l10n.moveDown,
                      onPressed: isLast
                          ? null
                          : () => controller.reorderSections(index, index + 2),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
