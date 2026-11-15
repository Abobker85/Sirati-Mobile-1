import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/storage/user_scoped_storage.dart';
import 'package:sirati/features/ats_scanner/application/last_scan_scores.dart';
import 'package:sirati/features/ats_scanner/domain/score_band.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_band_style.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/score_ring.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

Widget _app(
  Widget child, {
  bool reduce = false,
  TextDirection direction = TextDirection.ltr,
}) =>
    MaterialApp(
      theme: AppTheme.lightFor(arabic: direction == TextDirection.rtl),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: c!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

const _scoreColor = Color(0xFF0E7A4F);

/// Scores spread over every band, both edges of each boundary, and the ends.
List<int> get _scores => {
      0,
      1,
      100,
      for (final b in AnimatedScoreRing.bandBoundaries) ...[b - 1, b, b + 1],
      for (var s = 3; s < 100; s += 11) s,
    }.where((s) => s >= 0 && s <= 100).toList()
      ..sort();

ScoreRingPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(find.byKey(AnimatedScoreRing.ringKey)).painter!
        as ScoreRingPainter;

AnimatedScoreRingState _ring(WidgetTester tester) =>
    tester.state(find.byType(AnimatedScoreRing));

void main() {
  group('band boundaries', () {
    test('a climb to any score passes one boundary per band change', () {
      for (var score = 0; score <= 100; score++) {
        final bands = {for (var s = 0; s <= score; s++) ScoreBand.of(s)};
        expect(
          AnimatedScoreRing.crossingsTo(score),
          hasLength(bands.length - 1),
          reason: 'score $score',
        );
      }
    });

    test('out-of-range scores clamp instead of throwing', () {
      expect(AnimatedScoreRing.crossingsTo(-5), isEmpty);
      expect(
        AnimatedScoreRing.crossingsTo(140),
        AnimatedScoreRing.crossingsTo(100),
      );
    });
  });

  group('band ticks and colour', () {
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

    for (final score in _scores) {
      testWidgets('$score: ticks once per band, each on reaching it',
          (tester) async {
        await tester.pumpWidget(_app(AnimatedScoreRing(
            score: score, scoreColor: _scoreColor, reveal: true)));
        final crossings = AnimatedScoreRing.crossingsTo(score);
        var ticksSeen = 0;
        for (var f = 0; f < 100; f++) {
          await tester.pump(const Duration(milliseconds: 20));
          final shown = (_ring(tester).shownValue * 100).round();
          final ticks = haptics.where((h) => h.endsWith('selectionClick'));
          // Never ahead of the number, never behind it.
          expect(ticks.length, crossings.where((b) => b <= shown).length,
              reason: 'frame $f, shown $shown');
          expect(ticks.length, greaterThanOrEqualTo(ticksSeen));
          ticksSeen = ticks.length;
        }
        await tester.pumpAndSettle();
        expect(_ring(tester).bandTicks, crossings.length);
        expect(_painter(tester).color, _scoreColor,
            reason: 'the arc ends on the score colour');
      });
    }

    testWidgets('the arc colour ends exactly on the score colour for any score',
        (tester) async {
      for (final score in _scores) {
        await tester.pumpWidget(_app(AnimatedScoreRing(
          key: ValueKey(score),
          score: score,
          scoreColor: _scoreColor,
        )));
        final ctx = tester.element(find.byType(AnimatedScoreRing));
        expect(
            _ring(tester).bandColor(ctx.sirati, score.toDouble()), _scoreColor,
            reason: 'score $score');
      }
    });

    testWidgets('a band the climb reaches is fully its colour at its boundary',
        (tester) async {
      await tester.pumpWidget(_app(const AnimatedScoreRing(
          score: 100, scoreColor: _scoreColor, reveal: true)));
      final ctx = tester.element(find.byType(AnimatedScoreRing));
      final c = ctx.sirati;
      final ring = _ring(tester);
      for (final b in AnimatedScoreRing.bandBoundaries) {
        final band = ScoreBand.of(b);
        final expected =
            band == ScoreBand.of(100) ? _scoreColor : band.onContainer(c);
        expect(ring.bandColor(c, b.toDouble()), expected, reason: 'at $b');
      }
      await tester.pumpAndSettle();
    });

    for (final (name, reduce, reveal) in [
      ('reduce motion', true, true),
      ('saved result', false, false),
    ]) {
      testWidgets('$name: no band ticks', (tester) async {
        await tester.pumpWidget(_app(
          AnimatedScoreRing(score: 95, scoreColor: _scoreColor, reveal: reveal),
          reduce: reduce,
        ));
        await tester.pumpAndSettle();
        expect(haptics, isEmpty);
      });
    }
  });

  group('score journey', () {
    test('the change is the clamped difference, null when there is none', () {
      for (var prev = -10; prev <= 110; prev += 7) {
        for (var score = 0; score <= 100; score += 9) {
          final d = AnimatedScoreRing.deltaOf(score, prev);
          final expected = score - prev.clamp(0, 100);
          expect(d, expected == 0 ? isNull : expected);
        }
      }
      expect(AnimatedScoreRing.deltaOf(50, null), isNull);
    });

    test('the label is a sign then Latin digits, minus is a true minus', () {
      for (var d = -100; d <= 100; d++) {
        if (d == 0) continue;
        final label = AnimatedScoreRing.deltaLabel(d);
        expect(label, matches(RegExp(r'^[+−][0-9]+$')));
        expect(label.substring(1), '${d.abs()}');
        expect(label.startsWith('+'), d > 0);
      }
    });

    for (final direction in TextDirection.values) {
      for (final (prev, score) in [(40, 72), (88, 61), (59, 60), (0, 100)]) {
        testWidgets(
            '${direction.name} $prev → $score: ghost arc at the old score, '
            'chip after landing', (tester) async {
          await tester.pumpWidget(_app(
            AnimatedScoreRing(
              score: score,
              scoreColor: _scoreColor,
              previousScore: prev,
              reveal: true,
            ),
            direction: direction,
          ));
          // While climbing, no chip yet.
          await tester.pump(const Duration(milliseconds: 300));
          expect(_ring(tester).land, 0);
          expect(find.byKey(AnimatedScoreRing.deltaKey), findsNothing);
          expect(_painter(tester).ghost, prev / 100);
          await tester.pumpAndSettle();
          final chip = find.byKey(AnimatedScoreRing.deltaKey);
          expect(chip, findsOneWidget);
          final text = tester.widget<Text>(
              find.descendant(of: chip, matching: find.byType(Text)));
          expect(text.data, AnimatedScoreRing.deltaLabel(score - prev));
          expect(
            Directionality.of(tester.element(
                find.descendant(of: chip, matching: find.byType(Text)))),
            TextDirection.ltr,
            reason: 'the sign stays before the digits in Arabic too',
          );
          expect(_painter(tester).ghost, prev / 100);
          expect(_painter(tester).ghostColor.a, greaterThan(0));
        });
      }
    }

    testWidgets('reduce motion: ghost and chip are shown at once',
        (tester) async {
      await tester.pumpWidget(_app(
        const AnimatedScoreRing(
          score: 81,
          scoreColor: _scoreColor,
          previousScore: 66,
          reveal: true,
        ),
        reduce: true,
      ));
      expect(find.byKey(AnimatedScoreRing.deltaKey), findsOneWidget);
      expect(_painter(tester).ghost, .66);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('same score or no previous scan: no ghost, no chip',
        (tester) async {
      for (final prev in [null, 70]) {
        await tester.pumpWidget(_app(AnimatedScoreRing(
          key: ValueKey(prev),
          score: 70,
          scoreColor: _scoreColor,
          previousScore: prev,
          reveal: true,
        )));
        await tester.pumpAndSettle();
        expect(find.byKey(AnimatedScoreRing.deltaKey), findsNothing);
        expect(_painter(tester).ghost, 0);
      }
    });
  });

  group('last scan scores', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('needs a job title and a CV to name', () {
      expect(LastScanScores.keyFor(jobTitle: 'Nurse'), isNull);
      expect(LastScanScores.keyFor(savedCvId: 4, jobTitle: '  '), isNull);
      expect(LastScanScores.keyFor(fileName: ' ', jobTitle: 'Nurse'), isNull);
    });

    test('the same CV and job match despite case and spacing', () {
      for (final (a, b) in [
        ('Data  Analyst', ' data analyst '),
        ('محاسب   أول', 'محاسب أول'),
      ]) {
        expect(
          LastScanScores.keyFor(fileName: 'CV.pdf', jobTitle: a),
          LastScanScores.keyFor(fileName: 'cv.PDF ', jobTitle: b),
        );
        expect(
          LastScanScores.keyFor(savedCvId: 9, jobTitle: a),
          LastScanScores.keyFor(savedCvId: 9, jobTitle: b),
        );
      }
    });

    test('different CVs, jobs or sources never match', () {
      final keys = {
        LastScanScores.keyFor(savedCvId: 1, jobTitle: 'Nurse'),
        LastScanScores.keyFor(savedCvId: 2, jobTitle: 'Nurse'),
        LastScanScores.keyFor(savedCvId: 1, jobTitle: 'Doctor'),
        LastScanScores.keyFor(fileName: '1', jobTitle: 'Nurse'),
        LastScanScores.keyFor(fileName: 'a.pdf', jobTitle: 'Nurse'),
      };
      expect(keys, hasLength(5));
    });

    test('read returns the score written last, for any sequence', () async {
      final key = LastScanScores.keyFor(savedCvId: 3, jobTitle: 'Nurse')!;
      expect(await LastScanScores.read(key), isNull);
      for (final score in [55, 72, 72, 40, 100, 0]) {
        await LastScanScores.write(key, score);
        expect(await LastScanScores.read(key), score);
      }
    });

    test('keeps at most maxEntries, dropping the oldest', () async {
      const n = LastScanScores.maxEntries + 7;
      for (var i = 0; i < n; i++) {
        await LastScanScores.write('k$i', i);
      }
      // The oldest were dropped; the newest remain.
      for (var i = 0; i < n; i++) {
        expect(await LastScanScores.read('k$i'), i < 7 ? isNull : i);
      }
    });

    test('is account data, removed on sign-out', () {
      expect(
        UserScopedKeys.isUserScopedPreference(UserScopedKeys.lastScanScoresKey),
        isTrue,
      );
    });

    test('corrupt storage is ignored, not thrown', () async {
      SharedPreferences.setMockInitialValues(
          {UserScopedKeys.lastScanScoresKey: '{not json'});
      expect(await LastScanScores.read('k'), isNull);
      await LastScanScores.write('k', 5);
      expect(await LastScanScores.read('k'), 5);
    });
  });
}
