import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_cards.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_list_field.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/form_reveal.dart';

const _count = 16;

Widget _app(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
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
      home: Scaffold(body: child),
    );

/// A long form: field `i` is invalid when `i` is in [bad].
Widget _form(GlobalKey<FormState> key, Set<int> bad) => SingleChildScrollView(
      child: Form(
        key: key,
        child: Column(children: [
          for (var i = 0; i < _count; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: AppTextFormField(
                key: ValueKey('f$i'),
                initialValue: 'value $i',
                validator: (_) => bad.contains(i) ? 'fix $i' : null,
              ),
            ),
        ]),
      ),
    );

bool _onScreen(WidgetTester tester, Finder f) {
  final r = tester.getRect(f);
  final screen = tester.getRect(find.byType(Scaffold));
  return r.top >= screen.top && r.bottom <= screen.bottom;
}

FocusNode? _focusOf(WidgetTester tester, String key) => tester
    .widget<TextField>(find.descendant(
        of: find.byKey(ValueKey(key)), matching: find.byType(TextField)))
    .focusNode;

void main() {
  group('validateAndReveal', () {
    for (final bad in [
      {12},
      {9, 14},
      {15, 3, 11},
      {0},
    ]) {
      for (final reduce in [false, true]) {
        testWidgets(
            'bad $bad${reduce ? ' (reduced motion)' : ''}: the top-most bad '
            'field is shown and focused', (tester) async {
          final key = GlobalKey<FormState>();
          await tester.pumpWidget(_app(_form(key, bad), reduce: reduce));
          expect(validateAndReveal(key), isFalse);
          if (reduce) {
            await tester.pump();
            await tester.pump();
          } else {
            await tester.pumpAndSettle();
          }
          final first = bad.reduce((a, b) => a < b ? a : b);
          expect(_onScreen(tester, find.byKey(ValueKey('f$first'))), isTrue);
          expect(_focusOf(tester, 'f$first')!.hasFocus, isTrue);
          for (final other in bad.where((b) => b != first)) {
            expect(_focusOf(tester, 'f$other')!.hasFocus, isFalse);
          }
        });
      }
    }

    testWidgets('a valid form returns true and moves nothing', (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(_app(_form(key, const {})));
      final before = tester.getTopLeft(find.byKey(const ValueKey('f0')));
      expect(validateAndReveal(key), isTrue);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const ValueKey('f0'))), before);
      expect(FocusManager.instance.primaryFocus?.context?.widget,
          isNot(isA<EditableText>()));
    });

    for (final direction in TextDirection.values) {
      testWidgets('${direction.name}: on one row, the reading-start field wins',
          (tester) async {
        final key = GlobalKey<FormState>();
        await tester.pumpWidget(_app(
          Form(
            key: key,
            child: Row(children: [
              for (final k in ['a', 'b'])
                Expanded(
                  child: AppTextFormField(
                    key: ValueKey(k),
                    validator: (_) => 'fix',
                  ),
                ),
            ]),
          ),
          direction: direction,
        ));
        expect(validateAndReveal(key), isFalse);
        await tester.pumpAndSettle();
        // Row children run right to left in Arabic: 'a' is at the start
        // in both directions.
        expect(_focusOf(tester, 'a')!.hasFocus, isTrue);
      });
    }

    testWidgets('a non-text field is scrolled to but not focused',
        (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(_app(SingleChildScrollView(
        child: Form(
          key: key,
          child: Column(children: [
            const SizedBox(height: 2000),
            FormField<bool>(
              key: const ValueKey('choice'),
              validator: (_) => 'pick one',
              builder: (s) =>
                  SizedBox(height: 40, child: Text(s.errorText ?? '')),
            ),
          ]),
        ),
      )));
      expect(validateAndReveal(key), isFalse);
      await tester.pumpAndSettle();
      expect(_onScreen(tester, find.byKey(const ValueKey('choice'))), isTrue);
      expect(find.text('pick one'), findsOneWidget);
    });
  });

  group('adding an entry', () {
    for (final language in ['en', 'ar']) {
      testWidgets('$language: the new entry scrolls into view, focused',
          (tester) async {
        AppLocale.languageCode.value = language;
        final english = language == 'en';
        final text = TextEditingController();
        await tester.pumpWidget(_app(
          SingleChildScrollView(
            child: Column(children: [
              const SizedBox(height: 300),
              EntryListField<ExperienceEntry>(
                controller: text,
                english: english,
                autovalidateMode: AutovalidateMode.disabled,
                parse: parseExperience,
                serialize: (e) => serializeExperience(e, language),
                problems: experienceProblems,
                blank: const ExperienceEntry(),
                isBlank: (e) => e.isBlank,
                addLabel: 'Add',
                cardBuilder: (context, entry, onChanged, problems) =>
                    experienceCard(context, entry, onChanged, problems,
                        english: english),
              ),
            ]),
          ),
          direction: english ? TextDirection.ltr : TextDirection.rtl,
        ));
        await tester.pumpAndSettle();
        for (var added = 1; added <= 2; added++) {
          final add = find.byKey(const ValueKey('entry-add'));
          await tester.ensureVisible(add);
          await tester.pumpAndSettle();
          await tester.tap(add);
          await tester.pumpAndSettle();
          final cards = find.byWidgetPredicate(
              (w) => w.runtimeType.toString() == '_EntryCard');
          expect(cards, findsNWidgets(added + 1));
          final newest = cards.last;
          expect(_onScreen(tester, newest), isTrue, reason: 'entry $added');
          final focused = FocusManager.instance.primaryFocus;
          expect(focused, isNotNull);
          expect(
            find.descendant(
                of: newest,
                matching: find.byWidgetPredicate(
                    (w) => w is EditableText && w.focusNode == focused)),
            findsOneWidget,
            reason: 'the new entry has the focus',
          );
        }
      });
    }
  });
}
