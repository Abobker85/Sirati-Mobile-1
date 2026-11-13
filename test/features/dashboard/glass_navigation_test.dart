import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
Rect _pill(WidgetTester tester) =>
    tester.getRect(find.byKey(DashboardNavigationBar.pillKey));
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
      expect(
        find.descendant(of: _capsule, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
    });

    testWidgets('with more contrast asked for, it is solid with no blur',
        (tester) async {
      await _pump(tester, const _Shell(itemCount: 3), highContrast: true);
      expect(
        find.descendant(of: _capsule, matching: find.byType(BackdropFilter)),
        findsNothing,
      );
      final box = tester.widget<DecoratedBox>(find
          .descendant(of: _capsule, matching: find.byType(DecoratedBox))
          .first);
      final fill = (box.decoration as BoxDecoration).color!;
      expect(fill.a, 1);
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
          .widget<AnimatedOpacity>(find.byKey(HomeGlassHeader.glassKey))
          .opacity;
      final top = tester.getRect(find.byType(HomeGlassHeader));
      expect(glass(), 0);
      await _drag(tester, -400);
      expect(glass(), 1);
      // Pinned: still in the same place.
      expect(tester.getRect(find.byType(HomeGlassHeader)), top);
      await _drag(tester, 2000);
      expect(glass(), 0);
    });
  });

  group('sheets', () {
    for (final handle in [true, false]) {
      testWidgets('glass sheet, grab bar ${handle ? 'shown' : 'hidden'}',
          (tester) async {
        await _pump(
          tester,
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showGlassBottomSheet<void>(
                  context: context,
                  showDragHandle: handle,
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
        expect(
          find.descendant(of: glass, matching: find.byType(BackdropFilter)),
          findsOneWidget,
        );
        expect(find.byType(SheetDragHandle),
            handle ? findsOneWidget : findsNothing);
      });
    }
  });
}
