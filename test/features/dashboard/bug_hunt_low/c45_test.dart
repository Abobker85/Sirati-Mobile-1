import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/presentation/history/history_cards.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/theme/app_theme.dart';

// Invariant: the avatar initial is never clipped by its box, at any
// supported text scale, in either UI language, for any name.
void main() {
  for (final lang in ['ar', 'en']) {
    for (final scale in [1.0, 1.5, 2.0, 3.0]) {
      for (final name in ['Sara أحمد', 'محمد', 'Émile', 'ق', 'W']) {
        testWidgets('$lang x$scale "$name": initial fits its box',
            (tester) async {
          tester.view.physicalSize = const Size(400, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          AppLocale.languageCode.value = lang;
          await tester.pumpWidget(MaterialApp(
            theme: AppTheme.lightFor(arabic: lang == 'ar'),
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: GeneratedCvHistoryCard(
                  cv: GeneratedCv.fromJson({
                    'id': 2,
                    'full_name': name,
                    'target_job_title': 'Engineer',
                    'score_total': 90,
                    'grade': 'A',
                    'language': lang,
                    'created_at': '2026-10-19T10:00:00Z',
                  }),
                  onTap: () {},
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          final initial = find.descendant(
              of: find.byType(ExcludeSemantics), matching: find.byType(Text));
          final p = tester.renderObject<RenderParagraph>(initial.first);
          final needW = p.getMinIntrinsicWidth(double.infinity);
          final needH = p.getMaxIntrinsicHeight(needW);
          expect(p.size.width, greaterThanOrEqualTo(needW - 0.01),
              reason: 'initial clipped horizontally');
          expect(p.size.height, greaterThanOrEqualTo(needH - 0.01),
              reason: 'initial clipped vertically');
        });
      }
    }
  }
}
