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
    this.labelPadding = defaultLabelPadding,
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

  /// Horizontal padding inside each segment, per side.
  final double labelPadding;

  /// Default [labelPadding].
  static const defaultLabelPadding = AppSpacing.sm;

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
      labelPadding: widget.labelPadding,
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
/// [preferredSize] reserves the height the labels need on this screen,
/// wrapped onto more lines when they do not fit side by side, so an app bar
/// always holds the whole bar. [height] overrides it (for a bar that is not
/// screen-wide, from [heightFor]).
class AppSegmentedTabBar extends StatefulWidget implements PreferredSizeWidget {
  const AppSegmentedTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.colors,
    this.padding = defaultPadding,
    this.labelPadding = AppSegmentedControl.defaultLabelPadding,
    required this.textScaler,
    this.height,
  });

  final List<AppSegmentedTab> tabs;
  final TabController? controller;
  final AppSegmentedPalette? colors;

  /// Space around the track.
  final EdgeInsets padding;

  /// Horizontal padding inside each segment, per side.
  final double labelPadding;
  final TextScaler textScaler;

  /// Exact preferred height, from [heightFor]. Null reserves one label line
  /// at [textScaler].
  final double? height;

  static const defaultPadding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.xxs,
    AppSpacing.md,
    AppSpacing.xs,
  );

  /// The bar's real height for [tabs] laid out across [width] (default: the
  /// screen width), including [padding]: taller than one line only when
  /// labels have to wrap.
  static double heightFor(
    BuildContext context, {
    required List<AppSegmentedTab> tabs,
    double? width,
    EdgeInsets padding = defaultPadding,
    double labelPadding = AppSegmentedControl.defaultLabelPadding,
  }) {
    final inner = (width ?? MediaQuery.sizeOf(context).width) -
        padding.horizontal -
        2 * AppSegmentedControl.trackInset;
    final layout = SegmentLayout.compute(
      context,
      labels: tabs,
      maxWidth: inner,
      labelPadding: labelPadding,
    );
    return layout.height +
        2 * AppSegmentedControl.trackInset +
        padding.vertical;
  }

  /// Page-change duration for the [TabController] behind this bar: zero
  /// under reduced motion, so pages jump with the thumb.
  static Duration pageDuration(BuildContext context) =>
      MotionSettings.reduce(context) ? Duration.zero : kTabScrollDuration;

  @override
  Size get preferredSize {
    final fixed = height;
    if (fixed != null) return Size.fromHeight(fixed);
    // Fail safe: reserve the wrapped height for these tabs on this screen,
    // so a caller never has to opt in for labels to stay whole. The bar
    // spans the view's width (an app bar's bottom), read without a context.
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    final screen =
        view == null ? null : view.physicalSize.width / view.devicePixelRatio;
    if (screen == null || screen <= 0) {
      return Size.fromHeight(
          AppSegmentedControl.heightFor(textScaler) + padding.vertical);
    }
    final track = SegmentLayout.heightWithoutContext(
      labels: tabs,
      maxWidth:
          screen - padding.horizontal - 2 * AppSegmentedControl.trackInset,
      labelPadding: labelPadding,
      scaler: textScaler,
    );
    return Size.fromHeight(
        track + 2 * AppSegmentedControl.trackInset + padding.vertical);
  }

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
        labelPadding: widget.labelPadding,
      ),
    );
  }
}

/// Segment widths and height for a track of a given inner width.
///
/// Like iOS `apportionsSegmentWidthsByContent`, but only when needed:
/// 1. every label fits in an equal share: equal widths ([equal]);
/// 2. otherwise, if the labels fit side by side: each segment gets its
///    label's width plus an equal share of the slack;
/// 3. otherwise each segment gets at least its longest word, the rest is
///    shared by label width, and labels wrap onto more lines (every segment
///    grows taller);
/// 4. if even the longest words do not fit side by side, segment padding
///    shrinks to [AppSpacing.xxs] first; if that is still not enough, every
///    label wraps at its longest word and all are drawn at one reduced
///    factor ([scale]).
/// No label is ever cut off or ellipsized.
@immutable
class SegmentLayout {
  const SegmentLayout._(
    this.widths,
    this.height,
    this.equal,
    this.labelPadding, {
    this.scale = 1,
    this.wrapWidths,
  });

