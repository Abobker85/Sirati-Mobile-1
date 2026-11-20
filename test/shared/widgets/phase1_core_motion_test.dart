import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/fade_through_page_route.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/add_button.dart';
import 'package:sirati/shared/widgets/animated_ats_score_bar.dart';
import 'package:sirati/shared/widgets/animated_score_ring.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/loading/branded_loader.dart';
import 'package:sirati/shared/widgets/loading/cv_drafting_scene.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
  bool dark = false,
}) =>
    MaterialApp(
      themeAnimationDuration: Duration.zero,
      theme: dark
          ? AppTheme.darkFor(arabic: direction == TextDirection.rtl)
          : AppTheme.lightFor(arabic: direction == TextDirection.rtl),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: Directionality(textDirection: direction, child: c!),
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('bidirectional MotionStepSwitcher', () {
    Widget step(
      int n, {
      required int direction,
      TextDirection textDirection = TextDirection.ltr,
      bool reduce = false,
    }) =>
        _host(
          SizedBox(
            width: 200,
            height: 100,
            child: MotionStepSwitcher(
              stepKey: n,
              direction: direction,
              child: SizedBox.expand(key: ValueKey('step-$n')),
            ),
          ),
          direction: textDirection,
          reduce: reduce,
        );

    for (final textDir in TextDirection.values) {
      for (final stepDir in [1, -1]) {
        testWidgets(
          '${textDir.name} dir=$stepDir slides incoming from expected edge and outgoing opposite',
          (tester) async {
            await tester.pumpWidget(
              step(1, direction: stepDir, textDirection: textDir),
            );
            final rest = tester.getRect(find.byKey(const ValueKey('step-1')));

            await tester.pumpWidget(
              step(2, direction: stepDir, textDirection: textDir),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 24));

            final incoming =
                tester.getRect(find.byKey(const ValueKey('step-2')));
            final outgoing =
                tester.getRect(find.byKey(const ValueKey('step-1')));

            final endSign = textDir == TextDirection.rtl ? -1.0 : 1.0;
            final expectedSign = endSign * stepDir;
            expect((incoming.left - rest.left) * expectedSign, greaterThan(0));
            expect((outgoing.left - rest.left) * expectedSign, lessThan(0));

            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('step-1')), findsNothing);
            expect(tester.getRect(find.byKey(const ValueKey('step-2'))), rest);
          },
        );
      }
    }

    testWidgets('reduced motion swaps immediately with no running animations',
        (tester) async {
      await tester.pumpWidget(step(1, direction: -1, reduce: true));
      await tester.pumpWidget(step(2, direction: -1, reduce: true));
      expect(find.byKey(const ValueKey('step-1')), findsNothing);
      expect(find.byKey(const ValueKey('step-2')), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('MotionExpandSlot', () {
    testWidgets('animates height/content change and settles cleanly',
        (tester) async {
      Widget buildSlot(bool expanded, {bool reduce = false}) => _host(
            SizedBox(
              width: 240,
              child: MotionExpandSlot(
                child: expanded
                    ? const SizedBox(
                        key: ValueKey('expanded'),
                        height: 80,
                        child: Text('More info'),
                      )
                    : const SizedBox.shrink(key: ValueKey('collapsed')),
              ),
            ),
            reduce: reduce,
          );

      await tester.pumpWidget(buildSlot(false));
      expect(tester.getSize(find.byType(MotionExpandSlot)).height, 0);

      await tester.pumpWidget(buildSlot(true));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(MotionExpandSlot)).height, 80);
      expect(tester.hasRunningAnimations, isFalse);

      // Reduced motion snaps at once with zero running animations.
      await tester.pumpWidget(buildSlot(false, reduce: true));
      await tester.pumpWidget(buildSlot(true, reduce: true));
      expect(tester.getSize(find.byType(MotionExpandSlot)).height, 80);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('MotionSegmentedPill', () {
    final haptics = <String>[];
    setUp(() {
      haptics.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add('${call.arguments}');
        }
        return null;
      });
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    for (final textDir in TextDirection.values) {
      testWidgets(
        '${textDir.name}: pill aligns to selected segment, respects 48dp target, and keeps shipped weights',
        (tester) async {
          var current = 'a';
          Widget pill({required bool reduce, required bool dark}) => _host(
                StatefulBuilder(
                  builder: (context, setState) => SizedBox(
                    width: 300,
                    child: MotionSegmentedPill<String>(
                      value: current,
                      onChanged: (v) => setState(() => current = v),
                      options: const [
                        MotionSegmentOption(
                          value: 'a',
                          label: 'First',
                          key: ValueKey('seg-a'),
                        ),
                        MotionSegmentOption(
                          value: 'b',
                          label: 'Second',
                          key: ValueKey('seg-b'),
                        ),
                        MotionSegmentOption(
                          value: 'c',
                          label: 'Third',
                          key: ValueKey('seg-c'),
                        ),
                      ],
                    ),
                  ),
                ),
                direction: textDir,
                reduce: reduce,
                dark: dark,
              );

          await tester.pumpWidget(pill(reduce: false, dark: false));
          await tester.pumpAndSettle();

          for (final k in ['seg-a', 'seg-b', 'seg-c']) {
            expect(
              tester.getSize(find.byKey(ValueKey(k))).height,
              greaterThanOrEqualTo(AppTouchTarget.min),
            );
          }

          AnimatedAlign currentAlign() =>
              tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
          expect(currentAlign().alignment, const AlignmentDirectional(-1.0, 0));

          await tester.tap(find.byKey(const ValueKey('seg-b')));
          await tester.pump();
          expect(currentAlign().alignment, const AlignmentDirectional(0.0, 0));
          expect(haptics, hasLength(1));
          await tester.pumpAndSettle();

          await tester.tap(find.byKey(const ValueKey('seg-c')));
          await tester.pump();
          expect(currentAlign().alignment, const AlignmentDirectional(1.0, 0));
          await tester.pumpAndSettle();

          // FontWeight must never interpolate to w500; contrast must pass AA;
          // tapping a segment under reduced motion has zero running animations.
          for (final dark in [false, true]) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(pill(reduce: true, dark: dark));
            expect(tester.hasRunningAnimations, isFalse);
            await tester.tap(find.byKey(const ValueKey('seg-b')));
            await tester.pump();
            expect(tester.hasRunningAnimations, isFalse);
            final c = tester
                .element(find.byType(MotionSegmentedPill<String>))
                .sirati;
            expect(AppContrast.ratio(c.primaryInk, c.surface),
                greaterThanOrEqualTo(4.5));
            expect(AppContrast.ratio(c.textSecondary, c.surfaceLow),
                greaterThanOrEqualTo(4.5));
            for (final t in tester.widgetList<Text>(find.byType(Text))) {
              expect(
                t.style!.fontWeight,
                isIn([FontWeight.w400, FontWeight.w600, FontWeight.w700]),
              );
            }
          }
        },
      );
    }
  });

  group('shared AnimatedScoreRing', () {
    int shown(WidgetTester tester) => int.parse(
          tester
              .widget<Text>(find.descendant(
                of: find.byType(AnimatedScoreRing),
                matching: find.byType(Text),
              ))
              .data!,
        );

    AnimatedScoreRingPainter painter(WidgetTester tester) => tester
        .widget<CustomPaint>(find.byKey(AnimatedScoreRing.ringKey))
        .painter! as AnimatedScoreRingPainter;

    testWidgets('animates within default 420ms duration and settles cleanly',
        (tester) async {
      await tester.pumpWidget(_host(
        const AnimatedScoreRing(
          score: 84,
          arcColor: Color(0xFF006A60),
          trackColor: Color(0xFFBBC9C6),
          strokeCap: StrokeCap.butt,
        ),
      ));
      expect(shown(tester), 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(shown(tester), inExclusiveRange(0, 84));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.hasRunningAnimations, isFalse);
      expect(shown(tester), 84);
      expect(painter(tester).progress, closeTo(0.84, 1e-6));
      expect(painter(tester).strokeCap, StrokeCap.butt);
    });

    testWidgets('waits for route push transition before sweeping',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_host(Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      unawaited(Navigator.of(ctx).push(
        FadeThroughPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: AnimatedScoreRing(score: 76)),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      // Route transition is mid-flight, ring has not started yet.
      expect(shown(tester), 0);

      await tester.pumpAndSettle();
      expect(shown(tester), 76);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion shows target score on first frame',
        (tester) async {
      await tester.pumpWidget(
        _host(const AnimatedScoreRing(score: 91), reduce: true),
      );
      expect(shown(tester), 91);
      expect(painter(tester).progress, closeTo(0.91, 1e-6));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('CvDraftingScene', () {
    for (final stage in DraftStage.values) {
      testWidgets('renders ${stage.name} and stops under reduced motion',
          (tester) async {
        await tester.pumpWidget(
          _host(CvDraftingScene(stage: stage)),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byKey(CvDraftingScene.paintKey), findsOneWidget);

        await tester.pumpWidget(
          _host(CvDraftingScene(stage: stage), reduce: true),
        );
        expect(tester.hasRunningAnimations, isFalse);
        final s = tester.state<CvDraftingSceneState>(
          find.byType(CvDraftingScene),
        );
        expect(s.drafting, isFalse);
      });
    }

    for (final dir in TextDirection.values) {
      testWidgets('${dir.name}: badge sits on trailing side of miniature page',
          (tester) async {
        final paper = CvDraftingPainter.paperRect(CvDraftingScene.size);
        final badge = CvDraftingPainter.badgeCenter(
          CvDraftingScene.size,
          rtl: dir == TextDirection.rtl,
        );
        if (dir == TextDirection.rtl) {
          expect(badge.dx, lessThan(paper.center.dx));
        } else {
          expect(badge.dx, greaterThan(paper.center.dx));
        }
      });
    }

    testWidgets('respects slow pass and maxDraft cap', (tester) async {
      await tester.pumpWidget(
        _host(const CvDraftingScene(stage: DraftStage.working, slow: false)),
      );
      CvDraftingSceneState s() =>
          tester.state<CvDraftingSceneState>(find.byType(CvDraftingScene));
      expect(s().passDuration, CvDraftingScene.pass);
      expect(s().drafting, isTrue);

      await tester.pumpWidget(
        _host(const CvDraftingScene(stage: DraftStage.working, slow: true)),
      );
      expect(s().passDuration, CvDraftingScene.slowPass);

      await tester.pump(CvDraftingScene.maxDraft);
      await tester.pump(CvDraftingScene.slowPass);
      expect(s().drafting, isFalse);
    });
  });

  group('contrast, RTL, and reduced-motion hardening', () {
    for (final dark in [false, true]) {
      testWidgets(
        'SiratiAddButton meets WCAG AA (>= 4.5:1) in ${dark ? 'dark' : 'light'} mode',
        (tester) async {
          await tester.pumpWidget(
            _host(SiratiAddButton(onTap: () {}), dark: dark),
          );
          final icon = tester.widget<Icon>(find.byIcon(Icons.add_rounded));
          final material = tester.widget<Material>(
            find
                .ancestor(
                  of: find.byIcon(Icons.add_rounded),
                  matching: find.byType(Material),
                )
                .first,
          );
          expect(
            AppContrast.ratio(icon.color!, material.color!),
            greaterThanOrEqualTo(4.5),
          );
        },
      );

      testWidgets(
        'outlined SubmitButton disabled foreground differs from enabled and holds AA (${dark ? 'dark' : 'light'})',
        (tester) async {
          await tester.pumpWidget(_host(
            const SubmitButton(
              label: 'Enhance',
              outlined: true,
              onPressed: null,
            ),
            dark: dark,
          ));
          final c = tester.element(find.byType(SubmitButton)).sirati;
          final btn =
              tester.widget<OutlinedButton>(find.byType(OutlinedButton));
          final disabledFg =
              btn.style!.foregroundColor!.resolve({WidgetState.disabled})!;
          expect(disabledFg, isNot(equals(c.primaryInk)));
          expect(
            AppContrast.ratio(disabledFg, c.surface),
            greaterThanOrEqualTo(4.5),
          );
        },
      );
    }

    testWidgets('AppButton wraps directional icons in DirectionalIcon',
        (tester) async {
      await tester.pumpWidget(_host(
        AppButton.primary(
          label: 'Next',
          icon: Icons.arrow_forward,
          onPressed: () {},
        ),
        direction: TextDirection.rtl,
      ));
      expect(find.byType(DirectionalIcon), findsOneWidget);
    });

    testWidgets(
      'BrandedLoader and AppSkeleton stop animations when disableAnimations is true',
      (tester) async {
        await tester.pumpWidget(_host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandedLoader(),
              SizedBox(height: 12),
              AppSkeleton(width: 120, height: 16),
            ],
          ),
          reduce: true,
        ));
        expect(tester.hasRunningAnimations, isFalse);
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);

        // Toggle from active -> reduced motion dynamically.
        await tester.pumpWidget(_host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandedLoader(),
              SizedBox(height: 12),
              AppSkeleton(width: 120, height: 16),
            ],
          ),
          reduce: false,
        ));
        expect(tester.hasRunningAnimations, isTrue);

        await tester.pumpWidget(_host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandedLoader(),
              SizedBox(height: 12),
              AppSkeleton(width: 120, height: 16),
            ],
          ),
          reduce: true,
        ));
        await tester.pumpAndSettle();
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets(
      'AppFormSuccessBanner AnimatedSize and AnimatedAtsScoreBar complete cleanly under reduced motion',
      (tester) async {
        var completed = 0;
        await tester.pumpWidget(_host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppFormSuccessBanner(message: 'Saved'),
              AnimatedAtsScoreBar(
                value: 0.75,
                color: const Color(0xFF006A60),
                onAnimationComplete: () => completed++,
              ),
            ],
          ),
          reduce: true,
        ));
        await tester.pumpAndSettle();
        expect(completed, 1);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets(
      'FadeThroughPageRoute fades outgoing page with background veil when covered',
      (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          home: Builder(builder: (c) {
            ctx = c;
            return const Scaffold(body: Text('root'));
          }),
        ));

        unawaited(Navigator.of(ctx).push(FadeThroughPageRoute<void>(
          builder: (_) => const Scaffold(
            key: ValueKey('first-ft'),
            body: Text('first'),
          ),
        )));
        await tester.pumpAndSettle();

        unawaited(Navigator.of(ctx).push(FadeThroughPageRoute<void>(
          builder: (_) => const Scaffold(
            key: ValueKey('second-ft'),
            body: Text('second'),
          ),
        )));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Outgoing first-ft should have a ColoredBox veil over it while leaving.
        final veil = find.descendant(
          of: find.ancestor(
            of: find.byKey(const ValueKey('first-ft')),
            matching: find.byType(AnimatedBuilder),
          ),
          matching: find.byWidgetPredicate(
            (w) => w is ColoredBox && w.color.a > 0 && w.color.a < 1,
          ),
        );
        expect(veil, findsWidgets);
        await tester.pumpAndSettle();
      },
    );
  });
}
