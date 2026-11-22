import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/features/cv_builder/controllers/cv_builder_controller.dart';
import 'package:sirati/features/cv_builder/presentation/section_editor_framework.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Drag or step sections into the order they appear in the CV (SIRATI-40).
class SectionOrderTab extends StatelessWidget {
  final CvBuilderController controller;

  const SectionOrderTab({super.key, required this.controller});

  /// Key of the white card holding the section rows.
  static const listCardKey = ValueKey('section-order-card');

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

    // iOS 26 inset-grouped list: the title and hint on the page, the
    // sections as flat rows with hairlines in one white card.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            children: [
              Icon(Icons.format_line_spacing, color: c.primaryInk, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.sectionOrderTitle,
                  style: AppTypography.of(
                    context,
                    AppTypography.titleMd,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            l10n.sectionOrderHint,
            style: AppTypography.of(
              context,
              AppTypography.caption,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EditorGroupCard(
          key: SectionOrderTab.listCardKey,
          padding: EdgeInsets.zero,
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.length,
            proxyDecorator: reorderLiftProxyDecorator,
            onReorderStart: (_) => unawaited(HapticFeedback.selectionClick()),
            onReorderEnd: (_) => unawaited(HapticFeedback.selectionClick()),
            // ignore: deprecated_member_use
            onReorder: controller.reorderSections,
            itemBuilder: (context, index) {
              final sectionKey = order[index];
              final label = _sectionLabel(l10n, sectionKey);
              final icon = _sectionIcons[sectionKey] ?? Icons.folder_open;
              final isFirst = index == 0;
              final isLast = index == order.length - 1;

              // A flat row; the lifted drag proxy gets the card fill so it
              // stays visible over its neighbours.
              return Material(
                key: ValueKey(sectionKey),
                color: c.groupedCard,
                borderRadius: AppRadius.cardAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(bottom: BorderSide(color: c.separator)),
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
                      Icon(icon, size: 20, color: c.primaryInk),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          label,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            : () =>
                                controller.reorderSections(index, index - 1),
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        tooltip: l10n.moveDown,
                        onPressed: isLast
                            ? null
                            : () =>
                                controller.reorderSections(index, index + 2),
                        constraints:
                            const BoxConstraints(minWidth: 48, minHeight: 48),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
