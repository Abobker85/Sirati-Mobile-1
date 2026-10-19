import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/job_match/application/job_match_controller.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_suggestion_card.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';
import 'job_match_test_support.dart';

Future<void> open(
  WidgetTester tester,
  FakeJobMatchApi api, {
  String language = 'en',
  ThemeData? theme,
  List<Duration>? schedule,
}) async {
  useTallView(tester);
  await pumpJobMatch(
    tester,
    api: api,
    auth: FakeAuth(subscription()),
    language: language,
    theme: theme,
    schedule: schedule,
  );
  await enterJob(tester);
  await tester.tap(find.byKey(JobMatchScreen.submitKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

ProviderContainer container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).last));

void main() {
  for (final language in ['en', 'ar']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$language/$dark: confirmation gates selection and apply payload',
        (tester) async {
          final random = Random(910);
          final keys = List.generate(
            5,
            (i) => 'fact-$i-${random.nextInt(100000)}',
          );
          final api = FakeJobMatchApi()
            ..createResponses.add(
              matchJson(
                suggestions: [
                  for (final key in keys)
                    suggestionJson(key, needsUserFact: true),
                  suggestionJson('automatic'),
                  suggestionJson('empty', after: ' ', needsUserFact: true),
                  suggestionJson('applied', needsUserFact: true),
                ],
                applied: ['applied'],
              ),
            );
          await open(
            tester,
            api,
            language: language,
            theme: dark
                ? AppTheme.darkFor(arabic: language == 'ar')
                : AppTheme.lightFor(arabic: language == 'ar'),
          );
          final l = l10n(tester);
          final control = container(
            tester,
          ).read(jobMatchControllerProvider.notifier);
          final expectedDirection =
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr;
          expect(
            Directionality.of(
              tester.element(find.text(l.jm4ConfirmFact).first),
            ),
            expectedDirection,
          );
          expect(find.text(l.jm4HonestyHint), findsNWidgets(keys.length + 2));
          expectAllTextAa('unconfirmed $language/$dark');
          for (final key in keys) {
            expect(
              tester
                  .widget<Checkbox>(
                    find.byKey(JobMatchSuggestionCard.checkboxKey(key)),
                  )
                  .onChanged,
              isNull,
            );
            control.toggle(key);
            expect(
              container(tester).read(jobMatchControllerProvider).selected,
              isEmpty,
            );
            await tapVisible(
              tester,
              find.byKey(JobMatchSuggestionCard.confirmationKey(key)),
            );
            // Confirmation alone must never select an edit.
            expect(
              container(tester).read(jobMatchControllerProvider).selected,
              isEmpty,
            );
            await tapVisible(
              tester,
              find.byKey(JobMatchSuggestionCard.checkboxKey(key)),
            );
            expect(find.text(l.jobMatchApplySelected(1)), findsOneWidget);
            await tapVisible(
              tester,
              find.byKey(JobMatchSuggestionCard.confirmationKey(key)),
            );
            expect(
              container(tester).read(jobMatchControllerProvider).selected,
              isEmpty,
            );
            expect(
              tester
                  .widget<Checkbox>(
                    find.byKey(JobMatchSuggestionCard.checkboxKey(key)),
                  )
                  .value,
              isFalse,
            );
          }
          // An unknown, empty or already-applied fact cannot be confirmed.
          for (final key in ['unknown', 'empty', 'applied']) {
            control.confirmFact(key, true);
            control.toggle(key);
          }
          expect(
            container(tester).read(jobMatchControllerProvider).selected,
            isEmpty,
          );
          for (final key in keys.reversed) {
            await tapVisible(
              tester,
              find.byKey(JobMatchSuggestionCard.confirmationKey(key)),
            );
          }
          // A confirmed but unselected key must not be sent.
          for (final key in keys.skip(1).toList().reversed) {
            await tapVisible(
              tester,
              find.byKey(JobMatchSuggestionCard.checkboxKey(key)),
            );
          }
          await tapVisible(
            tester,
            find.byKey(JobMatchSuggestionCard.checkboxKey('automatic')),
          );
          expect(
            find.text(l.jobMatchApplySelected(keys.length)),
            findsOneWidget,
          );
          expectAllTextAa('confirmed $language/$dark');
          final pending = Completer<
              ({GeneratedCv generatedCv, Map<String, dynamic> jobMatch})>();
          api.applyOverride = () => pending.future;
          await tapVisible(tester, find.byKey(const ValueKey('jm-apply')));
          final button = tester.widget<ElevatedButton>(
            find.byKey(const ValueKey('jm-apply')),
          );
          expect(button.onPressed, isNull);
          expect(
            find.byKey(const ValueKey('jm-apply-progress')),
            findsOneWidget,
          );
          expectAllTextAa('applying $language/$dark');
          expect(api.applyCalls.single, [...keys.skip(1), 'automatic']);
          expect(api.confirmedFactCalls.single, keys.skip(1).toList());
          control.confirmFact(keys.last, false);
          expect(
            container(
              tester,
            ).read(jobMatchControllerProvider).confirmedFactKeys,
            contains(keys.last),
          );
          // Completing after disposal cannot update state or navigate.
          await tester.pumpWidget(const SizedBox());
          pending.complete((generatedCv: savedCv(88), jobMatch: matchJson()));
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'default polling uses increasing capped waits and an overall deadline',
    (tester) async {
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(aiStatus: 'processing'))
        ..fetchResponses.add(matchJson(aiStatus: 'processing'));
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        schedule: null,
      );
      useTallView(tester);
      await enterJob(tester);
      await tester.tap(find.byKey(JobMatchScreen.submitKey));
      await tester.pump();
      expect(api.fetchCalls, isEmpty);
      var elapsed = 0;
      for (var poll = 0; poll < 13; poll++) {
        final seconds = min(poll + 1, 5);
        await tester.pump(Duration(milliseconds: seconds * 1000 - 1));
        expect(api.fetchCalls, hasLength(poll));
        await tester.pump(const Duration(milliseconds: 1));
        expect(api.fetchCalls, hasLength(poll + 1));
        elapsed += seconds;
      }
      expect(elapsed, 55);
      await tester.pump(const Duration(seconds: 5));
      expect(api.fetchCalls, hasLength(13));
      // At the deadline the pending tick is cancelled, so the final poll is skipped.
      expect(find.text(l10n(tester).jobMatchAiStillProcessing), findsOneWidget);
      final calls = api.fetchCalls.length;
      await tester.pump(const Duration(minutes: 2));
      expect(api.fetchCalls, hasLength(calls));
    },
  );

  for (final failure in [false, true]) {
    testWidgets(
      'deadline ignores an in-flight ${failure ? 'error' : 'response'}',
      (tester) async {
        final pending = Completer<Map<String, dynamic>>();
        final api = FakeJobMatchApi()
          ..createResponses.add(matchJson(aiStatus: 'queued'))
          ..fetchOverride = (_) => pending.future;
        await open(tester, api);
        await tester.pump(const Duration(seconds: 1));
        expect(api.fetchCalls, hasLength(1));
        await tester.pump(const Duration(minutes: 1));
        expect(
          find.text(l10n(tester).jobMatchAiStillProcessing),
          findsOneWidget,
        );
        if (failure) {
          pending.completeError(StateError('late'));
        } else {
          pending.complete(matchJson(score: 13));
        }
        await tester.pump();
        expect(find.text('72'), findsOneWidget);
        expect(find.text('13'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final inFlight in [false, true]) {
    testWidgets(
      'dispose cancels timers and ignores refreshes (in flight: $inFlight)',
      (tester) async {
        final pending = Completer<Map<String, dynamic>>();
        final api = FakeJobMatchApi()
          ..createResponses.add(matchJson(aiStatus: 'queued'))
          ..fetchOverride = (_) => pending.future;
        await open(tester, api);
        if (inFlight) await tester.pump(const Duration(seconds: 1));
        final count = api.fetchCalls.length;
        expect(count, inFlight ? 1 : 0);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        if (inFlight) pending.complete(matchJson());
        await tester.pump(const Duration(minutes: 2));
        expect(api.fetchCalls, hasLength(count));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final language in ['ar', 'en']) {
    testWidgets(
      '$language: pending score and keywords are stable as skeleton becomes advice',
      (tester) async {
        final api = FakeJobMatchApi()
          ..createResponses.add(matchJson(aiStatus: 'queued'))
          ..fetchResponses.add(matchJson(suggestions: []));
        await open(tester, api, language: language);
        expect(find.text('72'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('jm-keywords-matched')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('jm-keywords-missing')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('jm-suggestions-skeleton')),
          findsOneWidget,
        );
        final matched = tester.getRect(
          find.byKey(const ValueKey('jm-keywords-matched')),
        );
        final regionRect =
            tester.getRect(find.byKey(const ValueKey('jm-suggestions-region')));
        final region = tester.getSize(
          find.byKey(const ValueKey('jm-suggestions-region')),
        );
        expect(
          tester
              .widget<ElevatedButton>(find.byKey(const ValueKey('jm-apply')))
              .onPressed,
          isNull,
        );
        expectAllTextAa('pending $language');
        await tester.pump(const Duration(seconds: 1));
        expect(
          find.byKey(const ValueKey('jm-suggestions-skeleton')),
          findsNothing,
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('jm-keywords-matched'))),
          matched,
        );
        expect(
          tester.getSize(find.byKey(const ValueKey('jm-suggestions-region'))),
          region,
        );
        expect(
            tester.getRect(find.byKey(const ValueKey('jm-suggestions-region'))),
            regionRect);
        expect(find.text(l10n(tester).jobMatchNoSuggestions), findsOneWidget);
      },
    );
  }
}
