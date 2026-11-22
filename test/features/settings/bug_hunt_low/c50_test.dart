import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/presentation/change_password_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final pw in ['Abcdefgh1!', 'longer password with spaces 123']) {
    testWidgets(
        'C50: fixing the current password clears "same as current" ($pw)',
        (tester) async {
      AppLocale.languageCode.value = 'en';
      addTearDown(() => AppLocale.languageCode.value = 'ar');
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const ChangePasswordScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(ChangePasswordScreen)));
      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), pw);
      await tester.enterText(fields.at(1), pw);
      await tester.enterText(fields.at(2), pw);
      await tester.pump();
      await tester.tap(find.text(l10n.settingsUpdatePassword));
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsNewPasswordSameAsCurrent), findsOneWidget);

      // The user fixes the CURRENT field instead.
      await tester.enterText(fields.at(0), '${pw}x');
      await tester.pumpAndSettle();
      expect(find.text(l10n.settingsNewPasswordSameAsCurrent), findsNothing,
          reason: 'new != current now, so the error is stale');
    });
  }
}
