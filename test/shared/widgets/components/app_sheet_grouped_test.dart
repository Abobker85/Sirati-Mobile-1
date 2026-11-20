import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';

import '../../../support/contrast_probe.dart';

/// Sheet content sits on the grouped page pattern: the pane is tinted with
/// the grouped background and the cards, fields and chips inside are filled
/// with the grouped card colour, every text on them strict AA, in light and
/// dark, Arabic and English, capped and scroll controlled sheets.

const _bodyKey = ValueKey('grouped-body');

Widget _content() => Padding(
      key: _bodyKey,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Sheet title'),
          ListTile(title: const Text('Pane row'), onTap: () {}),
          const SizedBox(height: 8),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Full name',
              hintText: 'Your name',
            ),
          ),
          const SizedBox(height: 8),
          const Card(child: ListTile(title: Text('Card row'))),
          const SizedBox(height: 8),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(label: Text('Chip label')),
          ),
        ],
      ),
    );

void main() {
  for (final dark in [false, true]) {
    for (final arabic in [true, false]) {
      for (final scrollControlled in [false, true]) {
        for (final highContrast in [false, true]) {
          final label = '${dark ? 'dark' : 'light'}, ${arabic ? 'ar' : 'en'}, '
              '${scrollControlled ? 'scroll controlled' : 'capped'}'
              '${highContrast ? ', high contrast' : ''}';
          final theme = dark
              ? AppTheme.darkFor(arabic: arabic)
              : AppTheme.lightFor(arabic: arabic);
          final c = theme.extension<SiratiColors>()!;

          testWidgets('$label: grouped fills on the grouped background',
              (tester) async {
            tester.view.physicalSize = const Size(320, 568);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                locale: Locale(arabic ? 'ar' : 'en'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(highContrast: highContrast),
                  child: child!,
                ),
                home: Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showGlassBottomSheet<void>(
                        context: context,
                        isScrollControlled: scrollControlled,
                        builder: (_) => _content(),
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

            final body = tester.element(find.byKey(_bodyKey));
            expect(PageSurface.of(body), PageSurfaceKind.grouped);
            expect(PageSurface.fillOf(body), c.groupedCard);

            // The pane: text on it is painted on the opaque grouped
            // background and nothing else, whatever is behind the sheet.
            expect(
                paintedBackgroundsOf(tester.element(find.text('Sheet title'))),
                [c.groupedBackground]);
            // Taps on a row on the pane paint their ink on the pane.
            expect(Material.of(tester.element(find.text('Pane row'))).color,
                c.groupedBackground);
            // The glass edge (firm in high contrast) still shows over it.
            final edge = tester
                .widgetList<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(appSheetPaneKey),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .firstWhere(
                  (d) => d.position == DecorationPosition.foreground,
                )
                .decoration as BoxDecoration;
            expect(
                edge.border,
                Border.all(
                  color: highContrast ? c.outline : c.glassEdge,
                ));
            expect(edge.borderRadius, AppRadius.sheetTop);

            // Field, card and chip are filled with the grouped card colour,
            // which differs from the pane so they keep an edge.
            expect(c.groupedCard, isNot(c.groupedBackground));
            final field = tester.widget<InputDecorator>(
              find.descendant(
                of: find.byType(TextField),
                matching: find.byType(InputDecorator),
              ),
            );
            final fieldTheme = Theme.of(
              tester.element(find.byType(TextField)),
            ).inputDecorationTheme;
            expect(field.decoration.fillColor ?? fieldTheme.fillColor,
                c.groupedCard);
            final card = tester.widget<Material>(
              find
                  .descendant(
                    of: find.byType(Card),
                    matching: find.byType(Material),
                  )
                  .first,
            );
            expect(card.color, c.groupedCard);
            final chipTheme =
                Theme.of(tester.element(find.byType(Chip))).chipTheme;
            expect(chipTheme.backgroundColor, c.groupedCard);

            // Every text on screen, on whatever it is painted on (glass is
            // checked over black and white), is strict AA.
            expectAllTextAa('sheet $label');
            // The round X is filled like the other controls on the pane.
            final close = tester.widget<IconButton>(
              find.byKey(const ValueKey('sheet-close')),
            );
            expect(close.style!.backgroundColor!.resolve({}), c.groupedCard);

            // ...and the field, card and chip text is painted on that fill.
            for (final text in ['Your name', 'Card row', 'Chip label']) {
              expect(paintedBackgroundsOf(tester.element(find.text(text))),
                  contains(c.groupedCard),
                  reason: '$text sits on the grouped card fill ($label)');
            }
          });
        }
      }
    }
  }
}
