import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

const _barKey = ValueKey('floating-bar');

/// A floating bottom bar laid over the body, like the dashboard tab bar
/// (`Scaffold.extendBody`): the body only learns about it through the
/// MediaQuery bottom padding.
Future<void> _pumpUnderFloatingBar(
  WidgetTester tester, {
  required bool english,
  required double textScale,
  required Size size,
  required double barHeight,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightFor(arabic: !english),
      locale: Locale(english ? 'en' : 'ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        extendBody: true,
        body: OfflineView(onRetry: () {}, onOpenSaved: () {}),
        bottomNavigationBar: SizedBox(key: _barKey, height: barHeight),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const sizes = [Size(320, 568), Size(390, 844)];
  for (final english in [false, true]) {
    for (final size in sizes) {
      for (final textScale in [1.0, 1.3, 2.0]) {
        for (final barHeight in [72.0, 120.0]) {
          final label = '${english ? 'en' : 'ar'} ${size.width.toInt()}x'
              '${size.height.toInt()} x$textScale bar $barHeight';
          testWidgets(
              'every action can rest fully above a floating bottom bar ($label)',
              (tester) async {
            await _pumpUnderFloatingBar(
              tester,
              english: english,
              textScale: textScale,
              size: size,
              barHeight: barHeight,
            );
            expect(tester.takeException(), isNull);

            // Scroll to the very end; the last action must clear the bar.
            final scrollable = find.byType(Scrollable).first;
            await tester.fling(scrollable, const Offset(0, -2000), 3000);
            await tester.pumpAndSettle();

            final barTop = tester.getTopLeft(find.byKey(_barKey)).dy;
            final actions = find.byType(AppButton);
            expect(actions, findsNWidgets(2));
            for (final action in actions.evaluate()) {
              final rect = tester.getRect(find.byWidget(action.widget));
              expect(rect.bottom, lessThanOrEqualTo(barTop),
                  reason: '${(action.widget as AppButton).variant} '
                      'ends at ${rect.bottom}, bar starts at $barTop ($label)');
            }
          });
        }
      }
    }
  }
}
