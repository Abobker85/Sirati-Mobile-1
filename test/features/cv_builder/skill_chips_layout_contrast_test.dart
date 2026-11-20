// Cross-ticket fix from ticket 14: the skills selector's count row must not
// overflow at any phone width or text size, and every chip label (selected
// and suggested) holds AA, in both languages and both themes, on the plain
// and the grouped page.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/skill_chips_selector.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

import '../../support/contrast_probe.dart';

const _suggested = ['Docker', 'Kubernetes', 'تحليل البيانات', 'REST APIs'];

const _titles = [
  JobTitle(
    id: 1,
    slug: 'backend-developer',
    nameAr: 'مطور خلفيات',
    nameEn: 'Backend Developer',
    category: 'tech',
    keywords: _suggested,
    sortOrder: 0,
  ),
];

/// Many selected skills, so the count runs to three digits' width and the
/// cloud wraps over many rows.
String _manySkills(int n) =>
    [for (var i = 0; i < n; i++) i.isEven ? 'Skill $i' : 'مهارة $i'].join(', ');

void main() {
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      for (final grouped in [false, true]) {
        for (final width in [320.0, 390.0]) {
          for (final scale in [1.0, 1.3]) {
            final tag = '$language ${dark ? 'dark' : 'light'} '
                '${grouped ? 'grouped' : 'plain'} ${width.toInt()} x$scale';
            testWidgets('$tag: no overflow, chip labels AA', (tester) async {
              AppLocale.languageCode.value = language;
              tester.view.physicalSize = Size(width, 2400);
              tester.view.devicePixelRatio = 1;
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(tester.view.reset);
              addTearDown(
                  tester.platformDispatcher.clearTextScaleFactorTestValue);
              final controller = TextEditingController(text: _manySkills(120));
              addTearDown(controller.dispose);
              final english = language == 'en';
              Widget page = Scaffold(
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    SkillChipsSelector(
                      controller: controller,
                      targetJobTitle: 'Backend Developer',
                      english: english,
                      allJobTitles: _titles,
                    ),
                  ],
                ),
              );
              if (grouped) page = GroupedSurface(child: page);
              await tester.pumpWidget(MaterialApp(
                theme: dark
                    ? AppTheme.darkFor(arabic: !english)
                    : AppTheme.lightFor(arabic: !english),
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: page,
              ));
              await tester.pumpAndSettle();

              expect(tester.takeException(), isNull, reason: tag);
              final l10n = AppLocalizations.of(
                  tester.element(find.byType(SkillChipsSelector)));
              expect(
                  find.text(l10n.cvSkillsSelectedCount(120)), findsOneWidget);
              // Selected chips and suggested (unselected) chips are both on
              // screen, so the walk below covers both kinds of label.
              expect(find.byKey(const ValueKey('selected_skill_0')),
                  findsOneWidget);
              expect(find.textContaining('Docker'), findsWidgets);
              expectAllTextAa(tag);

              // iOS 26 restyle: borderless card, filled capsule chips, and a
              // filled add-skill field with no resting outline whose fill
              // differs from the card it sits in.
              final card = tester
                  .widget<Container>(find.byKey(SkillChipsSelector.cardKey))
                  .decoration! as BoxDecoration;
              expect(card.border, isNull);
              expect(
                  card.color,
                  PageSurface.fillOf(
                      tester.element(find.byKey(SkillChipsSelector.cardKey))));
              final selected = tester
                  .widget<Container>(
                      find.byKey(const ValueKey('selected_skill_0')))
                  .decoration! as BoxDecoration;
              expect(selected.border, isNull);
              expect(selected.borderRadius, AppRadius.capsuleAll);
              for (final chip
                  in tester.widgetList<ActionChip>(find.byType(ActionChip))) {
                expect(chip.side, BorderSide.none);
                expect(chip.shape, isA<StadiumBorder>());
              }
              final field = find.descendant(
                  of: find.byKey(SkillChipsSelector.cardKey),
                  matching: find.byType(InputDecorator));
              final decorator = tester.widget<InputDecorator>(field);
              final resolved = decorator.decoration.applyDefaults(
                  Theme.of(tester.element(field)).inputDecorationTheme);
              expect(resolved.enabledBorder, isA<FilledFieldBorder>());
              expect(resolved.enabledBorder!.borderSide.style,
                  isNot(BorderStyle.solid),
                  reason: 'no resting outline');
              expect(resolved.filled, isTrue);
              expect(resolved.fillColor, isNot(card.color));
            });
          }
        }
      }
    }
  }
}
