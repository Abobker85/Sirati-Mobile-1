import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_navigation_bar.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/theme/app_theme.dart';

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
        'every dashboard tab can be activated through semantics ($locale)',
        (tester) async {
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(412, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var current = DashboardTab.home;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightFor(arabic: locale.languageCode == 'ar'),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            bottomNavigationBar: DashboardNavigationBar(
              current: current,
              onChanged: (t) => setState(() => current = t),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final buttons = find.descendant(
        of: find.byType(DashboardNavigationBar),
        matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.selected != null),
      );
      expect(buttons, findsNWidgets(DashboardNavigationBar.order.length));
      for (var i = 0; i < DashboardNavigationBar.order.length; i++) {
        final target = DashboardNavigationBar.order[i];
        if (target == current) continue;
        final node = tester.getSemantics(buttons.at(i));
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue,
            reason: 'tab $i is a button with no tap action');
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(current, target);
      }
      handle.dispose();
    });
  }
}
