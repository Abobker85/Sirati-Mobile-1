import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/domain/notification_groups.dart';
import 'package:sirati/features/settings/domain/notification_item.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/notification_target.dart';
import 'package:sirati/shared/services/notification_service.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/async_value_snapshot.dart';
import 'package:sirati/shared/widgets/motion.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    try {
      final next = ref.refresh(notificationsInboxProvider.future);
      await next;
    } catch (_) {}
  }

  void _reportFailure(BuildContext context, {String? message}) {
    if (!context.mounted) return;
    AppSnackBar.error(
      context,
      message ?? AppLocalizations.of(context).settingsNotificationsUpdateFailed,
    );
  }

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    final inbox = ref.read(notificationsInboxProvider.notifier);
    final handler = NotificationService.instance.onNotificationTap;
    if (item.opensSomething && handler != null) {
      final messenger = ScaffoldMessenger.of(context);
      final messengerContext = Navigator.of(context).context;
      final failureMessage =
          AppLocalizations.of(context).settingsNotificationsUpdateFailed;
      final startGen = SessionCache.instance.generation;
      final startUser = SessionCache.instance.user.value;
      // Same router as a tapped push. Screen targets may switch a Home tab,
      // so leave the inbox first to make the result visible.
      if (item.target is! OpenExternalUrl) Navigator.of(context).pop();
      handler(item.routePayload);
      if (!await inbox.markRead(item) &&
          SessionCache.instance.generation == startGen &&
          SessionCache.instance.user.value == startUser &&
          messenger.mounted &&
          messengerContext.mounted) {
        _reportFailure(messengerContext, message: failureMessage);
      }
      return;
    }
    final startGen = SessionCache.instance.generation;
    final startUser = SessionCache.instance.user.value;
    if (!await inbox.markRead(item) &&
        SessionCache.instance.generation == startGen &&
        SessionCache.instance.user.value == startUser &&
        context.mounted) {
      _reportFailure(context);
    }
  }

  /// Empty-inbox calls to action: same router as a push to [route].
  void _openRoute(BuildContext context, String route) {
    final handler = NotificationService.instance.onNotificationTap;
    if (handler == null) return;
    Navigator.of(context).pop();
    handler({'action_type': 'screen', 'action_url': route});
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    final inbox = ref.watch(notificationsInboxProvider);
    final hasUnread = inbox.value?.any((i) => !i.isRead) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsNotificationsTitle),
        // Shown only when it can act: a greyed-out "Read all" over an empty
        // or fully read inbox is noise (and fails text contrast).
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () async {
                final ok = await ref
                    .read(notificationsInboxProvider.notifier)
                    .markAllRead();
                if (!ok && context.mounted) _reportFailure(context);
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
              ),
              child: Text(l10n.settingsNotificationsReadAll),
            ),
        ],
      ),
      body: AppAsyncBody<List<NotificationItem>>(
        snapshot: inbox.toSnapshot(),
        english: english,
        onRetry: () => ref.invalidate(notificationsInboxProvider),
        fallbackOnEmptyError: const [],
        errorMessage: (error) => error is ApiException
            ? error.displayMessage
            : l10n.settingsNotificationsLoadFailed,
        loading: const ListScreenSkeleton(
          itemCount: 5,
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 18, AppSpacing.lg, 32),
        ),
        isEmpty: (items) => items.isEmpty,
        empty: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: NotificationsEmptyState(
            onRoute: NotificationService.instance.onNotificationTap == null
                ? null
                : (route) => _openRoute(context, route),
          ),
        ),
        builder: (items) => NotificationInbox(
          items: items,
          onRefresh: () => _refresh(ref),
          onOpen: (item) => unawaited(_open(context, ref, item)),
        ),
      ),
    );
  }
}

/// Grouped inbox: filter chips over date sections (today, yesterday, this
/// week, earlier). Filtering is client-side over the loaded rows.
class NotificationInbox extends StatefulWidget {
  const NotificationInbox({
    super.key,
    required this.items,
    required this.onRefresh,
    required this.onOpen,
    this.now,
  });

