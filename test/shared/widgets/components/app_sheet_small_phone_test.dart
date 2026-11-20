import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/keyword_group.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';

/// The X row added to every default sheet must fit on a small phone, with
/// larger text, in both languages: inside the 9/16 cap of a sheet that is
/// not scroll controlled, and in a default sheet.
Future<void> _pump(
  WidgetTester tester,
  Widget home, {
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
      home: Scaffold(body: home),
    ),
  );
}

void _expectFits(WidgetTester tester) {
  expect(tester.takeException(), isNull, reason: 'no overflow');
  final glass = tester.getRect(find.byType(GlassSurface).last);
  expect(glass.top, greaterThanOrEqualTo(0));
  expect(glass.bottom, lessThanOrEqualTo(568));
  final close = tester.getRect(find.byKey(const ValueKey('sheet-close')));
  expect(close.top, greaterThanOrEqualTo(glass.top));
}

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final textScale in const [1.0, 1.3]) {
      final label = '${locale.languageCode} x$textScale at 320x568';

      testWidgets('$label: capped keyword advice sheet fits', (tester) async {
        // A long keyword makes the title and the body wrap.
        const keyword = 'Cross-functional stakeholder management';
        await _pump(
          tester,
          const SingleChildScrollView(
            child: KeywordGroup(
              keywords: [keyword],
              found: false,
              english: true,
            ),
          ),
          locale: locale,
          textScale: textScale,
        );
        await tester.tap(find.text(keyword));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
        _expectFits(tester);

        // Content taller than the cap scrolls: its last button is reachable.
        final gotIt = find.text(
          AppLocalizations.of(tester.element(find.byType(GlassSurface).last))
              .atsGotIt,
        );
        await tester.ensureVisible(gotIt);
        await tester.pumpAndSettle();
        await tester.tap(gotIt);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('sheet-close')), findsNothing);
      });

      testWidgets('$label: default sheet fits', (tester) async {
        await _pump(
          tester,
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppBottomSheet<void>(
                context: context,
                semanticLabel: 'Options',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      ListTile(
                        leading: const Icon(Icons.photo_outlined),
                        title: Text('Option $i'),
                        onTap: () {},
                      ),
                  ],
                ),
              ),
              child: const Text('open'),
            ),
          ),
          locale: locale,
          textScale: textScale,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Option 2'), findsOneWidget);
        _expectFits(tester);
      });
    }
  }
}
