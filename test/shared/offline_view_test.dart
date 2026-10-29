import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/brand_gradient_button.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

import '../support/contrast_probe.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool english = false,
  bool dark = false,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightFor(arabic: !english),
      darkTheme: AppTheme.darkFor(arabic: !english),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(english ? 'en' : 'ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: app!,
      ),
      home: Scaffold(appBar: AppBar(), body: child),
    ),
  );
}

void _expectMeaningfulIconsAa(String label) {
  for (final element in find.byType(Icon).evaluate()) {
    var decorative = false;
    element.visitAncestorElements((ancestor) {
      decorative = ancestor.widget is ExcludeSemantics;
      return !decorative;
    });
    if (decorative) continue;
    final icon = element.widget as Icon;
    final ink = icon.color ?? IconTheme.of(element).color!;
    for (final background in paintedBackgroundsOf(element)) {
      expect(
        AppContrast.ratio(Color.alphaBlend(ink, background), background),
        greaterThanOrEqualTo(3),
        reason: '${icon.icon} on $background ($label)',
      );
    }
  }
}

const _delays = [
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 20),
];

void main() {
  const layouts = [
    (Size(390, 844), 1.0),
    (Size(320, 568), 1.0),
    (Size(320, 568), 2.0),
    (Size(1024, 768), 1.0),
  ];

  for (final english in [false, true]) {
    for (final dark in [false, true]) {
      for (final (size, scale) in layouts) {
        final label =
            '${english ? 'en' : 'ar'} ${dark ? 'dark' : 'light'} $size x$scale';
        testWidgets('lays out, reads and taps cleanly ($label)',
            (tester) async {
          await _pump(
            tester,
            OfflineView(onRetry: () {}, onOpenSaved: () {}),
            english: english,
            dark: dark,
            size: size,
            textScale: scale,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expectAllTextAa(label);
          _expectMeaningfulIconsAa(label);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          final retry = find.byType(BrandGradientButton);
          expect(tester.getSize(retry).width, lessThanOrEqualTo(440));
          await tester.ensureVisible(find.byType(OutlinedButton));
          await tester.pumpAndSettle();
          expect(
            tester.getRect(find.byType(OutlinedButton)).bottom,
            lessThanOrEqualTo(size.height),
          );
        });
      }
    }
  }

  testWidgets('retries on its own with growing gaps, capped at the last',
      (tester) async {
    final calls = <Duration>[];
    var elapsed = Duration.zero;
    await _pump(
      tester,
      OfflineView(
        retryDelays: _delays,
        onRetry: () => calls.add(elapsed),
      ),
    );

    Future<void> advance(Duration by) async {
      elapsed += by;
      await tester.pump(by);
    }

    // Each gap is measured from the end of the previous attempt.
    for (var i = 0; i < 40; i++) {
      await advance(const Duration(seconds: 1));
    }
    expect(calls, const [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 35),
    ]);
    for (var i = 0; i < 40; i++) {
      await advance(const Duration(seconds: 1));
    }
    // The last delay repeats once the list runs out.
    expect(calls.sublist(3), const [
      Duration(seconds: 55),
      Duration(seconds: 75),
    ]);
  });

  testWidgets('shows a checking state while a retry runs and survives errors',
      (tester) async {
    final attempt = Completer<void>();
    var calls = 0;
    await _pump(
      tester,
      OfflineView(
        retryDelays: _delays,
        onRetry: () {
          calls++;
          return attempt.future;
        },
      ),
      english: true,
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(OfflineView)));

    await tester.tap(find.byType(BrandGradientButton));
    await tester.pump();
    expect(calls, 1);
    expect(find.text(l10n.sharedOfflineChecking), findsWidgets);

    // A tap while checking does not start a second request.
    await tester.tap(find.byType(BrandGradientButton));
    await tester.pump();
    expect(calls, 1);

    attempt.completeError(const ApiException(
      'offline',
      type: ApiErrorType.network,
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.sharedOfflineChecking), findsNothing);
    expect(find.text(l10n.retry), findsOneWidget);
  });

  testWidgets('stops retrying once removed', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      OfflineView(retryDelays: _delays, onRetry: () => calls++),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
    expect(calls, 0);
  });

  testWidgets('pauses in the background and retries on return', (tester) async {
    var calls = 0;
    await _pump(
      tester,
      OfflineView(retryDelays: _delays, onRetry: () => calls++),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 2));
    expect(calls, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('without callbacks it shows no actions and never retries',
      (tester) async {
    await _pump(tester, const OfflineView());
    await tester.pump(const Duration(minutes: 2));
    expect(find.byType(BrandGradientButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('the saved-content action appears only when wired',
      (tester) async {
    var opened = 0;
    await _pump(tester, OfflineView(onRetry: () {}));
    expect(find.byType(OutlinedButton), findsNothing);

    await _pump(
      tester,
      OfflineView(onRetry: () {}, onOpenSaved: () => opened++),
    );
    await tester.ensureVisible(find.byType(OutlinedButton));
    await tester.tap(find.byType(OutlinedButton));
    expect(opened, 1);
  });

  testWidgets('reduced motion settles immediately', (tester) async {
    await _pump(
      tester,
      OfflineView(onRetry: () {}),
      disableAnimations: true,
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('AppErrorState routes only network errors to the offline view',
      (tester) async {
    for (final type in ApiErrorType.values) {
      await _pump(
        tester,
        AppErrorState(
          message: 'message',
          english: true,
          errorType: type,
          onRetry: () {},
        ),
        english: true,
      );
      expect(
        find.byType(OfflineView),
        type == ApiErrorType.network ? findsOneWidget : findsNothing,
        reason: '$type',
      );
    }
  });
}
