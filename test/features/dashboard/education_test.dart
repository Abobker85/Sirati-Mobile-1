import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/dashboard/application/education_interest_controller.dart';
import 'package:sirati/features/dashboard/presentation/education_detail_screen.dart';
import 'package:sirati/features/dashboard/presentation/education_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/screen_header.dart';

import '../../support/card_chrome.dart';
import '../../support/contrast_probe.dart';
import '../../support/non_text_contrast.dart';

/// Device storage that outlives a single ProviderContainer (an app restart).
class _Store extends EducationInterestStore {
  bool saved = false;
  bool failRead = false;
  bool failSave = false;
  int saves = 0;

  @override
  Future<bool> read() async {
    if (failRead) throw StateError('keystore');
    return saved;
  }

  @override
  Future<void> save() async {
    saves++;
    if (failSave) throw StateError('disk');
    saved = true;
  }
}

void main() {
  group('EducationInterestController', () {
    ProviderContainer boot(_Store store) {
      final c = ProviderContainer(
        overrides: [educationInterestStoreProvider.overrideWithValue(store)],
      );
      c.listen(educationInterestProvider, (_, __) {});
      addTearDown(c.dispose);
      return c;
    }

    test('interest survives a restart', () async {
      final store = _Store();
      final first = boot(store);
      expect(await first.read(educationInterestProvider.future), isFalse);
      await first.read(educationInterestProvider.notifier).register();
      expect(first.read(educationInterestProvider).value, isTrue);

      final afterRestart = boot(store);
      expect(await afterRestart.read(educationInterestProvider.future), isTrue);
    });

    test('registering twice writes once', () async {
      final store = _Store();
      final c = boot(store);
      await c.read(educationInterestProvider.future);
      for (var i = 0; i < 3; i++) {
        await c.read(educationInterestProvider.notifier).register();
      }
      expect(store.saves, 1);
    });

    test('storage failures never throw into the UI', () async {
      final store = _Store()
        ..failRead = true
        ..failSave = true;
      final c = boot(store);
      expect(await c.read(educationInterestProvider.future), isFalse);
      await c.read(educationInterestProvider.notifier).register();
      expect(c.read(educationInterestProvider).value, isTrue);
    });
  });

  group('EducationScreen', () {
    setUp(() => AppLocale.languageCode.value = 'en');

    Widget app(_Store store, ThemeData theme) => ProviderScope(
          overrides: [educationInterestStoreProvider.overrideWithValue(store)],
          child: MaterialApp(
            theme: theme,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: EducationScreen()),
          ),
        );

    testWidgets(
        'Register interest records interest without promising a message',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = _Store();
      await tester.pumpWidget(app(store, AppTheme.lightFor(arabic: false)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register interest'));
      await tester.pumpAndSettle();

      expect(store.saved, isTrue);
      expect(find.text('Interest Registered'), findsOneWidget);
      expect(find.textContaining('notified'), findsNothing,
          reason: 'no launch-notification pipeline exists yet');
    });

    for (final (mode, theme) in [
      ('light', AppTheme.lightFor(arabic: false)),
      ('dark', AppTheme.darkFor(arabic: false)),
    ]) {
      for (final registered in [false, true]) {
        testWidgets('all text is AA in $mode (registered: $registered)',
            (tester) async {
          tester.view.physicalSize = const Size(1080, 3200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(app(_Store()..saved = registered, theme));
          await tester.pumpAndSettle();
          expectAllTextAa('education $mode registered=$registered');
        });
      }
    }
  });

  group('Education on the grouped page (iOS 26)', () {
    for (final language in ['en', 'ar']) {
      for (final dark in [false, true]) {
        final arabic = language == 'ar';
        final theme = dark
            ? AppTheme.darkFor(arabic: arabic)
            : AppTheme.lightFor(arabic: arabic);
        final label = '$language/${dark ? 'dark' : 'light'}';

        Widget host(Widget home) => ProviderScope(
              overrides: [
                educationInterestStoreProvider.overrideWithValue(_Store()),
              ],
              child: MaterialApp(
                theme: theme,
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: home,
              ),
            );

        for (final registered in [false, true]) {
          testWidgets(
              '$label (registered: $registered): one white section of '
              'upcoming features, borderless cards, capsule CTAs',
              (tester) async {
            tester.view.physicalSize = const Size(1080, 3200);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            AppLocale.languageCode.value = language;
            final store = _Store()..saved = registered;
            await tester.pumpWidget(ProviderScope(
              overrides: [
                educationInterestStoreProvider.overrideWithValue(store)
              ],
              child: MaterialApp(
                theme: theme,
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: const Scaffold(body: EducationScreen()),
              ),
            ));
            await tester.pumpAndSettle();
            final context = tester.element(find.byType(EducationScreen));
            final c = context.sirati;
            final l10n = AppLocalizations.of(context);
            expect(Directionality.of(context),
                arabic ? TextDirection.rtl : TextDirection.ltr);

            // The whole tab is the grey grouped page, not the white shell.
            expect(
                tester
                    .widget<ColoredBox>(find.byKey(EducationScreen.pageKey))
                    .color,
                c.groupedBackground);
            expect(
                PageSurface.of(tester
                    .element(find.text(l10n.dashboardEducationHeroTitle))),
                PageSurfaceKind.grouped);

            // "What's coming" is one section: header, one white card, the
            // three features in order with a separator between each pair.
            final section = find.byKey(EducationScreen.upcomingKey);
            expect(tester.widget<AppListSection>(section).header,
                l10n.dashboardEducationWhatsComing);
            final card = find.descendant(
                of: section, matching: find.byKey(AppListSection.cardKey));
            expect(tester.widget<Material>(card).color, c.groupedCard);
            final titles = [
              l10n.dashboardEducationCoursesTitle,
              l10n.dashboardEducationInterviewTitle,
              l10n.dashboardEducationAtsGuidesTitle,
            ];
            final tops = [
              for (final title in titles)
                tester
                    .getTopLeft(
                        find.descendant(of: card, matching: find.text(title)))
                    .dy,
            ];
            expect(tops, orderedEquals([...tops]..sort()));
            expect(find.descendant(of: card, matching: find.byType(Divider)),
                findsNWidgets(titles.length - 1));
            // Descriptions are the only copy: never cut off.
            for (final body in [
              l10n.dashboardEducationCoursesBody,
              l10n.dashboardEducationInterviewBody,
              l10n.dashboardEducationAtsGuidesBody,
            ]) {
              final text = tester.widget<Text>(
                  find.descendant(of: card, matching: find.text(body)));
              expect(text.maxLines, isNull);
            }

            // Hero and CTA are white fills on the grey page.
            for (final text in [
              l10n.dashboardEducationHeroTitle,
              l10n.dashboardEducationCtaTitle,
            ]) {
              expect(paintedBackgroundsOf(tester.element(find.text(text))),
                  [c.groupedCard],
                  reason: '$label $text');
            }
            expectNoCardChrome(find.byType(EducationScreen), label,
                exclude: [find.byType(ScreenHeader)]);

            // Both CTAs are the theme's capsule.
            for (final button in find
                .descendant(
                    of: find.byType(EducationScreen),
                    matching:
                        find.byWidgetPredicate((w) => w is ButtonStyleButton))
                .evaluate()) {
              final shape = (button.widget as ButtonStyleButton)
                      .style
                      ?.shape
                      ?.resolve(const {}) ??
                  Theme.of(button)
                      .elevatedButtonTheme
                      .style
                      ?.shape
                      ?.resolve(const {});
              expect(shape, isA<StadiumBorder>(), reason: '$label CTA');
            }

            expectAllTextAa('education $label');
            expectAllIconsNonTextAa('education $label');
            expect(tester.takeException(), isNull);
          });
        }

        testWidgets('$label: detail is a white borderless card on grey',
            (tester) async {
          AppLocale.languageCode.value = language;
          await tester.pumpWidget(host(const EducationDetailScreen(
            fallback: {
              'title': 'Interview basics',
              'body': 'Prepare short stories about your work.',
              'duration': '10 min',
              'target_role': 'Designer',
              'badge': 'New',
            },
          )));
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(EducationDetailScreen));
          final c = context.sirati;
          expect(
              Theme.of(tester.element(find.byType(Scaffold)))
                  .scaffoldBackgroundColor,
              c.groupedBackground);
          expect(tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
              isNull,
              reason: 'the grouped theme owns the page colour');
          final body = find.byKey(EducationDetailScreen.bodyCardKey);
          final decoration =
              tester.widget<Container>(body).decoration! as BoxDecoration;
          expect(decoration.color, c.groupedCard);
          expect(decoration.borderRadius, AppRadius.cardAll);
          expectNoCardChrome(find.byType(EducationDetailScreen), label);
          expectAllTextAa('education detail $label');
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
