import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

import '../../support/app_screens.dart';
import '../../support/contrast_probe.dart';

/// Content-sized segments with the real app fonts: equal while labels fit,
/// apportioned by label width when they do not, wrapped as a last resort,
/// and never cut off.
void main() {
  setUpAll(loadAppFonts);

  /// Layout modes the matrix below actually reached (checked at the end, so
  /// the matrix cannot silently stop exercising wrapping or scaling).
  final reached = <String>{};

  const width = 320.0;
  const directions = [TextDirection.ltr, TextDirection.rtl];
  const scales = [1.0, 1.3, 2.0];

  /// Label sets: the CV builder's real tabs plus mixed-length labels.
  List<List<AppSegmentedTab>> labelSets(TextDirection direction, Random r) {
    final l10n = lookupAppLocalizations(
        Locale(direction == TextDirection.rtl ? 'ar' : 'en'));
    const pool = [
      'النتيجة',
      'Score',
      'التوصيات والتحسينات المقترحة',
      'Recommendations',
      'السير الذاتية المحفوظة',
      'CVs',
      'Experience and education',
      'المهارات',
    ];
    final mixed = [...pool]..shuffle(r);
    return [
      [
        AppSegmentedTab(label: l10n.tabPersonal, icon: Icons.person),
        AppSegmentedTab(label: l10n.tabExperience, icon: Icons.work),
        AppSegmentedTab(label: l10n.tabSkills, icon: Icons.psychology),
        AppSegmentedTab(label: l10n.tabOrder, icon: Icons.format_line_spacing),
      ],
      for (final n in [2, 3, 4])
        [for (final l in mixed.take(n)) AppSegmentedTab(label: l)],
      [for (final l in mixed.skip(4).take(3)) AppSegmentedTab(label: l)],
    ];
  }

  Future<AppSegmentedTabBar> pumpBar(
    WidgetTester tester, {
    required List<AppSegmentedTab> tabs,
    required TextDirection direction,
    required double scale,
    EdgeInsets padding = AppSegmentedTabBar.defaultPadding,
    double labelPadding = AppSegmentedControl.defaultLabelPadding,
    TabController? controller,
  }) async {
    tester.view.physicalSize = const Size(width, 700);
    tester.view.devicePixelRatio = 1;
    late AppSegmentedTabBar bar;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightFor(arabic: direction == TextDirection.rtl),
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, body) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(textDirection: direction, child: body!),
      ),
      home: DefaultTabController(
        key: UniqueKey(),
        length: tabs.length,
        child: Builder(builder: (context) {
          bar = AppSegmentedTabBar(
            tabs: tabs,
            controller: controller,
            padding: padding,
            labelPadding: labelPadding,
            textScaler: MediaQuery.textScalerOf(context),
            height: AppSegmentedTabBar.heightFor(
              context,
              tabs: tabs,
              padding: padding,
              labelPadding: labelPadding,
            ),
          );
          return Scaffold(
            appBar: AppBar(title: const Text('CV'), bottom: bar),
            body: TabBarView(
              controller: controller,
              children: [
                for (var i = 0; i < tabs.length; i++) Text('page $i'),
              ],
            ),
          );
        }),
      ),
    ));
    await tester.pumpAndSettle();
    return bar;
  }

  Finder segmentOf(String label) => find
      .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
      .first;

  /// [label] is painted whole: its paragraph is wide enough for its longest
  /// word and tall enough for all its lines (so nothing is clipped), it is
  /// not ellipsized, and the painted paragraph sits inside its segment.
  void expectWhole(WidgetTester tester, String label, String reason) {
    final element = find.text(label).evaluate().single;
    final text = element.widget as Text;
    expect(text.overflow, isNot(TextOverflow.ellipsis), reason: reason);
    expect(text.maxLines, isNull, reason: reason);
    final paragraph = paragraphOf(element.findRenderObject()!);
    final size = paragraph.size;
    expect(paragraph.getMinIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(size.width + 0.5),
        reason: '$label: longest word fits ($reason)');
    expect(paragraph.getMaxIntrinsicHeight(size.width),
        lessThanOrEqualTo(size.height + 0.5),
        reason: '$label: every line fits ($reason)');
    final painted = MatrixUtils.transformRect(
        paragraph.getTransformTo(null), Offset.zero & size);
    final segment = tester.getRect(segmentOf(label)).inflate(0.5);
    expect(segment.contains(painted.topLeft), isTrue,
        reason: '$label inside its segment ($reason)');
    expect(segment.contains(painted.bottomRight), isTrue,
        reason: '$label inside its segment ($reason)');
  }

  for (final direction in directions) {
    for (final scale in scales) {
      for (final compact in [false, true]) {
        final suffix = '${direction.name}, x$scale, '
            '${compact ? 'padding 8' : 'default padding'}';
        testWidgets('labels are never cut off at ${width.toInt()}dp ($suffix)',
            (tester) async {
          addTearDown(tester.view.reset);
          final r = Random(scale.hashCode ^ direction.index);
          for (final tabs in labelSets(direction, r)) {
            final reason = '${tabs.map((t) => t.label)}, $suffix';
            await pumpBar(
              tester,
              tabs: tabs,
              direction: direction,
              scale: scale,
              padding: compact
                  ? const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xxs,
                      AppSpacing.xs, AppSpacing.xs)
                  : AppSegmentedTabBar.defaultPadding,
              labelPadding: compact
                  ? AppSpacing.xs
                  : AppSegmentedControl.defaultLabelPadding,
            );
            expect(tester.takeException(), isNull, reason: reason);
            final track = tester.getRect(find.byKey(SegmentedTrack.trackKey));
            expect(track.left, greaterThanOrEqualTo(0), reason: reason);
            expect(track.right, lessThanOrEqualTo(width), reason: reason);
            // The bar's reserved height holds the laid-out control.
            final bar = tester.getRect(find.byType(AppSegmentedTabBar));
            expect(track.bottom, lessThanOrEqualTo(bar.bottom + 0.5),
                reason: reason);
            final layout = SegmentLayout.compute(
              tester.element(find.byType(Row).first),
              labels: tabs,
              maxWidth: track.width - 2 * AppSegmentedControl.trackInset,
              labelPadding: compact
                  ? AppSpacing.xs
                  : AppSegmentedControl.defaultLabelPadding,
            );
            reached.add(layout.equal
                ? 'equal'
                : layout.scaled
                    ? 'scaled'
                    : layout.height >
                            AppSegmentedControl.segmentHeightFor(
                                TextScaler.linear(scale))
                        ? 'wrapped'
                        : 'apportioned');
            for (final tab in tabs) {
              expectWhole(tester, tab.label, reason);
              expect(tester.getSize(segmentOf(tab.label)).height,
                  greaterThanOrEqualTo(44),
                  reason: reason);
            }
          }
        });
      }
    }
  }

  testWidgets('equal widths stay when every label fits an equal share',
      (tester) async {
    addTearDown(tester.view.reset);
    for (final direction in directions) {
      for (final tabs in [
        const [AppSegmentedTab(label: 'A'), AppSegmentedTab(label: 'B')],
        const [
          AppSegmentedTab(label: 'السجل'),
          AppSegmentedTab(label: 'Score'),
          AppSegmentedTab(label: 'CVs'),
        ],
      ]) {
        await pumpBar(tester, tabs: tabs, direction: direction, scale: 1);
        final widths = [
          for (final t in tabs) tester.getSize(segmentOf(t.label)).width,
        ];
        for (final w in widths) {
          expect(w, moreOrLessEquals(widths.first, epsilon: 0.01));
        }
        // Same height as the classic one-line control.
        expect(
          tester.getSize(segmentOf(tabs.first.label)).height,
          AppSegmentedControl.segmentHeightFor(TextScaler.noScaling),
        );
      }
    }
  });

  testWidgets('labels that do not fit equally get width by content',
      (tester) async {
    addTearDown(tester.view.reset);
    for (final direction in directions) {
      const tabs = [
        AppSegmentedTab(label: 'A'),
        AppSegmentedTab(label: 'Recommendations and fixes'),
      ];
      await pumpBar(tester, tabs: tabs, direction: direction, scale: 1);
      final short = tester.getSize(segmentOf('A')).width;
      final long = tester.getSize(segmentOf(tabs[1].label)).width;
      expect(long, greaterThan(short), reason: '$direction');
      expectWhole(tester, tabs[1].label, '$direction');
      // One line: no extra height when side by side fits.
      expect(tester.getSize(segmentOf('A')).height,
          AppSegmentedControl.segmentHeightFor(TextScaler.noScaling));
    }
  });

  testWidgets('thumb tracks a swipe across unequal widths', (tester) async {
    addTearDown(tester.view.reset);
    for (final direction in directions) {
      final controller = TabController(length: 3, vsync: const TestVSync());
      addTearDown(controller.dispose);
      const tabs = [
        AppSegmentedTab(label: 'A'),
        AppSegmentedTab(label: 'Recommendations'),
        AppSegmentedTab(label: 'B'),
      ];
      await pumpBar(tester,
          tabs: tabs, direction: direction, scale: 1, controller: controller);
      final rects = [for (final t in tabs) tester.getRect(segmentOf(t.label))];
      expect(rects[1].width, greaterThan(rects[0].width));

      Rect thumb() => tester.getRect(find.byKey(SegmentedTrack.thumbKey));
      void expectAt(double pos, String reason) {
        final i = pos.floor().clamp(0, 2);
        final next = min(i + 1, 2);
        final t = pos - i;
        final want = Rect.lerp(rects[i], rects[next], t)!;
        expect(thumb().left, moreOrLessEquals(want.left, epsilon: 0.5),
            reason: reason);
        expect(thumb().right, moreOrLessEquals(want.right, epsilon: 0.5),
            reason: reason);
      }

      expectAt(0, '$direction rest');
      // Drag the pages toward the next tab (left in LTR, right in RTL).
      final sign = direction == TextDirection.ltr ? -1.0 : 1.0;
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('page 0')));
      await gesture.moveBy(Offset(sign * 20, 0));
      await gesture.moveBy(Offset(sign * 100, 0));
      await tester.pump();
      final value = controller.animation!.value;
      expect(value, inExclusiveRange(0, 1));
      expectAt(value, '$direction mid-swipe at $value');
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(segmentOf('B'));
      await tester.pumpAndSettle();
      expect(controller.index, 2);
      expectAt(2, '$direction after tap');
    }
  });

  test('the matrix reached every layout mode', () {
    expect(reached, containsAll(['equal', 'apportioned', 'wrapped', 'scaled']));
  });
}
