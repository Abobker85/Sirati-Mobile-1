import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_navigation_bar.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';

/// Pumps the bar in a host that really switches tabs on tap.
Future<void> _pumpBar(
  WidgetTester tester, {
  required Locale locale,
  required bool dark,
  double width = 412,
  bool compact = false,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final arabic = locale.languageCode == 'ar';
  var current = DashboardTab.home;
  await tester.pumpWidget(
    MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: arabic)
          : AppTheme.lightFor(arabic: arabic),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          extendBody: true,
          bottomNavigationBar: DashboardNavigationBar(
            current: current,
            compact: compact,
            onChanged: (tab) => setState(() => current = tab),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _bar => find.byType(DashboardNavigationBar);
Finder get _pill => find.byKey(DashboardNavigationBar.pillKey);

/// Tab icons, in [DashboardNavigationBar.order].
Finder get _icons =>
    find.descendant(of: _bar, matching: find.byType(LivelyIcon));

/// The tab button holding icon [i]: its Semantics container.
Finder _tab(int i) => find
    .ancestor(
      of: _icons.at(i),
      matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.selected != null),
    )
    .first;

SiratiColors _colors(WidgetTester tester) => tester.element(_bar).sirati;

/// Colour the icon of tab [i] is drawn in.
Color _iconInk(WidgetTester tester, int i) =>
    IconTheme.of(tester.element(_icons.at(i))).color!;

/// Colour the label of tab [i] is drawn in.
Color _labelInk(WidgetTester tester, int i) => tester
    .widget<Text>(
        find.descendant(of: _tab(i), matching: find.byType(Text)).first)
    .style!
    .color!;

/// Fill of the rendered pill.
Color _pillFill(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(_pill).decoration as BoxDecoration).color!;

/// Tint of the glass capsule as rendered: the pane under its blur.
Color _glassFill(WidgetTester tester) => (tester
        .widget<DecoratedBox>(find
            .descendant(
              of: find.descendant(
                of: find.byKey(DashboardNavigationBar.capsuleKey),
                matching: find.byType(BackdropFilter),
              ),
              matching: find.byType(DecoratedBox),
            )
            .first)
        .decoration as BoxDecoration)
    .color!;

const _locales = [Locale('ar'), Locale('en')];
const _order = DashboardNavigationBar.order;

void main() {
  for (final locale in _locales) {
    for (final dark in const [false, true]) {
      final mode = '$locale ${dark ? 'dark' : 'light'}';

      for (final compact in const [false, true]) {
        for (final width in const [320.0, 412.0, 1024.0]) {
          testWidgets(
              '$mode ${compact ? 'compact' : 'open'} at ${width.toInt()}dp: '
              'one grey pill, on the selected tab only, holding its icon',
              (tester) async {
            await _pumpBar(tester,
                locale: locale, dark: dark, width: width, compact: compact);
            for (var i = 0; i < _order.length; i++) {
              await tester.tap(_icons.at(i));
              await tester.pumpAndSettle();
              expect(_pill, findsOneWidget, reason: 'tab $i');
              final pill = tester.getRect(_pill);
              final tab = tester.getRect(_tab(i));
              expect(tab.contains(pill.center), isTrue, reason: 'tab $i');
              final icon = tester.getRect(_icons.at(i));
              expect(
                  pill.contains(icon.topLeft) &&
                      pill.contains(icon.bottomRight),
                  isTrue,
                  reason: 'icon inside the pill, tab $i');
              if (!compact) {
                final label = tester.getRect(find
                    .descendant(of: _tab(i), matching: find.byType(Text))
                    .first);
                expect(pill.left <= label.left && pill.right >= label.right,
                    isTrue,
                    reason: 'label inside the pill, tab $i');
                expect(pill.bottom, greaterThanOrEqualTo(label.bottom));
              }
              expect(
                tester.getSemantics(_icons.at(i)),
                isSemantics(isSelected: true, isButton: true),
              );
            }
          });
        }
      }

      testWidgets('$mode: selected is brand ink, the rest primary text',
          (tester) async {
        await _pumpBar(tester, locale: locale, dark: dark);
        final c = _colors(tester);
        for (var sel = 0; sel < _order.length; sel++) {
          await tester.tap(_icons.at(sel));
          await tester.pumpAndSettle();
          for (var i = 0; i < _order.length; i++) {
            final want = i == sel ? c.primaryInk : c.textPrimary;
            expect(_iconInk(tester, i), want, reason: 'icon $i, sel $sel');
            expect(_labelInk(tester, i), want, reason: 'label $i, sel $sel');
          }
          expect(_pillFill(tester), DashboardNavigationBar.pillFill(c));
        }
      });

      testWidgets('$mode: every ink keeps AA on what it is drawn over',
          (tester) async {
        await _pumpBar(tester, locale: locale, dark: dark);
        for (var sel = 0; sel < _order.length; sel++) {
          await tester.tap(_icons.at(sel));
          await tester.pumpAndSettle();
          final pill = _pillFill(tester);
          // The pill is opaque, so the selected ink sits on exactly it.
          expect(pill.a, 1);
          expect(AppContrast.ratio(_iconInk(tester, sel), pill),
              greaterThanOrEqualTo(4.5));
          expect(AppContrast.ratio(_labelInk(tester, sel), pill),
              greaterThanOrEqualTo(4.5));
          // Unselected tabs sit on glass over whatever scrolls behind it.
          final glass = _glassFill(tester);
          for (final behind in const [
            Color(0xFF000000),
            Color(0xFFFFFFFF),
            Color(0xFF808080),
          ]) {
            final under = Color.alphaBlend(glass, behind);
            for (var i = 0; i < _order.length; i++) {
              if (i == sel) continue;
              expect(AppContrast.ratio(_iconInk(tester, i), under),
                  greaterThanOrEqualTo(4.5),
                  reason: 'icon $i over $behind');
              expect(AppContrast.ratio(_labelInk(tester, i), under),
                  greaterThanOrEqualTo(4.5),
                  reason: 'label $i over $behind');
            }
          }
        }
      });
    }

    testWidgets('$locale: switching is instant, the first frame is final',
        (tester) async {
      await _pumpBar(tester, locale: locale, dark: false);
      for (var from = 0; from < _order.length; from++) {
        for (var to = 0; to < _order.length; to++) {
          if (from == to) continue;
          await tester.tap(_icons.at(from));
          await tester.pumpAndSettle();
          await tester.tap(_icons.at(to));
          await tester.pump();
          final pill = tester.getRect(_pill);
          final inks = [
            for (var i = 0; i < _order.length; i++) _labelInk(tester, i),
          ];
          final widths = [
            for (var i = 0; i < _order.length; i++)
              tester.getSize(find
                  .descendant(of: _tab(i), matching: find.byType(Text))
                  .first),
          ];
          await tester.pumpAndSettle();
          expect(tester.getRect(_pill), pill, reason: '$from → $to');
          expect(tester.getRect(_tab(to)).contains(pill.center), isTrue);
          for (var i = 0; i < _order.length; i++) {
            expect(_labelInk(tester, i), inks[i], reason: '$from → $to');
            expect(
                tester.getSize(find
                    .descendant(of: _tab(i), matching: find.byType(Text))
                    .first),
                widths[i]);
          }
        }
      }
    });

    testWidgets('$locale: tabs run from the reading start', (tester) async {
      await _pumpBar(tester, locale: locale, dark: false);
      final xs = [
        for (var i = 0; i < _order.length; i++)
          tester.getCenter(_icons.at(i)).dx,
      ];
      for (var i = 1; i < xs.length; i++) {
        if (locale.languageCode == 'ar') {
          expect(xs[i], lessThan(xs[i - 1]), reason: 'RTL starts right');
        } else {
          expect(xs[i], greaterThan(xs[i - 1]), reason: 'LTR starts left');
        }
      }
    });

    for (final compact in const [false, true]) {
      testWidgets(
          '$locale ${compact ? 'compact' : 'open'} at 320dp: tap targets '
          'meet the guidelines', (tester) async {
        final semantics = tester.ensureSemantics();
        await _pumpBar(tester,
            locale: locale, dark: false, width: 320, compact: compact);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        for (var i = 0; i < _order.length; i++) {
          final size = tester.getSize(_tab(i));
          expect(size.height, greaterThanOrEqualTo(AppTouchTarget.min));
          expect(size.width, greaterThanOrEqualTo(AppTouchTarget.min));
        }
        semantics.dispose();
      });
    }
  }
}
