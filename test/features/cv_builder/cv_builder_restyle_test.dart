import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/data/cv_repository.dart';
import 'package:sirati/features/cv_builder/data/cv_repository_provider.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder/section_order_tab.dart';
import 'package:sirati/features/cv_builder/presentation/cv_builder_screen.dart';
import 'package:sirati/features/cv_builder/presentation/experience_education_editor.dart';
import 'package:sirati/features/cv_builder/presentation/personal_details_editor.dart';
import 'package:sirati/features/cv_builder/presentation/section_editor_framework.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_document.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

import '../../support/app_screens.dart';
import '../../support/contrast_probe.dart';

/// iOS 26 restyle of the CV builder (ticket 15): segmented tabs, grouped
/// editor page, flat entry rows, segmented language and calendar switches.

const _languages = ['ar', 'en'];

Future<CvDocument> _doc() async =>
    CvDocument.createEmpty(id: 'cv1', title: 'CV');

Future<void> _pump(
  WidgetTester tester, {
  String language = 'en',
  bool dark = false,
  bool reduceMotion = false,
  Size size = const Size(390, 844),
  double textScale = 1,
  CvDocument? document,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  AppLocale.languageCode.value = language;
  final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
  await repo.saveCv(document ?? await _doc());
  final arabic = language == 'ar';
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [cvRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: arabic)
          : AppTheme.lightFor(arabic: arabic),
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: const CvBuilderScreen(cvId: 'cv1'),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<AppLocalizations> _l10n(String language) =>
    AppLocalizations.delegate.load(Locale(language));

List<String> _tabLabels(AppLocalizations l) =>
    [l.tabPersonal, l.tabExperience, l.tabSkills, l.tabOrder];

Finder _tabLabel(String label) => find.descendant(
      of: find.byKey(CvBuilderScreen.tabBarKey),
      matching: find.text(label),
    );

/// The tappable segment holding [label] in the tab bar.
Finder _segment(String label) => find
    .ancestor(of: _tabLabel(label), matching: find.byType(GestureDetector))
    .first;

TabController _controller(WidgetTester tester) =>
    tester.widget<TabBarView>(find.byType(TabBarView)).controller!;

Rect _thumb(WidgetTester tester) => tester.getRect(find.descendant(
    of: find.byKey(CvBuilderScreen.tabBarKey),
    matching: find.byKey(SegmentedTrack.thumbKey)));

/// The thumb sits under the [index]th segment, whichever the direction.
void _expectThumbUnder(
    WidgetTester tester, List<String> labels, int index, String reason) {
  final thumb = _thumb(tester);
  final segment = tester.getRect(_segment(labels[index]));
  expect((thumb.center.dx - segment.center.dx).abs(), lessThan(2),
      reason: reason);
}

/// The selected tab as a screen reader reports it.
bool _announcedSelected(WidgetTester tester, String label) =>
    tester.getSemantics(_segment(label)).flagsCollection.isSelected ==
    Tristate.isTrue;

/// The page each tab shows (one stable widget per page).
const _pageTypes = [
  PersonalDetailsEditor,
  ExperienceEducationEditor,
  null, // skills editor: checked through the controller index
  SectionOrderTab,
];

void _expectPageShown(WidgetTester tester, int index, String reason) {
  final type = _pageTypes[index];
  if (type == null) return;
  // The page is in place: its start edge sits at the page padding, not
  // part-way through a slide.
  final page = tester.getRect(find.byType(type));
  final view = tester.getRect(find.byType(TabBarView));
  expect(page.left - view.left, closeTo(AppSpacing.md, 0.5), reason: reason);
}

void main() {
  setUpAll(loadAppFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('builder tabs are the shared segmented control', () {
    for (final language in _languages) {
      testWidgets(
          '$language: tap and swipe keep thumb, page and selection in '
          'sync', (tester) async {
        await _pump(tester, language: language);
        final l = await _l10n(language);
        final labels = _tabLabels(l);
        expect(find.byType(TabBar), findsNothing);
        expect(find.byType(AppSegmentedTabBar), findsOneWidget);
        // Labels only: no icon competes for the ~80dp segment.
        expect(
            find.descendant(
                of: find.byKey(CvBuilderScreen.tabBarKey),
                matching: find.byType(Icon)),
            findsNothing);

        final controller = _controller(tester);
        for (final index in [2, 0, 3, 1]) {
          await tester.tap(_segment(labels[index]));
          await tester.pumpAndSettle();
          expect(controller.index, index, reason: 'tap $index');
          _expectThumbUnder(tester, labels, index, 'tap $index');
          _expectPageShown(tester, index, 'tap $index');
          for (var i = 0; i < labels.length; i++) {
            expect(_announcedSelected(tester, labels[i]), i == index,
                reason: 'semantics after tap $index, tab $i');
          }
        }

        // Swipe the pages one step toward the end of the reading order:
        // leftwards in LTR, rightwards in RTL.
        final forward = language == 'ar' ? 1.0 : -1.0;
        await tester.fling(
            find.byType(TabBarView), Offset(300 * forward, 0), 1000);
        await tester.pumpAndSettle();
        expect(controller.index, 2, reason: 'swipe forward');
        _expectThumbUnder(tester, labels, 2, 'swipe forward');
        expect(_announcedSelected(tester, labels[2]), isTrue);
        expect(_announcedSelected(tester, labels[1]), isFalse);

        await tester.fling(
            find.byType(TabBarView), Offset(-300 * forward, 0), 1000);
        await tester.pumpAndSettle();
        expect(controller.index, 1, reason: 'swipe back');
        _expectThumbUnder(tester, labels, 1, 'swipe back');
      });

      testWidgets('$language: reduced motion jumps the page with the thumb',
          (tester) async {
        await _pump(tester, language: language, reduceMotion: true);
        final labels = _tabLabels(await _l10n(language));
        final controller = _controller(tester);
        expect(controller.animationDuration, Duration.zero);
        for (final index in [3, 0, 1, 3]) {
          await tester.tap(_segment(labels[index]));
          await tester.pump();
          expect(controller.index, index);
          expect(controller.indexIsChanging, isFalse,
              reason: 'no page slide under reduced motion');
          _expectThumbUnder(tester, labels, index, 'reduced $index');
          _expectPageShown(tester, index, 'one frame after tap $index');
        }
      });

      testWidgets('$language: with motion the page slides after a tap',
          (tester) async {
        await _pump(tester, language: language);
        final labels = _tabLabels(await _l10n(language));
        final controller = _controller(tester);
        expect(controller.animationDuration, greaterThan(Duration.zero));
        await tester.tap(_segment(labels[3]));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        final mid = controller.animation!.value;
        expect(mid, inExclusiveRange(0, 3), reason: 'pages mid-slide');
        await tester.pumpAndSettle();
        expect(controller.index, 3);
        _expectPageShown(tester, 3, 'after the slide');
      });
    }

    testWidgets(
        'turning reduced motion on keeps the open tab and stops '
        'the slide', (tester) async {
      final repo = LocalCvRepository(engine: MemoryCvStorageEngine());
      await repo.saveCv(await _doc());
      final reduce = ValueNotifier(false);
      addTearDown(reduce.dispose);
      AppLocale.languageCode.value = 'en';
      await tester.pumpWidget(ProviderScope(
        overrides: [cvRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: reduce,
            builder: (context, value, _) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: value),
              child: child!,
            ),
          ),
          home: const CvBuilderScreen(cvId: 'cv1'),
        ),
      ));
      await tester.pumpAndSettle();
      final labels = _tabLabels(await _l10n('en'));
      await tester.tap(_segment(labels[2]));
      await tester.pumpAndSettle();

      reduce.value = true;
      await tester.pumpAndSettle();
      final controller = _controller(tester);
      expect(controller.index, 2, reason: 'open tab kept');
      expect(controller.animationDuration, Duration.zero);
      await tester.tap(_segment(labels[0]));
      await tester.pump();
      _expectPageShown(tester, 0, 'jumps after the switch');

      reduce.value = false;
      await tester.pumpAndSettle();
      expect(_controller(tester).index, 0);
      expect(_controller(tester).animationDuration, greaterThan(Duration.zero));
      expect(tester.takeException(), isNull);
    });

    for (final language in _languages) {
      testWidgets('$language: every tab label is whole at 320dp and 130% text',
          (tester) async {
        await _pump(tester,
            language: language, size: const Size(320, 640), textScale: 1.3);
        expect(tester.takeException(), isNull);
        for (final label in _tabLabels(await _l10n(language))) {
          final paragraph = paragraphOf(tester.renderObject(_tabLabel(label)));
          expect(paragraph.didExceedMaxLines, isFalse,
              reason: '"$label" is cut off');
          final segment = tester.getSize(_segment(label));
          expect(segment.height, greaterThanOrEqualTo(44));
        }
      });
    }
  });

  group('editors sit on a grouped page', () {
    for (final language in _languages) {
      for (final dark in [false, true]) {
        final label = '$language/${dark ? 'dark' : 'light'}';

        testWidgets(
            '$label: grouped page, white bar, no bordered or warm '
            'boxes, every text AA', (tester) async {
          await _pump(tester, language: language, dark: dark);
          final context = tester.element(find.byType(PersonalDetailsEditor));
          final c = context.sirati;
          final scaffold = tester.widget<Scaffold>(find
              .ancestor(
                  of: find.byType(TabBarView), matching: find.byType(Scaffold))
              .first);
          final page = scaffold.backgroundColor ??
              Theme.of(tester.element(find.byType(TabBarView)))
                  .scaffoldBackgroundColor;
          expect(page, c.groupedBackground);
          final bar = tester.widget<AppBar>(find.byType(AppBar));
          expect(bar.backgroundColor, AppTheme.barColor(c, c.pageBackground),
              reason: 'the segmented track sits on the white bar');

          final labels = _tabLabels(await _l10n(language));
          for (var i = 0; i < labels.length; i++) {
            await tester.tap(_segment(labels[i]));
            await tester.pumpAndSettle();
            _expectNoBoxedEditors(tester, c, '$label tab $i');
            expectAllTextAa('$label tab $i');
          }
        });
      }
    }

    testWidgets(
        'language switch is the shared segmented control and still '
        'shows and hides the fields', (tester) async {
      for (final language in _languages) {
        await _pump(tester, language: language);
        final l = await _l10n(language);
        final control = find.byKey(PersonalDetailsEditor.languageModeKey);
        expect(tester.widget(control), isA<AppSegmentedControl<String>>());
        expect(find.byType(SegmentedButton<String>), findsNothing);

        final both = find.byType(TextField).evaluate().length;
        await tester.tap(find.descendant(
            of: control, matching: find.text(l.languageModeEnOnly)));
        await tester.pumpAndSettle();
        final enOnly = find.byType(TextField).evaluate().length;
        expect(enOnly, lessThan(both), reason: '$language: AR fields hidden');
        expect(find.text(l.fullNameAr), findsNothing);
        expect(find.text(l.fullNameEn), findsOneWidget);

        await tester.tap(find.descendant(
            of: control, matching: find.text(l.languageModeArOnly)));
        await tester.pumpAndSettle();
        expect(find.text(l.fullNameAr), findsOneWidget);
        expect(find.text(l.fullNameEn), findsNothing);

        await tester.tap(find.descendant(
            of: control, matching: find.text(l.languageModeDual)));
        await tester.pumpAndSettle();
        expect(find.byType(TextField).evaluate().length, both);
      }
    });

    testWidgets('calendar switch is the shared segmented control',
        (tester) async {
      await _pump(tester);
      final l = await _l10n('en');
      await tester.tap(_segment(l.tabExperience));
      await tester.pumpAndSettle();
      final control = find.byKey(ExperienceEducationEditor.calendarModeKey);
      final widget = tester.widget<AppSegmentedControl<String>>(control);
      expect(widget.value, 'gregorian');
      await tester.tap(
          find.descendant(of: control, matching: find.text(l.calendarHijri)));
      await tester.pumpAndSettle();
      expect(
          tester.widget<AppSegmentedControl<String>>(control).value, 'hijri');
    });

    testWidgets(
        'section order: one white card of flat rows; reordering '
        'still works', (tester) async {
      await _pump(tester);
      final l = await _l10n('en');
      await tester.tap(_segment(l.tabOrder));
      await tester.pumpAndSettle();
      final c = tester.element(find.byType(SectionOrderTab)).sirati;
      final card = tester.widget<DecoratedBox>(find
          .descendant(
              of: find.byKey(SectionOrderTab.listCardKey),
              matching: find.byType(DecoratedBox))
          .first);
      expect((card.decoration as BoxDecoration).color, c.groupedCard);

      final controller = tester
          .widget<SectionOrderTab>(find.byType(SectionOrderTab))
          .controller;
      final before = List.of(
          controller.document.sectionOrder ?? CvDocument.defaultSectionOrder);
      await tester.tap(find.byTooltip(l.moveDown).first);
      await tester.pumpAndSettle();
      final after = controller.document.sectionOrder!;
      expect(after[0], before[1]);
      expect(after[1], before[0]);
    });

    for (final language in _languages) {
      for (final dark in [false, true]) {
        final label = '$language/${dark ? 'dark' : 'light'}';
        testWidgets(
            '$label: entries are flat rows split by hairlines, AA with '
            'content; drag, move and delete still work', (tester) async {
          await _pump(tester, language: language, dark: dark);
          final l = await _l10n(language);
          await tester.tap(_segment(l.tabExperience));
          await tester.pumpAndSettle();
          final editor = find.byType(ExperienceEducationEditor);
          final addExperience =
              find.descendant(of: editor, matching: find.text(l.addExperience));
          for (var i = 0; i < 3; i++) {
            await tester.ensureVisible(addExperience);
            await tester.pumpAndSettle();
            await tester.tap(addExperience);
            await tester.pumpAndSettle();
          }
          // Content in every state an entry can show: a current role, a
          // date error and an achievement bullet.
          final current =
              find.descendant(of: editor, matching: find.byType(Checkbox));
          await tester.ensureVisible(current.first);
          await tester.tap(current.first);
          await tester.pumpAndSettle();
          final c = tester.element(editor).sirati;
          final list = find
              .descendant(
                  of: editor, matching: find.byType(ReorderableListView))
              .first;
          final hairlines = tester
              .widgetList<Container>(
                  find.descendant(of: list, matching: find.byType(Container)))
              .map((w) => w.decoration)
              .whereType<BoxDecoration>()
              .where((d) =>
                  d.border is Border &&
                  (d.border! as Border).bottom.color == c.separator)
              .length;
          expect(hairlines, 2, reason: 'n-1 hairlines between 3 entries');
          _expectNoBoxedEditors(tester, c, '$label with entries');
          expect(find.text('3'), findsWidgets, reason: 'entry count badge');
          expectAllTextAa('$label entries');

          // A lifted row hides what it is dragged over.
          final handle = find
              .descendant(of: list, matching: find.byIcon(Icons.drag_indicator))
              .first;
          await tester.ensureVisible(handle);
          await tester.pumpAndSettle();
          final drag = await tester.startGesture(tester.getCenter(handle));
          await tester.pump(const Duration(milliseconds: 50));
          await drag.moveBy(const Offset(0, 40));
          await tester.pump(const Duration(milliseconds: 300));
          final proxy = tester.widget<Material>(find.byKey(reorderProxyKey));
          expect(proxy.color, c.groupedCard);
          expect(proxy.color!.a, 1.0, reason: 'opaque lifted row');
          await drag.up();
          await tester.pumpAndSettle();

          final delete = find.descendant(
              of: editor, matching: find.byTooltip(l.deleteItem));
          expect(delete, findsNWidgets(3));
          await tester.ensureVisible(delete.first);
          await tester.tap(delete.first);
          await tester.pumpAndSettle();
          expect(
              find.descendant(
                  of: editor, matching: find.byTooltip(l.deleteItem)),
              findsNWidgets(2));
        });
      }
    }

    testWidgets('a section header still collapses and expands its fields',
        (tester) async {
      for (final reduce in [false, true]) {
        await _pump(tester, reduceMotion: reduce);
        final header = find.byKey(SectionCardWrapper.headerKey).first;
        final l = await _l10n('en');
        expect(find.text(l.fullNameEn), findsOneWidget);
        await tester.tap(header);
        await tester.pumpAndSettle();
        expect(find.text(l.fullNameEn), findsNothing, reason: 'reduce=$reduce');
        await tester.tap(header);
        await tester.pumpAndSettle();
        expect(find.text(l.fullNameEn), findsOneWidget);
      }
    });
  });
}

