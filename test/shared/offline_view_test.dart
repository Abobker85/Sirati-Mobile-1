import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

import '../support/card_chrome.dart';
import '../support/contrast_probe.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool english = false,
  bool dark = false,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = false,
  bool grouped = false,
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
      home: grouped
          ? GroupedSurface(
              child: Scaffold(appBar: AppBar(), body: child),
            )
          : Scaffold(appBar: AppBar(), body: child),
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

/// The retry action: the teal primary capsule.
final _retry = find.byWidgetPredicate(
  (w) => w is AppButton && w.variant == AppButtonVariant.primary,
);

/// The open-saved action: the grey secondary capsule.
final _openSaved = find.byWidgetPredicate(
  (w) => w is AppButton && w.variant == AppButtonVariant.secondary,
);

/// Asserts nothing painted under the offline view uses a gradient or a
/// shader, walking every widget in the pumped tree.
void _expectNoGradient(String label) {
  final root = find.byType(OfflineView);
  for (final element in find
      .descendant(of: root, matching: find.byWidgetPredicate((_) => true))
      .evaluate()) {
    final widget = element.widget;
    expect(widget, isNot(isA<ShaderMask>()), reason: label);
    final decoration = switch (widget) {
      DecoratedBox(:final decoration) => decoration,
      Ink(:final decoration) => decoration,
      _ => null,
    };
    if (decoration is BoxDecoration) {
      expect(decoration.gradient, isNull, reason: '$label: $widget');
    } else if (decoration is ShapeDecoration) {
      expect(decoration.gradient, isNull, reason: '$label: $widget');
    }
  }
}

/// The page colour actually painted behind [element].
Color _pageBehind(Element element) => paintedBackgroundsOf(element).single;

const _delays = [
  Duration(seconds: 5),
  Duration(seconds: 10),
  Duration(seconds: 20),
];

void main() {
  const layouts = [
    (Size(390, 844), 1.0),
    (Size(320, 568), 1.0),
    (Size(320, 568), 1.3),
    (Size(320, 568), 2.0),
    (Size(1024, 768), 1.0),
  ];

  for (final grouped in [false, true]) {
    final kind = grouped ? PageSurfaceKind.grouped : PageSurfaceKind.plain;
    for (final english in [false, true]) {
      for (final dark in [false, true]) {
        for (final (size, scale) in layouts) {
          final label = '${kind.name} ${english ? 'en' : 'ar'} '
              '${dark ? 'dark' : 'light'} $size x$scale';
          testWidgets('lays out, reads and taps cleanly ($label)',
              (tester) async {
            await _pump(
              tester,
              OfflineView(onRetry: () {}, onOpenSaved: () {}),
              english: english,
              dark: dark,
              size: size,
              textScale: scale,
              grouped: grouped,
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expectAllTextAa(label);
            _expectMeaningfulIconsAa(label);
            await expectLater(
                tester, meetsGuideline(androidTapTargetGuideline));
            await expectLater(
                tester, meetsGuideline(labeledTapTargetGuideline));
            _expectNoGradient(label);

            final c = Theme.of(tester.element(find.byType(OfflineView)))
                .extension<SiratiColors>()!;
            final fill = PageSurface.fillColor(c, kind);

            // Tips: an inset-grouped section with no outline or shadow, on
            // the page's fill, which differs from the page behind it.
            final section = find.byType(AppListSection);
            expect(section, findsOneWidget, reason: label);
            expectNoCardChrome(section, label);
            final card = find.byKey(AppListSection.cardKey);
            final cardFill = tester.widget<Material>(card).color!;
            expect(cardFill, fill, reason: label);
            expect(cardFill, isNot(_pageBehind(tester.element(card))),
                reason: '$label: card vs page');

            // The state circle stands out from the page too.
            final circle = tester.widget<Container>(find
                .descendant(
                    of: find.byType(AppStateIcon),
                    matching: find.byType(Container))
                .first);
            final circleFill = (circle.decoration! as BoxDecoration).color!;
            expect(
              circleFill,
              isNot(_pageBehind(tester.element(find.byType(AppStateIcon)))),
              reason: '$label: circle vs page',
            );

            // Retry: the teal filled capsule.
            final retryStyle = tester
                .widget<ElevatedButton>(find.descendant(
                    of: _retry, matching: find.byType(ElevatedButton)))
                .style!;
            expect(retryStyle.backgroundColor!.resolve(const {}), c.primary,
                reason: label);
            expect(retryStyle.shape!.resolve(const {}), isA<StadiumBorder>(),
                reason: label);
            expect(tester.getSize(_retry).width, lessThanOrEqualTo(440));
            // The teal capsule is a 3:1 boundary against the page.
            expect(
              AppContrast.ratio(
                c.primary,
                _pageBehind(tester.element(find.byType(ElevatedButton))),
              ),
              greaterThanOrEqualTo(3),
              reason: '$label: retry capsule vs page',
            );

            // Open saved: the grey secondary capsule with no outline.
            final savedStyle = tester
                .widget<OutlinedButton>(find.descendant(
                    of: _openSaved, matching: find.byType(OutlinedButton)))
                .style!;
            expect(savedStyle.backgroundColor!.resolve(const {}), fill,
                reason: label);
            expect(savedStyle.side!.resolve(const {}), BorderSide.none,
                reason: label);
            expect(savedStyle.shape!.resolve(const {}), isA<StadiumBorder>(),
                reason: label);

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

    await tester.tap(_retry);
    await tester.pump();
    expect(calls, 1);
    expect(find.text(l10n.sharedOfflineChecking), findsWidgets);
    // The badge sends out a reconnect ping for the attempt.
    await tester.pump(OfflinePing.duration ~/ 3);
    expect(find.byKey(OfflinePing.ringKey), findsOneWidget);
    // The capsule shows a spinner while checking.
    expect(
        find.descendant(
            of: _retry, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget);

    // A tap while checking does not start a second request.
    await tester.tap(_retry, warnIfMissed: false);
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
    expect(_retry, findsNothing);
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
    await tester.ensureVisible(_openSaved);
    await tester.tap(_openSaved);
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
