import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';

/// The two iOS 26 page patterns (restyle ticket 10).
///
/// * [plain]: content screens on [SiratiColors.pageBackground]; cards, fields,
///   secondary buttons and chips are filled with [SiratiColors.cardFill].
/// * [grouped]: forms, lists, settings and detail pages on
///   [SiratiColors.groupedBackground]; the same controls are filled with
///   [SiratiColors.groupedCard] so they keep an edge against the page.
enum PageSurfaceKind { plain, grouped }

/// Tells a subtree which page pattern it sits on. Every screen is [plain]
/// unless it is wrapped in [GroupedSurface].
class PageSurface extends InheritedWidget {
  const PageSurface({super.key, required this.kind, required super.child});

  final PageSurfaceKind kind;

  /// The pattern the nearest [GroupedSurface] (or none) sets.
  static PageSurfaceKind of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageSurface>()?.kind ??
      PageSurfaceKind.plain;

  /// Page colour for [kind].
  static Color pageColor(SiratiColors c, PageSurfaceKind kind) =>
      kind == PageSurfaceKind.grouped ? c.groupedBackground : c.pageBackground;

  /// Fill for cards, fields, secondary buttons and chips on [kind].
  static Color fillColor(SiratiColors c, PageSurfaceKind kind) =>
      kind == PageSurfaceKind.grouped ? c.groupedCard : c.cardFill;

  /// Fill for cards, fields, secondary buttons and chips here.
  static Color fillOf(BuildContext context) =>
      fillColor(context.sirati, of(context));

  @override
  bool updateShouldNotify(PageSurface oldWidget) => oldWidget.kind != kind;
}

/// The one API for a grouped page: wrap the screen's [Scaffold] (or a sheet's
/// content) in it.
///
/// ```dart
/// return GroupedSurface(child: Scaffold(appBar: ..., body: ...));
/// ```
///
/// It swaps the scaffold and app bar to [SiratiColors.groupedBackground] and
/// the fills of themed fields, secondary buttons, chips and cards to
/// [SiratiColors.groupedCard] (see [AppTheme.grouped]).
class GroupedSurface extends StatelessWidget {
  const GroupedSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.grouped(Theme.of(context)),
      child: PageSurface(kind: PageSurfaceKind.grouped, child: child),
    );
  }
}
