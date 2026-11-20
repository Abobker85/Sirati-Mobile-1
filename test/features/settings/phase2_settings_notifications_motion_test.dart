import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/domain/notification_item.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/features/settings/presentation/onboarding_screen.dart';
import 'package:sirati/features/settings/presentation/settings/settings_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

Widget _app(
  Widget child, {
  Locale locale = const Locale('en'),
  bool disableAnimations = false,
}) {
  AppLocale.languageCode.value = locale.languageCode;
  return MaterialApp(
    theme: AppTheme.lightFor(arabic: locale.languageCode == 'ar'),
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, body) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(disableAnimations: disableAnimations),
      child: body!,
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, (_) async => null);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorage, null);
  });

  group('OnboardingScreen parallax & continuous dots', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      final rtl = locale.languageCode == 'ar';
      testWidgets('interpolates dot widths continuously on drag ($locale)',
          (tester) async {
        await tester.pumpWidget(
          _app(OnboardingScreen(onFinished: () {}), locale: locale),
        );
        await tester.pumpAndSettle();

        final pageView = find.byType(PageView);
        final width = tester.getSize(pageView).width;
        await tester.drag(pageView, Offset(rtl ? width * 0.4 : -width * 0.4, 0));
        await tester.pump();

        final dots = tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .map((d) => d.constraints?.maxWidth ?? 0)
            .toList();
        expect(dots, hasLength(3));
        expect(dots[0], greaterThan(8.0));
        expect(dots[0], lessThan(22.0));
        expect(dots[1], greaterThan(8.0));
        expect(dots[1], lessThan(22.0));

        await tester.pumpAndSettle();
      });
    }

    testWidgets('reduced motion renders without active tickers and jumps pages',
        (tester) async {
      await tester.pumpWidget(
        _app(OnboardingScreen(onFinished: () {}), disableAnimations: true),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('Instant ATS analysis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ThemeModeSelector MotionSegmentedPill', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('orders segments by reading direction ($locale)',
          (tester) async {
        var mode = ThemeMode.system;
        await tester.pumpWidget(
          _app(
            StatefulBuilder(
              builder: (context, setState) => ThemeModeSelector(
                mode: mode,
                onChanged: (next) => setState(() => mode = next),
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();

        final l10n = AppLocalizations.of(
          tester.element(find.byType(ThemeModeSelector)),
        );
        expect(find.byType(MotionSegmentedPill<ThemeMode>), findsOneWidget);
        final sysX = tester.getCenter(find.text(l10n.themeSystem)).dx;
        final darkX = tester.getCenter(find.text(l10n.themeDark)).dx;
        if (locale.languageCode == 'ar') {
          expect(sysX, greaterThan(darkX));
        } else {
          expect(sysX, lessThan(darkX));
        }

        await tester.tap(find.text(l10n.themeDark));
        await tester.pumpAndSettle();
        expect(mode, ThemeMode.dark);
      });
    }

    testWidgets('snaps under disableAnimations', (tester) async {
      var mode = ThemeMode.system;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => ThemeModeSelector(
              mode: mode,
              onChanged: (next) => setState(() => mode = next),
            ),
          ),
          disableAnimations: true,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Dark'));
      await tester.pump();
      expect(mode, ThemeMode.dark);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('NotificationInbox filter motion', () {
    testWidgets('uses MotionStateSwitcher and keeps vertical Scrollable first',
        (tester) async {
      final items = [
        NotificationItem.fromJson(const {
          'id': 1,
          'type': 'cv_ready',
          'title': 'CV Ready',
          'body': 'Done',
          'is_read': false,
        }),
        NotificationItem.fromJson(const {
          'id': 2,
          'type': 'job',
          'title': 'New Job',
          'body': 'Riyadh',
          'is_read': true,
        }),
      ];
      await tester.pumpWidget(
        _app(
          NotificationInbox(
            items: items,
            onRefresh: () async {},
            onOpen: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MotionStateSwitcher), findsOneWidget);
      final firstScrollable =
          tester.widget<Scrollable>(find.byType(Scrollable).first);
      expect(firstScrollable.axisDirection, AxisDirection.down);

      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();
      expect(find.text('CV Ready'), findsOneWidget);
      expect(find.text('New Job'), findsNothing);
    });
  });
}
