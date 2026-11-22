// C20: the trailing chevron on the "next step" cards must point toward the
// trailing edge (right in LTR, left in RTL), as Flutter actually draws it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/app/sirati_route_table.dart';
import 'package:sirati/features/cv_builder/presentation/generated_cv_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../job_match/job_match_test_support.dart';

const _chevrons = {
  0xf63a: 'left', // Icons.chevron_left_rounded
  0xf63b: 'right', // Icons.chevron_right_rounded
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final language in ['ar', 'en']) {
    testWidgets('$language: next-step chevrons point to the trailing edge',
        (tester) async {
      AppLocale.languageCode.value = language;
      registerSiratiRouteWidgets();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          cvApiServiceProvider.overrideWithValue(FakeJobMatchApi()),
          authApiServiceProvider.overrideWithValue(FakeAuth(subscription())),
        ],
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: language == 'ar'),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: GeneratedCvScreen(
            generatedCv: GeneratedCv.fromJson({
              'id': 7,
              'full_name': 'Sara Ahmed',
              'target_job_title': 'Engineer',
              'language': language,
              'generated_markdown': '## Summary\nText',
              'ai_status': 'completed',
              'score_total': 80,
              'grade': 'B',
            }),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final rtl = language == 'ar';
      final expected = rtl ? 'left' : 'right';
      var checked = 0;
      for (final key in [
        GeneratedCvScreen.atsStepKey,
        GeneratedCvScreen.jobMatchStepKey,
        GeneratedCvScreen.editStepKey,
      ]) {
        final card = find.byKey(key, skipOffstage: false);
        if (card.evaluate().isEmpty) continue;
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        final icons = tester
            .widgetList<Icon>(find.descendant(
                of: find.byKey(key), matching: find.byType(Icon)))
            .where((i) => _chevrons.containsKey(i.icon?.codePoint));
        expect(icons, hasLength(1), reason: '$key');
        final icon = icons.single;
        final iconDir = Directionality.of(
            tester.element(find.byWidget(icon, skipOffstage: false)));
        final base = _chevrons[icon.icon!.codePoint]!;
        // Icon mirrors a matchTextDirection glyph itself in RTL.
        final mirrored =
            icon.icon!.matchTextDirection && iconDir == TextDirection.rtl;
        final drawn = mirrored ? (base == 'left' ? 'right' : 'left') : base;
        expect(drawn, expected, reason: '$key draws a $drawn chevron');
        checked++;
      }
      expect(checked, greaterThanOrEqualTo(2));
    });
  }
}
