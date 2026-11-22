import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('C03 a reconnect ping does not move the content (scale $scale)',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightFor(arabic: false),
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: app!,
        ),
        home: Scaffold(
          body: OfflineView(onRetry: () {}, retryDelays: const []),
        ),
      ));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(OfflineView)));
      final retry = find.text(l10n.retry);
      // Every text on screen except the retry label itself is tracked.
      final texts = find.byType(Text);
      Map<String, double> tops() => {
            for (final e in texts.evaluate())
              if ((e.widget as Text).data != null)
                (e.widget as Text).data!:
                    tester.getTopLeft(find.byWidget(e.widget).first).dy,
          };
      final before = tops();
      await tester.tap(retry.first);
      await tester.pump();
      double worst = 0;
      for (var i = 0; i < 9; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        final now = tops();
        for (final k in before.keys) {
          if (!now.containsKey(k)) continue;
          final d = (now[k]! - before[k]!).abs();
          if (d > worst) worst = d;
        }
      }
      expect(worst, lessThan(0.5), reason: 'content moved $worst px mid-ping');
      await tester.pumpAndSettle();
    });
  }
}
