import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';

/// Inside a capped sheet (not scroll controlled) the sheet owns vertical
/// scrolling, but a horizontal list and a multi-line field keep scrolling on
/// their own, none of them given physics by the caller.

const _horizontalKey = ValueKey('nested-horizontal');
const _fieldKey = ValueKey('nested-field');
const _tallKey = ValueKey('nested-tall');
const _boundedKey = ValueKey('nested-bounded');

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required double textScale,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightFor(arabic: locale.languageCode == 'ar'),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showGlassBottomSheet<void>(
              context: context,
              builder: (_) => const _Content(),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

/// Content taller than the cap: a horizontal list, a multi-line field with
/// more lines than it shows, and a tall vertical list with no physics.
class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 80,
          child: ListView.builder(
            key: _horizontalKey,
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            itemBuilder: (_, i) => SizedBox(
              width: 120,
              child: Center(child: Text('Chip $i')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            key: _fieldKey,
            minLines: 2,
            maxLines: 3,
            controller: TextEditingController(
              text: [for (var i = 0; i < 20; i++) 'Line $i'].join('\n'),
            ),
          ),
        ),
        ListView(
          key: _tallKey,
          shrinkWrap: true,
          children: [
            for (var i = 0; i < 12; i++)
              SizedBox(height: 60, child: Text('Row $i')),
          ],
        ),
        SizedBox(
          height: 100,
          child: ListView(
            key: _boundedKey,
            children: [
              for (var i = 0; i < 8; i++)
                SizedBox(height: 40, child: Text('Item $i')),
            ],
          ),
        ),
      ],
    );
  }
}

/// The scroll position of the [Scrollable] directly under [owner].
ScrollPosition _position(WidgetTester tester, Finder owner) => tester
    .state<ScrollableState>(
      find.descendant(of: owner, matching: find.byType(Scrollable)).first,
    )
    .position;

/// The sheet's own scroll: the nearest scrollable above the sheet's content.
ScrollPosition _sheetPosition(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .ancestor(
            of: find.byKey(_horizontalKey),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// No scrollable in the sheet sits outside its own extent: a list that
/// drifts past its end is not a scroll, it is a list taking a drag it has
/// no room for.
void _expectInBounds(WidgetTester tester) {
  final states = tester.stateList<ScrollableState>(
    find.descendant(
      of: find.byType(GlassSurface).last,
      matching: find.byType(Scrollable),
    ),
  );
  expect(states, isNotEmpty);
  for (final s in states) {
    final p = s.position;
    expect(p.pixels, greaterThanOrEqualTo(p.minScrollExtent),
        reason: '${s.widget.axisDirection} list above its start');
    expect(p.pixels, lessThanOrEqualTo(p.maxScrollExtent),
        reason: '${s.widget.axisDirection} list past its end');
  }
}

/// Android (the test default) and iOS, whose lists bounce.
const _platforms = TargetPlatformVariant(
  {TargetPlatform.android, TargetPlatform.iOS},
);

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final textScale in const [1.0, 1.3]) {
      final label = '${locale.languageCode} x$textScale at 320x568';

      testWidgets('$label: a horizontal list scrolls sideways', (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final list = find.byKey(_horizontalKey);
        final position = _position(tester, list);
        expect(position.maxScrollExtent, greaterThan(0));
        final rtl =
            Directionality.of(tester.element(list)) == TextDirection.rtl;
        // Forward is toward the end side: left in English, right in Arabic.
        await tester.drag(list, Offset(rtl ? 200 : -200, 0));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
        expect(_sheetPosition(tester).pixels, 0,
            reason: 'a sideways drag leaves the sheet where it is');
        _expectInBounds(tester);
      }, variant: _platforms);

      testWidgets('$label: a multi-line field scrolls its text',
          (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final field = find.byKey(_fieldKey);
        final position = _position(tester, field);
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.drag(field, const Offset(0, -40));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
        _expectInBounds(tester);
      }, variant: _platforms);

      testWidgets('$label: a drag on a vertical list scrolls the sheet',
          (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final sheet = _sheetPosition(tester);
        expect(sheet.maxScrollExtent, greaterThan(0));
        final last = find.text('Row 11');
        expect(tester.getRect(last).bottom, greaterThan(568),
            reason: 'starts below the screen, so scrolling is needed');
        // Each drag starts on a row of the list that is on screen.
        for (var i = 0; i < 20 && tester.getRect(last).bottom > 568; i++) {
          final onScreen = find.descendant(
            of: find.byKey(_tallKey),
            matching: find.byWidgetPredicate(
                (w) => w is Text && (w.data ?? '').startsWith('Row ')),
          );
          final from = tester.getCenter(onScreen.hitTestable().first);
          final before = sheet.pixels;
          await tester.dragFrom(from, const Offset(0, -120));
          await tester.pumpAndSettle();
          _expectInBounds(tester);
          expect(sheet.pixels, greaterThan(before));
        }
        expect(tester.getRect(last).bottom, lessThanOrEqualTo(568));
        // The list itself never moved; the sheet did.
        expect(_position(tester, find.byKey(_tallKey)).pixels, 0);
      }, variant: _platforms);

      testWidgets(
          '$label: a vertical drag on the horizontal list scrolls '
          'the sheet', (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final sheet = _sheetPosition(tester);
        await tester.drag(find.byKey(_horizontalKey), const Offset(0, -120));
        await tester.pumpAndSettle();
        expect(sheet.pixels, greaterThan(0));
        _expectInBounds(tester);
      }, variant: _platforms);

      testWidgets(
          '$label: a vertical list held shorter than its content '
          'scrolls itself', (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final list = find.byKey(_boundedKey);
        await tester.ensureVisible(list);
        await tester.pumpAndSettle();
        final position = _position(tester, list);
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.drag(list, const Offset(0, -60));
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
        _expectInBounds(tester);
      }, variant: _platforms);

      testWidgets('$label: swipe down closes', (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final glass = tester.getRect(find.byType(GlassSurface).last);
        await tester.flingFrom(
          Offset(glass.center.dx, glass.top + 20),
          const Offset(0, 400),
          2000,
        );
        await tester.pumpAndSettle();
        expect(find.byKey(_horizontalKey), findsNothing);
      }, variant: _platforms);

      testWidgets('$label: the X closes', (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        await tester.tap(find.byKey(const ValueKey('sheet-close')));
        await tester.pumpAndSettle();
        expect(find.byKey(_horizontalKey), findsNothing);
      }, variant: _platforms);
    }
  }
}
