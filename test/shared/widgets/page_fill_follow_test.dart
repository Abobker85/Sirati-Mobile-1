import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';
import 'package:sirati/shared/widgets/empty_state.dart';

import '../../support/contrast_probe.dart';

/// Ticket 23: disabled filled buttons, list-section cards and state circles
/// take the page's fill, so each keeps a visible shape on plain and grouped
/// pages in both themes, and none of them is a warm grey.

/// A warm grey leans red/yellow: its red channel is above its blue one.
bool _isWarm(Color color) => color.r > color.b;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required bool dark,
  required bool grouped,
  bool settle = true,
}) async {
  final scaffold = Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightFor(arabic: false),
      darkTheme: AppTheme.darkFor(arabic: false),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      home: grouped ? GroupedSurface(child: scaffold) : scaffold,
    ),
  );
  // A spinner never settles.
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

void main() {
  for (final dark in [false, true]) {
    for (final grouped in [false, true]) {
      final label =
          '${dark ? 'dark' : 'light'} ${grouped ? 'grouped' : 'plain'}';

      for (final variant in [
        AppButtonVariant.primary,
        AppButtonVariant.destructive,
      ]) {
        testWidgets(
            'disabled ${variant.name} button keeps a neutral shape '
            '($label)', (tester) async {
          await _pump(
            tester,
            AppButton(
              label: 'Disabled action',
              variant: variant,
              onPressed: null,
            ),
            dark: dark,
            grouped: grouped,
          );
          final button = find.byType(ElevatedButton);
          final fill = tester
              .widget<ElevatedButton>(button)
              .style!
              .backgroundColor!
              .resolve(const {WidgetState.disabled})!;
          final page = paintedBackgroundsOf(tester.element(button)).single;
          final ink = renderedTextColorOf(tester, 'Disabled action');

          expect(fill, PageSurface.fillOf(tester.element(button)),
              reason: label);
          expect(_isWarm(fill), isFalse, reason: '$label: warm fill $fill');
          expect(fill, isNot(page), reason: '$label: fill vs page');
          expect(ink, isNot(fill), reason: '$label: label vs fill');
          expect(AppContrast.ratio(ink, fill), greaterThan(1),
              reason: '$label: label vs fill');
        });

        testWidgets(
            'loading ${variant.name} button keeps its colour fill '
            '($label)', (tester) async {
          await _pump(
            tester,
            AppButton(
              label: 'Busy',
              variant: variant,
              isLoading: true,
              onPressed: () {},
            ),
            dark: dark,
            grouped: grouped,
            settle: false,
          );
          final c = Theme.of(tester.element(find.byType(AppButton)))
              .extension<SiratiColors>()!;
          final fill = tester
              .widget<ElevatedButton>(find.byType(ElevatedButton))
              .style!
              .backgroundColor!
              .resolve(const {WidgetState.disabled});
          expect(
            fill,
            variant == AppButtonVariant.primary ? c.primary : c.error,
            reason: label,
          );
        });
      }

      testWidgets('list section card differs from the page ($label)',
          (tester) async {
        await _pump(
          tester,
          const AppListSection(
            header: 'Header',
            children: [Text('Row one'), Text('Row two')],
          ),
          dark: dark,
          grouped: grouped,
        );
        final card = find.byKey(AppListSection.cardKey);
        final fill = tester.widget<Material>(card).color!;
        final page = paintedBackgroundsOf(tester.element(card)).single;
        expect(fill, PageSurface.fillOf(tester.element(card)), reason: label);
        expect(fill, isNot(page), reason: '$label: card vs page');
        expect(_isWarm(fill), isFalse, reason: label);
        expectAllTextAa(label);
      });

      testWidgets('state circle differs from the page ($label)',
          (tester) async {
        await _pump(
          tester,
          const AppStateIcon(Icons.inbox_outlined),
          dark: dark,
          grouped: grouped,
        );
        final circle = find.byType(AppStateIcon);
        final box = tester.widget<Container>(find
            .descendant(of: circle, matching: find.byType(Container))
            .first);
        final fill = (box.decoration! as BoxDecoration).color!;
        final page = paintedBackgroundsOf(tester.element(circle)).single;
        expect(fill, PageSurface.fillOf(tester.element(circle)), reason: label);
        expect(fill, isNot(page), reason: '$label: circle vs page');
      });
    }
  }
}

/// The colour the text [text] is drawn with, after theme defaults.
Color renderedTextColorOf(WidgetTester tester, String text) {
  final finder = find.text(text);
  final widget = tester.widget<Text>(finder);
  return DefaultTextStyle.of(tester.element(finder))
      .style
      .merge(widget.style)
      .color!;
}