  /// Padding inside each segment, per side: the requested one, or
  /// [AppSpacing.xxs] when padding had to give way before labels shrink.
  final double labelPadding;

  /// Segment widths in reading order.
  final List<double> widths;

  /// Height shared by every segment.
  final double height;

  /// Whether every segment has the same width (the classic control).
  final bool equal;

  /// Factor labels are drawn at: 1, except when even the longest words of
  /// all labels cannot sit side by side; then every label wraps at its
  /// longest word and is drawn at this same reduced factor.
  final double scale;

  /// Whether labels are scaled down (see [scale]).
  bool get scaled => scale < 1;

  /// Width each label wraps at before scaling, when [scaled].
  final List<double>? wrapWidths;

  /// Space for the icon and its gap, when a segment has one.
  static const iconSize = 18.0;
  static const iconGap = AppSpacing.xxs;

  /// Lays out [labels] across [maxWidth] (the track minus its inset) with the
  /// label style of [context].
  static SegmentLayout compute(
    BuildContext context, {
    required List<AppSegmentedTab> labels,
    required double maxWidth,
    required double labelPadding,
    bool allowWrap = true,
  }) {
    final defaults = DefaultTextStyle.of(context);
    // Measured exactly as [Text] will paint it, with the wider (selected)
    // weight so a label never outgrows its segment when it is selected.
    return measure(
      labels: labels,
      maxWidth: maxWidth,
      labelPadding: labelPadding,
      allowWrap: allowWrap,
      scaler: MediaQuery.textScalerOf(context),
      direction: Directionality.of(context),
      style: defaults.style.merge(
        AppTypography.of(context, AppSegmentedControl.labelToken)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      ),
      locale: Localizations.maybeLocaleOf(context),
      heightBehavior: defaults.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
    );
  }

  /// Height a track needs for [labels] across [maxWidth] without a
  /// [BuildContext]: the taller of the Arabic and Latin label metrics, so it
  /// holds the laid-out track in either reading direction.
  static double heightWithoutContext({
    required List<AppSegmentedTab> labels,
    required double maxWidth,
    required double labelPadding,
    required TextScaler scaler,
  }) {
    var height = AppSegmentedControl.segmentHeightFor(scaler);
    for (final arabic in [true, false]) {
      final layout = measure(
        labels: labels,
        maxWidth: maxWidth,
        labelPadding: labelPadding,
        allowWrap: true,
        scaler: scaler,
        direction: arabic ? TextDirection.rtl : TextDirection.ltr,
        style: AppSegmentedControl.labelToken
            .resolve(arabic: arabic)
            .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      );
      height = math.max(height, layout.height);
    }
    return height;
  }

  /// The layout for an explicit label [style] (see [compute]).
  static SegmentLayout measure({
    required List<AppSegmentedTab> labels,
    required double maxWidth,
    required double labelPadding,
    required bool allowWrap,
    required TextScaler scaler,
    required TextDirection direction,
    required TextStyle style,
    Locale? locale,
    TextHeightBehavior? heightBehavior,
  }) {
    final n = labels.length;
    final minHeight = AppSegmentedControl.segmentHeightFor(scaler);

    double chrome(AppSegmentedTab tab) =>
        2 * labelPadding + (tab.icon == null ? 0 : iconSize + iconGap);

    // One logical pixel of slack absorbs sub-pixel rounding between this
    // measurement and the painted paragraph.
    double whole(double width) => width.ceilToDouble() + 1;

    TextPainter painter(String text) => TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: direction,
          textScaler: scaler,
          textAlign: TextAlign.center,
          locale: locale,
          textHeightBehavior: heightBehavior,
        );

    final natural = <double>[];
    final minimum = <double>[];
    for (final tab in labels) {
      final tp = painter(tab.label)..layout();
      natural.add(whole(tp.width) + chrome(tab));
      // Longest unbreakable run: the narrowest the label can wrap to.
      minimum.add(whole(tp.minIntrinsicWidth) + chrome(tab));
      tp.dispose();
    }
    double sum(List<double> xs) => xs.fold<double>(0, (a, b) => a + b);
    final widest = natural.reduce(math.max);