/// No editor box paints a full outline or a warm-grey fill: entries are flat
/// rows, cards are the white grouped card.
void _expectNoBoxedEditors(WidgetTester tester, SiratiColors c, String label) {
  final warm = {c.surfaceLow, c.surfaceContainer, c.surfaceHigh};
  final view = find.byType(TabBarView);
  // The shared segmented control paints its own track and thumb (ticket 11
  // proved those); everything else in the editors is checked.
  bool inSegmented(Element e) {
    var found = false;
    e.visitAncestorElements((a) {
      found = a.widget is SegmentedTrack;
      return !found;
    });
    return found;
  }

  final decorations = <BoxDecoration>[
    for (final e in find
        .descendant(
            of: view,
            matching: find
                .byWidgetPredicate((w) => w is Container || w is DecoratedBox))
        .evaluate())
      if (!inSegmented(e))
        if (switch (e.widget) {
          Container(:final decoration) => decoration,
          DecoratedBox(:final decoration) => decoration,
          _ => null,
        }
            case final BoxDecoration d)
          d,
  ];
  for (final d in decorations) {
    expect(warm.contains(d.color), isFalse,
        reason: '$label: warm-grey fill ${d.color}');
    final border = d.border;
    if (border is Border) {
      expect(border.isUniform && border.top.style != BorderStyle.none, isFalse,
          reason: '$label: boxed outline $border');
    }
  }
  for (final chip in tester.widgetList<Chip>(
      find.descendant(of: view, matching: find.byType(Chip)))) {
    expect(chip.side, isNull, reason: '$label: chips use the theme capsule');
    expect(chip.backgroundColor, isNull);
  }
}
