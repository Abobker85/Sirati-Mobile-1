import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Key of the lifted drag proxy's fill.
const reorderProxyKey = ValueKey('reorder-lift-proxy');

/// Shared tactile lift decorator for [ReorderableListView] drag proxies.
Widget reorderLiftProxyDecorator(
  Widget child,
  int index,
  Animation<double> animation,
) {
  return Builder(
    builder: (context) {
      final c = context.sirati;
      // Entry rows are flat (no fill of their own), so the lifted copy gets
      // the white card fill: it must hide the rows it is dragged over. The
      // proxy lives in the overlay, outside the grouped theme, hence the
      // explicit colour.
      final lifted = Material(
        key: reorderProxyKey,
        color: c.groupedCard,
        borderRadius: AppRadius.cardAll,
        clipBehavior: Clip.antiAlias,
        child: child,
      );
      if (MotionSettings.reduce(context)) return lifted;
      return AnimatedBuilder(
        animation: animation,
        child: lifted,
        builder: (context, inner) {
          final t = Curves.easeOut.transform(animation.value);
          return Transform.scale(
            scale: 1.0 + 0.02 * t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.cardAll,
                boxShadow: AppShadows.of(
                  c,
                  elevation: AppElevation.sheet * t,
                ),
              ),
              child: inner,
            ),
          );
        },
      );
    },
  );
}

/// Generic card wrapper used across all CV builder section editors (SIRATI-36).
///
/// Provides a unified visual style, entry count badge, collapse/expand toggle,
/// and primary "Add Entry" action.
class SectionCardWrapper extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final int entryCount;
  final VoidCallback? onAdd;
  final String? addLabel;
  final Widget child;
  final bool initialExpanded;
  final String? validationError;

  const SectionCardWrapper({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.entryCount = 0,
    this.onAdd,
    this.addLabel,
    required this.child,
    this.initialExpanded = true,
    this.validationError,
  });

  /// Key of the collapsible header.
  static const headerKey = ValueKey('section-card-header');

  /// Key of the entry count badge.
  static const countKey = ValueKey('section-card-count');

  @override
  State<SectionCardWrapper> createState() => _SectionCardWrapperState();
}

class _SectionCardWrapperState extends State<SectionCardWrapper>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initialExpanded;
  late final AnimationController _expandController = AnimationController(
    vsync: this,
    duration: MotionDurations.medium,
    value: widget.initialExpanded ? 1.0 : 0.0,
  );
  late final Animation<double> _expandAnim = CurvedAnimation(
    parent: _expandController,
    curve: MotionCurves.enter,
    reverseCurve: MotionCurves.exit,
  );

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    final next = !_expanded;
    setState(() => _expanded = next);
    if (MotionSettings.reduce(context)) {
      _expandController.value = next ? 1.0 : 0.0;
    } else if (next) {
      unawaited(_expandController.forward());
    } else {
      unawaited(_expandController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final reduce = MotionSettings.reduce(context);

    // iOS 26 grouped section: a tappable header on the page, then the
    // section's fields straight on the grouped page (white fills on grey).
    // Nothing is nested in a second fill: in dark mode the card and field
    // fills are too close to tell apart.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Semantics(
          button: true,
          expanded: _expanded,
          child: InkWell(
            key: SectionCardWrapper.headerKey,
            onTap: _toggleExpanded,
            borderRadius: AppRadius.cardAll,
            splashFactory: NoSplash.splashFactory,
            highlightColor: c.pressOverlay(c.groupedBackground),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: c.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(widget.icon, size: 20, color: c.primaryInk),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.title,
                                  style: AppTypography.of(
                                    context,
                                    AppTypography.titleMd,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              if (widget.entryCount > 0) ...[
                                const SizedBox(width: AppSpacing.xs),
                                DecoratedBox(
                                  key: SectionCardWrapper.countKey,
                                  decoration: BoxDecoration(
                                    color: c.groupedCard,
                                    borderRadius: AppRadius.capsuleAll,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      '${widget.entryCount}',
                                      textDirection: TextDirection.ltr,
                                      style: AppTypography.of(
                                        context,
                                        AppTypography.labelMd,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: AppTypography.of(
                                context,
                                AppTypography.bodySm,
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: reduce ? Duration.zero : MotionDurations.fast,
                      curve: MotionCurves.state,
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Inline validation error
        if (widget.validationError != null &&
            widget.validationError!.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xxs,
              top: AppSpacing.xxs,
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: c.onErrorContainer),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    widget.validationError!,
                    style: AppTypography.of(
                      context,
                      AppTypography.bodySm,
                      color: c.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Collapsible Content: animate only on header toggle so child growth
        // inside an already-open section never animates or clips.
        SizeTransition(
          sizeFactor: _expandAnim,
          alignment: AlignmentDirectional.topStart,
          child: FadeTransition(
            opacity: _expandAnim,
            child: AnimatedBuilder(
              animation: _expandController,
              builder: (context, _) {
                if (!_expanded && _expandController.isDismissed) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      widget.child,
                      if (widget.onAdd != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppButton.secondary(
                          label: widget.addLabel ?? l10n.addItem,
                          icon: Icons.add,
                          onPressed: widget.onAdd,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A white inset-grouped card on the grouped editor page, for row-like
/// controls (switch rows, segmented switches, the section order list).
/// Fields never go inside it: they sit on the page itself.
class EditorGroupCard extends StatelessWidget {
  const EditorGroupCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.sirati.groupedCard,
        borderRadius: AppRadius.cardAll,
      ),
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
        child: child,
      ),
    );
  }
}

/// Generic reorderable entry list supporting RTL drag physics and accessible
/// Up / Down keyboard buttons (SIRATI-40).
class ReorderableEntryList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index)? onDelete;

  const ReorderableEntryList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      proxyDecorator: reorderLiftProxyDecorator,
      onReorderStart: (_) => unawaited(HapticFeedback.selectionClick()),
      // ignore: deprecated_member_use
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;
        final body = itemBuilder(context, item, index);

        return KeyedSubtree(
          // Key the row by the entry's stable identity (the tile's own key,
          // e.g. its id), not by hashCode: copyWith on every keystroke makes
          // a new object, and a changed key would rebuild the row's state.
          key: ValueKey<Object>(body.key ?? index),
          // Flat rows: entries are told apart by a hairline, not a box.
          child: Container(
            padding: EdgeInsets.only(
              top: isFirst ? 0 : AppSpacing.sm,
              bottom: isLast ? 0 : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(
                      bottom: BorderSide(color: context.sirati.separator),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reorder Drag Handle & Accessible Up/Down Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.xxs,
                        ),
                        child: Icon(Icons.drag_indicator, size: 20),
                      ),
                    ),
                    // Accessible move up button
                    IconButton(
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      tooltip: l10n.moveUp,
                      onPressed:
                          isFirst ? null : () => onReorder(index, index - 1),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                    // Accessible move down button
                    IconButton(
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      tooltip: l10n.moveDown,
                      onPressed:
                          isLast ? null : () => onReorder(index, index + 2),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 28),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.xs),
                // Entry Body
                Expanded(
                  child: body,
                ),
                // Delete button
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: context.sirati.error,
                    tooltip: l10n.deleteItem,
                    onPressed: () => onDelete!(index),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
