import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/job_match/presentation/job_match_result_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/animated_score_ring.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/motion.dart';

import '../../support/non_text_contrast.dart';
import 'job_match_test_support.dart';

Widget _reducedHost(Widget child, {String language = 'en'}) {
  return MaterialApp(
    theme: AppTheme.lightFor(arabic: language == 'ar'),
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, widget) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: widget!,
    ),
    home: child,
  );
}

void main() {
  setUp(ErrorShake.reset);

  group('JobMatchScoreRing motion & contrast invariants', () {
    for (final reduce in [false, true]) {
      testWidgets('reduce=$reduce: settles cleanly and keeps score text intact',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightFor(arabic: false),
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (_, child) => MediaQuery(
              data: MediaQueryData(disableAnimations: reduce),
              child: RepaintBoundary(key: phonePaintKey, child: child!),
            ),
            home: Scaffold(
              body: Center(
                child: ColoredBox(
                  color: SiratiColors.light.surface,
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: JobMatchScoreRing(score: 72),
                  ),
                ),
              ),
            ),
          ),
        );

        // Deterministic score text is immediately visible (required by 200ms checks).
        expect(find.text('72'), findsOneWidget);
        if (reduce) {
          expect(tester.hasRunningAnimations, isFalse);
        } else {
          await tester.pump(const Duration(milliseconds: 150));
          final painter = tester
              .widget<CustomPaint>(find.byKey(AnimatedScoreRing.ringKey))
              .painter! as AnimatedScoreRingPainter;
          expect(painter.progress, greaterThan(0));
          expect(painter.progress, lessThan(0.72));
          await tester.pumpAndSettle();
        }

        final settled = tester
            .widget<CustomPaint>(find.byKey(AnimatedScoreRing.ringKey))
            .painter! as AnimatedScoreRingPainter;
        expect(settled.progress, closeTo(0.72, 1e-6));
        expect(settled.strokeCap, StrokeCap.butt);
        expect(
          await expectRenderedControlsAa(tester, 'score ring reduce=$reduce'),
          1,
        );
      });
    }
  });

  group('JobMatch form & result motion', () {
    for (final language in ['en', 'ar']) {
      testWidgets(
          '$language: invalid submit shakes once and expands inline notice',
          (tester) async {
        useTallView(tester);
        final api = FakeJobMatchApi()
          ..cvs = [savedCv(1), savedCv(2, title: 'Analyst')];
        await pumpJobMatch(
          tester,
          api: api,
          auth: FakeAuth(subscription()),
          language: language,
        );

        await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
        await tester.pump(const Duration(milliseconds: 50));

        final shaking = tester
            .stateList<ErrorShakeState>(find.byType(ErrorShake))
            .where((s) => s.shaking)
            .toList();
        expect(shaking, hasLength(1));

        await settle(tester);
        expect(find.byKey(const ValueKey('jm-input-error')), findsOneWidget);

        // Now fix description and trigger CV pick error.
        await enterJob(tester);
        await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
        await settle(tester);
        expect(find.byKey(const ValueKey('jm-pick-error')), findsOneWidget);
      });
    }

    testWidgets(
        'pending skeleton uses AppSkeletonScope and preserves jm-suggestions-region bounds',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(aiStatus: 'queued'))
        ..fetchResponses.add(matchJson(suggestions: []));
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        schedule: const [Duration(seconds: 1)],
      );
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      expect(find.byType(JobMatchResultScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('jm-suggestions-skeleton')),
          matching: find.byType(AppSkeleton),
        ),
        findsNWidgets(5),
      );
      final regionBefore = tester.getRect(
        find.byKey(const ValueKey('jm-suggestions-region')),
      );

      // Immediately upon poll completion, skeleton unmounts and advice reveals.
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.byKey(const ValueKey('jm-suggestions-skeleton')),
        findsNothing,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('jm-suggestions-region'))),
        regionBefore,
      );

      await settle(tester);
      expect(find.byType(MotionReveal), findsWidgets);
    });

    testWidgets('JobMatchSection reduced motion snaps without running tickers',
        (tester) async {
      await tester.pumpWidget(
        _reducedHost(
          const Scaffold(
            body: JobMatchSection(
              highlighted: true,
              child: Text('Highlighted'),
            ),
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Highlighted'), findsOneWidget);
    });
  });
}