  final List<NotificationItem> items;
  final Future<void> Function() onRefresh;
  final ValueChanged<NotificationItem> onOpen;

  /// Clock for the date sections; tests pin it.
  final DateTime? now;

  @override
  State<NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<NotificationInbox> {
  bool _unreadOnly = false;
  NotificationCategory? _category;

  void _select({bool unreadOnly = false, NotificationCategory? category}) {
    setState(() {
      _unreadOnly = unreadOnly;
      _category = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = AppLocale.isEnglish(context);
    final present = {for (final item in widget.items) item.category};
    // A category whose rows went away on refresh falls back to "All".
    final category = present.contains(_category) ? _category : null;
    final unread = widget.items.where((i) => !i.isRead).length;
    final visible = [
      for (final item in widget.items)
        if ((!_unreadOnly || !item.isRead) &&
            (category == null || item.category == category))
          item,
    ];
    final groups = groupNotifications(visible, widget.now ?? DateTime.now());

    final chips = <Widget>[
      NotificationFilterChip(
        label: l10n.settingsNotificationsFilterAll,
        count:
            unread == 0 ? null : AppFormat.digits('$unread', english: english),
        selected: !_unreadOnly && category == null,
        onTap: _select,
      ),
      NotificationFilterChip(
        label: l10n.settingsNotificationsUnread,
        selected: _unreadOnly,
        onTap: () => _select(unreadOnly: true),
      ),
      for (final c in NotificationCategory.values)
        if (present.contains(c))
          NotificationFilterChip(
            label: notificationCategoryLabel(l10n, c),
            selected: category == c,
            onTap: () => _select(category: c),
          ),
    ];

    var order = 0;
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxs),
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xs),
                    chips[i],
                  ],
                ],
              ),
            ),
          ),
          if (groups.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              sliver: SliverToBoxAdapter(
                child: Text(
                  l10n.settingsNotificationsFilterEmpty,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm(context.sirati)
                      .copyWith(color: context.sirati.textSecondary),
                ),
              ),
            ),
          for (final group in groups) ...[
            SliverToBoxAdapter(child: NotificationGroupHeader(group: group)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList.separated(
                itemCount: group.items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = group.items[index];
                  return MotionReveal(
                    order: (order++).clamp(0, 5),
                    child: NotificationCard(
                      item: item,
                      onTap: () => widget.onOpen(item),
                    ),
                  );
                },
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}

String notificationCategoryLabel(
  AppLocalizations l10n,
  NotificationCategory category,
) =>
    switch (category) {
      NotificationCategory.cv => l10n.settingsNotificationsCategoryCv,
      NotificationCategory.jobs => l10n.settingsNotificationsCategoryJobs,
      NotificationCategory.analysis =>
        l10n.settingsNotificationsCategoryAnalysis,
      NotificationCategory.learning =>
        l10n.settingsNotificationsCategoryLearning,
      NotificationCategory.general => l10n.settingsNotificationsCategoryGeneral,
    };

/// Pill filter; selected is a primary fill with `onPrimary` text.
class NotificationFilterChip extends StatelessWidget {
  const NotificationFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Unread badge, already formatted for the locale.
  final String? count;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final shape = StadiumBorder(
      side: BorderSide(color: selected ? c.primary : c.borderStrong),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: selected ? c.primary : c.surface,
            shape: shape,
            child: InkWell(
              onTap: onTap,
              customBorder: shape,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.labelMd(c).copyWith(
                        color: selected ? c.onPrimary : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        constraints: const BoxConstraints(minWidth: 20),
                        decoration: BoxDecoration(
                          color: selected ? c.onPrimary : c.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelMd(c).copyWith(
                            color: selected ? c.primary : c.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section title on the start side; unread count (or row count) at the end.
class NotificationGroupHeader extends StatelessWidget {
  const NotificationGroupHeader({super.key, required this.group});

  final NotificationGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = AppLocale.isEnglish(context);
    final c = context.sirati;
    final title = switch (group.period) {
      NotificationPeriod.today => l10n.settingsNotificationsToday,
      NotificationPeriod.yesterday => l10n.settingsNotificationsYesterday,
      NotificationPeriod.thisWeek => l10n.settingsNotificationsThisWeek,
      NotificationPeriod.earlier => l10n.settingsNotificationsEarlier,
    };
    final unread = group.unreadCount;
    final meta = AppFormat.digits(
      unread > 0
          ? l10n.settingsNotificationsNewCount(unread)
          : l10n.settingsNotificationsCount(group.items.length),
      english: english,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppTextStyles.titleSm(c).copyWith(color: c.primaryInk),
              ),
            ),
          ),
          Text(
            meta,
            style: AppTextStyles.labelMd(c).copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Icon and tile colours per category: container / on-container token pairs
/// so the icon holds contrast in light and dark.
({IconData icon, Color fg, Color bg}) notificationTileStyle(
  NotificationItem item,
  SiratiColors c,
) {
  if (item.isFailure) {
    return (
      icon: Icons.error_outline_rounded,
      fg: c.onErrorContainer,
      bg: c.errorLight,
    );
  }
  return notificationCategoryTile(item.category, c);
}

({IconData icon, Color fg, Color bg}) notificationCategoryTile(
  NotificationCategory category,
  SiratiColors c,
) {
  return switch (category) {
    NotificationCategory.cv => (
        icon: Icons.description_outlined,
        fg: c.primaryInk,
        bg: c.primaryLight,
      ),
    NotificationCategory.jobs => (
        icon: Icons.work_outline_rounded,
        fg: c.onSuccessContainer,
        bg: c.successLight,
      ),
    NotificationCategory.analysis => (
        icon: Icons.insights_rounded,
        fg: c.onWarningContainer,
        bg: c.warningLight,
      ),
    NotificationCategory.learning => (
        icon: Icons.school_outlined,
        fg: c.tertiary,
        bg: c.tertiaryLight,
      ),
    NotificationCategory.general => (
        icon: Icons.notifications_none_rounded,
        fg: c.textSecondary,
        bg: c.surfaceContainer,
      ),
  };
}

String notificationTimeLabel(
  NotificationItem item,
  AppLocalizations l10n, {
  required bool english,
}) {
  final at = item.createdAt;
  if (at != null) return AppFormat.relativeTime(at, l10n);
  if (item.createdLabel.isEmpty) return '';
  return AppFormat.digits(item.createdLabel, english: english);
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({super.key, required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    final c = context.sirati;
    final time = notificationTimeLabel(item, AppLocalizations.of(context),
        english: english);
    final tile = notificationTileStyle(item, c);
    final radius = BorderRadius.circular(16);
    final unread = !item.isRead;

    return PressScale(
      child: DecoratedBox(
        decoration:
            BoxDecoration(borderRadius: radius, boxShadow: c.softShadow),
        child: Material(
          color: unread ? c.primaryLight : c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: unread ? c.primary.withValues(alpha: .28) : c.border,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    // On the teal unread tint the light tile tints blend in;
                    // a surface tile with a category-coloured edge pops.
                    decoration: BoxDecoration(
                      color: unread ? c.surface : tile.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: unread
                          ? Border.all(color: tile.fg.withValues(alpha: .35))
                          : null,
                    ),
                    child: Icon(tile.icon, size: 22, color: tile.fg),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                textAlign: TextAlign.start,
                                style: AppTextStyles.titleSm(c).copyWith(
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (unread)
                              Semantics(
                                label: l10n.settingsNotificationsUnread,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsetsDirectional.only(
                                      start: AppSpacing.xs, top: 6),
                                  decoration: BoxDecoration(
                                    color: c.primaryInk,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (item.opensSomething) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: c.textSecondary,
                                textDirection: Directionality.of(context),
                              ),
                            ],
                          ],
                        ),
                        if (item.body.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            item.body,
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm(c),
                          ),
                        ],
                        if (time.isNotEmpty || _showsViewCv) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  time,
                                  style: AppTextStyles.labelMd(c)
                                      .copyWith(color: c.textSecondary),
                                ),
                              ),
                              if (_showsViewCv)
                                FilledButton.icon(
                                  onPressed: onTap,
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 18),
                                  label: Text(l10n.settingsNotificationsViewCv),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: c.primary,
                                    foregroundColor: c.onPrimary,
                                    minimumSize:
                                        const Size(0, AppTouchTarget.min),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.mdAll),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Inline shortcut only where it saves a decision: a fresh, ready CV.
  bool get _showsViewCv =>
      !item.isRead && item.type == 'cv_ready' && item.opensSomething;
}

/// Inbox with no notifications at all: what will arrive here, plus the two
/// actions that start producing it. [onRoute] opens an in-app route through
/// the push router; without one the buttons are hidden.
class NotificationsEmptyState extends StatelessWidget {
  const NotificationsEmptyState({super.key, required this.onRoute});

  final ValueChanged<String>? onRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.sirati;
    final previews = [
      (
        NotificationCategory.cv,
        l10n.settingsNotificationsPreviewCvTitle,
        l10n.settingsNotificationsPreviewCvBody,
      ),
      (
        NotificationCategory.jobs,
        l10n.settingsNotificationsPreviewJobsTitle,
        l10n.settingsNotificationsPreviewJobsBody,
      ),
      (
        NotificationCategory.analysis,
        l10n.settingsNotificationsPreviewAnalysisTitle,
        l10n.settingsNotificationsPreviewAnalysisBody,
      ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
      children: [
        const Center(child: _BellHero()),
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.settingsNotificationsEmptyTitle,
            textAlign: TextAlign.center,
            style: AppTypography.of(context, AppTypography.titleLg),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.settingsNotificationsEmptyBody,
          textAlign: TextAlign.center,
          style: AppTypography.of(context, AppTypography.bodyMd,
              color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: c.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20, color: c.primaryInk),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l10n.settingsNotificationsPreviewTitle,
                          style: AppTextStyles.titleSm(c),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (final (category, title, body) in previews) ...[
                Divider(height: 1, color: c.border),
                _PreviewRow(category: category, title: title, body: body),
              ],
            ],
          ),
        ),
        if (onRoute case final open?) ...[
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () => open('cv-analysis'),
            icon: const Icon(Icons.document_scanner_outlined, size: 20),
            label: Text(l10n.settingsNotificationsScanCta),
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
              textStyle: AppTypography.of(context, AppTypography.labelLg),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () => open('create-cv'),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
            label: Text(l10n.settingsNotificationsCreateCvCta),
            style: TextButton.styleFrom(
              foregroundColor: c.primaryInk,
              minimumSize: const Size.fromHeight(AppTouchTarget.min),
              textStyle: AppTypography.of(context, AppTypography.labelLg),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bell on a primary disc inside two soft rings.
class _BellHero extends StatelessWidget {
  const _BellHero();

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return ExcludeSemantics(
      child: Container(
        width: 112,
        height: 112,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.primaryLight.withValues(alpha: .5),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.primaryLight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary),
            child: Icon(Icons.notifications_none_rounded,
                size: 36, color: c.onPrimary),
          ),
        ),
      ),
    );
  }
}

/// A sample of a future notification, using the inbox's own category tile.
class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.category,
    required this.title,
    required this.body,
  });

  final NotificationCategory category;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final tile = notificationCategoryTile(category, c);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tile.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tile.icon, size: 22, color: tile.fg),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSm(c)),
                const SizedBox(height: AppSpacing.xxs),
                Text(body, style: AppTextStyles.bodySm(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
