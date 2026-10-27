import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/cv_builder/application/my_cvs_controller.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_template_picker.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';
import 'package:sirati/shared/widgets/screen_header.dart';

/// "My CVs" tab: saved CVs with edit, download (per template), and delete.
class MyCvsScreen extends ConsumerStatefulWidget {
  const MyCvsScreen({super.key});

  @override
  ConsumerState<MyCvsScreen> createState() => _MyCvsScreenState();
}

class _MyCvsScreenState extends ConsumerState<MyCvsScreen> {
  bool get _english => AppLocale.isEnglish(context);

  Future<void> _refresh() => refreshMyCvs(ref, english: _english);

  void _openGenerator() {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CvGeneratorScreen()),
    ));
  }

  Future<void> _edit(CvListItem item) async {
    final id = item.id;
    if (id == null) return;
    try {
      final cv = await ref.read(cvApiServiceProvider).getGeneratedCv(id);
      if (!mounted) return;
      final updated = await Navigator.of(context).push<GeneratedCv>(
        MaterialPageRoute(builder: (_) => CvGeneratorScreen(initialCv: cv)),
      );
      if (!mounted) return;
      unawaited(_refresh());
      if (updated != null) {
        unawaited(Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GeneratedCvScreen(generatedCv: updated),
          ),
        ));
      }
    } catch (error) {
      _reportError(
        error,
        AppLocalizations.of(context).cvOpenFailed,
      );
    }
  }

  Future<void> _delete(CvListItem item) async {
    final id = item.id;
    if (id == null) return;
    final english = _english;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).cvDeleteTitle),
        content: Text(AppLocalizations.of(context).cvDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: context.sirati.error,
            ),
            child: Text(AppLocalizations.of(context).deleteItem),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(myCvsProvider(english).notifier).delete(id);
    } catch (error) {
      _reportError(
        error,
        l10n.cvDeleteFailed,
      );
    }
  }

  Future<void> _download(CvListItem item) async {
    final english = _english;
    // The PDF link opens in a browser; a CV the server refuses would land
    // on an error page there, so explain the gap here instead.
    final export = item.export;
    if (export != null && !export.ready) {
      AppSnackBar.warning(
        context,
        export.message(english: english) ??
            AppLocalizations.of(context).cvNotReadyToSend,
      );
      return;
    }
    final api = ref.read(cvApiServiceProvider);
    final String? slug;
    if (item.offersTemplateChoice) {
      final choice = await _chooseTemplate(english);
      if (choice case _Cancelled()) return;
      slug = (choice as _Chosen).template?.slug;
    } else {
      slug = null;
    }
    if (!mounted) return;

    AppSnackBar.info(
      context,
      AppLocalizations.of(context).cvOpeningPdf,
    );
    final url = await resolveCvDownloadUrl(api, item, templateSlug: slug);
    if (!mounted) return;
    if (url.isEmpty) {
      AppSnackBar.error(
        context,
        AppLocalizations.of(context).cvPdfLinkNotFound,
      );
      return;
    }
    final launched = await launchSafeExternalUrl(url);
    if (mounted && !launched) {
      AppSnackBar.error(
        context,
        AppLocalizations.of(context).cvPdfOpenFailed,
      );
    }
  }

  Future<_TemplateChoice> _chooseTemplate(bool english) async {
    final l10n = AppLocalizations.of(context);
    try {
      final templates = await ref
          .read(cvApiServiceProvider)
          .listCvTemplates(english: english);
      if (!mounted) return const _Cancelled();
      if (templates.isEmpty) return const _Chosen(null);

      final picked = await showModalBottomSheet<CvTemplate>(
        context: context,
        showDragHandle: true,
        builder: (_) =>
            CvTemplatePicker(templates: templates, english: english),
      );
      return picked == null ? const _Cancelled() : _Chosen(picked);
    } catch (error) {
      _reportError(
        error,
        l10n.cvTemplatesLoadFailed,
      );
      return const _Chosen(null);
    }
  }

  void _reportError(Object error, String fallback) {
    if (!mounted) return;
    if (error is ApiException) {
      AppSnackBar.fromException(context, error);
    } else {
      AppSnackBar.error(context, fallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final cvs = ref.watch(myCvsProvider(english));

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxContentWidth = constraints.maxWidth >= 1100
              ? 920.0
              : constraints.maxWidth >= 780
                  ? 760.0
                  : constraints.maxWidth;
          final horizontalPadding = AppSpacing.pageGutter(constraints.maxWidth);

          Widget shell(Widget child) => Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
                  child: child,
                ),
              );

          return AppAsyncBody<CvList>(
            snapshot: cvs.toSnapshot(),
            english: english,
            onRetry: () => ref.invalidate(myCvsProvider(english)),
            fallbackOnEmptyError: CvList.empty(english: english),
            errorMessage: (error) => error is ApiException
                ? error.displayMessage
                : AppLocalizations.of(context).cvListLoadFailed,
            loading: shell(
              CvListSkeleton(horizontalPadding: horizontalPadding),
            ),
            builder: (data) => shell(
              RefreshIndicator(
                color: context.sirati.primary,
                onRefresh: _refresh,
                child: _buildList(context, data, english, horizontalPadding),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    CvList data,
    bool english,
    double horizontalPadding,
  ) {
    final items = data.items;
    // Header, then the empty state or every card plus the create CTA.
    final itemCount = items.isEmpty ? 2 : items.length + 2;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding,
          AppSpacing.scrollBottomNavFab),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(
                english: english,
                title: data.title,
                icon: Icons.description_rounded,
                unreadCount: SessionCache.instance.unreadCount,
                onNotifications: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
                onAvatarTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.settings),
              ),
              if (data.offline) ...[
                const SizedBox(height: AppSpacing.sm),
                OfflineCacheBanner(english: english, surface: 'cvs'),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppLocalizations.of(context).cvCount(items.length),
                textAlign: TextAlign.start,
                style: AppTextStyles.bodySm(context.sirati),
              ),
              const SizedBox(height: AppSpacing.md),
              _JobMatchEntryTile(
                onTap: () async {
                  await Navigator.of(context).pushNamed(AppRoutes.jobMatch);
                  if (mounted) await _refresh();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        }

        if (items.isEmpty) {
          return AppEmptyState(
            icon: Icons.description_outlined,
            title: AppLocalizations.of(context).cvListEmptyTitle,
            subtitle: AppLocalizations.of(context).cvListEmptyBody,
            actionLabel: AppLocalizations.of(context).cvCreateNew,
            onAction: _openGenerator,
            scrollable: false,
          );
        }

        if (index == items.length + 1) {
          return CreateCvCard(english: english, onTap: _openGenerator);
        }

        final item = items[index - 1];
        return Padding(
          // Stable key: a delete shifts rows without reusing card state.
          key: ValueKey(item.id ?? 'row-$index'),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          // order > maxStaggerIndex → no reveal controller.
          child: MotionReveal(
            order: index - 1,
            child: CvDocumentCard(
              item: item,
              onEdit: () => unawaited(_edit(item)),
              onDelete: () => unawaited(_delete(item)),
              onDownload: () => unawaited(_download(item)),
            ),
          ),
        );
      },
    );
  }
}

sealed class _TemplateChoice {
  const _TemplateChoice();
}

/// Download with [template], or the default design when null.
final class _Chosen extends _TemplateChoice {
  const _Chosen(this.template);
  final CvTemplate? template;
}

final class _Cancelled extends _TemplateChoice {
  const _Cancelled();
}

/// Entry to Job Match (a separate feature, reached by route).
class _JobMatchEntryTile extends StatelessWidget {
  const _JobMatchEntryTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: c.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('my-cvs-job-match'),
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.work_outline_rounded, color: c.primaryInk),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.jobMatchEntryTitle,
                        style: AppTypography.of(context, AppTypography.titleSm),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.jobMatchEntrySubtitle,
                        style: AppTypography.of(
                          context,
                          AppTypography.bodySm,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                DirectionalIcon(
                  Icons.chevron_right_rounded,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
