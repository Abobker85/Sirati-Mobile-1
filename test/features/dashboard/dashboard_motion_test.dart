import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_navigation_bar.dart';
import 'package:sirati/features/dashboard/presentation/home/home_intro.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Pumps the bottom bar in a host that really switches tabs on tap.
Future<void> _pumpBar(
  WidgetTester tester, {
  required Locale locale,
  required double width,
  DashboardTab start = DashboardTab.home,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var current = start;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightFor(arabic: locale.languageCode == 'ar'),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          bottomNavigationBar: DashboardNavigationBar(
            current: current,
            onChanged: (tab) => setState(() => current = tab),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The grey pill behind the selected tab, as laid out now.
Rect _pill(WidgetTester tester) =>
    tester.getRect(find.byKey(DashboardNavigationBar.pillKey));

/// Centre of the selected tab's icon.
Offset _selectedIconCenter(WidgetTester tester) =>
    tester.getCenter(find.descendant(
      of: find.byKey(DashboardNavigationBar.pillKey),
      matching: find.byType(LivelyIcon),
    ));

/// Tab icons, in [DashboardNavigationBar.order].
Finder get _icons => find.descendant(
    of: find.byType(DashboardNavigationBar), matching: find.byType(LivelyIcon));

/// Taps the bar item at [index] of [DashboardNavigationBar.order].
Future<void> _tapItem(WidgetTester tester, int index) =>
    tester.tap(_icons.at(index));

void main() {
  group('bottom bar pill', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      for (final width in const [320.0, 412.0, 900.0]) {
        testWidgets(
            '$locale at ${width.toInt()}dp: the pill rests centred on the '
            'selected icon for every tab', (tester) async {
          await _pumpBar(tester, locale: locale, width: width);
          const order = DashboardNavigationBar.order;
          for (var i = 0; i < order.length; i++) {
            await _tapItem(tester, i);
            await tester.pumpAndSettle();
            // Centred across the selected icon.
            expect(
                (_pill(tester).center.dx - _selectedIconCenter(tester).dx)
                    .abs(),
                lessThan(.5),
                reason: 'tab ${order[i]}');
          }
        });
      }
    }

    testWidgets(
        'switching is instant: the pill is at rest one frame after any tap',
        (tester) async {
      await _pumpBar(tester, locale: const Locale('ar'), width: 412);
      const order = DashboardNavigationBar.order;
      for (var from = 0; from < order.length; from++) {
        for (var to = 0; to < order.length; to++) {
          if (from == to) continue;
          await _tapItem(tester, from);
          await tester.pumpAndSettle();
          await _tapItem(tester, to);
          await tester.pump();
          final first = _pill(tester);
          await tester.pumpAndSettle();
          expect(_pill(tester), first, reason: '$from -> $to');
          expect((first.center.dx - _selectedIconCenter(tester).dx).abs(),
              lessThan(.5),
              reason: '$from -> $to');
        }
      }
    });

    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets('$locale: pressing any tab paints no ripple or highlight',
          (tester) async {
        await _pumpBar(tester, locale: locale, width: 412);
        // Ink that would actually show: any feature with a visible colour.
        List<Object> inkUnderBar() => [
              for (final o in tester.allRenderObjects)
                if (o.runtimeType.toString() == '_RenderInkFeatures')
                  for (final f
                      in ((o as dynamic).debugInkFeatures as List?) ?? const [])
                    if (f is! InteractiveInkFeature || f.color.a > 0) f,
            ];
        final icons = _icons;
        for (var i = 0; i < DashboardNavigationBar.order.length; i++) {
          final gesture =
              await tester.startGesture(tester.getCenter(icons.at(i)));
          // Hold well past the long-press delay, where a highlight would show.
          for (var f = 0; f < 10; f++) {
            await tester.pump(const Duration(milliseconds: 80));
            expect(inkUnderBar(), isEmpty, reason: 'tab $i, frame $f');
          }
          await gesture.up();
          await tester.pump(const Duration(milliseconds: 50));
          expect(inkUnderBar(), isEmpty, reason: 'tab $i after release');
          await tester.pumpAndSettle();
        }
      });
    }

    testWidgets('with animations removed the pill jumps straight there',
        (tester) async {
      await _pumpBar(
        tester,
        locale: const Locale('ar'),
        width: 412,
        disableAnimations: true,
      );
      for (var i = DashboardNavigationBar.order.length - 1; i >= 0; i--) {
        await _tapItem(tester, i);
        await tester.pump();
        await tester.pump();
        expect(
          (_pill(tester).center.dx - _selectedIconCenter(tester).dx).abs(),
          lessThan(.5),
        );
      }
    });
  });

  group('home intro', () {
    Future<AnimationController> pumpIntro(
      WidgetTester tester,
      Widget Function(Animation<double>) build, {
      TextDirection direction = TextDirection.ltr,
    }) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: MotionDurations.homeIntro,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        Theme(
          data: AppTheme.lightFor(arabic: false),
          child: Directionality(
            textDirection: direction,
            child: Center(child: build(controller)),
          ),
        ),
      );
      return controller;
    }

    const box = SizedBox(key: ValueKey('piece'), width: 100, height: 60);

    for (final motion in HomeIntroMotion.values) {
      for (final (begin, end) in const [(0.0, .3), (.3, .62), (.6, 1.0)]) {
        testWidgets('$motion in $begin..$end: hidden before, settled after',
            (tester) async {
          final c = await pumpIntro(
            tester,
            (a) => HomeIntroItem(
              animation: a,
              begin: begin,
              end: end,
              motion: motion,
              child: box,
            ),
          );
          final rest = Rect.fromCenter(
            center: tester.getCenter(find.byType(Center)),
            width: 100,
            height: 60,
          );
          double opacity() => tester
              .widget<FadeTransition>(find.byType(FadeTransition))
              .opacity
              .value;

          for (final v in [0.0, begin]) {
            c.value = v;
            await tester.pump();
            expect(opacity(), 0, reason: 'at $v');
          }
          c.value = (begin + end) / 2;
          await tester.pump();
          expect(opacity(), inExclusiveRange(0, 1));
          for (final v in [end, 1.0]) {
            c.value = v;
            await tester.pump();
            expect(opacity(), 1, reason: 'at $v');
            final r = tester.getRect(find.byKey(const ValueKey('piece')));
            expect((r.topLeft - rest.topLeft).distance, lessThan(.01));
            expect(
                (r.width - rest.width).abs() + (r.height - rest.height).abs(),
                lessThan(.01));
          }
        });
      }
    }

    for (final direction in TextDirection.values) {
      testWidgets(
          'sweep in $direction: light only inside its slice, '
          'moving leading → trailing', (tester) async {
        final c = await pumpIntro(
          tester,
          direction: direction,
          (a) => HomeIntroSweep(
            animation: a,
            begin: .3,
            end: .7,
            radius: 22,
            child: box,
          ),
        );
        Finder light() => find.descendant(
              of: find.byType(HomeIntroSweep),
              matching: find.byType(ClipRRect),
            );
        double bandX() {
          final deco = tester
              .widget<DecoratedBox>(
                find.descendant(
                    of: light(), matching: find.byType(DecoratedBox)),
              )
              .decoration as BoxDecoration;
          final g = deco.gradient! as LinearGradient;
          return ((g.begin as Alignment).x + (g.end as Alignment).x) / 2;
        }

        for (final v in [0.0, .3, .7, 1.0]) {
          c.value = v;
          await tester.pump();
          expect(light(), findsNothing, reason: 'at $v');
        }
        final xs = <double>[];
        for (final v in [.35, .45, .55, .65]) {
          c.value = v;
          await tester.pump();
          expect(light(), findsOneWidget);
          xs.add(bandX());
        }
        for (var i = 1; i < xs.length; i++) {
          if (direction == TextDirection.rtl) {
            expect(xs[i], lessThan(xs[i - 1]));
          } else {
            expect(xs[i], greaterThan(xs[i - 1]));
          }
        }
        // The card itself stays the same size and place throughout.
        expect(tester.getSize(find.byKey(const ValueKey('piece'))),
            const Size(100, 60));
      });
    }
  });
}
