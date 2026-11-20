import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// One option of an [AppSegmentedControl].
@immutable
class AppSegment<T> {
  const AppSegment({
    required this.value,
    required this.label,
    this.icon,
    this.semanticLabel,
  });

  final T value;

  /// Visible label. Keep it short: segments share the track width equally.
  final String label;

  /// Optional leading icon (for example the CV builder's section tabs).
  final IconData? icon;

  /// What a screen reader says instead of [label] (for example the full
  /// language name behind a short code).
  final String? semanticLabel;
}

/// One tab of an [AppSegmentedTabBar]; its value is its index.
@immutable
class AppSegmentedTab {
  const AppSegmentedTab({required this.label, this.icon, this.semanticLabel});

  final String label;
  final IconData? icon;
  final String? semanticLabel;
}

/// Fills and inks of a segmented control.
///
/// [AppSegmentedPalette.of] is the themed default, which follows the page
/// pattern ([PageSurface]): the track is that page's control fill and the
/// thumb is drawn in the other surface tone. Both inks hold AA on the track
/// AND on the thumb, so a label stays readable while the thumb slides under
/// it.
@immutable
class AppSegmentedPalette {
  const AppSegmentedPalette({
    required this.track,
    required this.thumb,
    required this.selectedInk,
    required this.unselectedInk,
    this.trackBorder = BorderSide.none,
    this.thumbBorder = BorderSide.none,
    this.thumbShadow = const [],
  });

  /// Themed default for the page pattern around [context].
  ///
  /// * Plain page: `cardFill` track; the thumb is white (`groupedCard`) in
  ///   light mode and the lighter `surfaceHigh` in dark mode, so it looks
  ///   raised.
  /// * Grouped page: the page is `groupedBackground`, which `cardFill`
  ///   matches, so the track takes the grouped control fill (`groupedCard`)
  ///   and the thumb the `cardFill` tone.
  ///
  /// Track and thumb fills are close in tone on purpose (the iOS look), so
  /// the thumb carries an `outline` edge: that boundary holds the 3:1
  /// non-text contrast against the track on either page, in both themes.
  factory AppSegmentedPalette.of(BuildContext context) {
    final c = context.sirati;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grouped = PageSurface.of(context) == PageSurfaceKind.grouped;
    return AppSegmentedPalette(
      track: PageSurface.fillOf(context),
      thumb: grouped
          ? c.cardFill
          : dark
              ? c.surfaceHigh
              : c.groupedCard,
      // Teal ink marks the selection as well as the thumb.
      selectedInk: c.primaryInk,
      unselectedInk: c.textSecondary,
      // 2dp, not a hairline: on a 1x raster a 1dp edge that lands on a
      // half pixel is antialiased to under 3:1; 2dp always paints a fully
      // covered pixel column.
      thumbBorder: BorderSide(color: c.outline, width: 2),
      thumbShadow: c.softShadow,
    );
  }

  final Color track;
  final Color thumb;
  final Color selectedInk;
  final Color unselectedInk;
  final BorderSide trackBorder;
  final BorderSide thumbBorder;
  final List<BoxShadow> thumbShadow;
}

/// Grey capsule segmented control with a sliding thumb, driven by a value.
///
/// - Thumb position follows reading direction (the first segment sits at the
///   start edge); under reduced motion it jumps instead of sliding.
/// - Every segment is a semantics tab with its label and selected state.
/// - Segments are at least [minSegmentHeight] tall and grow with text scale
///   (see [segmentHeightFor]).
///
/// To drive it from a [TabController] use [AppSegmentedTabBar].
class AppSegmentedControl<T> extends StatefulWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.colors,
    this.expand = true,
  });

  final List<AppSegment<T>> segments;

  /// The selected segment's value. Null, or a value no segment carries,
  /// selects nothing: the thumb hides and every segment is tappable.
  final T? value;

  /// Called with the tapped segment's value. Null disables the control.
  final ValueChanged<T>? onChanged;

  /// Defaults to [AppSegmentedPalette.of].
  final AppSegmentedPalette? colors;

  /// Fill the available width (true) or size to the widest label times the
  /// segment count (false, for app-bar actions and other unbounded slots).
  final bool expand;

  /// Space between the track edge and the thumb.
  static const trackInset = 2.0;

  /// Segments are at least 44 tall, so the whole control is
  /// [AppTouchTarget.min] (48) tall at normal text size.
  static const minSegmentHeight = AppTouchTarget.min - 2 * trackInset;

  /// Label style token.
  static const labelToken = AppTypography.bodySm;

  /// Height of one segment for [scaler]: the taller (Arabic) label line plus
  /// padding, never under [minSegmentHeight].
  static double segmentHeightFor(TextScaler scaler) {
    final line = scaler.scale(labelToken.size) *
        math.max(labelToken.heightArabic, labelToken.heightLatin);
    return math.max(minSegmentHeight, line + 2 * AppSpacing.xs);
  }

  /// Height of the whole control for [scaler].
  static double heightFor(TextScaler scaler) =>
      segmentHeightFor(scaler) + 2 * trackInset;

  @override
  State<AppSegmentedControl<T>> createState() => _AppSegmentedControlState<T>();
}

