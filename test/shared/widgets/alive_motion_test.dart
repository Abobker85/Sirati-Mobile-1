import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ambient_motion.dart';
import 'package:sirati/shared/widgets/compass_needle.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/fresh_glint.dart';
import 'package:sirati/shared/widgets/greeting_reveal.dart';
import 'package:sirati/shared/widgets/offline_view.dart';
import 'package:sirati/shared/widgets/rolling_number.dart';
import 'package:sirati/shared/widgets/word_write_in.dart';

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

/// Texts of mixed scripts, spacing and length.
const _texts = [
  '',
  'one',
  'Led a team of five engineers',
  '  leading and trailing spaces  ',
  'قدت فريقاً من خمسة مهندسين لتطوير نظام الرواتب',
  'أدرت مشاريع Flutter و Laravel لعملاء في الرياض',
  'line one\nline two\n\nline   four',
];

void main() {
  group('RollingNumber', () {
    test('caps the label', () {
      for (var v = 0; v < 40; v++) {
        for (final cap in [null, 9, 20]) {
          final label = RollingNumber.label(v, cap: cap);
          expect(label, cap != null && v > cap ? '$cap+' : '$v');
        }
      }
    });

    for (final direction in TextDirection.values) {
      testWidgets('${direction.name}: digits stay in order', (tester) async {
        for (final v in [7, 12, 305, 9081]) {
          await tester.pumpWidget(_app(
            RollingNumber(key: ValueKey(v), value: v),
            direction: direction,
          ));
          final text = find.text('$v');
          expect(text, findsOneWidget);
          expect(Directionality.of(tester.element(text)), TextDirection.ltr);
        }
      });
    }

    for (final (from, to) in [(3, 4), (8, 2), (9, 15)]) {
      testWidgets('$from → $to rolls from the right side, then settles',
          (tester) async {
        Widget at(int v) => _app(RollingNumber(value: v, cap: 9));
        await tester.pumpWidget(at(from));
        final restY = tester.getTopLeft(find.byType(Text)).dy;
        await tester.pumpWidget(at(to));
        await tester.pump(const Duration(milliseconds: 60));
        final incoming = find.text(RollingNumber.label(to, cap: 9));
        final y = tester.getTopLeft(incoming).dy;
        // Up: the new number comes from below; down: from above.
        if (to > from) {
          expect(y, greaterThan(restY));
        } else {
          expect(y, lessThan(restY));
        }
        await tester.pumpAndSettle();
        expect(find.byType(Text), findsOneWidget);
        expect(tester.getTopLeft(incoming).dy, restY);
      });
    }

    testWidgets('reduced motion: no roll', (tester) async {
      await tester
          .pumpWidget(_app(const RollingNumber(value: 1), reduce: true));
      await tester
          .pumpWidget(_app(const RollingNumber(value: 2), reduce: true));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('time-of-day greeting', () {
    test('every hour has exactly one part, in day order', () {
      final parts = [
        for (var h = 0; h < 24; h++) AppLocale.dayPart(DateTime(2026, 1, 1, h)),
      ];
      expect(parts.sublist(4, 12).toSet(), {DayPart.morning});
      expect(parts.sublist(12, 17).toSet(), {DayPart.afternoon});
      expect({...parts.sublist(17), ...parts.sublist(0, 4)}, {DayPart.evening});
    });

    for (final direction in TextDirection.values) {
      testWidgets('${direction.name}: names the user at every hour',
          (tester) async {
        late BuildContext ctx;
        await tester.pumpWidget(_app(
          Builder(builder: (c) {
            ctx = c;
            return const SizedBox();
          }),
          direction: direction,
        ));
        final l = AppLocalizations.of(ctx);
        for (final name in ['Sara', 'سارة', 'Ayşe Nur']) {
          for (var h = 0; h < 24; h++) {
            final text = AppLocale.timedGreeting(name, ctx,
                now: DateTime(2026, 1, 1, h));
            expect(text, contains(name), reason: '$name at $h');
          }
        }
        expect(AppLocale.timedGreeting('  ', ctx), l.coreGreetingWelcome);
      });
    }

    testWidgets('plays once per session, then shows at once', (tester) async {
      GreetingReveal.resetSession();
      Widget greet() => _app(const GreetingReveal(
          text: 'Good morning, Sara', dayPart: DayPart.morning));
      await tester.pumpWidget(greet());
      final first =
          tester.state<GreetingRevealState>(find.byType(GreetingReveal));
      expect(first.wipe, 0);
      await tester.pumpAndSettle();
      expect(first.wipe, 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(greet());
      expect(
        tester.state<GreetingRevealState>(find.byType(GreetingReveal)).wipe,
        1,
        reason: 'the second showing in a session does not replay',
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduced motion: shown at once; evening shows the moon',
        (tester) async {
      GreetingReveal.resetSession();
      await tester.pumpWidget(_app(
        const GreetingReveal(
            text: 'مساء الخير، سارة', dayPart: DayPart.evening),
        reduce: true,
        direction: TextDirection.rtl,
      ));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('مساء الخير، سارة'), findsOneWidget);
      final glyph = tester.widget<Icon>(find.byKey(GreetingReveal.glyphKey));
      expect(glyph.icon, Icons.nightlight_round);
    });
  });

  group('valid tick', () {
    Future<void> blur(WidgetTester tester) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
    }

    Widget field(TextEditingController controller, {bool reduce = false}) =>
        _app(
          SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextFormField(
                  controller: controller,
                  tickWhenValid: true,
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'too short' : null,
                ),
              ],
            ),
          ),
          reduce: reduce,
        );

    testWidgets('draws once when the field first becomes valid, then leaves',
        (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(field(controller));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'x');
      await blur(tester);
      expect(find.byType(ValidTick), findsNothing, reason: 'invalid');

      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Riyadh');
      await tester.pump();
      expect(find.byType(ValidTick), findsOneWidget);
      // It leaves by itself, soon after its own duration.
      for (var i = 0;
          i < 30 && find.byType(ValidTick).evaluate().isNotEmpty;
          i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(ValidTick), findsNothing);

      // Invalid, then valid again: no second tick.
      await tester.enterText(find.byType(TextField), 'R');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Riyadh!');
      await tester.pump();
      expect(find.byType(ValidTick), findsNothing);
    });

    testWidgets('never for an empty field', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(_app(AppTextFormField(
        controller: controller,
        tickWhenValid: true,
      )));
      await tester.tap(find.byType(TextField));
      await blur(tester);
      expect(find.byType(ValidTick), findsNothing);
    });

    testWidgets('reduced motion: no tick is left behind', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(field(controller, reduce: true));
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Jeddah');
      await blur(tester);
      await tester.pump();
      expect(find.byType(ValidTick), findsNothing);
    });
  });

  group('404 compass', () {
    test('ends exactly at rest; swings shrink; no jumps', () {
      expect(CompassNeedle.angleAt(1), CompassNeedle.restAngle);
      expect(CompassNeedle.angleAt(2), CompassNeedle.restAngle);
      var prev = CompassNeedle.angleAt(0);
      var lastPeak = double.infinity;
      var lastDelta = 0.0;
      for (var i = 1; i <= 1000; i++) {
        final a = CompassNeedle.angleAt(i / 1000);
        expect((a - prev).abs(), lessThan(.1), reason: 'smooth at ${i / 1000}');
        final delta = a - prev;
        // At each turning point the swing is smaller than the one before.
        if (delta.sign != lastDelta.sign && lastDelta != 0) {
          final peak = (prev - CompassNeedle.restAngle).abs();
          expect(peak, lessThanOrEqualTo(lastPeak + 1e-9));
          lastPeak = peak;
        }
        lastDelta = delta;
        prev = a;
      }
    });

    testWidgets('settles pointing down; reduced motion starts there',
        (tester) async {
      await tester.pumpWidget(_app(const CompassNeedle()));
      final s = tester.state<CompassNeedleState>(find.byType(CompassNeedle));
      expect(s.angle, isNot(CompassNeedle.restAngle));
      await tester.pumpAndSettle();
      expect(s.angle, CompassNeedle.restAngle);

      await tester.pumpWidget(
          _app(const CompassNeedle(key: ValueKey(2)), reduce: true));
      expect(
        tester.state<CompassNeedleState>(find.byType(CompassNeedle)).angle,
        math.pi,
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('offline ping', () {
    testWidgets('pings once per attempt, never by itself', (tester) async {
      Widget at(int n, {bool reduce = false}) => _app(
            OfflinePing(
                trigger: n, child: const SizedBox(width: 56, height: 56)),
            reduce: reduce,
          );
      await tester.pumpWidget(at(0));
      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(OfflinePing.ringKey), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(at(1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(OfflinePing.ringKey), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(OfflinePing.ringKey), findsNothing);

      await tester.pumpWidget(at(2, reduce: true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(OfflinePing.ringKey), findsNothing);
    });
  });

  group('fresh glint', () {
    setUp(() {
      FreshSeen.reset();
      AmbientConductor.reset();
      AmbientMotion.enabled.value = true;
    });
    tearDown(() {
      AmbientMotion.enabled.value = false;
      AmbientConductor.reset();
      FreshSeen.reset();
    });

    Widget card(String id) => _app(FreshGlint(
          key: ValueKey(id),
          id: id,
          child: const SizedBox(width: 200, height: 80),
        ));

    Future<bool> glintsFor(WidgetTester tester, String id) async {
      await tester.pumpWidget(card(id));
      await tester.runAsync(FreshSeen.ensureLoaded);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final glowing =
          tester.state<FreshGlintState>(find.byType(FreshGlint)).glowing;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(AmbientConductor.gap);
      return glowing;
    }

    testWidgets('the first session only records; later, new items glint once',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      expect(await glintsFor(tester, 'job:1'), isFalse,
          reason: 'nothing is new on a first visit');

      // A new session: job:1 was seen, job:2 is new.
      FreshSeen.reset();
      expect(await glintsFor(tester, 'job:1'), isFalse);
      expect(await glintsFor(tester, 'job:2'), isTrue);
      await tester.pump(FreshGlint.duration);
      expect(await glintsFor(tester, 'job:2'), isFalse,
          reason: 'once seen, never again');
    });

    testWidgets('with decorative motion off it stays new for later',
        (tester) async {
      SharedPreferences.setMockInitialValues({'fresh_seen.ids': <String>[]});
      AmbientMotion.enabled.value = false;
      expect(await glintsFor(tester, 'job:9'), isFalse);
      AmbientMotion.enabled.value = true;
      expect(await glintsFor(tester, 'job:9'), isTrue);
    });
  });

  group('word write-in', () {
    test('frames grow by whole words and end on the exact text', () {
      final word = RegExp(r'\S');
      for (final text in _texts) {
        final frames = WordWriteIn.framesFor(text);
        expect(frames.last, text);
        final maxFrames = WordWriteIn.maxDuration.inMilliseconds ~/
                WordWriteIn.step.inMilliseconds +
            1;
        expect(frames.length, lessThanOrEqualTo(maxFrames));
        var prev = '';
        for (final f in frames.take(frames.length - 1)) {
          expect(text.startsWith(f), isTrue);
          expect(f.length, greaterThan(prev.length));
          // Never inside a word: the next character is not part of it.
          expect(word.hasMatch(text[f.length]), isFalse, reason: '"$f"');
          expect(word.hasMatch(f[f.length - 1]), isTrue);
          prev = f;
        }
      }
    });

    testWidgets('writes every frame, then stops', (tester) async {
      for (final text in _texts) {
        final written = <String>[];
        var field = '';
        final w = WordWriteIn.start(
          text: text,
          animate: true,
          current: () => field,
          write: (s) => written.add(field = s),
        );
        await tester.pump(WordWriteIn.maxDuration + WordWriteIn.step * 2);
        expect(written, WordWriteIn.framesFor(text));
        expect(w.active, isFalse);
      }
    });

    testWidgets('without animation it writes the whole text at once',
        (tester) async {
      final written = <String>[];
      WordWriteIn.start(
        text: _texts[4],
        animate: false,
        current: () => written.last,
        write: written.add,
      );
      expect(written, [_texts[4]]);
    });

    testWidgets('someone else changing the field stops it', (tester) async {
      var field = '';
      final w = WordWriteIn.start(
        text: _texts[2],
        animate: true,
        current: () => field,
        write: (s) => field = s,
      );
      field = 'typed by the user';
      await tester.pump(WordWriteIn.step);
      expect(w.active, isFalse);
      expect(field, 'typed by the user');
    });
  });
}
