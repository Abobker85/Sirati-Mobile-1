import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/job_match/presentation/job_match_result_screen.dart';
import 'package:sirati/features/job_match/presentation/job_match_screen.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_suggestion_card.dart';
import 'package:sirati/features/job_match/presentation/widgets/job_match_widgets.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';
import 'job_match_test_support.dart';

/// Ticket 16: the job match form is a grouped page and the result a plain
/// one. Sections are borderless cards on the page's own card fill; every
/// field and button has a fill that differs from what is painted behind
/// it; the CV choice is marked by its radio, not by a coloured edge; and
/// every number is in Latin digits, AR/EN x light/dark.

final _easternDigits = RegExp('[٠-٩۰-۹]');

List<Color> _behind(Element element) {
  late Element parent;
  element.visitAncestorElements((e) {
    parent = e;
    return false;
  });
  return paintedBackgroundsOf(parent);
}

Color _page(WidgetTester tester) {
  final scaffold = find.byType(Scaffold).last;
  return tester.widget<Scaffold>(scaffold).backgroundColor ??
      Theme.of(tester.element(scaffold)).scaffoldBackgroundColor;
}

/// Sections: the page's own card fill, a ring only when highlighted.
void _expectSections(WidgetTester tester, Color fill, String label) {
  for (final element in find.byType(JobMatchSection).evaluate()) {
    final section = element.widget as JobMatchSection;
    final box = tester.widget<AnimatedContainer>(find
        .descendant(
          of: find.byWidget(section),
          matching: find.byType(AnimatedContainer),
        )
        .first);
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, fill, reason: '$label section fill');
    expect(decoration.boxShadow, isNull, reason: label);
    if (section.highlighted) {
      final side = (decoration.border! as Border).top;
      expect(
        AppContrast.ratio(side.color, fill),
        greaterThanOrEqualTo(3),
        reason: '$label highlight ring',
      );
    } else {
      expect(decoration.border, isNull, reason: '$label resting border');
    }
  }
}

/// Fields and buttons never take the colour of what is behind them.
void _expectOwnFills(String label) {
  for (final element in find.byType(InputDecorator).evaluate()) {
    final decoration = (element.widget as InputDecorator).decoration;
    expect(decoration.filled, isTrue, reason: label);
    final resting = decoration.enabledBorder ?? decoration.border;
    expect(
      resting == null ||
          resting.borderSide.style == BorderStyle.none ||
          resting.borderSide.width == 0,
      isTrue,
      reason: '$label field outline',
    );
    for (final bg in _behind(element)) {
      expect(decoration.fillColor, isNot(bg), reason: '$label field fill');
    }
  }
  for (final element in find
      .byWidgetPredicate((w) =>
          w is ElevatedButton || w is OutlinedButton || w is FilledButton)
      .evaluate()) {
    final material = find
        .descendant(
          of: find.byWidget(element.widget),
          matching: find.byType(Material),
        )
        .evaluate()
        .first
        .widget as Material;
    for (final bg in _behind(element)) {
      expect(material.color, isNot(bg),
          reason: '$label ${element.widget.runtimeType} fill');
    }
  }
}

void _expectLatinDigits(WidgetTester tester, String label) {
  for (final p in tester.allRenderObjects.whereType<RenderParagraph>()) {
    final s = p.text.toPlainText();
    expect(_easternDigits.hasMatch(s), isFalse, reason: '"$s" ($label)');
  }
}

void main() {
  tearDown(() => AppLocale.languageCode.value = 'en');

  for (final dark in [false, true]) {
    for (final language in ['ar', 'en']) {
      final label = '$language ${dark ? 'dark' : 'light'}';
      ThemeData theme() => dark
          ? AppTheme.darkFor(arabic: language == 'ar')
          : AppTheme.lightFor(arabic: language == 'ar');

      testWidgets('$label: form is grouped; CV rows marked by their radio',
          (tester) async {
        useTallView(tester);
        final api = FakeJobMatchApi()
          ..cvs = [savedCv(1), savedCv(2, title: 'محلل بيانات')];
        await pumpJobMatch(
          tester,
          api: api,
          auth: FakeAuth(subscription(used: 3)),
          language: language,
          theme: theme(),
        );
        final c = tester.element(find.byType(JobMatchScreen)).sirati;
        expect(_page(tester), c.groupedBackground, reason: label);
        _expectSections(tester, c.groupedCard, label);
        _expectOwnFills('$label form');

        await enterJob(tester, title: 'Data Analyst 2026');
        await tapVisible(tester, find.byKey(JobMatchScreen.cvOptionKey(2)));
        await settle(tester);
        for (final id in [1, 2]) {
          final option = find.byKey(JobMatchScreen.cvOptionKey(id));
          final radio = tester.widget<Icon>(
              find.descendant(of: option, matching: find.byType(Icon)).first);
          expect(
            radio.icon,
            id == 2 ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            reason: '$label option $id',
          );
          // No coloured edge carries the choice.
          expect(
            find.descendant(
              of: option,
              matching: find.byWidgetPredicate((w) =>
                  w is DecoratedBox &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).border != null),
            ),
            findsNothing,
            reason: '$label option $id border',
          );
        }
        expectAllTextAa('$label form');
        expectAllIconsAa('$label form');
        _expectLatinDigits(tester, '$label form');
      });

      for (final gate in ['paywall', 'load failure']) {
        testWidgets('$label: $gate gate sits on the page', (tester) async {
          useTallView(tester);
          await pumpJobMatch(
            tester,
            api: FakeJobMatchApi(),
            auth: gate == 'paywall'
                ? FakeAuth(subscription(subscribed: false, trialDays: 7))
                : (FakeAuth(subscription())
                  ..error = const ApiException.network('offline')),
            language: language,
            theme: theme(),
          );
          expect(find.byType(JobMatchSection), findsNothing, reason: label);
          _expectOwnFills('$label $gate');
          expectAllTextAa('$label $gate');
          _expectLatinDigits(tester, '$label $gate');
        });
      }

      for (final status in ['completed', 'failed']) {
        testWidgets('$label: $status result is a plain page of grey cards',
            (tester) async {
          useTallView(tester);
          final api = FakeJobMatchApi()
            ..createResponses.add(matchJson(
              aiStatus: status,
              applied: status == 'completed' ? ['s3'] : const [],
              appliedCvId: status == 'completed' ? 55 : null,
            ));
          await pumpJobMatch(
            tester,
            api: api,
            auth: FakeAuth(subscription()),
            language: language,
            theme: theme(),
          );
          await enterJob(tester);
          await tapVisible(tester, find.byKey(JobMatchScreen.submitKey));
          await settle(tester);
          expect(find.byType(JobMatchResultScreen), findsOneWidget);
          if (status == 'completed') {
            await tapVisible(
              tester,
              find.byKey(JobMatchSuggestionCard.checkboxKey('s1')),
            );
            await settle(tester);
          }

          final c = tester.element(find.byType(JobMatchResultScreen)).sirati;
          expect(_page(tester), c.pageBackground, reason: label);
          _expectSections(tester, c.cardFill, '$label $status');
          _expectOwnFills('$label $status');
          if (status == 'completed') {
            final bar = tester.widget<ColoredBox>(
                find.byKey(JobMatchResultScreen.applyBarKey));
            expect(bar.color, c.pageBackground, reason: label);
          }
          expectAllTextAa('$label $status');
          expectAllIconsAa('$label $status');
          _expectLatinDigits(tester, '$label $status');
        });
      }
    }
  }
}
