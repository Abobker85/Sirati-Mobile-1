import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/routing/expand_page_route.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/cv_builder/application/my_cvs_controller.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_template_picker.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/navigation/dashboard_scroll_end.dart';
import 'package:sirati/shared/premium/premium_feature.dart';
import 'package:sirati/shared/premium/premium_ui.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/components/app_dialog.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';
import 'package:sirati/shared/widgets/sirati_refresh_indicator.dart';

/// "My CVs" tab (design/cv-tab): tools to create, scan, upload or target a
/// job, then saved CVs with open, edit, download (per template) and delete.
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
    final confirmed = await showSiratiDialog<bool>(
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
    // Locked for a free account: offer Premium, then carry on if bought.
    if (!item.canDownload || currentSubscription().downloadLocked) {
      final premium =
          await PremiumPromptSheet.show(context, PremiumFeature.download);
      if (!premium || !mounted) return;
    }
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
    // Designs are offered in the CV's language; when it can't be learned
    // the server's default design is used.
    final language =
        item.offersTemplateChoice ? await _cvLanguage(api, item) : null;
    if (!mounted) return;
    if (language != null) {
      final choice = await _chooseTemplate(language);
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

  /// The CV's own language: from the list row, else from the CV itself.
  Future<String?> _cvLanguage(CvApiService api, CvListItem item) async {
    if (item.language != null) return item.language;
    final id = item.id;
    if (id == null) return null;
    try {
      return (await api.getGeneratedCv(id)).language;
    } catch (_) {
      return null;
    }
  }

  Future<_TemplateChoice> _chooseTemplate(String language) async {
    final l10n = AppLocalizations.of(context);
    final english = AppLocale.isEnglishCode(language);
    try {
      final templates = await ref
          .read(cvApiServiceProvider)
          .listCvTemplates(language: language);
      if (!mounted) return const _Cancelled();
      if (templates.isEmpty) return const _Chosen(null);

      final picked = await showGlassBottomSheet<CvTemplate>(
        context: context,
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

  void _openScan({int? cvId, bool upload = false}) {
    unawaited(() async {
      await Navigator.of(context).pushNamed(
        AppRoutes.atsScan,
        arguments: AtsScanArgs(cvId: cvId, upload: upload),
      );
      if (mounted) await _refresh();
    }());
  }

  void _openJobMatch() {
    unawaited(() async {
      await Navigator.of(context).pushNamed(AppRoutes.jobMatch);
      if (mounted) await _refresh();
    }());
  }

  /// Opens the CV. With [card] (the tapped card's context) the page grows
  /// out of that card.
  void _open(CvListItem item, {BuildContext? card}) {
    final id = item.id;
    if (id == null) return;
    final origin = card == null ? null : ExpandOrigin.of(card);
    unawaited(() async {
      await Navigator.of(context).pushNamed(
        AppRoutes.cv(id),
        arguments: origin == null ? null : ExpandFrom(origin),
      );
      if (mounted) await _refresh();
    }());
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final cvs = ref.watch(myCvsProvider(english));

    // The brand band draws under the status bar; the rest stays inset.
    return SafeArea(
      top: false,
      bottom: false,
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
            loading: SafeArea(
              bottom: false,
              child: shell(
                CvListSkeleton(horizontalPadding: horizontalPadding),
              ),
            ),
            builder: (data) => Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: _onListScroll,
                  child: SiratiRefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildList(context, data, english, horizontalPadding,
                        shell: shell),
                  ),
                ),
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  child: _slimHeader(context, data),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Whether the band's top row has scrolled out, so the slim header shows.
  final _slim = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _slim.dispose();
    super.dispose();
  }

  bool _onListScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      _slim.value = notification.metrics.pixels > MyCvsSlimHeader.showAfter;
    }
    return false;
  }

  String _title(BuildContext context, CvList data) => data.title.isNotEmpty
      ? data.title
      : AppLocalizations.of(context).myCvsListTitle;

  /// Slides down over the band as its top row leaves, and back up at the top
  /// of the list. Out of the tree while hidden, so the page has one title and
  /// one bell at a time for screen readers.
  Widget _slimHeader(BuildContext context, CvList data) {
    final reduce = MotionSettings.reduce(context);
    return ValueListenableBuilder<bool>(
      valueListenable: _slim,
      builder: (context, slim, _) => AnimatedSwitcher(
        duration: reduce ? Duration.zero : MotionDurations.slow,
        switchInCurve: MotionCurves.standard,
        switchOutCurve: MotionCurves.standard.flipped,
        transitionBuilder: (child, animation) => ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: slim
            ? MyCvsSlimHeader(
                title: _title(context, data),
                unreadCount: SessionCache.instance.unreadCount,
                onNotifications: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }

  /// How far the tools card reaches up into the brand band.
  static const _toolsOverlap = 40.0;

  Widget _buildList(
    BuildContext context,
    CvList data,
    bool english,
    double horizontalPadding, {
    required Widget Function(Widget child) shell,
  }) {
    final items = data.items;
    final gutter = EdgeInsets.symmetric(horizontal: horizontalPadding);
    // Header block, then the empty state or every card.
    final itemCount = items.isEmpty ? 2 : items.length + 1;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: dashboardScrollEnd(context)),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MyCvsHeader(
                title: _title(context, data),
                unreadCount: SessionCache.instance.unreadCount,
                onNotifications: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
              ),
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _toolsOverlap,
                    child: DecoratedBox(
                      decoration: MyCvsHeader.brandBand(context),
                    ),
                  ),
                  shell(Padding(
                    padding: gutter,
                    child: MotionReveal(
                      order: 0,
                      child: MyCvsToolsCard(
                        onCreate: _openGenerator,
                        onScan: _openScan,
                        onUpload: () => _openScan(upload: true),
                        onTarget: _openJobMatch,
                      ),
                    ),
                  )),
                ],
              ),
              shell(Padding(
                padding: gutter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.offline) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OfflineCacheBanner(english: english, surface: 'cvs'),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    MyCvsListHeading(count: items.length),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              )),
            ],
          );
        }

        if (items.isEmpty) {
          return shell(Padding(
            padding: gutter,
            child: MyCvsEmptyCard(
              onCreate: _openGenerator,
              onUpload: () => _openScan(upload: true),
            ),
          ));
        }

        final item = items[index - 1];
        return shell(Padding(
          // Stable key: a delete shifts rows without reusing card state.
          key: ValueKey(item.id ?? 'row-$index'),
          padding: gutter.copyWith(bottom: AppSpacing.sm),
          // order > maxStaggerIndex → no reveal controller.
          child: MotionReveal(
            order: index,
            // The Builder's context is the card itself, which is what the
            // CV page expands from.
            child: Builder(
              builder: (card) => CvDocumentCard(
                item: item,
                onOpen: () => _open(item, card: card),
                onEdit: () => unawaited(_edit(item)),
                onDelete: () => unawaited(_delete(item)),
                onDownload: () => unawaited(_download(item)),
                onScan: () => _openScan(cvId: item.id),
              ),
            ),
          ),
        ));
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
