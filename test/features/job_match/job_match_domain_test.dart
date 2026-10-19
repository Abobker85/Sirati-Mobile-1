import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/features/job_match/application/job_match_controller.dart';
import 'package:sirati/features/job_match/domain/job_match.dart';
import 'package:sirati/features/job_match/domain/job_match_entitlement.dart';
import 'package:sirati/features/job_match/domain/job_match_failure.dart';
import 'package:sirati/features/job_match/domain/job_match_input.dart';
import 'package:sirati/shared/models/cv_target_job.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';

import 'job_match_test_support.dart';

void main() {
  group('JobMatchEntitlement fails closed', () {
    // Values a misbehaving backend or proxy might send instead of `true`.
    const notTrue = <Object?>[
      false, null, 'true', 'TRUE', 1, '1', 1.0, 'yes', <String>[], {}, //
    ];
    const anyValue = <Object?>[true, ...notTrue];

    test('access is granted only for explicit is_subscribed and '
        'can_job_match booleans', () {
      final random = Random(20261018);
      for (var i = 0; i < 400; i++) {
        final subscribed = anyValue[random.nextInt(anyValue.length)];
        final canMatch = anyValue[random.nextInt(anyValue.length)];
        final state = <String, dynamic>{
          if (random.nextBool()) 'is_subscribed': subscribed,
          if (random.nextBool()) 'can_job_match': canMatch,
          if (random.nextBool())
            'quota': {
              'job_match': {
                'limit': random.nextInt(6),
                'used': random.nextInt(8),
              },
            },
        };
        final access = JobMatchEntitlement.fromSubscription(state).access;
        final granted = state['is_subscribed'] == true &&
            state['can_job_match'] == true;
        expect(
          access == JobMatchAccess.allowed,
          granted,
          reason: 'state $state gave $access',
        );
        if (state['is_subscribed'] != true) {
          expect(access, JobMatchAccess.subscriptionRequired);
        }
      }
    });

    test('missing state is unavailable, never allowed', () {
      expect(
        JobMatchEntitlement.fromSubscription(null).access,
        JobMatchAccess.unavailable,
      );
      expect(
        JobMatchEntitlement.fromSubscription({}).access,
        JobMatchAccess.subscriptionRequired,
      );
    });

    test('a denied subscriber is told about the quota only when it is used up',
        () {
      for (var limit = 0; limit <= 6; limit++) {
        for (var used = 0; used <= 8; used++) {
          final e = JobMatchEntitlement.fromSubscription(
            subscription(canJobMatch: false, limit: limit, used: used),
          );
          expect(
            e.access,
            limit > 0 && used >= limit
                ? JobMatchAccess.quotaReached
                : JobMatchAccess.unavailable,
          );
          expect(e.remaining, (limit - used).clamp(0, limit));
        }
      }
      final noQuota = {...subscription(canJobMatch: false)}..remove('quota');
      final e = JobMatchEntitlement.fromSubscription(noQuota);
      expect(e.access, JobMatchAccess.unavailable);
      expect(e.remaining, isNull);
    });
  });

  group('JobMatchFailure.from', () {
    ApiException status(int code, [Map<String, List<String>> errors = const {}]) =>
        ApiException.fromStatus(code, message: '', errors: errors);

    test('every status maps to one kind per operation', () {
      for (final op in JobMatchOperation.values) {
        JobMatchFailureKind kind(Object e) => JobMatchFailure.from(e, op).kind;

        expect(kind(status(402)), JobMatchFailureKind.subscriptionRequired);
        expect(kind(status(429)), JobMatchFailureKind.limitReached);
        expect(kind(status(503)), JobMatchFailureKind.unavailable);
        expect(kind(status(404)), JobMatchFailureKind.notFound);
        for (final code in [500, 502, 504, 599]) {
          expect(kind(status(code)), JobMatchFailureKind.server);
        }
        for (final code in [400, 401, 403, 418]) {
          expect(kind(status(code)), JobMatchFailureKind.unknown);
        }
        expect(kind(const ApiException.network('x')), JobMatchFailureKind.network);
        expect(kind(const ApiException.timeout('x')), JobMatchFailureKind.network);
        expect(kind(StateError('x')), JobMatchFailureKind.unknown);

        expect(
          kind(status(409)),
          op == JobMatchOperation.apply
              ? JobMatchFailureKind.stale
              : JobMatchFailureKind.conflict,
        );
        expect(
          kind(status(422, {'generated_cv_id': ['too long']})),
          op == JobMatchOperation.apply
              ? JobMatchFailureKind.invalidSelection
              : JobMatchFailureKind.cvTooLong,
        );
        expect(
          kind(status(422, {'job_description_input': ['bad']})),
          op == JobMatchOperation.apply
              ? JobMatchFailureKind.invalidSelection
              : JobMatchFailureKind.invalidJobDescription,
        );
      }
    });

    test('only entitlement-related failures trigger an entitlement re-read',
        () {
      for (final kind in JobMatchFailureKind.values) {
        expect(
          JobMatchFailure(kind).affectsEntitlement,
          kind == JobMatchFailureKind.subscriptionRequired ||
              kind == JobMatchFailureKind.unavailable,
        );
      }
    });
  });

  group('JobMatchInput.validate', () {
    test('limits match what CvTargetJob would otherwise clip silently', () {
      final random = Random(7);
      const alphabet = ['a', ' ', 'ع', '📊', '\n', '+', '٣'];
      for (var i = 0; i < 300; i++) {
        final buffer = StringBuffer();
        final target = random.nextInt(JobMatchInput.descriptionMax + 40);
        while (buffer.length < target) {
          buffer.write(alphabet[random.nextInt(alphabet.length)]);
        }
        final jd = buffer.toString();
        final title = 'T' * random.nextInt(JobMatchInput.titleMax + 5);
        final error = JobMatchInput.validate(description: jd, title: title);
        if (error == null) {
          // Valid input survives the generator's clipping untouched.
          final target = CvTargetJob(title: title, description: jd);
          expect(target.description, jd.trim());
          expect(target.title, title.trim());
        } else if (jd.trim().isEmpty) {
          expect(error, JobMatchInputError.descriptionEmpty);
        } else if (jd.trim().length > JobMatchInput.descriptionMax) {
          expect(error, JobMatchInputError.descriptionTooLong);
        } else {
          expect(error, JobMatchInputError.titleTooLong);
          expect(title.length, greaterThan(JobMatchInput.titleMax));
        }
      }
    });

    test('boundaries are counted in UTF-16 units after trimming', () {
      JobMatchInputError? jd(String d) =>
          JobMatchInput.validate(description: d, title: '');
      const max = JobMatchInput.descriptionMax;
      expect(jd(''), JobMatchInputError.descriptionEmpty);
      expect(jd(' \n\t '), JobMatchInputError.descriptionEmpty);
      expect(jd('a' * max), isNull);
      expect(jd('  ${'a' * max}\n'), isNull);
      expect(jd('a' * (max + 1)), JobMatchInputError.descriptionTooLong);
      // A surrogate pair crossing the limit counts as two units.
      expect(jd('${'a' * (max - 1)}📊'), JobMatchInputError.descriptionTooLong);
      expect(jd('${'a' * (max - 2)}📊'), isNull);
      expect(
        JobMatchInput.validate(
          description: 'x',
          title: 'T' * JobMatchInput.titleMax,
        ),
        isNull,
      );
      expect(
        JobMatchInput.validate(
          description: 'x',
          title: 'T' * (JobMatchInput.titleMax + 1),
        ),
        JobMatchInputError.titleTooLong,
      );
    });
  });

  group('JobMatch.fromJson', () {
    test('suggestion keys are unique and non-empty, first one wins', () {
      final random = Random(99);
      for (var i = 0; i < 100; i++) {
        final raw = [
          for (var j = 0; j < random.nextInt(12); j++)
            suggestionJson(
              ['a', 'b', 'c', '', ' ', 'd'][random.nextInt(6)],
              after: 'after $j',
            ),
        ];
        final match = JobMatch.fromJson(matchJson(suggestions: raw));
        final keys = match.suggestions.map((s) => s.key).toList();
        expect(keys.toSet(), hasLength(keys.length));
        expect(keys.every((k) => k.trim().isNotEmpty), isTrue);
        for (final s in match.suggestions) {
          final first = raw.firstWhere((r) => (r['key'] as String) == s.key);
          expect(s.after, first['after']);
        }
      }
    });

    test('selectable only when an automatic edit exists', () {
      for (final needsFact in [true, false]) {
        for (final after in ['', '   ', 'Add SQL']) {
          final s = JobMatchSuggestion.fromJson(
            suggestionJson('k', after: after, needsUserFact: needsFact),
          );
          expect(s.selectable, !needsFact && after.trim().isNotEmpty);
        }
      }
    });

    test('scores are clamped and malformed lists are empty', () {
      for (final raw in <Object?>[-20, 0, 55, 100, 140, '87', null, 'x']) {
        final json = {...matchJson(), 'score_total': raw, 'job_match': raw};
        final match = JobMatch.fromJson(json);
        expect(match.scoreTotal, inInclusiveRange(0, 100));
        if (match.coverage != null) {
          expect(match.coverage, inInclusiveRange(0, 100));
        }
      }
      final match = JobMatch.fromJson({
        ...matchJson(),
        'keywords_found': 'SQL',
        'keywords_missing': [null, '', ' Power BI '],
      });
      expect(match.keywordsFound, isEmpty);
      expect(match.keywordsMissing, ['Power BI']);
    });
  });

  group('JobMatchController', () {
    late FakeJobMatchApi api;
    late ProviderContainer container;

    setUp(() {
      api = FakeJobMatchApi();
      container = ProviderContainer(overrides: [
        cvApiServiceProvider.overrideWithValue(api),
        authApiServiceProvider.overrideWithValue(FakeAuth(subscription())),
        jobMatchPollScheduleProvider.overrideWithValue(const []),
      ]);
      addTearDown(container.dispose);
      // Keep the autoDispose controller alive for the whole test.
      container.listen(jobMatchControllerProvider, (_, __) {});
    });

    JobMatchController controller() =>
        container.read(jobMatchControllerProvider.notifier);

    test('a retry of the same request reuses its idempotency key', () async {
      api.createResponses.addAll([
        const ApiException.network('offline'),
        const ApiException.timeout('slow'),
        matchJson(),
      ]);
      for (var i = 0; i < 3; i++) {
        await controller().submit(
          generatedCvId: 1,
          jobDescription: ' Need SQL ',
          targetJobTitle: 'Analyst',
        );
      }
      final keys = api.createCalls.map((c) => c['key']).toSet();
      expect(keys, hasLength(1));
      expect(keys.single, isA<String>());
    });

    test('any change to CV, description or title gets a new key', () async {
      api.createResponses.add(const ApiException.network('offline'));
      final requests = [
        (1, 'Need SQL', ''),
        (1, 'Need SQL ', ''), // same after trimming
        (2, 'Need SQL', ''),
        (2, 'Need SQL.', ''),
        (2, 'Need SQL.', 'Analyst'),
        (2, 'Need SQL.', 'Analyst'),
      ];
      for (final (cv, jd, title) in requests) {
        await controller().submit(
          generatedCvId: cv,
          jobDescription: jd,
          targetJobTitle: title,
        );
      }
      final keys = api.createCalls.map((c) => c['key']).toList();
      expect(keys[0], keys[1]);
      expect({keys[1], keys[2], keys[3], keys[4]}, hasLength(4));
      expect(keys[4], keys[5]);
    });

    test('a 409 conflict drops the key so the next try is a new request',
        () async {
      api.createResponses.addAll([
        ApiException.fromStatus(409, message: ''),
        matchJson(),
      ]);
      expect(
        (await controller().submit(generatedCvId: 1, jobDescription: 'jd'))
            ?.kind,
        JobMatchFailureKind.conflict,
      );
      expect(
        await controller().submit(generatedCvId: 1, jobDescription: 'jd'),
        isNull,
      );
      expect(api.createCalls[0]['key'], isNot(api.createCalls[1]['key']));
    });

    test('invalid input never reaches the API', () async {
      for (final jd in ['', '  ', 'a' * (JobMatchInput.descriptionMax + 1)]) {
        expect(
          await controller().submit(generatedCvId: 1, jobDescription: jd),
          isNotNull,
        );
      }
      expect(api.createCalls, isEmpty);
    });

    test('apply sends exactly the selectable, unapplied selection in '
        'suggestion order', () async {
      final random = Random(4242);
      for (var round = 0; round < 60; round++) {
        final count = 1 + random.nextInt(8);
        final suggestions = [
          for (var i = 0; i < count; i++)
            suggestionJson(
              'k$i',
              after: random.nextInt(5) == 0 ? ' ' : 'edit $i',
              needsUserFact: random.nextInt(4) == 0,
            ),
        ];
        final applied = [
          for (var i = 0; i < count; i++)
            if (random.nextInt(5) == 0) 'k$i',
        ];
        api
          ..createResponses.clear()
          ..createResponses.add(
            matchJson(suggestions: suggestions, applied: applied),
          )
          ..applyCalls.clear()
          ..applyResponses.clear()
          ..applyResponses.add((
            generatedCv: savedCv(100 + round),
            jobMatch: matchJson(suggestions: suggestions),
          ));
        await controller().submit(
          generatedCvId: 1,
          jobDescription: 'round $round',
        );
        final match = container.read(jobMatchControllerProvider).match!;

        // Tap random keys (including unknown ones) in random order, some twice.
        final taps = [
          for (var i = 0; i < random.nextInt(14); i++)
            'k${random.nextInt(count + 2)}',
        ];
        for (final key in taps) {
          controller().toggle(key);
        }
        final toggledOdd = <String>{
          for (final key in taps)
            if (taps.where((t) => t == key).length.isOdd) key,
        };
        final expected = [
          for (final s in match.suggestions)
            if (s.selectable &&
                !applied.contains(s.key) &&
                toggledOdd.contains(s.key))
              s.key,
        ];
        expect(
          container.read(jobMatchControllerProvider).selected,
          expected.toSet(),
        );

        final outcome = await controller().apply();
        if (expected.isEmpty) {
          expect(outcome, isNull);
          expect(api.applyCalls, isEmpty);
        } else {
          expect(outcome, isA<JobMatchApplied>());
          expect(api.applyCalls.single, expected);
          expect(container.read(jobMatchControllerProvider).selected, isEmpty);
        }
      }
    });

    test('a failed apply keeps the selection for another try', () async {
      api
        ..createResponses.add(matchJson())
        ..applyResponses.add(ApiException.fromStatus(500, message: ''));
      await controller().submit(generatedCvId: 1, jobDescription: 'jd');
      controller().toggle('s1');
      final outcome = await controller().apply();
      expect(
        (outcome! as JobMatchApplyFailed).failure.kind,
        JobMatchFailureKind.server,
      );
      final state = container.read(jobMatchControllerProvider);
      expect(state.selected, {'s1'});
      expect(state.applying, isFalse);
    });

    test('retryAdvice guards against non-failed status or in-flight', () async {
      api.createResponses.add(matchJson(aiStatus: 'completed'));
      await controller().submit(generatedCvId: 1, jobDescription: 'jd');
      await controller().retryAdvice();
      expect(api.retryCalls, isEmpty);
    });

    test('retryAdvice failure records retryFailure and resets in-flight',
        () async {
      api
        ..createResponses.add(matchJson(aiStatus: 'failed'))
        ..retryResponses.add(ApiException.fromStatus(503, message: ''));
      await controller().submit(generatedCvId: 1, jobDescription: 'jd');
      await controller().retryAdvice();
      expect(api.retryCalls, [7]);
      final state = container.read(jobMatchControllerProvider);
      expect(state.retryingAdvice, isFalse);
      expect(state.retryFailure?.kind, JobMatchFailureKind.unavailable);
    });

    test('retryAdvice success sets match and initiates polling', () async {
      final customContainer = ProviderContainer(overrides: [
        cvApiServiceProvider.overrideWithValue(api),
        authApiServiceProvider.overrideWithValue(FakeAuth(subscription())),
        jobMatchPollScheduleProvider
            .overrideWithValue(const [Duration(minutes: 1)]),
      ]);
      addTearDown(customContainer.dispose);
      customContainer.listen(jobMatchControllerProvider, (_, __) {});
      final customController =
          customContainer.read(jobMatchControllerProvider.notifier);

      api
        ..createResponses.add(matchJson(aiStatus: 'failed'))
        ..retryResponses.add(matchJson(aiStatus: 'processing'));
      await customController.submit(generatedCvId: 1, jobDescription: 'jd');
      await customController.retryAdvice();
      expect(api.retryCalls, [7]);
      final state = customContainer.read(jobMatchControllerProvider);
      expect(state.retryingAdvice, isFalse);
      expect(state.retryFailure, isNull);
      expect(state.match?.aiStatus, 'processing');
      expect(state.pollPhase, JobMatchPollPhase.polling);
    });
  });
}
