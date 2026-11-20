import 'dart:ui' show FrameTiming;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_navigation_bar.dart';
import 'package:sirati/features/dashboard/presentation/home/home_glass_header.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_scroll_end.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// A shell like the real one: the glass bar floats over a long list that
/// pads its end with [dashboardScrollEnd], and the bar folds while the list
/// scrolls down.
class _Shell extends StatefulWidget {
  const _Shell({required this.itemCount, this.axis = Axis.vertical});

  final int itemCount;
  final Axis axis;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  var tab = DashboardTab.home;
  var compact = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          final next = DashboardNavigationBar.compactAfter(n, compact);
          if (next != compact) setState(() => compact = next);
          return false;
        },
        child: Builder(
          builder: (context) => ListView.builder(
            key: const ValueKey('list'),
            scrollDirection: widget.axis,
            padding: EdgeInsets.only(bottom: dashboardScrollEnd(context)),
            itemCount: widget.itemCount,
            itemBuilder: (_, i) => SizedBox(
              key: ValueKey('row-$i'),
              height: 90,
              width: 90,
              child: Text('row $i'),
            ),
          ),
        ),
      ),
      bottomNavigationBar: DashboardNavigationBar(
        current: tab,
        compact: compact,
        onChanged: (t) => setState(() => tab = t),
      ),
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Locale locale = const Locale('ar'),
  double width = 412,
  double height = 800,
  bool highContrast = false,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightFor(arabic: locale.languageCode == 'ar'),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          highContrast: highContrast,
          disableAnimations: disableAnimations,
        ),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _capsule => find.byKey(DashboardNavigationBar.capsuleKey);

/// Whether any glass pane inside [of] is blurring what is behind it.
bool _blurring(WidgetTester tester, Finder of) => tester
    .widgetList<BackdropFilter>(
        find.descendant(of: of, matching: find.byType(BackdropFilter)))
    .any((b) => b.enabled);

/// The tint of the glass pane inside [of].
Color _fill(WidgetTester tester, Finder of) => (tester
        .widget<DecoratedBox>(find
            .descendant(
              of: find.descendant(
                  of: of, matching: find.byType(BackdropFilter)),
              matching: find.byType(DecoratedBox),
            )
            .first)
        .decoration as BoxDecoration)
    .color!;

/// The pill as painted in the last frame, in global coordinates.
Rect _pill(WidgetTester tester) => tester
    .state<DashboardNavigationBarState>(find.byType(DashboardNavigationBar))
    .paintedPill!;
Offset _selectedIcon(WidgetTester tester) => tester.getCenter(
      find.byWidgetPredicate((w) => w is MotionNavIcon && w.selected),
    );
Finder get _icons => find.byWidgetPredicate((w) => w is MotionNavIcon);

/// Drags the list by [dy] (negative scrolls the page down).
Future<void> _drag(WidgetTester tester, double dy) async {
  await tester.drag(find.byKey(const ValueKey('list')), Offset(0, dy));
  await tester.pumpAndSettle();
}

