import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/fade_through_page_route.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_dialog.dart';
import 'package:sirati/shared/widgets/motion.dart';

const _a = ValueKey('page-a');
const _b = ValueKey('page-b');

/// The real app theme (its page transitions), in [direction].
Widget _app(
  Widget home, {
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
  TargetPlatform platform = TargetPlatform.android,
}) =>
    MaterialApp(
      // The app theme is cached, so the platform is set explicitly.
      theme: AppTheme.lightFor(arabic: direction == TextDirection.rtl)
          .copyWith(platform: platform),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: c!,
      ),
      home: home,
    );

Widget _page(Key key) => Scaffold(
      key: key,
      body: const Center(child: Text('page')),
    );

/// The horizontal offset of the page with [key], relative to the screen.
double _x(WidgetTester tester, Key key) =>
    tester.getTopLeft(find.byKey(key)).dx;

void main() {
  group('shared axis (Android and others)', () {
    for (final direction in TextDirection.values) {
      testWidgets(
          '${direction.name}: new page comes from the end edge, old one steps '
          'toward the start, both settle', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        late BuildContext ctx;
        await tester.pumpWidget(_app(
          Builder(builder: (c) {
            ctx = c;
            return _page(_a);
          }),
          direction: direction,
        ));
        final end = direction == TextDirection.rtl ? -1.0 : 1.0;
        unawaited(Navigator.of(ctx)
            .push(MaterialPageRoute<void>(builder: (_) => _page(_b))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(_x(tester, _b) * end, greaterThan(0),
            reason: 'from the end edge (left in Arabic)');
        expect(_x(tester, _a) * end, lessThan(0),
            reason: 'the old page steps toward the start edge');
        // Never further than the travel distance.
        expect(_x(tester, _b).abs(),
            lessThanOrEqualTo(SiratiPageTransitionsBuilder.distance));
        await tester.pumpAndSettle();
        expect(_x(tester, _b), 0);

        // Back: the same in reverse, settling the old page in place.
        Navigator.of(ctx).pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        expect(_x(tester, _b) * end, greaterThan(0));
        await tester.pumpAndSettle();
        expect(find.byKey(_b), findsNothing);
        expect(_x(tester, _a), 0);
        debugDefaultTargetPlatformOverride = null;
      });
    }

    test('uses the app timings', () {
      const b = SiratiPageTransitionsBuilder();
      expect(b.transitionDuration, MotionDurations.step);
      expect(b.reverseTransitionDuration, MotionDurations.medium);
    });

    testWidgets('reduced motion: the page simply appears', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      late BuildContext ctx;
      await tester.pumpWidget(_app(
        Builder(builder: (c) {
          ctx = c;
          return _page(_a);
        }),
        reduce: true,
      ));
      unawaited(Navigator.of(ctx)
          .push(MaterialPageRoute<void>(builder: (_) => _page(_b))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(_x(tester, _b), 0);
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('iOS edge swipe back', () {
    for (final direction in TextDirection.values) {
      for (final blocked in [false, true]) {
        testWidgets(
            '${direction.name}: a swipe from the leading edge '
            '${blocked ? 'is refused by a blocking screen' : 'goes back'}',
            (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
          late BuildContext ctx;
          await tester.pumpWidget(_app(
            Builder(builder: (c) {
              ctx = c;
              return _page(_a);
            }),
            direction: direction,
            platform: TargetPlatform.iOS,
          ));
          unawaited(Navigator.of(ctx).push(MaterialPageRoute<void>(
            builder: (_) =>
                blocked ? PopScope(canPop: false, child: _page(_b)) : _page(_b),
          )));
          await tester.pumpAndSettle();
          final size = tester.getSize(find.byKey(_b));
          final rtl = direction == TextDirection.rtl;
          // The leading edge is the right one in Arabic.
          final from = Offset(rtl ? size.width - 5 : 5, size.height / 2);
          await tester.timedDragFrom(
            from,
            Offset(rtl ? -size.width * .8 : size.width * .8, 0),
            const Duration(milliseconds: 400),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(_b), blocked ? findsOneWidget : findsNothing);
          debugDefaultTargetPlatformOverride = null;
        });
      }
    }
  });

  group('fade through', () {
    testWidgets('never slides; fades in after a short wait, then settles',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return _page(_a);
      })));
      final centre = tester.getCenter(find.byKey(_a)).dx;
      unawaited(Navigator.of(ctx)
          .push(FadeThroughPageRoute<void>(builder: (_) => _page(_b))));
      await tester.pump();
      const step = Duration(milliseconds: 20);
      final frames =
          FadeThroughPageRoute.duration.inMilliseconds ~/ step.inMilliseconds;
      for (var f = 1; f <= frames; f++) {
        await tester.pump(step);
        // It grows a little from 98%, but its centre never moves sideways.
        expect(tester.getCenter(find.byKey(_b)).dx, centre,
            reason: 'no sideways move at frame $f');
        final fade = tester
            .widgetList<FadeTransition>(find.ancestor(
                of: find.byKey(_b), matching: find.byType(FadeTransition)))
            .first
            .opacity
            .value;
        if (f * step.inMilliseconds <
            FadeThroughPageRoute.duration.inMilliseconds *
                FadeThroughPageRoute.fadeInStart) {
          expect(fade, 0, reason: 'waits for the old page at frame $f');
        }
      }
      await tester.pumpAndSettle();
      expect(_x(tester, _b), 0);
    });

    test('its timings match the app tokens', () {
      expect(FadeThroughPageRoute.duration, MotionDurations.slow);
      expect(FadeThroughPageRoute.reverseDuration, MotionDurations.fast);
      expect(FadeThroughPageRoute.enterCurve, MotionCurves.enter);
    });
  });

  group('dialogs', () {
    for (final reduce in [false, true]) {
      testWidgets(
          reduce
              ? 'reduced motion: appears at once'
              : 'fades in and grows from 96%, then closes', (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_app(
          Builder(builder: (c) {
            ctx = c;
            return _page(_a);
          }),
          reduce: reduce,
        ));
        unawaited(showSiratiDialog<void>(
          context: ctx,
          builder: (_) => const AlertDialog(content: Text('hello')),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        final scale = tester
            .widgetList<ScaleTransition>(find.ancestor(
                of: find.text('hello'), matching: find.byType(ScaleTransition)))
            .map((s) => s.scale.value);
        if (reduce) {
          expect(scale, isEmpty);
        } else {
          expect(scale.first, inExclusiveRange(SiratiDialogRoute.scaleFrom, 1));
        }
        await tester.pumpAndSettle();
        expect(find.text('hello'), findsOneWidget);
        Navigator.of(ctx, rootNavigator: true).pop();
        await tester.pumpAndSettle();
        expect(find.text('hello'), findsNothing);
      });
    }
  });
}
