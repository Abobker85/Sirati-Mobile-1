import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/fade_through_page_route.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';
import 'package:sirati/shared/widgets/loading/scan_paper_scene.dart';

const _form = ValueKey('the-form');
const _result = ValueKey('the-result');

Widget _app(Widget home, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.lightFor(arabic: false),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: c!,
      ),
      home: home,
    );

/// Whether the AI overlay's tinted barrier is on screen (page routes have
/// clear barriers).
bool _overlayShown(WidgetTester tester) => find
    .byWidgetPredicate(
        (w) => w is ModalBarrier && w.color != null && w.color!.a > 0)
    .evaluate()
    .isNotEmpty;

void main() {
  group('curtain lift', () {
    for (final kind in AiProgressKind.values) {
      testWidgets(
          '$kind: the result arrives over the overlay; the form never shows '
          'through on its own', (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_app(Builder(builder: (c) {
          ctx = c;
          return const Scaffold(key: _form, body: Text('form'));
        })));
        final shown = AiProgressOverlay.show(ctx, kind: kind, english: true);
        await tester.pump(const Duration(milliseconds: 50));
        final progress = await shown;
        await tester.pump(const Duration(milliseconds: 400));
        expect(_overlayShown(tester), isTrue);
        // complete() waits on the test clock: pump while it waits.
        final done = progress.complete();
        await tester.pump(const Duration(milliseconds: 500));
        await done;

        unawaited(progress.handOff(
          Navigator.of(ctx),
          FadeThroughPageRoute<void>(
            builder: (_) => const Scaffold(key: _result, body: Text('result')),
          ),
        ));
        // Every frame: the overlay or the result covers the form.
        for (var f = 0; f < 40; f++) {
          await tester.pump(const Duration(milliseconds: 16));
          final covered = _overlayShown(tester) ||
              find.byKey(_result).evaluate().isNotEmpty;
          expect(covered, isTrue, reason: 'frame $f');
        }
        await tester.pump(const Duration(milliseconds: 600));
        expect(_overlayShown(tester), isFalse, reason: 'the overlay left');
        expect(find.byKey(_result), findsOneWidget);
        // The form is now under an opaque page: off stage, as after a push.
        expect(find.byKey(_form), findsNothing);
        // Back from the result goes to the form, not to the overlay.
        Navigator.of(tester.element(find.byKey(_result))).pop();
        await tester.pumpAndSettle();
        expect(find.byKey(_form), findsOneWidget);
        expect(_overlayShown(tester), isFalse);
      });
    }

    testWidgets(
        'closing the result before it has arrived also removes the overlay',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const Scaffold(key: _form, body: Text('form'));
      })));
      final shown = AiProgressOverlay.show(ctx,
          kind: AiProgressKind.analysis, english: true);
      await tester.pump(const Duration(milliseconds: 50));
      final progress = await shown;
      await tester.pump(const Duration(milliseconds: 400));
      unawaited(progress.handOff(
        Navigator.of(ctx),
        FadeThroughPageRoute<void>(
          builder: (_) => const Scaffold(key: _result, body: Text('result')),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // Back right away, mid-arrival.
      Navigator.of(tester.element(find.byKey(_result, skipOffstage: false)))
          .pop();
      for (var f = 0; f < 30; f++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(_overlayShown(tester), isFalse);
      expect(find.byKey(_form), findsOneWidget);
      // One more Back would leave the form: nothing else is stacked on it.
      expect(Navigator.of(tester.element(find.byKey(_form))).canPop(), isFalse);
    });

    testWidgets('with the overlay already closed it is a plain push',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const Scaffold(key: _form, body: Text('form'));
      })));
      final shown = AiProgressOverlay.show(ctx,
          kind: AiProgressKind.analysis, english: true);
      await tester.pump(const Duration(milliseconds: 50));
      final progress = await shown;
      await tester.pump(const Duration(milliseconds: 400));
      await progress.dismiss();
      await tester.pumpAndSettle();
      unawaited(progress.handOff(
        Navigator.of(ctx),
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(key: _result, body: Text('result')),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(_result), findsOneWidget);
      Navigator.of(tester.element(find.byKey(_result))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(_form), findsOneWidget);
    });
  });

  group('long waits', () {
    testWidgets('the beam slows after a long wait and keeps the time cap',
        (tester) async {
      Widget scene({required bool slow}) => _app(Scaffold(
            body: ScanPaperScene(stage: ScanStage.reading, slow: slow),
          ));
      await tester.pumpWidget(scene(slow: false));
      ScanPaperSceneState s() =>
          tester.state<ScanPaperSceneState>(find.byType(ScanPaperScene));
      expect(s().passDuration, ScanPaperScene.pass);
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpWidget(scene(slow: true));
      expect(s().passDuration, ScanPaperScene.slowPass);
      expect(s().scanning, isTrue);
      expect(ScanPaperScene.slowPass, greaterThan(ScanPaperScene.pass));
      // Never longer than the cap, whatever the pace.
      await tester.pump(ScanPaperScene.maxScan);
      await tester.pump(ScanPaperScene.slowPass);
      expect(s().scanning, isFalse);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('error banner', () {
    for (final reduce in [false, true]) {
      testWidgets(
          reduce
              ? 'reduced motion: shown at once'
              : 'eases in, drifting into place, then stays still',
          (tester) async {
        await tester.pumpWidget(_app(
          const Scaffold(body: AppFormErrorBanner(message: 'Please check')),
          reduce: reduce,
        ));
        Opacity fade() => tester.widget<Opacity>(find
            .ancestor(
                of: find.text('Please check'), matching: find.byType(Opacity))
            .first);
        await tester.pump(const Duration(milliseconds: 30));
        if (reduce) {
          expect(fade().opacity, 1);
        } else {
          expect(fade().opacity, inExclusiveRange(0, 1));
        }
        await tester.pumpAndSettle();
        expect(fade().opacity, 1);
        expect(tester.hasRunningAnimations, isFalse);
      });
    }
  });
}