void main() {
  group('floating glass bar', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final width in const [320.0, 412.0, 1024.0]) {
        testWidgets(
            '$locale at ${width.toInt()}dp: floats inside the screen with a '
            'gap on every side, no wider than its cap', (tester) async {
          await _pump(tester, const _Shell(itemCount: 3),
              locale: locale, width: width);
          final capsule = tester.getRect(_capsule);
          expect(capsule.left, greaterThanOrEqualTo(16));
          expect(width - capsule.right, greaterThanOrEqualTo(16));
          expect(800 - capsule.bottom, greaterThan(0));
          expect(capsule.width,
              lessThanOrEqualTo(DashboardNavigationBar.maxWidth - 32 + .5));
          // Centred.
          expect((capsule.left - (width - capsule.right)).abs(), lessThan(.5));
        });
      }
    }

    testWidgets('it is frosted glass: the page behind is blurred',
        (tester) async {
      await _pump(tester, const _Shell(itemCount: 3));
      expect(_blurring(tester, _capsule), isTrue);
    });

    testWidgets('with more contrast asked for, it is solid with no blur',
        (tester) async {
      await _pump(tester, const _Shell(itemCount: 3), highContrast: true);
      expect(_blurring(tester, _capsule), isFalse);
      expect(_fill(tester, _capsule).a, 1);
    });

    testWidgets('every tab is announced as a tab with its place and state',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, const _Shell(itemCount: 3),
          locale: const Locale('en'));
      const order = DashboardNavigationBar.order;
      for (var i = 0; i < order.length; i++) {
        final node = tester.getSemantics(_icons.at(i));
        expect(node.label, contains('${i + 1}'));
        expect(node.label, contains('${order.length}'));
        expect(node, isSemantics(isButton: true, isSelected: i == 0));
      }
      semantics.dispose();
    });

    testWidgets('the pill stretches while sliding and is back to size at rest',
        (tester) async {
      await _pump(tester, const _Shell(itemCount: 3));
      const order = DashboardNavigationBar.order;
      for (var to = 1; to < order.length; to++) {
        await tester.tap(_icons.at(to));
        await tester.pump();
        await tester.pump();
        await tester.pump(MotionDurations.navIndicator ~/ 2);
        expect(_pill(tester).width,
            greaterThan(DashboardNavigationBar.pillSize.width + 1));
        expect(_pill(tester).height, DashboardNavigationBar.pillSize.height);
        await tester.pumpAndSettle();
        expect(_pill(tester).size, DashboardNavigationBar.pillSize);
        expect((_pill(tester).center - _selectedIcon(tester)).distance,
            lessThan(.5));
      }
    });
  });

  group('scrolling', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets(
          '$locale: the page slides under the bar, yet its last row can '
          'scroll fully clear of it', (tester) async {
        await _pump(tester, const _Shell(itemCount: 30), locale: locale);
        // At the top, rows already sit behind the capsule.
        final capsule = tester.getRect(_capsule);
        final behind = [
          for (var i = 0; i < 30; i++)
            if (find.byKey(ValueKey('row-$i')).evaluate().isNotEmpty &&
                tester
                    .getRect(find.byKey(ValueKey('row-$i')))
                    .overlaps(capsule))
              i,
        ];
        expect(behind, isNotEmpty);

        // Scroll to the very end, then bring the bar back open.
        await tester.fling(
            find.byKey(const ValueKey('list')), const Offset(0, -6000), 4000);
        await tester.pumpAndSettle();
        await _drag(tester, 1);
        final lastRow = tester.getRect(find.byKey(const ValueKey('row-29')));
        expect(lastRow.bottom, lessThanOrEqualTo(tester.getRect(_capsule).top));
      });
    }

    testWidgets(
        'scrolling down folds the bar to icons and narrows it; scrolling up '
        'or reaching the top opens it again', (tester) async {
      await _pump(tester, const _Shell(itemCount: 30));
      final open = tester.getRect(_capsule);
      Finder label(String text) => find.text(text);
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      double labelHeight() => tester
          .getSize(find
              .ancestor(
                of: label(l10n.dashboardNavHome),
                matching: find.byType(ClipRect),
              )
              .first)
          .height;
      expect(labelHeight(), greaterThan(0));

      await _drag(tester, -300);
      final folded = tester.getRect(_capsule);
      expect(folded.width, lessThan(open.width));
      expect(folded.height, lessThan(open.height));
      expect(labelHeight(), 0);
      // The pill still sits on the selected icon in the folded bar.
      expect((_pill(tester).center - _selectedIcon(tester)).distance,
          lessThan(.5));

      await _drag(tester, 120);
      expect(tester.getRect(_capsule).width, open.width);
      expect(labelHeight(), greaterThan(0));

      await _drag(tester, -300);
      expect(labelHeight(), 0);
      await tester.fling(
          find.byKey(const ValueKey('list')), const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.getRect(_capsule), open);
    });

    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets(
          '$locale: the pill stays on its icon in every frame of the fold',
          (tester) async {
        await _pump(tester, const _Shell(itemCount: 30), locale: locale);
        for (final tab in [0, 2]) {
          await tester.tap(_icons.at(tab));
          await tester.pumpAndSettle();
          for (final dy in [-300.0, 200.0]) {
            await tester.drag(
                find.byKey(const ValueKey('list')), Offset(0, dy));
            for (var f = 0; f < 20; f++) {
              await tester.pump(const Duration(milliseconds: 16));
              expect(
                (_pill(tester).center - _selectedIcon(tester)).distance,
                lessThan(.5),
                reason: 'tab $tab, drag $dy, frame $f',
              );
            }
            await tester.pumpAndSettle();
          }
        }
      });
    }

    testWidgets('a sideways list never folds the bar', (tester) async {
      await _pump(tester, const _Shell(itemCount: 30, axis: Axis.horizontal));
      final open = tester.getRect(_capsule);
      await tester.drag(
          find.byKey(const ValueKey('list')), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(_capsule), open);
    });
  });

  group('Home header', () {
    testWidgets('clear at the top, glass once the page scrolls under it',
        (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: CustomScrollView(
            key: const ValueKey('list'),
            slivers: [
              const PinnedHeaderSliver(
                child: HomeGlassHeader(child: SizedBox(height: 80)),
              ),
              SliverList.list(children: [
                for (var i = 0; i < 20; i++) const SizedBox(height: 100),
              ]),
            ],
          ),
        ),
      );
      double glass() => tester
          .widget<GlassSurface>(find.byKey(HomeGlassHeader.glassKey))
          .strength;
      final top = tester.getRect(find.byType(HomeGlassHeader));
      expect(glass(), 0);
      await _drag(tester, -400);
      expect(glass(), 1);
      // Pinned: still in the same place.
      expect(tester.getRect(find.byType(HomeGlassHeader)), top);
      await _drag(tester, 2000);
      expect(glass(), 0);
    });

    testWidgets(
        'while the glass fades in, the blur grows with the tint and is never '
        'inside an opacity layer', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: CustomScrollView(
            key: const ValueKey('list'),
            slivers: [
              const PinnedHeaderSliver(
                child: HomeGlassHeader(child: SizedBox(height: 80)),
              ),
              SliverList.list(children: [
                for (var i = 0; i < 20; i++) const SizedBox(height: 100),
              ]),
            ],
          ),
        ),
      );
      await tester.drag(
          find.byKey(const ValueKey('list')), const Offset(0, -400));
      var previous = 0.0;
      var sawMiddle = false;
      for (var f = 0; f < 30; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        final glass = find.byKey(HomeGlassHeader.glassKey);
        final strength = tester.widget<GlassSurface>(glass).strength;
        expect(strength, greaterThanOrEqualTo(previous));
        previous = strength;
        if (strength > 0 && strength < 1) sawMiddle = true;
        for (final blur in tester
            .widgetList<BackdropFilter>(find.descendant(
                of: glass, matching: find.byType(BackdropFilter)))
            .where((b) => b.enabled)) {
          final under = find.ancestor(
              of: find.byWidget(blur),
              matching: find.byWidgetPredicate((w) =>
                  w is Opacity || w is FadeTransition || w is AnimatedOpacity));
          expect(under, findsNothing, reason: 'frame $f');
        }
      }
      expect(sawMiddle, isTrue, reason: 'it fades, it does not snap');
      expect(previous, 1);
    });
  });

  group('glass quality', () {
    setUp(() {
      GlassQuality.reset();
      // Glass is blurring on screen unless a test says otherwise.
      GlassQuality.debugVisibleBlur = 1;
      SharedPreferences.setMockInitialValues({});
    });
    tearDown(() {
      GlassQuality.reset();
      GlassQuality.debugVisibleBlur = 0;
    });

    List<Duration> frames(int count, int ms) =>
        List.filled(count, Duration(milliseconds: ms));
    List<Duration> warmUp() => frames(GlassQuality.warmUpFrames, 50);
    List<Duration> slowRun() =>
        frames(GlassQuality.window * GlassQuality.slowWindowsToSwitch, 30);

    test('smooth frames keep the glass', () {
      GlassQuality.report(
          [...warmUp(), ...frames(GlassQuality.window * 10, 8)]);
      expect(GlassQuality.tooSlow, isFalse);
    });

    test('a slow start (shader warm-up, splash) never counts', () {
      GlassQuality.report(frames(GlassQuality.warmUpFrames, 80));
      GlassQuality.report(frames(GlassQuality.window * 5, 8));
      expect(GlassQuality.tooSlow, isFalse);
    });

    test('slow frames while no glass is on screen never count', () {
      GlassQuality.debugVisibleBlur = 0;
      GlassQuality.report([...warmUp(), ...slowRun(), ...slowRun()]);
      expect(GlassQuality.tooSlow, isFalse);
    });

    test('a short hiccup keeps the glass', () {
      GlassQuality.report(warmUp());
      for (var i = 0; i < 5; i++) {
        GlassQuality.report(frames(
            GlassQuality.window * (GlassQuality.slowWindowsToSwitch - 1), 30));
        GlassQuality.report(frames(GlassQuality.window, 8));
      }
      expect(GlassQuality.tooSlow, isFalse);
    });

    test('only the slowest tenth decides: a few slow frames are fine', () {
      GlassQuality.report(warmUp());
      final mixed = [
        ...frames((GlassQuality.window * .92).floor(), 8),
        ...frames(
            GlassQuality.window - (GlassQuality.window * .92).floor(), 40),
      ];
      for (var i = 0; i < 10; i++) {
        GlassQuality.report(mixed);
      }
      expect(GlassQuality.tooSlow, isFalse);
    });

    for (final (rate, fine, slow) in [
      (60.0, 13, 16),
      (90.0, 9, 11),
      (120.0, 6, 9),
    ]) {
      test('the budget follows the display: ${rate.toInt()} Hz', () {
        GlassQuality.reset(refreshRate: rate);
        GlassQuality.report(
            [...warmUp(), ...frames(GlassQuality.window * 10, fine)]);
        expect(GlassQuality.tooSlow, isFalse, reason: '$fine ms is fine');
        GlassQuality.report(frames(
            GlassQuality.window * GlassQuality.slowWindowsToSwitch, slow));
        expect(GlassQuality.tooSlow, isTrue, reason: '$slow ms is slow');
      });
    }

    test(
        'a run of slow windows is saved for the next launch, and never flips '
        'the glass mid-session', () async {
      GlassQuality.report([...warmUp(), ...slowRun()]);
      expect(GlassQuality.tooSlow, isTrue);
      expect(GlassQuality.solid.value, isFalse, reason: 'not mid-session');
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('glass_quality.solid'), isTrue);

      // The next launch starts solid.
      GlassQuality.reset();
      await GlassQuality.debugLoadSaved();
      expect(GlassQuality.solid.value, isTrue);
    });

    test('engine frame timings feed the same decision', () {
      FrameTiming timing(int rasterMs) => FrameTiming(
            vsyncStart: 0,
            buildStart: 0,
            buildFinish: 1000,
            rasterStart: 1000,
            rasterFinish: 1000 + rasterMs * 1000,
            rasterFinishWallTime: 1000 + rasterMs * 1000,
          );
      GlassQuality.onTimings([
        for (var i = 0; i < GlassQuality.warmUpFrames; i++) timing(50),
        for (var i = 0;
            i < GlassQuality.window * GlassQuality.slowWindowsToSwitch;
            i++)
          timing(30),
      ]);
      expect(GlassQuality.tooSlow, isTrue);
    });

    testWidgets('glass on screen is counted only while it blurs',
        (tester) async {
      GlassQuality.debugVisibleBlur = 0;
      await _pump(tester, const _Shell(itemCount: 3));
      expect(GlassQuality.visibleBlur, 1, reason: 'the bar');
      await tester.pumpWidget(const SizedBox());
      expect(GlassQuality.visibleBlur, 0);
      await _pump(tester, const _Shell(itemCount: 3), highContrast: true);
      expect(GlassQuality.visibleBlur, 0, reason: 'solid does not blur');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a solid decision draws no blur', (tester) async {
      GlassQuality.debugVisibleBlur = 0;
      await _pump(tester, const _Shell(itemCount: 3));
      expect(_blurring(tester, _capsule), isTrue);
      GlassQuality.solid.value = true;
      await tester.pump();
      expect(_blurring(tester, _capsule), isFalse);
      expect(_fill(tester, _capsule).a, 1);
    });

    testWidgets(
        'switching glass to solid keeps what is inside: typed text, focus '
        'and scroll', (tester) async {
      GlassQuality.debugVisibleBlur = 0;
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await _pump(
        tester,
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: GlassSurface(
                borderRadius: BorderRadius.circular(24),
                child: ListView(
                  controller: scroll,
                  children: [
                    const TextField(key: ValueKey('field')),
                    for (var i = 0; i < 20; i++) const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('field')), 'my notes');
      await tester.pump();
      scroll.jumpTo(10);
      await tester.pump();
      final field = tester.state<EditableTextState>(find.byType(EditableText));

      for (final solid in [true, false, true]) {
        GlassQuality.solid.value = solid;
        await tester.pump();
        expect(_blurring(tester, find.byType(GlassSurface)), !solid);
        expect(find.text('my notes'), findsOneWidget);
        expect(
          tester.state<EditableTextState>(find.byType(EditableText)),
          same(field),
          reason: 'the same field, not a new one',
        );
        expect(field.widget.focusNode.hasFocus, isTrue);
        expect(scroll.offset, 10);
      }
    });
  });

  group('sheets', () {
    for (final close in [true, false]) {
      testWidgets('glass sheet, no grab bar, X ${close ? 'shown' : 'hidden'}',
          (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showGlassBottomSheet<void>(
                  context: context,
                  showCloseButton: close,
                  builder: (_) => const SizedBox(
                    key: ValueKey('sheet-body'),
                    height: 120,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final glass = find.ancestor(
          of: find.byKey(const ValueKey('sheet-body')),
          matching: find.byType(GlassSurface),
        );
        expect(glass, findsOneWidget);
        expect(_blurring(tester, glass), isTrue);
        expect(tester.widget<GlassSurface>(glass).borderRadius,
            AppRadius.sheetTop);
        final closeButton = find.byKey(const ValueKey('sheet-close'));
        expect(closeButton, close ? findsOneWidget : findsNothing);
        // Only the X row, if any, sits above the content: no grab bar.
        final bodyTop =
            tester.getTopLeft(find.byKey(const ValueKey('sheet-body'))).dy;
        expect(
          bodyTop,
          close
              ? tester.getBottomLeft(closeButton).dy
              : tester.getTopLeft(glass).dy,
        );
      });
    }
  });
}
