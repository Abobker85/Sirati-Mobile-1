import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';

/// Inset-grouped section: an optional grey header, one rounded
/// [SiratiColors.groupedCard] card holding the rows, hairline separators
/// between them, and an optional grey footer. Put it on a
/// [SiratiColors.groupedBackground] page.
///
/// ```dart
/// AppListSection(
///   header: l10n.accountSection,
///   children: [
///     AppListTile(leadingIcon: Icons.person_outline, title: .., onTap: ..),
///     if (canChangePassword) AppListTile(..),
///   ],
/// )
/// ```
///
/// Rows are usually [AppListTile]s, which drop their own card look inside a
/// section (see [AppListSection.contains]); any other widget works too, e.g.
/// a `SwitchListTile`. Separators are inserted here, so callers may leave
/// rows out conditionally without dangling lines. They start
/// [separatorIndent] from the start edge (under the row text, past the
/// icon) and mirror in RTL. A section with no rows draws nothing.
class AppListSection extends StatelessWidget {
  const AppListSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.separatorIndent = iconSeparatorIndent,
  });

  /// Grey label above the card, announced as a heading.
  final String? header;

  /// Grey help text under the card.
  final String? footer;

  /// The rows, top to bottom.
  final List<Widget> children;

  /// Gap at the start of each separator.
  final double separatorIndent;

  /// Separator start for rows with a leading icon: row padding + icon box +
  /// gap, so the line starts under the title text.
  static const double iconSeparatorIndent =
      rowPadding + AppListTileMetrics.groupedIcon + AppListTileMetrics.gap;

  /// Separator start for rows without an icon.
  static const double textSeparatorIndent = rowPadding;

  /// Start and end padding of a row inside a section.
  static const double rowPadding = 16;

  /// Key of the card, for tests and layout checks.
  static const cardKey = ValueKey('app-list-section-card');

  /// Whether [context] sits inside an [AppListSection] card.
  static bool contains(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SectionScope>() != null;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final c = context.sirati;
    final labelStyle = AppTypography.of(
      context,
      AppTypography.caption,
      color: c.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              rowPadding,
              0,
              rowPadding,
              AppSpacing.xs + 2,
            ),
            child: Semantics(
              header: true,
              child:
                  Text(header!, textAlign: TextAlign.start, style: labelStyle),
            ),
          ),
        Material(
          key: cardKey,
          color: c.groupedCard,
          borderRadius: AppRadius.cardAll,
          clipBehavior: Clip.antiAlias,
          child: _SectionScope(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      thickness: 0,
                      indent: separatorIndent,
                      color: c.separator,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              rowPadding,
              AppSpacing.xs + 2,
              rowPadding,
              0,
            ),
            child: Text(footer!, textAlign: TextAlign.start, style: labelStyle),
          ),
      ],
    );
  }
}

/// Sizes shared by [AppListSection] and the rows inside it.
abstract final class AppListTileMetrics {
  /// Icon box of a row inside a section.
  static const double groupedIcon = 32;

  /// Icon box of a standalone row.
  static const double standaloneIcon = 40;

  /// Gap between the icon box and the text.
  static const double gap = 12;
}

class _SectionScope extends InheritedWidget {
  const _SectionScope({required super.child});

  @override
  bool updateShouldNotify(_SectionScope oldWidget) => false;
}
