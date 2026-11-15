import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/features/dashboard/presentation/home/home_premium_card.dart';
import 'package:sirati/features/dashboard/presentation/home/home_start_card.dart';
import 'package:sirati/features/dashboard/presentation/premium_unlocked_mark.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/sirati_refresh_indicator.dart';

/// A loop that reports whether it is moving.
class _Probe extends StatelessWidget {
  const _Probe(this.id, this.moving);

  final int id;
  final Map<int, bool> moving;

  @override
  Widget build(BuildContext context) => AmbientLoop(
        active: const Duration(milliseconds: 600),
        rest: const Duration(seconds: 3),
        builder: (context, t, _) {
          moving[id] = t > 0;
          return const SizedBox(width: 10, height: 10);
        },
      );
}

Widget _app(Widget home, {bool reduce = false, bool screenReader = false}) =>
    MaterialApp(
      theme: AppTheme.lightFor(arabic: false),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduce,
          accessibleNavigation: screenReader,
        ),
        child: child!,
      ),
      home: home,
    );

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(AmbientConductor.gap);
}

void main() {
  setUp(() {
    AmbientMotion.enabled.value = true;
    AmbientMotion.foreground.value = true;
    AmbientConductor.reset();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    AmbientMotion.enabled.value = false;
    AmbientMotion.foreground.value = true;
    AmbientConductor.reset();
  });

  group('taking turns', () {
    for (final count in [2, 4, 8]) {
      testWidgets(
          '$count loops: one move at a time, a quiet gap between moves, and '
          'the screen still most of the time', (tester) async {
        final moving = <int, bool>{};
        await tester.pumpWidget(_app(Scaffold(
          body: Wrap(children: [
            for (var i = 0; i < count; i++) _Probe(i, moving),
          ]),
        )));
        const step = Duration(milliseconds: 50);
        var movingTicks = 0;
        var stillRun = 0;
        var shortestGap = 1 << 30;
        var sawMove = false;
        const ticks = 1200; // 60 s
        for (var i = 0; i < ticks; i++) {
          await tester.pump(step);
          final now = moving.values.where((m) => m).length;
          expect(now, lessThanOrEqualTo(1), reason: 'tick $i');
          if (now == 1) {
            movingTicks++;
            if (sawMove && stillRun > 0 && stillRun < shortestGap) {
              shortestGap = stillRun;
            }
            sawMove = true;
            stillRun = 0;
          } else {
            stillRun++;
          }
        }
        // Between two moves there is at least the conductor's gap.
        expect(shortestGap * step.inMilliseconds,
            greaterThanOrEqualTo(AmbientConductor.gap.inMilliseconds - 50));
        // Still for most of the time, however many loops there are.
        expect(movingTicks / ticks, lessThan(.2));
        await _finish(tester);
      });
    }
  });

  group('stillness', () {
    testWidgets('under a bottom sheet nothing moves; closing it resumes',
        (tester) async {
      final moving = <int, bool>{};
      late BuildContext ctx;
      await tester.pumpWidget(_app(Scaffold(
        body: Builder(builder: (c) {
          ctx = c;
          return _Probe(0, moving);
        }),
      )));
      unawaited(showModalBottomSheet<void>(
        context: ctx,
        builder: (_) => const SizedBox(height: 200),
      ));
      await tester.pumpAndSettle();
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(moving[0] ?? false, isFalse, reason: 'tick $i');
      }
      Navigator.of(ctx).pop();
      await tester.pumpAndSettle();
      var moved = false;
      for (var i = 0; i < 200 && !moved; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        moved = moving[0] ?? false;
      }
      expect(moved, isTrue);
      await _finish(tester);
    });

    for (final (name, reduce, reader) in [
      ('a screen reader is on', false, true),
      ('reduce motion is on', true, false),
    ]) {
      testWidgets('$name: nothing moves', (tester) async {
        final moving = <int, bool>{};
        await tester.pumpWidget(_app(Scaffold(body: _Probe(0, moving)),
            reduce: reduce, screenReader: reader));
        for (var i = 0; i < 200; i++) {
          await tester.pump(const Duration(milliseconds: 50));
          expect(moving[0] ?? false, isFalse);
        }
        await _finish(tester);
      });
    }

    testWidgets('in the background nothing moves; back in front it resumes',
        (tester) async {
      final moving = <int, bool>{};
      await tester.pumpWidget(_app(Scaffold(body: _Probe(0, moving))));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      for (var i = 0; i < 200; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(moving[0] ?? false, isFalse, reason: 'tick $i');
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      var moved = false;
      for (var i = 0; i < 100 && !moved; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        moved = moving[0] ?? false;
      }
      expect(moved, isTrue);
      await _finish(tester);
    });

    testWidgets('a rest shorter than 5x the move is refused', (tester) async {
      await tester.pumpWidget(_app(AmbientLoop(
        active: const Duration(seconds: 1),
        rest: const Duration(seconds: 4),
        builder: (_, __, ___) => const SizedBox(),
      )));
      expect(tester.takeException(), isA<AssertionError>());
      await _finish(tester);
    });
  });

  group('Decorative motion setting', () {
    test('turning it off stops it and is remembered for the next launch',
        () async {
      await AmbientMotion.setEnabled(false);
      expect(AmbientMotion.enabled.value, isFalse);
      AmbientMotion.enabled.value = true;
      await AmbientMotion.load();
      expect(AmbientMotion.enabled.value, isFalse);
      await AmbientMotion.setEnabled(true);
      AmbientMotion.enabled.value = false;
      await AmbientMotion.load();
      expect(AmbientMotion.enabled.value, isTrue);
    });

    test('on by default', () async {
      AmbientMotion.enabled.value = false;
      await AmbientMotion.load();
      expect(AmbientMotion.enabled.value, isTrue);
    });
  });

  group('readable under the shine', () {
    for (final (mode, c) in [
      ('light', SiratiColors.light),
      ('dark', SiratiColors.dark),
    ]) {
      test('start cards keep AA at the shine\'s brightest ($mode)', () {
        for (final band in [c.brandSurface, c.inkSurface]) {
          final lit = Color.alphaBlend(
            c.onBrandSurface.withValues(alpha: HomeStartCard.shineStrength),
            band,
          );
          // Titles at full ink, body lines at 92%.
          for (final alpha in [1.0, .92]) {
            final ink = Color.alphaBlend(
                c.onBrandSurface.withValues(alpha: alpha), lit);
            expect(AppContrast.ratio(ink, lit), greaterThanOrEqualTo(4.5),
                reason: 'band $band, ink alpha $alpha');
          }
        }
      });

      test('Premium card keeps AA at the gold shine\'s brightest ($mode)', () {
        final lit = Color.alphaBlend(
          c.amberAccent.withValues(alpha: HomePremiumCard.shineStrength),
          c.surface,
        );
        for (final ink in [c.textPrimary, c.textSecondary]) {
          expect(AppContrast.ratio(ink, lit), greaterThanOrEqualTo(4.5),
              reason: 'ink $ink');
        }
      });
    }
  });

  group('idle hint', () {
    Future<IdleNudgeState> pumpHint(WidgetTester tester,
        {Listenable? activity}) async {
      await tester.pumpWidget(_app(Scaffold(
        body: Center(
          child: IdleNudge(
            activity: activity,
            child: const SizedBox(width: 80, height: 40),
          ),
        ),
      )));
      return tester.state(find.byType(IdleNudge));
    }

    testWidgets('one hint by default', (tester) async {
      final s = await pumpHint(tester);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 7));
      }
      expect(s.hints, 1);
      await _finish(tester);
    });

    testWidgets('typing keeps resetting the wait: no hint while typing',
        (tester) async {
      final text = TextEditingController();
      addTearDown(text.dispose);
      final s = await pumpHint(tester, activity: text);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 4));
        text.text = '${text.text}a';
      }
      expect(s.hints, 0);
      await _finish(tester);
    });

    testWidgets('a key press resets the wait too', (tester) async {
      final s = await pumpHint(tester);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 4));
        await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      }
      expect(s.hints, 0);
      await _finish(tester);
    });

    testWidgets('in the background: no hint', (tester) async {
      final s = await pumpHint(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(s.hints, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _finish(tester);
    });
  });

  group('should-fix items', () {
    testWidgets('the Premium mark is the same size waiting or confirmed',
        (tester) async {
      AmbientMotion.enabled.value = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      Size size(bool confirmed) =>
          tester.getSize(find.byType(PremiumUnlockedMark));
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: PremiumUnlockedMark(confirmed: false)))));
      final waiting = size(false);
      await tester.pumpWidget(_app(const Scaffold(
          body: Center(child: PremiumUnlockedMark(confirmed: true)))));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        expect(size(true), waiting, reason: 'frame $i');
      }
      await tester.pumpAndSettle();
    });

    testWidgets('screen readers hear the refresh while it loads',
        (tester) async {
      AmbientMotion.enabled.value = false;
      final handle = tester.ensureSemantics();
      final done = Completer<void>();
      await tester.pumpWidget(_app(Scaffold(
        body: SiratiRefreshIndicator(
          onRefresh: () => done.future,
          child: ListView(children: [
            for (var i = 0; i < 30; i++) const SizedBox(height: 60),
          ]),
        ),
      )));
      final g = await tester.startGesture(const Offset(400, 200));
      for (var i = 0; i < 30; i++) {
        await g.moveBy(const Offset(0, 12));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final l = MaterialLocalizations.of(
          tester.element(find.byType(SiratiRefreshIndicator)));
      expect(find.bySemanticsLabel(l.refreshIndicatorSemanticLabel),
          findsOneWidget);
      done.complete();
      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('RouteSettled waits for the page to arrive', (tester) async {
      AmbientMotion.enabled.value = false;
      final seen = <bool>[];
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));
      unawaited(Navigator.of(ctx).push(MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: RouteSettled(builder: (context, settled) {
            seen.add(settled);
            return const SizedBox();
          }),
        ),
      )));
      await tester.pump();
      await tester.pump();
      final route = ModalRoute.of(tester.element(find.byType(RouteSettled)))!;
      while (!route.animation!.isCompleted) {
        expect(seen.last, isFalse);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump();
      expect(seen.last, isTrue);
    });

    testWidgets('the step on its way out cannot be tapped', (tester) async {
      AmbientMotion.enabled.value = false;
      var taps = 0;
      Widget step(int n) => _app(Scaffold(
            body: MotionStepSwitcher(
              stepKey: n,
              child: n == 1
                  ? TextButton(
                      onPressed: () => taps++, child: const Text('send'))
                  : const SizedBox(height: 40, width: 40),
            ),
          ));
      await tester.pumpWidget(step(1));
      await tester.pumpWidget(step(2));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('send'), findsOneWidget, reason: 'still fading out');
      await tester.tap(find.text('send'), warnIfMissed: false);
      expect(taps, 0);
      await tester.pumpAndSettle();
    });
  });
}
