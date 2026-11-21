import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_news_common.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

import '../../support/contrast_probe.dart';

/// Ticket 06: every empty, error and offline state shares one calm look,
/// whatever the copy: a grey glyph in a soft circle, a bold title, grey
/// explanation, and buttons only where the caller gives an action.
void main() {
  for (final (mode, language) in [
    ('light', 'en'),
    ('light', 'ar'),
    ('dark', 'en'),
    ('dark', 'ar'),
  ]) {
    final arabic = language == 'ar';
    final theme = mode == 'light'
        ? AppTheme.lightFor(arabic: arabic)
        : AppTheme.darkFor(arabic: arabic);
    final suffix = '$mode, $language';

    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(390 * 3, 1400 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            backgroundColor: context.sirati.pageBackground,
            body: child,
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    void expectCalm(WidgetTester tester, String label, {required int buttons}) {
      final c = theme.extension<SiratiColors>()!;
      final circle = find.byType(AppStateIcon);
      expect(circle, findsOneWidget, reason: label);
      final box = tester.widget<Container>(
          find.descendant(of: circle, matching: find.byType(Container)).first);
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle, reason: label);
      expect(decoration.color, c.cardFill, reason: label);
      final glyph = tester.widget<Icon>(
          find.descendant(of: circle, matching: find.byType(Icon)));
      expect(glyph.color, c.textHint, reason: label);
      // The circle sits above the title and never steals focus.
      expect(
        find.descendant(
            of: circle,
            matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.label != null)),
        findsNothing,
      );

      final allButtons = find.byWidgetPredicate((w) => w is ButtonStyleButton);
      expect(allButtons, findsNWidgets(buttons), reason: label);
      for (final b in allButtons.evaluate()) {
        final size = tester.getSize(find.byWidget(b.widget));
        expect(size.height, greaterThanOrEqualTo(AppTouchTarget.min),
            reason: label);
      }
      expectAllTextAa(label);
      expectAllIconsAa(label);
    }

    group('calm states ($suffix)', () {
      for (final type in ApiErrorType.values) {
        if (type == ApiErrorType.network) continue;
        for (final retry in [false, true]) {
          testWidgets('error ${type.name}, retry=$retry', (tester) async {
            var taps = 0;
            await pump(
              tester,
              AppErrorState(
                message: 'Server said so قال الخادم 503',
                english: !arabic,
                errorType: type,
                onRetry: retry ? () => taps++ : null,
              ),
            );
            expectCalm(tester, 'error ${type.name} $suffix',
                buttons: retry ? 1 : 0);
            final title = tester.widget<Text>(find
                .descendant(
                    of: find.byType(AppEmptyState), matching: find.byType(Text))
                .first);
            final weight =
                DefaultTextStyle.of(tester.element(find.byWidget(title)))
                    .style
                    .merge(title.style)
                    .fontWeight!;
            expect(weight.value, greaterThanOrEqualTo(600));
            if (retry) {
              final l10n =
                  await AppLocalizations.delegate.load(Locale(language));
              await tester.tap(find.text(l10n.retry));
              await tester.pumpAndSettle();
              expect(taps, 1);
            }
          });
        }
      }

      testWidgets('offline', (tester) async {
        await pump(tester, OfflineView(onRetry: () {}));
        expectCalm(tester, 'offline $suffix', buttons: 1);
      });

      for (final (name, widget, buttons) in [
        ('job news feed empty', const EmptyJobNews(english: true), 0),
        (
          'job news filtered',
          EmptyJobNews(english: true, onClearFilters: () {}),
          1
        ),
        (
          'job news region',
          EmptyJobNews(
              english: true,
              regionLabel: 'الرياض Riyadh',
              onShowAllRegions: () {}),
          1
        ),
        ('my cvs', MyCvsEmptyCard(onCreate: () {}, onUpload: () {}), 2),
        (
          'plain empty without action',
          const AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here yet لا شيء هنا بعد',
            subtitle:
                'A longer explanation that wraps onto a second line شرح أطول يلتف على سطرين',
            scrollable: false,
          ),
          0
        ),
      ]) {
        testWidgets(name, (tester) async {
          await pump(tester, SingleChildScrollView(child: widget));
          expectCalm(tester, '$name $suffix', buttons: buttons);
        });
      }

      testWidgets('the explanation wraps at the shared width', (tester) async {
        const body =
            'A longer explanation that wraps onto a second line شرح أطول يلتف على سطرين';
        await pump(
          tester,
          const AppEmptyState(
              icon: Icons.inbox_outlined, title: 'T', subtitle: body),
        );
        expect(tester.getSize(find.text(body)).width,
            lessThanOrEqualTo(AppEmptyState.textMaxWidth));
      });
    });
  }
}
