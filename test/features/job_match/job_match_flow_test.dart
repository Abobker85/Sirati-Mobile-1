import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs_screen.dart';
import 'package:sirati/features/job_match/domain/job_match_input.dart';
import 'package:sirati/features/job_match/presentation/job_match_result_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_suggestion_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/routing/app_router.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/services/mobile_content_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import 'job_match_test_support.dart';

ApiException _status(int code, {Map<String, List<String>> errors = const {}}) =>
    ApiException.fromStatus(code, message: 'HTTP $code', errors: errors);

void main() {
  setUp(() => AppLocale.languageCode.value = 'en');

  group('entitlement gate (server state only, fails closed)', () {
    final cases =
        <(String, Map<String, dynamic>?, String Function(AppLocalizations))>[
      (
        'free user',
        subscription(subscribed: false),
        (l) => l.jobMatchPaywallTitle
      ),
      (
        'subscribed, quota used up',
        subscription(canJobMatch: false, limit: 3, used: 3),
        (l) => l.jobMatchQuotaTitle,
      ),
      (
        'subscribed, not granted for another reason',
        subscription(canJobMatch: false, limit: 3, used: 0),
        (l) => l.jobMatchUnavailableTitle,
      ),
      ('no subscription data', null, (l) => l.jobMatchUnavailableTitle),
      (
        'server reports an unconfigured quota',
        subscription(canJobMatch: false, limit: 0, used: 0),
        (l) => l.jobMatchUnavailableTitle,
      ),
      (
        'malformed grant',
        {...subscription(), 'can_job_match': 'true'},
        (l) => l.jobMatchUnavailableTitle,
      ),
    ];

    for (final (label, state, title) in cases) {
      testWidgets('$label: no form, no request', (tester) async {
        useTallView(tester);
        final api = FakeJobMatchApi();
        await pumpJobMatch(tester, api: api, auth: FakeAuth(state));

        expect(find.text(title(l10n(tester))), findsOneWidget);
        expect(find.byKey(JobMatchScreen.descriptionFieldKey), findsNothing);
        expect(find.byKey(JobMatchScreen.submitKey), findsNothing);
        expect(api.createCalls, isEmpty);
      });
    }

    testWidgets('paywall shows the trial and re-checks the server on refresh',
        (tester) async {
      useTallView(tester);
      final auth = FakeAuth(subscription(subscribed: false, trialDays: 7));
      await pumpJobMatch(tester, api: FakeJobMatchApi(), auth: auth);
      final l = l10n(tester);
      expect(find.text(l.jobMatchPaywallTrial(7)), findsOneWidget);
      final before = auth.calls;

      auth.subscriptionState = subscription(limit: 5, used: 1);
      await tapVisible(tester, find.byKey(const ValueKey('jm-gate-action')));
      await settle(tester);

      expect(auth.calls, before + 1);
      expect(find.byKey(JobMatchScreen.descriptionFieldKey), findsOneWidget);
      expect(find.text(l.jobMatchQuotaRemaining(4)), findsOneWidget);
    });

    testWidgets('entitlement load failure offers retry, never the form',
        (tester) async {
      useTallView(tester);
      final auth = FakeAuth(subscription())
        ..error = const ApiException.network('offline');
      await pumpJobMatch(tester, api: FakeJobMatchApi(), auth: auth);
      final l = l10n(tester);
      expect(find.text(l.jobMatchEntitlementLoadFailed), findsOneWidget);
      expect(find.byKey(JobMatchScreen.descriptionFieldKey), findsNothing);

      auth.error = null;
      await tapVisible(tester, find.byKey(const ValueKey('jm-gate-action')));
      await settle(tester);
      expect(find.byKey(JobMatchScreen.descriptionFieldKey), findsOneWidget);
    });

    testWidgets('a 402 on create re-reads entitlement and shows the paywall',
        (tester) async {
      useTallView(tester);
      final auth = FakeAuth(subscription());
      final api = FakeJobMatchApi()..createResponses.add(_status(402));
      await pumpJobMatch(tester, api: api, auth: auth);
      await enterJob(tester);

      auth.subscriptionState = subscription(subscribed: false);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      expect(api.createCalls, hasLength(1));
      expect(find.text(l10n(tester).jobMatchPaywallTitle), findsOneWidget);
    });

    testWidgets('the counter reflects a refreshed quota after create',
        (tester) async {
      useTallView(tester);
      final auth = FakeAuth(subscription(limit: 5, used: 1));
      final api = FakeJobMatchApi()..createResponses.add(matchJson());
      await pumpJobMatch(tester, api: api, auth: auth);
      final l = l10n(tester);

      expect(find.text(l.jobMatchQuotaRemaining(4)), findsOneWidget);

      await enterJob(tester);
      // Simulate backend updating the user's quota used when the match is created.
      auth.subscriptionState = subscription(limit: 5, used: 2);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      expect(find.byType(JobMatchResultScreen), findsOneWidget);

      // Return to the entry screen; the quota counter reflects the decrement.
      await tester.pageBack();
      await settle(tester);

      expect(find.byType(JobMatchScreen), findsOneWidget);
      expect(find.text(l.jobMatchQuotaRemaining(3)), findsOneWidget);
      expect(find.text(l.jobMatchQuotaRemaining(4)), findsNothing);
    });
  });

  group('input validation happens before any request or generator push', () {
    // Lengths straddling the limit, built from mixed scripts and surrogate
    // pairs so UTF-16 length and visible characters differ.
    // Starts and ends with a non-space so trimming keeps the exact length.
    String descriptionOf(int units) {
      const pieces = ['SQL ', 'تحليل ', '📊', 'C++ ', 'بيانات\n'];
      final buffer = StringBuffer('x');
      var i = 0;
      while (buffer.length < units - 1) {
        final next = pieces[i++ % pieces.length];
        buffer.write(buffer.length + next.length <= units - 1 ? next : 'y');
      }
      buffer.write('z');
      return buffer.toString();
    }

    for (final units in [
      JobMatchInput.descriptionMax - 1,
      JobMatchInput.descriptionMax,
      JobMatchInput.descriptionMax + 1,
      JobMatchInput.descriptionMax + 2,
      JobMatchInput.descriptionMax * 2,
    ]) {
      testWidgets('description of $units UTF-16 units', (tester) async {
        useTallView(tester);
        final description = descriptionOf(units);
        expect(description.length, units);
        final allowed = units <= JobMatchInput.descriptionMax;
        final api = FakeJobMatchApi();
        if (allowed) api.createResponses.add(matchJson());
        final routes = FakeGeneratorRoute();
        await pumpJobMatch(
          tester,
          api: api,
          auth: FakeAuth(subscription()),
          routes: routes,
        );
        await enterJob(tester, description: description);

        await tapVisible(tester, find.byKey(JobMatchScreen.createTailoredKey));
        await settle(tester);
        if (allowed) {
          expect(routes.opened, hasLength(1));
          // Unclipped: what the generator receives is what the user typed.
          expect(routes.opened.single!.description, description);
          await tapVisible(
            tester,
            find.byKey(const ValueKey('fake-generator-done')),
          );
          await settle(tester);
        } else {
          expect(routes.opened, isEmpty);
          expect(find.byKey(const ValueKey('jm-input-error')), findsOneWidget);
        }

        await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
        await settle(tester);
        expect(api.createCalls, hasLength(allowed ? 1 : 0));
        if (allowed) {
          expect(api.createCalls.single['jd'], description);
        }
      });
    }

    testWidgets('empty description and over-long title are refused',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi();
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      final l = l10n(tester);

      await enterJob(tester, description: '   \n  ');
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      expect(find.text(l.jobMatchDescriptionRequired), findsOneWidget);

      await enterJob(tester, title: 'T' * (JobMatchInput.titleMax + 1));
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      expect(
        find.text(l.jobMatchTitleTooLong(JobMatchInput.titleMax)),
        findsOneWidget,
      );
      expect(api.createCalls, isEmpty);
    });
  });

  group('choosing the CV', () {
    testWidgets('a single saved CV is used; the result screen opens',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()..createResponses.add(matchJson());
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester, title: '  Data Analyst ', description: ' JD ');
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      expect(api.createCalls.single['cv'], 1);
      expect(api.createCalls.single['jd'], 'JD');
      expect(api.createCalls.single['title'], 'Data Analyst');
      expect(find.byType(JobMatchResultScreen), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
      // Completed on create: nothing to poll.
      await tester.pump(const Duration(seconds: 2));
      expect(api.fetchCalls, isEmpty);
    });

    testWidgets('CV list failure offers retry and never submits',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..cvsError = const ApiException.network('offline');
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      final l = l10n(tester);
      expect(find.text(l.jobMatchCvsLoadFailed), findsOneWidget);
      expect(find.byKey(JobMatchScreen.submitKey), findsNothing);

      api.cvsError = null;
      await tapVisible(tester, find.text(l.jobMatchRetry));
      await settle(tester);
      expect(find.text(l.jobMatchCvsLoadFailed), findsNothing);
      expect(find.byKey(JobMatchScreen.submitKey), findsOneWidget);
    });

    testWidgets('with several CVs the user must pick one', (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..cvs = [savedCv(1), savedCv(2, title: 'محلل بيانات')]
        ..createResponses.add(matchJson(cvId: 2));
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);

      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      expect(find.text(l10n(tester).jobMatchPickCvRequired), findsOneWidget);
      expect(api.createCalls, isEmpty);

      await tapVisible(tester, find.byKey(JobMatchScreen.cvOptionKey(2)));
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      expect(api.createCalls.single['cv'], 2);
    });

    testWidgets('no CV: the generator hands the new CV back and it is matched',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..cvs = []
        ..createResponses.add(matchJson(cvId: 9));
      final routes = FakeGeneratorRoute()..result = savedCv(9);
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        routes: routes,
      );
      expect(find.text(l10n(tester).jobMatchNoCvTitle), findsOneWidget);
      expect(find.byKey(JobMatchScreen.submitKey), findsNothing);
      await enterJob(tester, title: 'Analyst', description: 'Need SQL');

      await tapVisible(tester, find.byKey(JobMatchScreen.createTailoredKey));
      await settle(tester);
      final target = routes.opened.single!;
      expect(target.handBackResult, isTrue);
      expect(target.title, 'Analyst');
      expect(target.description, 'Need SQL');

      api.cvs = [savedCv(9)];
      await tapVisible(
          tester, find.byKey(const ValueKey('fake-generator-done')));
      await settle(tester, frames: 20);

      expect(api.createCalls.single['cv'], 9);
      expect(find.byType(JobMatchResultScreen), findsOneWidget);
    });

    testWidgets('a handed-back CV still being written is selected, not matched',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()..cvs = [];
      final routes = FakeGeneratorRoute()
        ..result = savedCv(9, aiStatus: 'processing');
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        routes: routes,
      );
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.createTailoredKey));
      await settle(tester);
      api.cvs = [savedCv(9, aiStatus: 'processing'), savedCv(3)];
      await tapVisible(
          tester, find.byKey(const ValueKey('fake-generator-done')));
      await settle(tester, frames: 20);

      expect(api.createCalls, isEmpty);
      expect(find.text(l10n(tester).jobMatchCvStillPreparing), findsOneWidget);

      api.createResponses.add(matchJson(cvId: 9));
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      expect(api.createCalls.single['cv'], 9);
    });

    testWidgets('leaving the generator without a CV changes nothing',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()..cvs = [];
      final routes = FakeGeneratorRoute();
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        routes: routes,
      );
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.createTailoredKey));
      await settle(tester);
      await tapVisible(
          tester, find.byKey(const ValueKey('fake-generator-done')));
      await settle(tester);
      expect(api.createCalls, isEmpty);
      expect(find.text(l10n(tester).jobMatchNoCvTitle), findsOneWidget);
    });
  });

  group('waiting for AI advice', () {
    for (final failure in [
      const ApiException.network('offline'),
      _status(500),
    ]) {
      testWidgets(
          'a failed replacement leaves the old match resumable '
          '(${failure.type})', (tester) async {
        useTallView(tester);
        final api = FakeJobMatchApi()
          ..createResponses.addAll([
            matchJson(aiStatus: 'processing'),
            failure,
          ])
          ..fetchResponses.add(matchJson());
        await pumpJobMatch(
          tester,
          api: api,
          auth: FakeAuth(subscription()),
          schedule: const [Duration(minutes: 1)],
        );
        await enterJob(tester);
        await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
        await settle(tester);
        await tester.pageBack();
        await settle(tester);
        await enterJob(tester, description: 'Another job requiring C++');
        await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
        await settle(tester);
        await tapVisible(tester, find.byKey(const ValueKey('jm-resume')));
        await settle(tester);

        final l = l10n(tester);
        expect(find.text(l.jobMatchAiStillProcessing), findsOneWidget);
        await tapVisible(tester, find.text(l.jobMatchCheckAgain));
        await settle(tester);
        expect(api.fetchCalls, [7]);
        expect(find.text(l.jobMatchSuggestionsTitle), findsOneWidget);
      });
    }

    testWidgets(
        'returning to a result preserves selection without creating '
        'another match', (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()..createResponses.add(matchJson());
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      await tapVisible(
        tester,
        find.byKey(JobMatchSuggestionCard.checkboxKey('s1')),
      );
      await tester.pageBack();
      await settle(tester);
      await tapVisible(tester, find.byKey(const ValueKey('jm-resume')));
      await settle(tester);
      final selected = tester.widget<Checkbox>(
        find.byKey(JobMatchSuggestionCard.checkboxKey('s1')),
      );
      expect(selected.value, isTrue);
      expect(api.createCalls, hasLength(1));
    });

    for (final fails in [false, true]) {
      testWidgets(
          'an old refresh ${fails ? 'failure' : 'result'} cannot '
          'replace a newer match', (tester) async {
        useTallView(tester);
        final refresh = Completer<Map<String, dynamic>>();
        final api = FakeJobMatchApi()
          ..createResponses.addAll([
            matchJson(id: 12, aiStatus: 'processing'),
            matchJson(id: 28, score: 91),
          ])
          ..fetchOverride = (_) => refresh.future;
        await pumpJobMatch(
          tester,
          api: api,
          auth: FakeAuth(subscription()),
        );
        await enterJob(tester);
        await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
        await settle(tester);
        expect(api.fetchCalls, [12]);
        await tester.pageBack();
        await settle(tester);
        await enterJob(tester, description: 'A different role requiring SQL');
        await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
        await settle(tester);

        if (fails) {
          refresh.completeError(const ApiException.network('offline'));
        } else {
          refresh.complete(matchJson(id: 12, score: 18));
        }
        await settle(tester);
        expect(find.text('91'), findsOneWidget);
        expect(find.text('18'), findsNothing);
        expect(find.text(l10n(tester).jobMatchAiStillProcessing), findsNothing);
        expect(api.createCalls, hasLength(2));
      });
    }

    testWidgets('sparse refreshes, then "still processing" with Check again',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(aiStatus: 'processing'))
        ..fetchResponses.add(matchJson(aiStatus: 'processing'));
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        schedule: const [
          Duration(milliseconds: 100),
          Duration(milliseconds: 100),
          Duration(milliseconds: 100),
        ],
      );
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester, frames: 4);
      final l = l10n(tester);
      expect(find.text(l.jobMatchAiPreparing), findsOneWidget);
      // The deterministic score is shown while advice is pending.
      expect(find.text('72'), findsOneWidget);

      await settle(tester, frames: 20);
      expect(api.fetchCalls, hasLength(3));
      expect(find.text(l.jobMatchAiStillProcessing), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(api.fetchCalls, hasLength(3), reason: 'no unbounded polling');

      api.fetchResponses
        ..clear()
        ..add(matchJson());
      await tapVisible(tester, find.text(l.jobMatchCheckAgain));
      await settle(tester);
      expect(api.fetchCalls, hasLength(4));
      expect(find.text(l.jobMatchAiStillProcessing), findsNothing);
      expect(find.text(l.jobMatchSuggestionsTitle), findsOneWidget);
    });

    testWidgets('a quota 429 while refreshing keeps the score and explains',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(aiStatus: 'queued', score: 58))
        ..fetchResponses.add(_status(429));
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester, frames: 20);

      final l = l10n(tester);
      expect(api.fetchCalls, hasLength(1));
      expect(find.text('58'), findsOneWidget);
      expect(find.text(l.jobMatchAiStillProcessing), findsOneWidget);
      expect(find.text(l.jobMatchErrorLimit), findsOneWidget);
    });

    testWidgets('leaving the result screen stops refreshing', (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(aiStatus: 'processing'))
        ..fetchResponses.add(matchJson(aiStatus: 'processing'));
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        schedule: const [Duration(seconds: 1), Duration(seconds: 1)],
      );
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester, frames: 4);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
      expect(api.fetchCalls, isEmpty);
    });

    testWidgets(
        'failed -> tap retry -> pending -> completed shows suggestion cards '
        'and hides retry button', (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(id: 7, aiStatus: 'failed'))
        ..retryResponses.add(matchJson(id: 7, aiStatus: 'processing'))
        ..fetchResponses.add(matchJson(id: 7, aiStatus: 'completed'));
      final auth = FakeAuth(subscription());
      await pumpJobMatch(
        tester,
        api: api,
        auth: auth,
        schedule: const [Duration(milliseconds: 100)],
      );
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      final l = l10n(tester);
      expect(find.byType(JobMatchResultScreen), findsOneWidget);
      expect(find.text(l.jobMatchAiFailed), findsOneWidget);
      expect(find.text(l.jobMatchRetrySuggestions), findsOneWidget);
      expect(find.text(l.jobMatchSuggestionsTitle), findsNothing);

      await tapVisible(tester, find.text(l.jobMatchRetrySuggestions));
      expect(api.retryCalls, [7]);

      await tester.pump();
      expect(find.text(l.jobMatchAiPreparing), findsOneWidget);
      expect(find.text(l.jobMatchRetrySuggestions), findsNothing);

      await settle(tester, frames: 10);
      expect(api.fetchCalls, [7]);
      expect(find.text(l.jobMatchAiPreparing), findsNothing);
      expect(find.text(l.jobMatchAiFailed), findsNothing);
      expect(find.text(l.jobMatchRetrySuggestions), findsNothing);
      expect(find.text(l.jobMatchSuggestionsTitle), findsOneWidget);
      expect(find.byType(JobMatchSuggestionCard), findsWidgets);
    });

    testWidgets('retry button is disabled while request is in flight',
        (tester) async {
      useTallView(tester);
      final retryCompleter = Completer<Map<String, dynamic>>();
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(id: 7, aiStatus: 'failed'))
        ..retryOverride = (_) => retryCompleter.future;
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      final l = l10n(tester);
      final retryFinder =
          find.widgetWithText(ElevatedButton, l.jobMatchRetrySuggestions);
      expect(retryFinder, findsOneWidget);
      expect(tester.widget<ElevatedButton>(retryFinder).enabled, isTrue);

      await tester.tap(retryFinder);
      await tester.pump();

      expect(api.retryCalls, [7]);
      expect(tester.widget<ElevatedButton>(retryFinder).enabled, isFalse);

      retryCompleter.complete(matchJson(id: 7, aiStatus: 'completed'));
      await settle(tester);
      expect(find.text(l.jobMatchRetrySuggestions), findsNothing);
      expect(find.text(l.jobMatchSuggestionsTitle), findsOneWidget);
    });

    testWidgets('retry error shows message and keeps the retry button',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(id: 7, aiStatus: 'failed'))
        ..retryResponses.add(_status(503));
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      final l = l10n(tester);
      expect(find.text(l.jobMatchAiFailed), findsOneWidget);
      expect(find.text(l.jobMatchRetrySuggestions), findsOneWidget);

      await tapVisible(tester, find.text(l.jobMatchRetrySuggestions));
      await settle(tester);

      expect(api.retryCalls, [7]);
      expect(find.text(l.jobMatchErrorUnavailable), findsOneWidget);
      expect(find.text(l.jobMatchAiFailed), findsOneWidget);
      expect(find.text(l.jobMatchRetrySuggestions), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, l.jobMatchRetrySuggestions),
            )
            .enabled,
        isTrue,
      );

      // Subsequent retry succeeds
      api.retryResponses
        ..clear()
        ..add(matchJson(id: 7, aiStatus: 'completed'));
      await tapVisible(tester, find.text(l.jobMatchRetrySuggestions));
      await settle(tester);
      expect(find.text(l.jobMatchSuggestionsTitle), findsOneWidget);
      expect(find.text(l.jobMatchRetrySuggestions), findsNothing);
    });

    testWidgets('retry button is hidden when initial status is completed',
        (tester) async {
      useTallView(tester);
      final api = FakeJobMatchApi()..createResponses.add(matchJson());
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);

      final l = l10n(tester);
      expect(find.byType(JobMatchResultScreen), findsOneWidget);
      expect(find.text(l.jobMatchRetrySuggestions), findsNothing);
      expect(find.text(l.jobMatchAiFailed), findsNothing);
    });
  });

  group('selecting and applying suggestions', () {
    testWidgets('a late apply cannot replace a newer match or its selection',
        (tester) async {
      useTallView(tester);
      final apply = Completer<
          ({GeneratedCv generatedCv, Map<String, dynamic> jobMatch})>();
      final api = FakeJobMatchApi()
        ..createResponses.addAll([
          matchJson(id: 12),
          matchJson(id: 28, score: 91),
        ])
        ..applyOverride = () => apply.future;
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      await tapVisible(
          tester, find.byKey(JobMatchSuggestionCard.checkboxKey('s1')));
      await tapVisible(tester, find.byKey(const ValueKey('jm-apply')));
      await settle(tester);
      expect(api.applyCalls, hasLength(1));
      await tester.pageBack();
      await settle(tester);
      await enterJob(tester, description: 'Different role requiring SQL');
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      await tapVisible(
          tester, find.byKey(JobMatchSuggestionCard.checkboxKey('s3')));

      apply.complete((
        generatedCv: savedCv(55),
        jobMatch: matchJson(id: 12, applied: ['s1'], appliedCvId: 55),
      ));
      await settle(tester);
      expect(find.text('91'), findsOneWidget);
      final box = tester.widget<Checkbox>(
        find.byKey(JobMatchSuggestionCard.checkboxKey('s3')),
      );
      expect(box.value, isTrue);
    });

    testWidgets('only explicit fact-free suggestions can be selected',
        (tester) async {
      useTallView(tester);
      const values = <Object?>[
        false,
        true,
        null,
        0,
        1,
        'false',
        'true',
        {},
        []
      ];
      final suggestions = [
        for (var i = 0; i < values.length; i++)
          {...suggestionJson('fact-$i'), 'needs_user_fact': values[i]},
        suggestionJson('missing')..remove('needs_user_fact'),
      ];
      final api = FakeJobMatchApi()
        ..createResponses.add(matchJson(suggestions: suggestions));
      await pumpJobMatch(tester, api: api, auth: FakeAuth(subscription()));
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      for (final json in suggestions) {
        final key = json['key'] as String;
        final box = tester.widget<Checkbox>(
          find.byKey(JobMatchSuggestionCard.checkboxKey(key)),
        );
        expect(box.onChanged != null, json['needs_user_fact'] == false);
      }
    });

    Future<FakeGeneratorRoute> openResult(
      WidgetTester tester,
      FakeJobMatchApi api,
    ) async {
      useTallView(tester);
      final routes = FakeGeneratorRoute();
      api.createResponses.add(matchJson());
      await pumpJobMatch(
        tester,
        api: api,
        auth: FakeAuth(subscription()),
        routes: routes,
      );
      await enterJob(tester);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      expect(find.byType(JobMatchResultScreen), findsOneWidget);
      return routes;
    }

    Checkbox box(WidgetTester tester, String key) => tester
        .widget<Checkbox>(find.byKey(JobMatchSuggestionCard.checkboxKey(key)));

    testWidgets('needs_user_fact cannot be selected; apply sends server order',
        (tester) async {
      final api = FakeJobMatchApi();
      final routes = await openResult(tester, api);
      final l = l10n(tester);

      expect(box(tester, 's2').onChanged, isNull);
      expect(find.text(l.jm4ConfirmFact), findsOneWidget);
      expect(find.text(l.jobMatchSelectToApply), findsOneWidget);
      expect(
          tester
              .widget<ElevatedButton>(find.byKey(const ValueKey('jm-apply')))
              .onPressed,
          isNull);

      await tapVisible(
          tester, find.byKey(JobMatchSuggestionCard.checkboxKey('s2')));
      expect(box(tester, 's2').value, isFalse);

      // Selected in reverse order.
      await tapVisible(
          tester, find.byKey(JobMatchSuggestionCard.checkboxKey('s3')));
      await tapVisible(
          tester, find.byKey(JobMatchSuggestionCard.checkboxKey('s1')));
      expect(find.text(l.jobMatchApplySelected(2)), findsOneWidget);

      api.applyResponses.add((
        generatedCv: savedCv(55),
        jobMatch: matchJson(applied: ['s1', 's3'], appliedCvId: 55),
      ));
      await tapVisible(tester, find.byKey(const ValueKey('jm-apply')));
      await settle(tester);

      expect(api.applyCalls.single, ['s1', 's3']);
      expect(routes.openedCvPages, [AppRoutes.cv(55)]);
    });

    testWidgets('a stale match (409) offers a new match', (tester) async {
      final api = FakeJobMatchApi();
      await openResult(tester, api);
      final l = l10n(tester);
      await tapVisible(
          tester, find.byKey(JobMatchSuggestionCard.checkboxKey('s1')));
      api.applyResponses.add(_status(409));
      await tapVisible(tester, find.byKey(const ValueKey('jm-apply')));
      await settle(tester);

      expect(find.text(l.jobMatchErrorStale), findsOneWidget);
      await tester.tap(find.text(l.jobMatchNewMatch));
      await settle(tester);
      expect(find.byType(JobMatchResultScreen), findsNothing);
      expect(find.byKey(JobMatchScreen.descriptionFieldKey), findsOneWidget);
      await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
      await settle(tester);
      expect(api.createCalls, hasLength(2));
      expect(api.createCalls[0]['key'], isNot(api.createCalls[1]['key']));
    });

    testWidgets('an invalid selection (422) keeps the user on the result',
        (tester) async {
      final api = FakeJobMatchApi();
      await openResult(tester, api);
      await tapVisible(
          tester, find.byKey(JobMatchSuggestionCard.checkboxKey('s3')));
      api.applyResponses.add(_status(422));
      await tapVisible(tester, find.byKey(const ValueKey('jm-apply')));
      await settle(tester);

      expect(
        find.text(l10n(tester).jobMatchErrorInvalidSelection),
        findsOneWidget,
      );
      expect(find.byType(JobMatchResultScreen), findsOneWidget);
    });
  });

  group('entry points', () {
    test('the route is known', () {
      final parsed = AppRouter.parse(AppRoutes.jobMatch);
      expect(parsed.name, AppRoutes.jobMatch);
      expect(parsed.unknown, isFalse);
    });

    testWidgets('My CVs opens Job Match through the app router',
        (tester) async {
      useTallView(tester);
      registerSiratiRouteWidgets();
      SharedPreferences.setMockInitialValues({});
      const storage =
          MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(storage, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(storage, null));

      await tester.pumpWidget(ProviderScope(
        overrides: [
          mobileContentServiceProvider.overrideWithValue(_EmptyContent()),
          cvApiServiceProvider.overrideWithValue(FakeJobMatchApi()),
          authApiServiceProvider.overrideWithValue(FakeAuth(subscription())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const Scaffold(body: MyCvsScreen()),
        ),
      ));
      await settle(tester);

      await tapVisible(tester, find.byKey(MyCvsToolsCard.targetKey));
      await settle(tester);
      expect(find.byType(JobMatchScreen), findsOneWidget);
    });
  });
}

class _EmptyContent extends MobileContentService {
  @override
  Future<Map<String, dynamic>> myCvs(bool english,
          {bool force = false}) async =>
      {'title': 'My CVs', 'items': <Object>[]};
}
