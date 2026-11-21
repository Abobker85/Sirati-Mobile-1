// Ticket 14 (iOS 26 restyle round 2): the CV generator wizard on the grouped
// page. Every check runs on the real pumped screen, AR/EN x light/dark.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/storage/preference_store.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/application/cv_draft_store.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/draft_restore_banner.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_footer.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_header.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/cv_api_service.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

import '../../support/contrast_probe.dart';

class _FakeDraftStore extends CvDraftStore {
  _FakeDraftStore(this.draft) : super(const PreferenceStore());

  SavedCvDraft? draft;
  final saves = <(CvFormData, int)>[];
  var clears = 0;

  @override
  Future<SavedCvDraft?> read({required int stepCount}) async => draft;

  @override
  Future<void> save(CvFormData data, {required int step}) async =>
      saves.add((data, step));

  @override
  Future<void> clear() async {
    clears++;
    draft = null;
  }
}

class _FakeApi extends CvApiService {}

/// A form that passes every step's validation, in the CV's own language.
CvFormData _completeForm(String language) => CvFormData(
      fullName: 'Sara Ali',
      email: 'sara@example.com',
      phone: '+966 59 189 0300',
      targetJobTitle: 'Backend Developer',
      skills: 'Laravel, PHP, MySQL',
      summary: 'Backend developer building payment APIs.',
      experience: serializeExperience(const [
        ExperienceEntry(
          title: 'Backend Developer',
          company: 'Acme',
          start: YearMonth(2020, 1),
          current: true,
          description:
              'Built and ran payment APIs serving two million requests a day '
              'for retail clients across the region.',
        ),
      ], language),
      education: serializeEducation(const [
        EducationEntry(
          degree: 'BSc Computer Science',
          institution: 'King Saud University',
          start: YearMonth(2014, 9),
          end: YearMonth(2018, 6),
        ),
      ], language),
      language: language,
    );

const _arabicDigits = r'[٠-٩۰-۹]';