    if (widest * n <= maxWidth) {
      return SegmentLayout._(
          List.filled(n, maxWidth / n), minHeight, true, labelPadding);
    }
    if (sum(natural) <= maxWidth) {
      final slack = (maxWidth - sum(natural)) / n;
      return SegmentLayout._(
          [for (final w in natural) w + slack], minHeight, false, labelPadding);
    }
    if (allowWrap && sum(minimum) <= maxWidth) {
      // Every word fits its segment; share the rest by how much each label
      // still wants, and let labels wrap.
      final want = [for (var i = 0; i < n; i++) natural[i] - minimum[i]];
      final totalWant = sum(want);
      final spare = maxWidth - sum(minimum);
      final widths = [
        for (var i = 0; i < n; i++)
          minimum[i] +
              (totalWant == 0 ? spare / n : spare * want[i] / totalWant),
      ];
      var height = minHeight;
      for (var i = 0; i < n; i++) {
        final tp = painter(labels[i].label)
          ..layout(maxWidth: widths[i] - chrome(labels[i]));
        height = math.max(height, tp.height.ceilToDouble() + 2 * AppSpacing.xs);
        tp.dispose();
      }
      return SegmentLayout._(widths, height, false, labelPadding);
    }
    // Before any label shrinks, segment padding gives way.
    if (labelPadding > AppSpacing.xxs) {
      return measure(
        labels: labels,
        maxWidth: maxWidth,
        labelPadding: AppSpacing.xxs,
        allowWrap: allowWrap,
        scaler: scaler,
        direction: direction,
        style: style,
        locale: locale,
        heightBehavior: heightBehavior,
      );
    }
    // Some word cannot fit even with every label wrapped (or wrapping is
    // off): each label wraps at its longest word (one line without
    // wrapping), and all labels are drawn at the one factor that fits them
    // side by side. Padding and icons keep their size.
    final chromes = [for (final tab in labels) chrome(tab)];
    final text = [
      for (var i = 0; i < n; i++)
        (allowWrap ? minimum[i] : natural[i]) - chromes[i],
    ];
    final room = math.max(0.0, maxWidth - sum(chromes));
    final totalText = sum(text);
    if (room == 0 || totalText == 0) {
      return SegmentLayout._(
          List.filled(n, maxWidth / n), minHeight, false, labelPadding,
          scale: 0.01, wrapWidths: text);
    }
    final scale = math.min(1.0, room / totalText);
    var height = minHeight;
    for (var i = 0; i < n; i++) {
      final tp = painter(labels[i].label)..layout(maxWidth: text[i]);
      height = math.max(
          height, (tp.height * scale).ceilToDouble() + 2 * AppSpacing.xs);
      tp.dispose();
    }
    return SegmentLayout._(
      [for (var i = 0; i < n; i++) chromes[i] + text[i] * scale],
      height,
      false,
      labelPadding,
      scale: scale,
      wrapWidths: text,
    );
  }
}

