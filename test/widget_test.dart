import 'package:flutter_test/flutter_test.dart';

import 'package:sirati/main.dart';

void main() {
  testWidgets('Sirati cold start reaches onboarding or welcome',
      (tester) async {
    await tester.pumpWidget(const SiratiApp());

    // Bootstrap is async (token + onboarding flags). Avoid pumpAndSettle —
    // BrandedLoader uses a repeating animation that never settles on boot.
    var sawGate = false;
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final onboarding =
          find.text('مرحباً بك في سيرتي').evaluate().isNotEmpty ||
              find.text('Welcome to Sirati').evaluate().isNotEmpty;
      final welcome =
          find.text('اصنع سيرتك الذاتية باحترافية').evaluate().isNotEmpty ||
              find.text('Build your CV professionally').evaluate().isNotEmpty;
      if (onboarding || welcome) {
        sawGate = true;
        break;
      }
    }

    expect(sawGate, isTrue, reason: 'onboarding or welcome after bootstrap');
    expect(find.text('سيرتي'), findsWidgets);
  });
}
