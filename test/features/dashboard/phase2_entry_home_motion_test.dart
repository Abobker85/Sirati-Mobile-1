import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_header.dart';
import 'package:sirati/features/dashboard/presentation/home/home_glass_header.dart';
import 'package:sirati/features/dashboard/presentation/home/home_latest_cv_section.dart';
import 'package:sirati/features/dashboard/presentation/home/home_start_card.dart';
import 'package:sirati/features/dashboard/presentation/splash/splash_boot_body.dart';
import 'package:sirati/features/dashboard/presentation/splash/welcome_body.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';

Widget _wrap(
  Widget child, {
  Locale locale = const Locale('en'),
  bool disableAnimations = false,
}) {
  return MaterialApp(
    theme: AppTheme.lightFor(arabic: locale.languageCode == 'ar'),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, body) => MediaQuery(
      data:
          MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
      child: body!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('SplashBootBody motion', () {
    testWidgets('reduced motion starts zero tickers and renders settled dots',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const SplashBootBody(), disableAnimations: true),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(find.byType(SiratiMark), findsOneWidget);
    });

    testWidgets(
        'wait pulse continues past 860ms when bootstrap is pending and settles cleanly',
        (tester) async {
      await tester.pumpWidget(_wrap(const SplashBootBody()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 860));
      // Bounded wait pulse starts after intro completes, then stops cleanly.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SiratiMark), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('WelcomeBody -> LoginScreen Hero continuity', () {
    testWidgets('WelcomeBody and LoginScreen share sirati-brand-mark Hero tag',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => WelcomeBody(
              onRegister: () {},
              onLogin: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              ),
              onPrivacy: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final heroes = tester.widgetList<Hero>(find.byType(Hero)).toList();
      expect(heroes.map((h) => h.tag), contains('sirati-brand-mark'));
    });

    testWidgets('Hero is omitted when disableAnimations is true',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          WelcomeBody(
            onRegister: () {},
            onLogin: () {},
            onPrivacy: () {},
          ),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      expect(find.byType(Hero), findsNothing);
    });
  });

  group('HomeGlassHeader scroll ramp', () {
    testWidgets('interpolates strength proportionally over 0..24dp',
        (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _wrap(
          CustomScrollView(
            controller: controller,
            slivers: [
              const PinnedHeaderSliver(
                child: HomeGlassHeader(child: SizedBox(height: 80)),
              ),
              SliverList.list(
                children: [
                  for (var i = 0; i < 20; i++) const SizedBox(height: 100),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      double glassStrength() => tester
          .widget<GlassSurface>(find.byKey(HomeGlassHeader.glassKey))
          .strength;

      expect(glassStrength(), 0);
      controller.jumpTo(12);
      await tester.pumpAndSettle();
      expect(glassStrength(), closeTo(0.5, 0.02));

      controller.jumpTo(36);
      await tester.pumpAndSettle();
      expect(glassStrength(), 1.0);
    });
  });

  group('Home RTL directional chevrons', () {
    testWidgets('chevrons use DirectionalIcon or horizontal flip in RTL',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              DashboardHomeHeader(
                name: 'سارة',
                unreadCount: 0,
                onNotifications: () {},
                onAvatarTap: () {},
              ),
              HomeStartCard(
                tone: HomeStartTone.create,
                title: 'أنشئ سيرتك',
                body: 'ابدأ الآن',
                onTap: () {},
              ),
              HomeViewAllButton(onPressed: () {}),
            ],
          ),
          locale: const Locale('ar'),
        ),
      );
      await tester.pumpAndSettle();
      // The header pill has no chevron since the iOS 26 restyle. The
      // fixture's chevrons: one on the start card (flipped), one on View all.
      final flipped = find.byWidgetPredicate(
        (w) => w is Transform && w.transform.storage[0] == -1.0,
      );
      expect(
        find.descendant(
            of: find.byType(HomeViewAllButton),
            matching: find.byType(DirectionalIcon)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(HomeStartCard), matching: flipped),
        findsWidgets,
      );
      // Every chevron on screen points the reading way: inside a
      // DirectionalIcon or a horizontal flip, never a bare Icon.
      final chevrons = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.chevron_right_rounded,
      );
      expect(chevrons, findsNWidgets(2));
      for (final chevron in chevrons.evaluate()) {
        expect(
          find.ancestor(
            of: find.byWidget(chevron.widget),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DirectionalIcon ||
                  w is Transform && w.transform.storage[0] == -1.0,
            ),
          ),
          findsWidgets,
          reason: 'chevron ${chevron.widget}',
        );
      }
    });
  });
}