class _AppSegmentedControlState<T> extends State<AppSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  late double _target = math.max(_index, 0).toDouble();
  late final AnimationController _position =
      AnimationController.unbounded(vsync: this, value: _target);

  /// Index of the selected segment, or -1 when nothing is selected.
  int get _index => widget.value == null
      ? -1
      : widget.segments.indexWhere((s) => s.value == widget.value);

  @override
  void didUpdateWidget(covariant AppSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _index;
    if (index < 0) return;
    final target = index.toDouble();
    if (target == _target) return;
    final appearing = oldWidget.value == null ||
        !oldWidget.segments.any((s) => s.value == oldWidget.value);
    _target = target;
    if (appearing || MotionSettings.reduce(context)) {
      _position.value = target;
    } else {
      _position.animateTo(
        target,
        duration: MotionDurations.navIndicator,
        curve: MotionCurves.state,
      );
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onChanged = widget.onChanged;
    return SegmentedTrack(
      labels: [
        for (final s in widget.segments)
          AppSegmentedTab(
            label: s.label,
            icon: s.icon,
            semanticLabel: s.semanticLabel,
          ),
      ],
      position: _position,
      selectedIndex: _index,
      onTap: onChanged == null
          ? null
          : (i) {
              if (i != _index) onChanged(widget.segments[i].value);
            },
      colors: widget.colors ?? AppSegmentedPalette.of(context),
      expand: widget.expand,
    );
  }
}

/// [AppSegmentedControl] bound to a [TabController], to replace a Material
/// [TabBar] (for example in [AppBar.bottom]).
///
/// Uses [controller] or, when null, the ambient [DefaultTabController]. The
/// thumb follows the controller's animation, so a [TabBarView] swipe drags it
/// along and a tap animates the pages.
///
/// Reduced motion: a tap jumps the thumb, and the [TabBarView] jumps only if
/// the controller's `animationDuration` is zero (the view reads nothing
/// else). Build the controller, or [DefaultTabController], with
/// `animationDuration: AppSegmentedTabBar.pageDuration(context)`; a debug
/// build reports a controller that would still slide the pages.
///
/// [preferredSize] grows with [textScaler]: pass
/// `MediaQuery.textScalerOf(context)` so an app bar reserves enough height.
class AppSegmentedTabBar extends StatefulWidget implements PreferredSizeWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.colors,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xxs,
      AppSpacing.md,
      AppSpacing.xs,
    ),
    required this.textScaler,
  });

  final List<AppSegmentedTab> tabs;
  final TabController? controller;
  final AppSegmentedPalette? colors;
  final EdgeInsets padding;
  final TextScaler textScaler;

  /// Page-change duration for the [TabController] behind this bar: zero
  /// under reduced motion, so pages jump with the thumb.
  static Duration pageDuration(BuildContext context) =>
      MotionSettings.reduce(context) ? Duration.zero : kTabScrollDuration;

  @override
  Size get preferredSize => Size.fromHeight(
      AppSegmentedControl.heightFor(textScaler) + padding.vertical);

  @override
  State<AppSegmentedTabBar> createState() => _AppSegmentedTabBarState();
}

