import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_suggestion_card.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';
import 'job_match_test_support.dart';

/// Independent first-strong-character oracle (UAX #9 P2/P3) for the
/// characters the generator below can produce.
TextDirection? _firstStrong(String text) {
  for (final rune in text.runes) {
    final latin = (rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0xC0 && rune <= 0x24F && rune != 0xD7 && rune != 0xF7);
    if (latin) return TextDirection.ltr;
    final arabicLetter = (rune >= 0x0620 && rune <= 0x064A) ||
        (rune >= 0x0671 && rune <= 0x06D3) ||
        (rune >= 0x06FA && rune <= 0x06FC);
    if (arabicLetter) return TextDirection.rtl;
  }
  return null;
}

const _latinTerms = [
  'C++', 'C#', '.NET', 'Node.js', 'Power BI', 'SQL', 'UI/UX', //
  'ASP.NET Core', 'Résumé', 'Excel', 'CI/CD', 'A/B testing', 'Go',
];
const _arabicTerms = [
  'تحليل البيانات', 'إدارة المشاريع', 'المحاسبة', 'خدمة العملاء', //
  'برمجة', 'ی‌کاربر',
];
const _neutralPieces = ['3+', '٣', '۵', '(', '%', '٪', '#', '- ', '2024', '،'];

/// Mixed-script keywords, some led by digits or punctuation, some with no
/// strong character at all.
List<String> _randomTerms(Random random, int count) => [
      for (var i = 0; i < count; i++)
        switch (random.nextInt(6)) {
          0 => _latinTerms[random.nextInt(_latinTerms.length)],
          1 => _arabicTerms[random.nextInt(_arabicTerms.length)],
          2 => '${_neutralPieces[random.nextInt(_neutralPieces.length)]} '
              '${_latinTerms[random.nextInt(_latinTerms.length)]}',
          3 => '${_neutralPieces[random.nextInt(_neutralPieces.length)]}'
              '${_arabicTerms[random.nextInt(_arabicTerms.length)]} '
              '${_latinTerms[random.nextInt(_latinTerms.length)]}',
          4 => '${_latinTerms[random.nextInt(_latinTerms.length)]} '
              '${_arabicTerms[random.nextInt(_arabicTerms.length)]}',
          _ => _neutralPieces[random.nextInt(_neutralPieces.length)] +
              _neutralPieces[random.nextInt(_neutralPieces.length)],
        },
    ];

bool _hasArabic(String text) =>
    text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);

Future<void> _openResult(
  WidgetTester tester, {
  required Map<String, dynamic> match,
  String language = 'en',
  ThemeData? theme,
  List<Duration> schedule = const [
    Duration(milliseconds: 100),
    Duration(milliseconds: 100),
  ],
  Object? fetch,
}) async {
  useTallView(tester);
  final api = FakeJobMatchApi()..createResponses.add(match);
  if (fetch != null) api.fetchResponses.add(fetch);
  await pumpJobMatch(
    tester,
    api: api,
    auth: FakeAuth(subscription()),
    language: language,
    theme: theme,
    schedule: schedule,
  );
  await enterJob(tester);
  await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
  await settle(tester);
}

