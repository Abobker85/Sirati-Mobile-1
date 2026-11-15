import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/models/ats_grade.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/score_ring.dart';

const _scores = [0, 1, 37, 59, 60, 74, 86, 99, 100];

Future<void> _pump(
  WidgetTester tester,
  int score, {
  bool reduce = false,
  bool dark = false,
  String language = 'ar',
  String? label,
}) async {
  AppLocale.languageCode.value = language;
  final arabic = language == 'ar';
  await tester.pumpWidget(MaterialApp(
    theme:
        dark ? AppTheme.darkFor(arabic: arabic) : AppTheme.lightFor(arabic: arabic),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: child!,
    ),
    home: Scaffold(
      body: Center(child: ScoreRing(score: score, semanticLabel: label)),
    ),
  ));
}

/// What the ring shows right now: (number in the middle, arc fill 0–1).
(int, double) _shown(WidgetTester tester) {
  final ring = find.byType(ScoreRing);
  final number = tester.widget<Text>(
    find.descendant(of: ring, matching: find.byType(Text)),
  );
  final arc = tester.widget<CircularProgressIndicator>(
    find.descendant(of: ring, matching: find.byType(CircularProgressIndicator)),
  );
  return (int.parse(number.data!), arc.value!);
}

void main() {
  for (final score in _scores) {
    testWidgets('$score: starts empty, only grows, lands on the score',
        (tester) async {
      await _pump(tester, score);
      expect(_shown(tester), (0, 0.0));

      var previous = _shown(tester);
      const frames = 16;
      for (var i = 0; i < frames; i++) {
        await tester.pump(ScoreRing.duration ~/ frames);
        final now = _shown(tester);
        expect(now.$1, greaterThanOrEqualTo(previous.$1));
        expect(now.$2, greaterThanOrEqualTo(previous.$2));
        expect(now.$1, lessThanOrEqualTo(score));
        expect(now.$2, lessThanOrEqualTo(score / 100));
        // The number and the arc always tell the same score.
        expect(now.$1, (now.$2 * 100).round());
        previous = now;
      }

      await tester.pumpAndSettle();
      expect(_shown(tester), (score, score / 100));
    });

    testWidgets('$score: reduced motion shows the score on the first frame',
        (tester) async {
      await _pump(tester, score, reduce: true);
      expect(_shown(tester), (score, score / 100));
      await tester.pump(ScoreRing.duration);
      expect(_shown(tester), (score, score / 100));
    });
  }

  for (final (from, to) in [(40, 90), (90, 40), (0, 100), (73, 74)]) {
    testWidgets('a new score moves from $from to $to without leaving the range',
        (tester) async {
      await _pump(tester, from);
      await tester.pumpAndSettle();
      await _pump(tester, to);

      final low = from < to ? from : to, high = from < to ? to : from;
      const frames = 12;
      for (var i = 0; i < frames; i++) {
        await tester.pump(ScoreRing.duration ~/ frames);
        final (number, arc) = _shown(tester);
        expect(number, inInclusiveRange(low, high));
        expect(arc, inInclusiveRange(low / 100, high / 100));
      }
      await tester.pumpAndSettle();
      expect(_shown(tester), (to, to / 100));
    });
  }

  for (final dark in [false, true]) {
    testWidgets(
        'arc colour follows the score band, number stays on body ink '
        '(${dark ? 'dark' : 'light'})', (tester) async {
      for (final score in _scores) {
        await _pump(tester, score, dark: dark, reduce: true);
        final context = tester.element(find.byType(ScoreRing));
        final colors = context.sirati;
        final expected = switch (ScoreBand.of(score)) {
          ScoreBand.excellent || ScoreBand.veryGood => colors.success,
          ScoreBand.fair => colors.warning,
          ScoreBand.weak => colors.error,
        };
        final arc = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(arc.color, expected, reason: 'score $score');

        final number = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byType(ScoreRing),
            matching: find.byType(RichText),
          ),
        );
        expect(number.text.style!.color, colors.textPrimary);
      }
    });
  }

  for (final language in ['ar', 'en']) {
    testWidgets('$language: the number is always 0-9 digits', (tester) async {
      for (final score in _scores) {
        await _pump(tester, score, language: language, reduce: true);
        final text = tester
            .widget<Text>(find.descendant(
              of: find.byType(ScoreRing),
              matching: find.byType(Text),
            ))
            .data!;
        expect(text, '$score');
      }
    });
  }

  testWidgets('with a label the ring is one node that reads the label',
      (tester) async {
    final handle = tester.ensureSemantics();
    for (final score in _scores) {
      final label = 'score label $score';
      await _pump(tester, score, label: label, reduce: true);
      expect(find.bySemanticsLabel(label), findsOneWidget);
      expect(find.bySemanticsLabel('$score'), findsNothing);
    }
    handle.dispose();
  });

  testWidgets('without a label the ring is silent', (tester) async {
    final handle = tester.ensureSemantics();
    for (final score in _scores) {
      await _pump(tester, score, reduce: true);
      expect(find.bySemanticsLabel('$score'), findsNothing);
    }
    handle.dispose();
  });
}