class _AppSegmentedTabBarState extends State<AppSegmentedTabBar> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bind();
  }

  @override
  void didUpdateWidget(covariant AppSegmentedTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) _bind();
  }

  void _bind() {
    final next = widget.controller ?? DefaultTabController.of(context);
    assert(
      next.length == widget.tabs.length,
      'TabController.length (${next.length}) must equal tabs '
      '(${widget.tabs.length})',
    );
    if (identical(next, _controller)) return;
    _controller?.removeListener(_onIndex);
    _controller = next..addListener(_onIndex);
  }

  void _onIndex() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onIndex);
    super.dispose();
  }

  void _select(int i) {
    final controller = _controller!;
    if (i == controller.index) return;
    if (MotionSettings.reduce(context)) {
      assert(() {
        if (controller.animationDuration != Duration.zero) {
          FlutterError.reportError(FlutterErrorDetails(
            exception: FlutterError(
              'Reduced motion is on but the TabController animates pages '
              'for ${controller.animationDuration}. Create it with '
              'animationDuration: AppSegmentedTabBar.pageDuration(context).',
            ),
            library: 'app_segmented_control',
          ));
        }
        return true;
      }());
      controller.index = i;
    } else {
      controller.animateTo(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    return Padding(
      padding: widget.padding,
      child: SegmentedTrack(
        labels: widget.tabs,
        position: controller.animation!,
        selectedIndex: controller.index,
        onTap: _select,
        colors: widget.colors ?? AppSegmentedPalette.of(context),
        expand: true,
      ),
    );
  }
}

/// The painted control shared by both modes. Public for tests and for
/// callers that own their own position animation; prefer the two widgets
/// above.
class SegmentedTrack extends StatelessWidget {
  const SegmentedTrack({
    super.key,
    required this.labels,
    required this.position,
    required this.selectedIndex,
    required this.onTap,
    required this.colors,
    required this.expand,
  });

  /// Key of the sliding thumb's painted box.
  static const thumbKey = ValueKey('app-segmented-thumb');

  /// Key of the track's painted box.
  static const trackKey = ValueKey('app-segmented-track');

  final List<AppSegmentedTab> labels;

  /// Thumb position in segment units (0 = first segment). Fractional while
  /// sliding or while a tab view is being swiped.
  final Animation<double> position;

  /// The selected segment for semantics; -1 selects nothing and hides the
  /// thumb.
  final int selectedIndex;
  final ValueChanged<int>? onTap;
  final AppSegmentedPalette colors;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    assert(n > 0, 'a segmented control needs at least one segment');
    final height =
        AppSegmentedControl.segmentHeightFor(MediaQuery.textScalerOf(context));
    const inset = AppSegmentedControl.trackInset;
    const capsule = BorderRadius.all(Radius.circular(AppRadius.capsule));

    Widget control = DecoratedBox(
      key: trackKey,
      decoration: BoxDecoration(
        color: colors.track,
        borderRadius: capsule,
        border: Border.fromBorderSide(colors.trackBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(inset),
        child: AnimatedBuilder(
          animation: position,
          builder: (context, _) {
            final pos = position.value.clamp(0.0, (n - 1).toDouble());
            final hasSelection = selectedIndex >= 0;
            final inkIndex = hasSelection ? pos.round() : -1;
            return Stack(
              children: [
                if (hasSelection)
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: FractionallySizedBox(
                        widthFactor: 1 / n,
                        alignment: AlignmentDirectional(
                          n == 1 ? 0 : -1 + 2 * pos / (n - 1),
                          0,
                        ),
                        child: DecoratedBox(
                          key: thumbKey,
                          decoration: BoxDecoration(
                            color: colors.thumb,
                            borderRadius: capsule,
                            border: Border.fromBorderSide(colors.thumbBorder),
                            boxShadow: colors.thumbShadow,
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      Expanded(
                        child: _Segment(
                          tab: labels[i],
                          height: height,
                          selected: i == selectedIndex,
                          inked: i == inkIndex,
                          colors: colors,
                          onTap: onTap == null ? null : () => onTap!(i),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
    if (!expand) control = IntrinsicWidth(child: control);
    return Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      child: control,
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.tab,
    required this.height,
    required this.selected,
    required this.inked,
    required this.colors,
    required this.onTap,
  });

  final AppSegmentedTab tab;
  final double height;
  final bool selected;

  /// Whether the thumb currently sits under this label.
  final bool inked;
  final AppSegmentedPalette colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = inked ? colors.selectedInk : colors.unselectedInk;
    final style = AppTypography.of(
      context,
      AppSegmentedControl.labelToken,
      color: ink,
    ).copyWith(fontWeight: inked ? FontWeight.w600 : FontWeight.w400);
    Widget label = Text(
      tab.label,
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
    if (tab.semanticLabel != null) label = ExcludeSemantics(child: label);
    final icon = tab.icon;

    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.tab,
        selected: selected,
        enabled: onTap != null,
        label: tab.semanticLabel,
        child: MouseRegion(
          cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: ink),
                      const SizedBox(width: AppSpacing.xxs),
                    ],
                    Flexible(child: label),
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
