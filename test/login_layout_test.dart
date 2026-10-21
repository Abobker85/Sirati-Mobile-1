import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/auth_form_constraint.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

import 'support/contrast_probe.dart';

void expectHeaderPaint(WidgetTester tester) {
  final mark = tester.element(find.byType(SiratiMark));
  final colors = Theme.of(mark).extension<SiratiColors>()!;
  expect(paintedBackgroundsOf(mark), [colors.surface]);
  final headers = <BoxDecoration>[];
  mark.visitAncestorElements((ancestor) {
    if (ancestor.widget is DecoratedBox) {
      final paint = ancestor.findRenderObject()! as RenderDecoratedBox;
      final decoration = paint.decoration;
      if (decoration is BoxDecoration && decoration.border != null) {
        headers.add(decoration);
      }
    }
    return true;
  });
  expect(headers, hasLength(1));
  expect(headers.single.color, colors.surface);
  final border = headers.single.border! as Border;
  expect(border.bottom.color, colors.outline);
  expect(border.bottom.width, greaterThan(0));
  final markPaint = tester.renderObject<RenderDecoratedBox>(find.descendant(
    of: find.byType(SiratiMark), matching: find.byType(DecoratedBox)));
  final decoration = markPaint.decoration as BoxDecoration;
  expect(decoration.shape, BoxShape.circle);
  expect(decoration.gradient, isA<LinearGradient>());
  expect(decoration.boxShadow, isNull);
}

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
    expect(find.text('Welcome to Siratie'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);

    final title = tester.widget<Text>(find.text('Welcome to Siratie'));
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
        matching: find.text('Welcome to Siratie'),
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
    for (final size in const [
      Size(390, 844), Size(390, 520), Size(390, 519), Size(390, 480),
    ]) {
      shortLoginTest(arabic: arabic, size: size, keyboard: false);
      if (size.height < 520) {
        shortLoginTest(arabic: arabic, size: size, keyboard: true);
      }
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

    expectHeaderPaint(tester);

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

    final title = find.text(arabic ? 'مرحباً بك في سيرتي' : 'Welcome to Siratie');
    final titleBefore = tester.getTopLeft(title).dy;
    await tester.drag(scroll, const Offset(0, -240));
    await tester.pump();
    expectHeaderPaint(tester);
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

void shortLoginTest({
  required bool arabic,
  required Size size,
  required bool keyboard,
}) {
  final language = arabic ? 'ar' : 'en';
  final signIn = arabic ? 'تسجيل الدخول' : 'Sign in';
  final banner = arabic
      ? 'يرجى تصحيح الحقول المحددة للمتابعة.'
      : 'Please fix the highlighted fields to continue.';
  testWidgets(
    'login header at ${size.width.toInt()}x${size.height.toInt()} '
    'keyboard=$keyboard ($language)',
    (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightFor(arabic: arabic),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LoginScreen(),
        ),
      ));
      await tester.pump();

      expectHeaderPaint(tester);

      final scroll = find.byType(SingleChildScrollView);
      expect(scroll, findsOneWidget);
      expect(
        find.descendant(of: scroll, matching: find.byType(SiratiMark)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: scroll, matching: find.text(signIn)),
        findsOneWidget,
      );

      final mark = tester.widget<SiratiMark>(find.byType(SiratiMark));
      if (size.height < 520) {
        expect(mark.size, lessThan(56));
        expect(mark.size, greaterThanOrEqualTo(32));
      } else {
        expect(mark.size, 56);
      }

      if (keyboard) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 320);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();
        expectHeaderPaint(tester);
        expect(
          tester.widget<SiratiMark>(find.byType(SiratiMark)).size,
          lessThan(56),
        );
        final position = tester
            .state<ScrollableState>(
              find
                  .descendant(of: scroll, matching: find.byType(Scrollable))
                  .first,
            )
            .position;
        expect(position.maxScrollExtent, greaterThan(0));
        expect(find.byType(SubmitButton).hitTestable(), findsNothing);
        await tester.ensureVisible(find.byType(SubmitButton));
        await tester.pump();
      }

      await tester.ensureVisible(find.byType(SubmitButton));
      await tester.pump();
      expect(find.byType(SubmitButton).hitTestable(), findsOneWidget);
      await tester.tap(find.byType(SubmitButton));
      await tester.pump();
      expect(find.text(banner), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
