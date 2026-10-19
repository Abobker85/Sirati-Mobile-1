import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/auth_form_constraint.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  testWidgets('login centers the brand header and start-aligns fields',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en', 'US'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const LoginScreen(),
      ),
    ));

    expect(find.byType(AuthFormConstraint), findsOneWidget);
    expect(find.text('Welcome to Sirati'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);

    final title = tester.widget<Text>(find.text('Welcome to Sirati'));
    expect(title.textAlign, TextAlign.center);

    final subtitle = tester.widget<Text>(find.text('Sign in to continue'));
    expect(subtitle.textAlign, TextAlign.center);

    final emailLabel = tester.widget<Text>(find.text('Email'));
    expect(emailLabel.textAlign, TextAlign.start);

    final scroll = find.byType(SingleChildScrollView);
    expect(scroll, findsOneWidget);
    expect(
      find.descendant(
        of: scroll,
        matching: find.text('Welcome to Sirati'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: scroll, matching: find.text('Sign in')),
      findsOneWidget,
    );
  });

  for (final arabic in [false, true]) {
    for (final dark in [false, true]) {
      phoneLoginTest(arabic: arabic, dark: dark);
    }
  }
}

void phoneLoginTest({required bool arabic, required bool dark}) {
  testWidgets('phone login scrolls at 200 percent (arabic=$arabic, dark=$dark)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: dark
            ? AppTheme.darkFor(arabic: arabic)
            : AppTheme.lightFor(arabic: arabic),
        locale: Locale(arabic ? 'ar' : 'en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    ));
    await tester.pump();

    final scroll = find.byType(SingleChildScrollView);
    final position = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: scroll,
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    expect(position.maxScrollExtent, greaterThan(0));

    final title = find.text(arabic ? 'مرحباً بك في سيرتي' : 'Welcome to Sirati');
    final titleBefore = tester.getTopLeft(title).dy;
    await tester.drag(scroll, const Offset(0, -240));
    await tester.pump();
    expect(
      tester.getTopLeft(title).dy,
      lessThan(titleBefore),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.ensureVisible(find.byType(SubmitButton));
    await tester.pumpAndSettle();
    expect(find.byType(SubmitButton).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
