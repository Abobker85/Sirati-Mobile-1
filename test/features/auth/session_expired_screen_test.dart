import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/features/auth/presentation/session_expired_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/brand_gradient_button.dart';

import '../../support/contrast_probe.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool english,
  required bool dark,
  Size size = const Size(390, 844),
  double textScale = 1,
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: const SessionExpiredScreen(),
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text('route ${settings.name}')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Icons in the illustration are shapes, not information; every other icon
/// must be legible.
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
            english: english,
            dark: dark,
            size: size,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
          expectAllTextAa(label);
          _expectMeaningfulIconsAa(label);
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          // Content never runs wider than the readable column, and the call
          // to action stays reachable by scrolling on short screens.
          final button = find.byType(BrandGradientButton);
          expect(tester.getSize(button).width, lessThanOrEqualTo(440));
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          expect(tester.getRect(button).bottom, lessThanOrEqualTo(size.height));
        });
      }
    }
  }

  testWidgets('sign in again clears the stack and opens sign-in',
      (tester) async {
    await _pump(tester, english: true, dark: false);
    await tester.tap(find.byType(BrandGradientButton));
    await tester.pumpAndSettle();
    expect(find.byType(SessionExpiredScreen), findsNothing);
    expect(find.text('route ${AppRoutes.login}'), findsOneWidget);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('system back does not leave the screen', (tester) async {
    await _pump(tester, english: false, dark: false);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(SessionExpiredScreen), findsOneWidget);
  });

  testWidgets('title is announced as a heading in both languages',
      (tester) async {
    for (final english in [false, true]) {
      await _pump(tester, english: english, dark: false);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(SessionExpiredScreen)),
      );
      expect(
        tester.getSemantics(find.text(l10n.authSessionExpiredTitle)),
        matchesSemantics(isHeader: true, label: l10n.authSessionExpiredTitle),
      );
    }
  });
}
