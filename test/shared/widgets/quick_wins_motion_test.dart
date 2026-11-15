import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/auth/presentation/forgot_password_screen.dart';
import 'package:sirati/features/settings/presentation/notifications_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  bool reduce = false,
}) =>
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Directionality(
        textDirection: direction,
        child: Theme(
          data: AppTheme.lightFor(arabic: direction == TextDirection.rtl),
          child: Center(child: SizedBox(width: 200, height: 100, child: child)),
        ),
      ),
    );

class _FakeAuth extends AuthApiService {
  int sent = 0;

  @override
  Future<void> forgotPassword({required String email}) async => sent++;
}

void main() {
  group('step switcher', () {
    Widget step(int n, {TextDirection d = TextDirection.ltr, bool r = false}) =>
        _host(
          MotionStepSwitcher(
            stepKey: n,
            child: SizedBox.expand(key: ValueKey('step-$n')),
          ),
          direction: d,
          reduce: r,
        );

    for (final d in TextDirection.values) {
      testWidgets('$d: the next step comes in from the reading end and rests',
          (tester) async {
        await tester.pumpWidget(step(1, d: d));
        final rest = tester.getRect(find.byKey(const ValueKey('step-1')));
        await tester.pumpWidget(step(2, d: d));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        final early = tester.getRect(find.byKey(const ValueKey('step-2')));
        final dx = early.left - rest.left;
        // In English the reading end is the right, in Arabic the left.
        if (d == TextDirection.ltr) {
          expect(dx, greaterThan(0));
        } else {
          expect(dx, lessThan(0));
        }
        expect(dx.abs(), lessThanOrEqualTo(200 * MotionStepSwitcher.slide));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(const ValueKey('step-2'))), rest);
        expect(find.byKey(const ValueKey('step-1')), findsNothing);
      });
    }

    testWidgets('reduced motion swaps at once', (tester) async {
      await tester.pumpWidget(step(1, r: true));
      await tester.pumpWidget(step(2, r: true));
      expect(find.byKey(const ValueKey('step-1')), findsNothing);
      expect(find.byKey(const ValueKey('step-2')), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('morph', () {
    Widget morph(bool done, {bool r = false}) => _host(
          MotionMorph(
            morphKey: done,
            child: SizedBox.square(key: ValueKey('state-$done'), dimension: 40),
          ),
          reduce: r,
        );

    testWidgets('the new state grows in with a small overshoot and settles',
        (tester) async {
      await tester.pumpWidget(morph(false));
      await tester.pumpWidget(morph(true));
      final sizes = <double>[];
      for (var f = 0; f < 50; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        final w = tester.getSize(find.byKey(const ValueKey('state-true')));
        sizes.add(
            tester.getRect(find.byKey(const ValueKey('state-true'))).width);
        expect(w.width, 40);
      }
      await tester.pumpAndSettle();
      expect(sizes.first, lessThan(40), reason: 'starts small');
      expect(sizes.reduce((a, b) => a > b ? a : b), greaterThan(40),
          reason: 'overshoots a little');
      expect(
          tester.getRect(find.byKey(const ValueKey('state-true'))).width, 40);
      expect(find.byKey(const ValueKey('state-false')), findsNothing);
    });

    testWidgets('reduced motion swaps at once', (tester) async {
      await tester.pumpWidget(morph(false, r: true));
      await tester.pumpWidget(morph(true, r: true));
      expect(find.byKey(const ValueKey('state-false')), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('unread dot', () {
    Widget dots(bool unread, {int count = 9, bool r = false}) => _host(
          Row(children: [
            for (var i = 0; i < count; i++)
              NotificationUnreadDot(
                key: ValueKey('dot-$i'),
                unread: unread,
                order: i,
                label: 'unread',
                color: const Color(0xFF006A60),
              ),
          ]),
          reduce: r,
        );

    double shown(WidgetTester tester, int i) {
      final dot = find.byKey(ValueKey('dot-$i'));
      final opacity = find.descendant(of: dot, matching: find.byType(Opacity));
      if (opacity.evaluate().isEmpty) return 0;
      return tester.widget<Opacity>(opacity).opacity;
    }

    testWidgets(
        'marking read: dots go one after another (capped), then are gone',
        (tester) async {
      await tester.pumpWidget(dots(true));
      for (var i = 0; i < 9; i++) {
        expect(shown(tester, i), 1);
      }
      await tester.pumpWidget(dots(false));
      // Each dot starts going no earlier than the one before it.
      final goneAt = List<int?>.filled(9, null);
      final startedAt = List<int?>.filled(9, null);
      for (var f = 0; f < 60; f++) {
        await tester.pump(const Duration(milliseconds: 10));
        for (var i = 0; i < 9; i++) {
          final s = shown(tester, i);
          if (s < 1 && startedAt[i] == null) startedAt[i] = f;
          if (s == 0 && goneAt[i] == null) goneAt[i] = f;
        }
      }
      for (var i = 1; i < 9; i++) {
        expect(startedAt[i]!, greaterThanOrEqualTo(startedAt[i - 1]!),
            reason: 'dot $i');
      }
      expect(startedAt[NotificationUnreadDot.maxStagger]! - startedAt[0]!,
          greaterThan(0),
          reason: 'they do not all go together');
      for (var i = NotificationUnreadDot.maxStagger; i < 9; i++) {
        expect(startedAt[i], startedAt[NotificationUnreadDot.maxStagger],
            reason: 'after the cap they go together');
      }
      for (var i = 0; i < 9; i++) {
        expect(goneAt[i], isNotNull, reason: 'dot $i is gone');
      }
    });

    testWidgets('screen readers hear "unread" only on unread items',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(dots(true, count: 1));
      expect(find.bySemanticsLabel('unread'), findsOneWidget);
      await tester.pumpWidget(dots(false, count: 1));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('unread'), findsNothing);
      semantics.dispose();
    });

    testWidgets('reduced motion: gone at once', (tester) async {
      await tester.pumpWidget(dots(true, r: true));
      await tester.pumpWidget(dots(false, r: true));
      for (var i = 0; i < 9; i++) {
        expect(shown(tester, i), 0);
      }
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('forgot password', () {
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

    for (final lang in ['ar', 'en']) {
      testWidgets(
          '$lang: after the code is sent the next stage slides in and the '
          'code field has focus', (tester) async {
        AppLocale.languageCode.value = lang;
        final auth = _FakeAuth();
        await tester.pumpWidget(ProviderScope(
          overrides: [authApiServiceProvider.overrideWithValue(auth)],
          child: MaterialApp(
            theme: AppTheme.lightFor(arabic: lang == 'ar'),
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ForgotPasswordScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
            tester.element(find.byType(ForgotPasswordScreen)));
        await tester.enterText(find.byType(EditableText).first, 'a@b.co');
        await tester.tap(find.text(l.authForgotSendCode));
        await tester.pump();
        await tester.pump();
        expect(auth.sent, 1);
        expect(find.byType(MotionStepSwitcher), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text(l.authForgotSendCode), findsNothing);
        expect(find.text(l.authVerificationCodeLabel), findsOneWidget);
        final focused = FocusManager.instance.primaryFocus;
        expect(focused, isNotNull);
        // The code field is the only number field on the screen.
        final focusedField = tester
            .widgetList<EditableText>(find.byType(EditableText))
            .where((e) => e.focusNode == focused);
        expect(focusedField, hasLength(1));
        expect(focusedField.single.keyboardType, TextInputType.number,
            reason: 'the code field has focus');
        AppLocale.languageCode.value = 'en';
      });
    }
  });
}
