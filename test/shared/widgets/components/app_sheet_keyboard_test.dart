import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';

/// In a capped sheet (not scroll controlled), a field focused anywhere in a
/// shrink-wrapped list ends up fully visible above the keyboard, the way a
/// phone does it: the field takes focus first, then the keyboard rises.

const _screen = Size(320, 568);

/// A small phone's keyboard with its suggestion bar.
const _keyboard = 260.0;

/// Where the fields sit among the list's rows: first, middle and last.
const _fieldRows = [0, 5, 10];

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  required double textScale,
}) async {
  tester.view.physicalSize = _screen;
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
              builder: (_) => ListView(
                shrinkWrap: true,
                children: [
                  for (var i = 0; i <= 10; i++)
                    _fieldRows.contains(i)
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: TextField(key: ValueKey('field-$i')),
                          )
                        : SizedBox(height: 60, child: Text('Row $i')),
                ],
              ),
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

/// The sheet's own scroll view: the outermost scrollable in the sheet.
Finder get _sheetScroll => find
    .descendant(
      of: find.byType(GlassSurface).last,
      matching: find.byType(Scrollable),
    )
    .first;

void _expectInBounds(WidgetTester tester) {
  for (final s in tester.stateList<ScrollableState>(
    find.descendant(
      of: find.byType(GlassSurface).last,
      matching: find.byType(Scrollable),
    ),
  )) {
    final p = s.position;
    expect(p.pixels, inInclusiveRange(p.minScrollExtent, p.maxScrollExtent));
  }
}

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final textScale in const [1.0, 1.3]) {
      final label = '${locale.languageCode} x$textScale at 320x568';

      for (final row in _fieldRows) {
        testWidgets('$label: a field at row $row shows above the keyboard',
            (tester) async {
          await _pump(tester, locale: locale, textScale: textScale);
          final field = find.byKey(ValueKey('field-$row'));
          await tester.showKeyboard(field);
          await tester.pumpAndSettle();
          tester.view.viewInsets =
              const FakeViewPadding(bottom: _keyboard);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final keyboardTop = _screen.height - _keyboard;
          final rect = tester.getRect(field);
          final viewport = tester.getRect(_sheetScroll);
          expect(rect.top, greaterThanOrEqualTo(viewport.top),
              reason: 'not hidden under the top of the sheet');
          expect(rect.bottom, lessThanOrEqualTo(keyboardTop),
              reason: 'not hidden behind the keyboard');
          expect(viewport.bottom, lessThanOrEqualTo(keyboardTop),
              reason: 'the sheet scrolls only what is above the keyboard');
          _expectInBounds(tester);

          // The sheet still scrolls with the keyboard up.
          final sheet = tester.state<ScrollableState>(_sheetScroll).position;
          expect(sheet.maxScrollExtent, greaterThan(0));
          await tester.dragFrom(
            tester.getCenter(find.byType(GlassSurface).last),
            Offset(0, sheet.pixels > 0 ? 80 : -80),
          );
          await tester.pumpAndSettle();
          _expectInBounds(tester);
        });
      }

      testWidgets('$label: without the keyboard the sheet keeps its cap',
          (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final glass = tester.getRect(find.byType(GlassSurface).last);
        expect(glass.bottom, _screen.height);
        expect(
          glass.height,
          lessThanOrEqualTo(
            _screen.height * appSheetContentHeightRatio +
                AppSpacing.md +
                kMinInteractiveDimension,
          ),
        );
      });

      testWidgets('$label: the keyboard going down gives the height back',
          (tester) async {
        await _pump(tester, locale: locale, textScale: textScale);
        final before = tester.getRect(_sheetScroll);
        await tester.showKeyboard(find.byKey(const ValueKey('field-10')));
        tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
        await tester.pumpAndSettle();
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(tester.getRect(_sheetScroll), before);
        _expectInBounds(tester);
      });
    }
  }
}
