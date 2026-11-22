// Home in the iOS 26 style (restyle ticket 03): a white page with a large
// title that collapses into a small pinned title, a floating pill that stays
// put, and grey shadowless cards that darken and spring when pressed.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_header.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_tab.dart';
import 'package:sirati/features/dashboard/presentation/home/home_glass_header.dart';
import 'package:sirati/features/dashboard/presentation/home/home_large_title.dart';
import 'package:sirati/features/dashboard/presentation/home/home_premium_card.dart';
import 'package:sirati/features/dashboard/presentation/home/home_pressable_card.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';

import '../../support/contrast_probe.dart';
import 'cv_analysis_home_acceptance_test.dart' show app, cv, verticalScroll;

void main() {
  setUp(() {
    MobileContentService.invalidate();
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
  });

  double compactTitleOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.byKey(DashboardHomeHeader.compactTitleKey))
      .opacity;

  for (final arabic in [false, true]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
            'large title collapses into the pinned bar, the pill stays put '
            '(ar=$arabic dark=$dark scale=$scale)', (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final latest = cv(72, id: 71);
          await tester.pumpWidget(app(
            Scaffold(body: DashboardHomeTab(onNavigate: (_) {})),
            arabic: arabic,
            dark: dark,
            scale: scale,
            latest: latest,
          ));
          await tester.pumpAndSettle();
          final c = Theme.of(tester.element(find.byType(DashboardHomeTab)))
              .extension<SiratiColors>()!;

          final pill = find.byKey(DashboardHomeHeader.pillKey);
          // Scrolled under the bar, the title leaves the viewport (offstage).
          final large =
              find.byKey(HomeLargeTitle.titleKey, skipOffstage: false);
          final largeText =
              find.descendant(of: large, matching: find.byType(Text)).first;
          final bar = find.byType(HomeGlassHeader);
          final pillAtRest = tester.getRect(pill);
          final largeAtRest = tester.getRect(large);
          final textAtRest = tester.getRect(largeText);

          // At rest: the large title is below the bar, on the start side;
          // the pill sits on the end side; the small title is hidden.
          expect(largeAtRest.top,
              greaterThanOrEqualTo(tester.getRect(bar).bottom));
          final rtl = arabic;
          if (rtl) {
            expect(pillAtRest.center.dx, lessThan(195));
            expect(textAtRest.right, greaterThan(300));
          } else {
            expect(pillAtRest.center.dx, greaterThan(195));
            expect(textAtRest.left, lessThan(90));
          }
          expect(compactTitleOpacity(tester), 0);
          // The page is the plain white (light) page, not the warm background.
          expect(
              paintedBackgroundsOf(tester.element(large)), [c.pageBackground]);
          expectAllTextAa('home at rest ar=$arabic dark=$dark');

          // A real scroll.
          await tester.drag(verticalScroll(), const Offset(0, -400));
          await tester.pumpAndSettle();
          expect(tester.getRect(pill), pillAtRest, reason: 'pill pinned');
          // The large title went up and under the bar.
          expect(tester.getRect(large).bottom,
              lessThanOrEqualTo(tester.getRect(bar).bottom));
          expect(compactTitleOpacity(tester), 1);
          // The small title is read over the glass, whatever scrolls under.
          final glass =
              tester.widget<GlassSurface>(find.byKey(HomeGlassHeader.glassKey));
          expect(glass.strength, 1);
          final title = tester.widget<Text>(find.descendant(
              of: find.byKey(DashboardHomeHeader.compactTitleKey),
              matching: find.byType(Text)));
          for (final under in const [Color(0xFF000000), Color(0xFFFFFFFF)]) {
            final tint = Color.alphaBlend(c.glassFill, under);
            expect(AppContrast.ratio(title.style!.color!, tint),
                greaterThanOrEqualTo(4.5),
                reason: 'small title on glass over $under');
          }

          // Back to the top: the small title goes away again.
          await tester.drag(verticalScroll(), const Offset(0, 800));
          await tester.pumpAndSettle();
          expect(compactTitleOpacity(tester), 0);
          expect(tester.getRect(pill), pillAtRest);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  group('card press', () {
    Future<void> pumpCard(WidgetTester tester,
        {required bool reduce, required bool dark, Color? color}) async {
      await tester.pumpWidget(MaterialApp(
        theme: dark
            ? AppTheme.darkFor(arabic: false)
            : AppTheme.lightFor(arabic: false),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Scaffold(
            body: Center(
              child: HomePressableCard(
                onTap: () {},
                color: color,
                child: const SizedBox(width: 160, height: 90),
              ),
            ),
          ),
        ),
      ));
    }

    BoxDecoration decoration(WidgetTester tester) => tester
        .widget<AnimatedContainer>(find.descendant(
            of: find.byType(HomePressableCard),
            matching: find.byType(AnimatedContainer)))
        .decoration! as BoxDecoration;

    double scale(WidgetTester tester) => tester
        .widget<AnimatedScale>(find.descendant(
            of: find.byType(HomePressableCard),
            matching: find.byType(AnimatedScale)))
        .scale;

    for (final dark in [false, true]) {
      for (final reduce in [false, true]) {
        testWidgets(
            'grey, shadowless, darkens and springs (dark=$dark '
            'reduce=$reduce)', (tester) async {
          await pumpCard(tester, reduce: reduce, dark: dark);
          final c = Theme.of(tester.element(find.byType(HomePressableCard)))
              .extension<SiratiColors>()!;
          var d = decoration(tester);
          expect(d.color, c.cardFill);
          expect(d.boxShadow, anyOf(isNull, isEmpty));
          expect(d.border, isNull);
          expect(d.borderRadius, BorderRadius.circular(AppRadius.card));
          expect(scale(tester), 1);

          final gesture = await tester
              .startGesture(tester.getCenter(find.byType(HomePressableCard)));
          await tester.pump(const Duration(milliseconds: 200));
          d = decoration(tester);
          expect(d.color, c.cardFillPressed);
          expect(d.color, isNot(c.cardFill));
          expect(scale(tester), reduce ? 1 : HomePressableCard.pressedScale);
          expect(HomePressableCard.pressedScale, closeTo(.96, .005));

          await gesture.up();
          await tester.pumpAndSettle();
          expect(decoration(tester).color, c.cardFill);
          expect(scale(tester), 1);
        });
      }
    }

    testWidgets('a custom fill darkens by the same rule', (tester) async {
      await pumpCard(tester,
          reduce: false, dark: false, color: SiratiColors.light.surfaceLow);
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(HomePressableCard)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(decoration(tester).color,
          SiratiColors.light.pressed(SiratiColors.light.surfaceLow));
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('readable on the grey cards', () {
    for (final (mode, c) in [
      ('light', SiratiColors.light),
      ('dark', SiratiColors.dark),
    ]) {
      test(
          'Premium card text keeps AA at the gold shine\'s brightest, '
          'resting and pressed ($mode)', () {
        for (final fill in [c.cardFill, c.cardFillPressed]) {
          final lit = Color.alphaBlend(
            c.amberAccent.withValues(alpha: HomePremiumCard.shineStrength),
            fill,
          );
          for (final ink in [c.textPrimary, c.textSecondary]) {
            expect(AppContrast.ratio(ink, lit), greaterThanOrEqualTo(4.5),
                reason: 'ink $ink on $lit');
          }
        }
      });
    }
  });
}
