import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/presentation/onboarding_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorage, (_) async => null));

  // Visual opacity of the hero on page 2 (the brand mark).
  double heroOpacity(WidgetTester tester) {
    final fades = tester.widgetList<FadeTransition>(find.ancestor(
        of: find.byKey(const ValueKey('onboarding_brand_mark')),
        matching: find.byType(FadeTransition)));
    return fades.fold(1.0, (a, f) => a * f.opacity.value);
  }

  for (final lang in ['en', 'ar']) {
    testWidgets('$lang: incoming hero does not flash out mid-swipe',
        (tester) async {
      AppLocale.languageCode.value = lang;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightFor(arabic: lang == 'ar'),
        locale: Locale(lang),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: OnboardingScreen(onFinished: () {})),
      ));
      await tester.pumpAndSettle();
      final pv = find.byType(PageView);
      final w = tester.getSize(pv).width;
      final dir = lang == 'ar' ? 1.0 : -1.0;
      final g = await tester.startGesture(tester.getCenter(pv));
      // Move in small steps toward the next page; the incoming hero is on
      // screen the whole time, so its opacity must never drop.
      var last = -1.0;
      for (var f = 0.1; f <= 0.8; f += 0.1) {
        await g.moveBy(Offset(dir * w * 0.1, 0));
        await tester.pump(const Duration(milliseconds: 16));
        if (find.byKey(const ValueKey('onboarding_brand_mark'))
            .evaluate()
            .isEmpty) continue;
        final o = heroOpacity(tester);
        expect(o, greaterThanOrEqualTo(last),
            reason: 'opacity fell at ${(f * 100).round()}% of the swipe');
        last = o;
      }
      await g.up();
      await tester.pumpAndSettle();
    });
  }
}