Future<void> _pump(
  WidgetTester tester, {
  required String language,
  required bool dark,
  SavedCvDraft? draft,
  Size size = const Size(390, 844),
  double textScale = 1,
  double keyboard = 0,
  _FakeDraftStore? store,
}) async {
  // A fresh screen each time: the wizard reads its draft once, in initState.
  await tester.pumpWidget(const SizedBox());
  AppLocale.languageCode.value = language;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final english = language == 'en';
  await tester.pumpWidget(ProviderScope(
    overrides: [
      cvApiServiceProvider.overrideWithValue(_FakeApi()),
      cvDraftStoreProvider.overrideWithValue(store ?? _FakeDraftStore(draft)),
    ],
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: !english)
          : AppTheme.lightFor(arabic: !english),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const CvGeneratorScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Opens [step] the way a user gets there with a saved draft: restore it.
Future<void> _restoreTo(WidgetTester tester, int step) async {
  final restore = find.descendant(
      of: find.byType(DraftRestoreBanner), matching: find.byType(FilledButton));
  await tester.ensureVisible(restore);
  await tester.pumpAndSettle();
  await tester.tap(restore);
  await tester.pumpAndSettle();
  expect(find.byType(DraftRestoreBanner), findsNothing);
  final l10n = AppLocalizations.of(tester.element(find.byType(WizardHeader)));
  expect(find.text(l10n.cvWizardStepOf(step + 1, 4)), findsOneWidget);
}

SavedCvDraft _draftAt(String language, int step) => SavedCvDraft(
      data: _completeForm(language),
      step: step,
      savedAt: null,
    );

/// Scrolls the step's list from top to bottom, calling [check] at every
/// stop (the top included) until the list can scroll no further.
Future<void> _scrollThrough(
    WidgetTester tester, void Function(int stop) check) async {
  final list = find.byType(ListView).last;
  final scrollable =
      find.descendant(of: list, matching: find.byType(Scrollable)).first;
  ScrollPosition position() =>
      tester.state<ScrollableState>(scrollable).position;
  var stop = 0;
  check(stop);
  while (position().pixels < position().maxScrollExtent) {
    final before = position().pixels;
    await tester.drag(list, const Offset(0, -250));
    await tester.pumpAndSettle();
    check(++stop);
    if (position().pixels == before) break;
  }
}

SiratiColors _colors(WidgetTester tester) =>
    tester.element(find.byType(WizardHeader)).sirati;

/// The colour the screen's [Scaffold] paints.
Color _pageColor(WidgetTester tester) => tester
    .widget<Material>(find
        .descendant(of: find.byType(Scaffold), matching: find.byType(Material))
        .first)
    .color!;

/// The Material a button paints (its rendered fill and shape).
Material _buttonMaterial(WidgetTester tester, Finder button) =>
    tester.widget<Material>(
        find.descendant(of: button, matching: find.byType(Material)).first);

void main() {
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      final tag = '$language ${dark ? 'dark' : 'light'}';

      testWidgets('$tag: grouped page, calm header, glass footer, banner card',
          (tester) async {
        await _pump(tester,
            language: language, dark: dark, draft: _draftAt(language, 2));
        final c = _colors(tester);

        // The page is the grouped page, and the header has no band of its
        // own: the first opaque paint under the step status is the page.
        expect(_pageColor(tester), c.groupedBackground);
        expect(
          paintedBackgroundsOf(
              tester.element(find.byKey(WizardHeader.statusKey))),
          [c.groupedBackground],
        );

        // Draft banner: a borderless card in the grouped card fill, and its
        // grey "Start fresh" capsule differs from the card it sits on.
        final card =
            tester.widget<Material>(find.byKey(DraftRestoreBanner.cardKey));
        expect(card.color, c.groupedCard);
        expect(card.color, isNot(_pageColor(tester)));
        expect((card.shape! as RoundedRectangleBorder).side, BorderSide.none);
        final startFresh = _buttonMaterial(
            tester,
            find.descendant(
                of: find.byType(DraftRestoreBanner),
                matching: find.byType(OutlinedButton)));
        expect(startFresh.color, isNot(card.color));
        expect(startFresh.shape, isA<StadiumBorder>());
        expect((startFresh.shape! as StadiumBorder).side, BorderSide.none);

        // Footer: a glass bar holding the Next capsule.
        final glass = find.byKey(WizardFooter.glassKey);
        expect(tester.widget(glass), isA<GlassSurface>());
        expect(tester.widget<GlassSurface>(glass).elevated, isFalse);
        final next =
            find.descendant(of: glass, matching: find.byType(ElevatedButton));
        final nextMaterial = _buttonMaterial(tester, next.last);
        expect(nextMaterial.shape, isA<StadiumBorder>());
        expect(nextMaterial.color, c.primary);

        expectAllTextAa('$tag step 1 with banner');
        expectAllProgressIndicatorsAa('$tag step 1 with banner');
      });

      testWidgets(
          '$tag: every step on the grouped page is AA, cards borderless',
          (tester) async {
        for (var step = 0; step < 4; step++) {
          await _pump(tester,
              language: language,
              dark: dark,
              draft: step == 0 ? null : _draftAt(language, step));
          if (step > 0) await _restoreTo(tester, step);
          final c = _colors(tester);
          expect(_pageColor(tester), c.groupedBackground);

          // Back is a grey capsule distinct from the glass behind it.
          if (step > 0) {
            final back = _buttonMaterial(
                tester,
                find.descendant(
                    of: find.byKey(WizardFooter.glassKey),
                    matching: find.byType(OutlinedButton)));
            expect(back.shape, isA<StadiumBorder>());
            expect((back.shape! as StadiumBorder).side, BorderSide.none);
            expect(back.color, c.cardFill);
          }

          // Every step groups its fields in borderless cards (sections or
          // entry cards) in the grouped card fill, and every field inside a
          // card fills with the other colour so it keeps an edge.
          final cards = find.byWidgetPredicate((w) =>
              w is WizardSection || w.runtimeType.toString() == '_EntryCard');
          expect(cards, findsWidgets, reason: 'step $step');
          for (final cardElement in cards.evaluate()) {
            final card = tester.widget<Material>(find
                .descendant(
                    of: find.byWidget(cardElement.widget),
                    matching: find.byType(Material))
                .first);
            expect(card.color, c.groupedCard);
            expect(
                (card.shape! as RoundedRectangleBorder).side, BorderSide.none);
            final fields = find.descendant(
                of: find.byWidget(cardElement.widget),
                matching: find.byType(TextField));
            for (final f in fields.evaluate()) {
              final fill = (f.widget as TextField).decoration!.fillColor;
              expect(fill, isNot(card.color), reason: 'step $step field');
            }
          }
          if (step == 0) {
            // All of step 1's text fields sit inside a section.
            expect(
                find.byType(TextField).evaluate().length,
                find
                    .descendant(
                        of: find.byType(WizardSection),
                        matching: find.byType(TextField))
                    .evaluate()
                    .length);
          }

          await _scrollThrough(tester, (stop) {
            final label = '$tag step ${step + 1} stop $stop';
            expectAllTextAa(label);
            expectAllIconsAa(label);
            expectAllProgressIndicatorsAa(label);
          });
        }
      });

      testWidgets('$tag: progress line is teal and holds 3:1 on its track',
          (tester) async {
        await _pump(tester, language: language, dark: dark);
        final c = _colors(tester);
        final boxes = tester
            .widgetList<ColoredBox>(find.descendant(
                of: find.byType(WizardProgressBar),
                matching: find.byType(ColoredBox)))
            .toList();
        final track = boxes.first.color;
        final fill = boxes.last.color;
        expect(fill, c.primaryInk);
        final page = _pageColor(tester);
        expect(
          AppContrast.ratio(
              Color.alphaBlend(fill, page), Color.alphaBlend(track, page)),
          greaterThanOrEqualTo(3),
        );
      });
    }

    testWidgets('$language: step progress is announced, in Latin digits',
        (tester) async {
      final semantics = tester.ensureSemantics();
      for (var step = 0; step < 4; step++) {
        await _pump(tester,
            language: language,
            dark: false,
            draft: step == 0 ? null : _draftAt(language, step));
        if (step > 0) await _restoreTo(tester, step);
        final l10n =
            AppLocalizations.of(tester.element(find.byType(WizardHeader)));
        final title = wizardStepTitles(l10n)[step];
        final node = tester.getSemantics(find.byKey(WizardHeader.statusKey));
        final data = node.getSemanticsData();
        expect(data.flagsCollection.isLiveRegion, isTrue);
        expect(data.label, contains(title));
        expect(data.label, contains('${step + 1}'));
        expect(data.label, contains('4'));
        expect(RegExp(_arabicDigits).hasMatch(data.label), isFalse,
            reason: data.label);
        final count = l10n.cvWizardStepOf(step + 1, 4);
        expect(find.text(count), findsOneWidget);
        expect(RegExp(_arabicDigits).hasMatch(count), isFalse, reason: count);
      }
      semantics.dispose();
    });
  }

  // Behaviour the restyle must not change: autosave after an edit, Start
  // fresh clearing the draft, restore landing on the saved step.
  for (final language in ['ar', 'en']) {
    testWidgets('$language: autosave, start fresh and restore still work',
        (tester) async {
      final store = _FakeDraftStore(_draftAt(language, 2));
      await _pump(tester, language: language, dark: false, store: store);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(WizardHeader)));

      await tester.tap(find.text(l10n.cvDraftStartFresh));
      await tester.pumpAndSettle();
      expect(store.clears, 1);
      expect(find.byType(DraftRestoreBanner), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Sara Ali');
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(store.saves, isNotEmpty);
      expect(store.saves.last.$1.fullName, 'Sara Ali');
      expect(store.saves.last.$2, 0);
    });
  }

  // 320x568 at text scale 1.3 with the keyboard up: nothing overflows and
  // the footer's primary button stays on screen and takes the tap.
  group('small phone, keyboard open', () {
    const size = Size(320, 568);
    const keyboard = 260.0;

    void expectFooterReachable(WidgetTester tester) {
      final button = find.byType(SubmitButton).last;
      final rect = tester.getRect(button);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(size.height - keyboard));
      expect(button.hitTestable(), findsOneWidget);
    }

    for (final language in ['ar', 'en']) {
      testWidgets('$language: step 1 with the draft banner', (tester) async {
        await _pump(tester,
            language: language,
            dark: false,
            draft: _draftAt(language, 2),
            size: size,
            textScale: 1.3,
            keyboard: keyboard);
        expect(tester.takeException(), isNull);
        expect(find.byType(DraftRestoreBanner), findsOneWidget);
        expect(find.byKey(WizardHeader.dotsKey), findsNothing,
            reason: 'the dot row folds while the keyboard is open');
        expectFooterReachable(tester);

        // Empty form: the tap runs validation and names what to fix.
        await tester.tap(find.byType(SubmitButton).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AppFormErrorBanner), findsOneWidget);
        expectFooterReachable(tester);
      });

      for (var step = 0; step < 4; step++) {
        testWidgets('$language: step ${step + 1} advances from the footer',
            (tester) async {
          await _pump(tester,
              language: language,
              dark: false,
              draft: _draftAt(language, step),
              size: size,
              textScale: 1.3,
              keyboard: keyboard);
          // Restore needs the step; step 1 restores onto itself.
          await _restoreTo(tester, step);
          expect(tester.takeException(), isNull);
          expectFooterReachable(tester);
          // Nothing overflows anywhere on the step, not just in view.
          await _scrollThrough(tester, (stop) {
            expect(tester.takeException(), isNull, reason: 'stop $stop');
            expectFooterReachable(tester);
          });
          if (step == 3) return; // Generate starts a network request.

          await tester.tap(find.byType(SubmitButton).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final l10n =
              AppLocalizations.of(tester.element(find.byType(WizardHeader)));
          expect(find.text(l10n.cvWizardStepOf(step + 2, 4)), findsOneWidget);
          expectFooterReachable(tester);
        });
      }
    }

    // The general case: every text scale up to 2.0, keyboard up or down,
    // every step scrolled end to end. Nothing overflows (header, step or
    // footer), the footer's primary button stays on screen and takes taps.
    for (final language in ['ar', 'en']) {
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        for (final kb in [0.0, keyboard]) {
          testWidgets(
              '$language x$scale ${kb > 0 ? 'keyboard open' : 'keyboard closed'}: '
              'every step fits', (tester) async {
            for (var step = 0; step < 4; step++) {
              await _pump(tester,
                  language: language,
                  dark: false,
                  draft: step == 0 ? null : _draftAt(language, step),
                  size: size,
                  textScale: scale,
                  keyboard: kb);
              if (step > 0) await _restoreTo(tester, step);
              expect(tester.takeException(), isNull, reason: 'step $step');
              await _scrollThrough(tester, (stop) {
                expect(tester.takeException(), isNull,
                    reason: 'step ${step + 1} stop $stop');
                final button = find.byType(SubmitButton).last;
                expect(button.hitTestable(), findsOneWidget);
                final rect = tester.getRect(button);
                expect(rect.top, greaterThanOrEqualTo(0));
                expect(rect.bottom, lessThanOrEqualTo(size.height - kb));
              });
            }
          });
        }
      }

      // Text resizable to 200%: with the keyboard closed the header and
      // footer are painted at the user's full size (the 1.5 cap is only for
      // the half screen left above a keyboard), and nothing overflows.
      testWidgets(
          '$language: keyboard closed at x2.0, chrome text is full size',
          (tester) async {
        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d.exceptionAsString());
        addTearDown(() => FlutterError.onError = old);
        for (var step = 0; step < 4; step++) {
          await _pump(tester,
              language: language,
              dark: false,
              draft: step == 0 ? null : _draftAt(language, step),
              size: size,
              textScale: 2.0);
          if (step > 0) await _restoreTo(tester, step);
          for (final part in [
            find.byKey(WizardHeader.statusKey),
            find.byKey(WizardFooter.glassKey),
          ]) {
            final paragraphs =
                find.descendant(of: part, matching: find.byType(Text));
            expect(paragraphs, findsWidgets);
            for (final e in paragraphs.evaluate()) {
              final scaler = paragraphOf(e.renderObject!).textScaler;
              expect(scaler.scale(10), 20, reason: 'step ${step + 1}');
            }
          }
          expect(errors, isEmpty, reason: 'step ${step + 1}');
        }
        FlutterError.onError = old;
      });

      testWidgets('$language: keyboard open at x2.0, chrome text is capped',
          (tester) async {
        await _pump(tester,
            language: language,
            dark: false,
            size: size,
            textScale: 2.0,
            keyboard: keyboard);
        for (final part in [
          find.byKey(WizardHeader.statusKey),
          find.byKey(WizardFooter.glassKey),
        ]) {
          for (final e in find
              .descendant(of: part, matching: find.byType(Text))
              .evaluate()) {
            final scaler = paragraphOf(e.renderObject!).textScaler;
            expect(scaler.scale(10), 10 * WizardHeader.maxChromeTextScale);
          }
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('$language: keyboard closed at x1.3, the dots are shown',
          (tester) async {
        for (var step = 0; step < 4; step++) {
          await _pump(tester,
              language: language,
              dark: false,
              draft: step == 0 ? null : _draftAt(language, step),
              size: size,
              textScale: 1.3);
          if (step > 0) await _restoreTo(tester, step);
          // Shown means painted and tappable, not just in the tree.
          final dotIcons = find.descendant(
              of: find.byKey(WizardHeader.dotsKey),
              matching: find.byType(Icon));
          expect(dotIcons, findsNWidgets(4));
          for (final e in dotIcons.evaluate()) {
            expect(find.byWidget(e.widget).hitTestable(), findsOneWidget,
                reason: 'step ${step + 1}');
          }
        }
      });
    }
  });
}