/// The painted control shared by both modes. Public for tests and for
/// callers that own their own position animation; prefer the two widgets
/// above.
///
/// In a bounded width ([expand]) segments are laid out by [SegmentLayout]:
/// equal while labels fit, apportioned by label width when they do not, and
/// wrapped onto more lines as a last resort. The thumb interpolates between
/// segment rects, so it tracks a swipe across unequal widths too.
class SegmentedTrack extends StatelessWidget {
  const SegmentedTrack({
    super.key,
    required this.labels,
    required this.position,
    required this.selectedIndex,
    required this.onTap,
    required this.colors,
    required this.expand,
    this.labelPadding = AppSegmentedControl.defaultLabelPadding,
    this.allowWrap = true,
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

  /// Horizontal padding inside each segment, per side.
  final double labelPadding;

  /// Whether labels may wrap onto more lines (the track grows taller).
  /// Without it, labels that do not fit side by side are scaled down.
  final bool allowWrap;

  static const _capsule = BorderRadius.all(Radius.circular(AppRadius.capsule));

  Widget _thumb() => DecoratedBox(
        key: thumbKey,
        decoration: BoxDecoration(
          color: colors.thumb,
          borderRadius: _capsule,
          border: Border.fromBorderSide(colors.thumbBorder),
          boxShadow: colors.thumbShadow,
        ),
      );

  Widget _segment(int i, double height, int inkIndex,
          {double? wrapWidth, double? padding}) =>
      _Segment(
        tab: labels[i],
        height: height,
        wrapWidth: wrapWidth,
        selected: i == selectedIndex,
        inked: i == inkIndex,
        colors: colors,
        labelPadding: padding ?? labelPadding,
        onTap: onTap == null ? null : () => onTap!(i),
      );

  /// Equal segments: the classic control.
  Widget _equal(int n, double height) => AnimatedBuilder(
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
                      child: _thumb(),
                    ),
                  ),
                ),
              Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Expanded(child: _segment(i, height, inkIndex)),
                ],
              ),
            ],
          );
        },
      );

  /// Segments of [layout]'s widths; the thumb interpolates between them.
  Widget _apportioned(int n, SegmentLayout layout) {
    final starts = <double>[0];
    for (var i = 0; i < n - 1; i++) {
      starts.add(starts.last + layout.widths[i]);
    }
    return AnimatedBuilder(
      animation: position,
      builder: (context, _) {
        final pos = position.value.clamp(0.0, (n - 1).toDouble());
        final hasSelection = selectedIndex >= 0;
        final inkIndex = hasSelection ? pos.round() : -1;
        final i = pos.floor().clamp(0, n - 1);
        final next = math.min(i + 1, n - 1);
        final t = pos - i;
        final start = starts[i] + (starts[next] - starts[i]) * t;
        final width =
            layout.widths[i] + (layout.widths[next] - layout.widths[i]) * t;
        return Stack(
          children: [
            if (hasSelection)
              PositionedDirectional(
                start: start,
                width: width,
                top: 0,
                bottom: 0,
                child: ExcludeSemantics(child: _thumb()),
              ),
            Row(
              children: [
                for (var k = 0; k < n; k++)
                  SizedBox(
                    width: layout.widths[k],
                    child: _segment(k, layout.height, inkIndex,
                        wrapWidth: layout.scaled ? layout.wrapWidths![k] : null,
                        padding: layout.labelPadding),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    assert(n > 0, 'a segmented control needs at least one segment');
    final height =
        AppSegmentedControl.segmentHeightFor(MediaQuery.textScalerOf(context));
    const inset = AppSegmentedControl.trackInset;

    Widget body;
    if (expand) {
      body = LayoutBuilder(builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return IntrinsicWidth(child: _equal(n, height));
        }
        final layout = SegmentLayout.compute(
          context,
          labels: labels,
          maxWidth: constraints.maxWidth,
          labelPadding: labelPadding,
          allowWrap: allowWrap,
        );
        return layout.equal && layout.labelPadding == labelPadding
            ? _equal(n, height)
            : _apportioned(n, layout);
      });
    } else {
      body = _equal(n, height);
    }

    Widget control = DecoratedBox(
      key: trackKey,
      decoration: BoxDecoration(
        color: colors.track,
        borderRadius: _capsule,
        border: Border.fromBorderSide(colors.trackBorder),
      ),
      child: Padding(padding: const EdgeInsets.all(inset), child: body),
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
    required this.labelPadding,
    required this.onTap,
    this.wrapWidth,
  });

  final AppSegmentedTab tab;

  /// When set, the label wraps at this width and is scaled down to fit its
  /// segment (see [SegmentLayout.scale]).
  final double? wrapWidth;
  final double height;
  final bool selected;

  /// Whether the thumb currently sits under this label.
  final bool inked;
  final AppSegmentedPalette colors;
  final double labelPadding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = inked ? colors.selectedInk : colors.unselectedInk;
    final style = AppTypography.of(
      context,
      AppSegmentedControl.labelToken,
      color: ink,
    ).copyWith(
      fontWeight: inked ? FontWeight.w600 : FontWeight.w400,
      // Fixed, not inherited, so the measured layout matches the paint.
      letterSpacing: 0,
    );
    // Never truncated: [SegmentLayout] gives the label room on one line, or
    // a taller segment to wrap into.
    Widget label = Text(
      tab.label,
      style: style,
      textAlign: TextAlign.center,
    );
    final wrapWidth = this.wrapWidth;
    if (wrapWidth != null) {
      label = FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: wrapWidth, child: label),
      );
    }
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
                padding: EdgeInsets.symmetric(horizontal: labelPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: SegmentLayout.iconSize, color: ink),
                      const SizedBox(width: SegmentLayout.iconGap),
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