void main() {
  group('keyword chips keep each term intact in its own direction', () {
    for (final language in ['ar', 'en']) {
      testWidgets('$language UI', (tester) async {
        final ambient =
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr;
        final random = Random(language == 'ar' ? 1018 : 1914);
        for (var round = 0; round < 4; round++) {
          final found = _randomTerms(random, 6);
          final missing = _randomTerms(random, 6);
          final jdTerms = _randomTerms(random, 3);
          await _openResult(
            tester,
            language: language,
            match: matchJson(
              found: found,
              missing: missing,
              suggestions: [suggestionJson('s1', jdTerms: jdTerms)],
            ),
          );

          final chips = tester
              .widgetList<JobMatchKeywordChip>(
                find.byType(JobMatchKeywordChip),
              )
              .map((c) => c.term)
              .toList();
          expect(
            chips,
            [...found, ...missing, ...jdTerms].map((t) => t.trim()),
          );

          for (final term in chips.toSet()) {
            final text = find.descendant(
              of: find.byWidgetPredicate(
                (w) => w is JobMatchKeywordChip && w.term == term,
              ),
              matching: find.byType(Text),
            );
            final expected = _firstStrong(term) ?? ambient;
            for (final element in text.evaluate()) {
              final widget = element.widget as Text;
              expect(widget.data, term, reason: 'no bidi controls injected');
              expect(widget.textDirection, expected, reason: term);
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(
                  of: find.byWidget(widget),
                  matching: find.byType(RichText),
                ),
              );
              expect(paragraph.textDirection, expected, reason: term);
            }
          }
          await tester.pumpWidget(const SizedBox());
        }
      });
    }
  });

  testWidgets('an English UI shows no Arabic when the server content is Latin',
      (tester) async {
    await _openResult(
      tester,
      match: matchJson(applied: ['s3'], appliedCvId: 55),
    );
    final strings = [
      for (final element in find.byType(Text).evaluate())
        (element.widget as Text).data ??
            (element.widget as Text).textSpan?.toPlainText() ??
            '',
    ];
    expect(strings, isNotEmpty);
    for (final s in strings) {
      expect(_hasArabic(s), isFalse, reason: s);
    }
  });

  group('WCAG AA for every visible text', () {
    final themes = <String, ThemeData Function(bool arabic)>{
      'light': (arabic) => AppTheme.lightFor(arabic: arabic),
      'dark': (arabic) => AppTheme.darkFor(arabic: arabic),
    };

    for (final MapEntry(key: mode, value: themeFor) in themes.entries) {
      for (final language in ['ar', 'en']) {
        final label = '$mode/$language';
        final theme = themeFor(language == 'ar');

        testWidgets('$label: form with input and pick errors', (tester) async {
          useTallView(tester);
          final api = FakeJobMatchApi()
            ..cvs = [savedCv(1), savedCv(2, title: 'محلل بيانات')];
          await pumpJobMatch(
            tester,
            api: api,
            auth: FakeAuth(subscription()),
            language: language,
            theme: theme,
          );
          expectAllTextAa('$label empty form');
          await enterJob(tester, description: ' ');
          await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
          expectAllTextAa('$label input error');
          await enterJob(tester);
          await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
          expectAllTextAa('$label pick error');
          await tapVisible(tester, find.byKey(JobMatchScreen.cvOptionKey(2)));
          expectAllTextAa('$label picked');
        });

        testWidgets('$label: no saved CV', (tester) async {
          useTallView(tester);
          await pumpJobMatch(
            tester,
            api: FakeJobMatchApi()..cvs = [],
            auth: FakeAuth(subscription()),
            language: language,
            theme: theme,
          );
          expectAllTextAa('$label no CV');
        });

        testWidgets('$label: CV list failure', (tester) async {
          useTallView(tester);
          await pumpJobMatch(
            tester,
            api: FakeJobMatchApi()
              ..cvsError = const ApiException.network('offline'),
            auth: FakeAuth(subscription()),
            language: language,
            theme: theme,
          );
          expectAllTextAa('$label CVs failed');
        });

        final gates = <String, FakeAuth Function()>{
          'paywall + trial': () => FakeAuth(
                subscription(subscribed: false, trialDays: 7),
              ),
          'quota': () => FakeAuth(subscription(canJobMatch: false, used: 5)),
          'unavailable': FakeAuth.new,
          'load failure': () => FakeAuth(subscription())
            ..error = const ApiException.network('offline'),
        };
        for (final MapEntry(key: gate, value: auth) in gates.entries) {
          testWidgets('$label: $gate', (tester) async {
            useTallView(tester);
            await pumpJobMatch(
              tester,
              api: FakeJobMatchApi(),
              auth: auth(),
              language: language,
              theme: theme,
            );
            expectAllTextAa('$label $gate');
          });
        }

        testWidgets('$label: completed result with selection and applied edit',
            (tester) async {
          await _openResult(
            tester,
            language: language,
            theme: theme,
            match: matchJson(applied: ['s3'], appliedCvId: 55),
          );
          expectAllTextAa('$label result');
          await tapVisible(
            tester,
            find.byKey(JobMatchSuggestionCard.checkboxKey('s1')),
          );
          expectAllTextAa('$label result selected');
        });

        testWidgets('$label: result with no keywords or suggestions',
            (tester) async {
          await _openResult(
            tester,
            language: language,
            theme: theme,
            match: matchJson(found: [], missing: [], suggestions: []),
          );
          expectAllTextAa('$label empty result');
        });

        testWidgets('$label: preparing advice', (tester) async {
          await _openResult(
            tester,
            language: language,
            theme: theme,
            schedule: const [Duration(minutes: 5)],
            match: matchJson(aiStatus: 'processing'),
          );
          expectAllTextAa('$label polling');
          await tester.pumpWidget(const SizedBox());
        });

        for (final status in ['failed', 'not_configured']) {
          testWidgets('$label: advice $status', (tester) async {
            await _openResult(
              tester,
              language: language,
              theme: theme,
              match: matchJson(aiStatus: status),
            );
            expectAllTextAa('$label $status');
          });
        }

        testWidgets('$label: advice failed with retry error', (tester) async {
          useTallView(tester);
          final api = FakeJobMatchApi()
            ..createResponses.add(matchJson(aiStatus: 'failed'))
            ..retryResponses.add(ApiException.fromStatus(503, message: ''));
          await pumpJobMatch(
            tester,
            api: api,
            auth: FakeAuth(subscription()),
            language: language,
            theme: theme,
          );
          await enterJob(tester);
          await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
          await settle(tester);
          await tapVisible(
            tester,
            find.text(l10n(tester).jobMatchRetrySuggestions),
          );
          await settle(tester);
          expectAllTextAa('$label retry error');
        });

        testWidgets('$label: advice failed with retry in flight (busy)',
            (tester) async {
          useTallView(tester);
          final retryCompleter = Completer<Map<String, dynamic>>();
          final api = FakeJobMatchApi()
            ..createResponses.add(matchJson(aiStatus: 'failed'))
            ..retryOverride = (_) => retryCompleter.future;
          await pumpJobMatch(
            tester,
            api: api,
            auth: FakeAuth(subscription()),
            language: language,
            theme: theme,
          );
          await enterJob(tester);
          await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
          await settle(tester);
          await tester.tap(find.text(l10n(tester).jobMatchRetrySuggestions));
          await tester.pump();
          expectAllTextAa('$label retry busy');
          retryCompleter.complete(matchJson(aiStatus: 'completed'));
          await settle(tester);
        });

        testWidgets('$label: still processing after a refresh failure',
            (tester) async {
          await _openResult(
            tester,
            language: language,
            theme: theme,
            match: matchJson(aiStatus: 'queued'),
            fetch: ApiException.fromStatus(429, message: ''),
          );
          await settle(tester);
          expect(
            find.byWidgetPredicate(
              (w) => w is JobMatchNotice && w.tone == JobMatchTone.warning,
            ),
            findsOneWidget,
          );
          expectAllTextAa('$label still processing');
        });
      }
    }
  });
}
