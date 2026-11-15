import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/dashboard/presentation/home/dashboard_home_header.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/sticky_text_direction.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.lightFor(arabic: false),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: c!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

String? _minLength(String? v) =>
    (v ?? '').trim().length < 3 ? 'too short' : null;

void main() {
  final haptics = <String>[];
  setUp(() {
    haptics.clear();
    ErrorShake.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add('${call.arguments}');
      }
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('one shake per submit', () {
    for (final fields in [1, 2, 4, 7]) {
      testWidgets('$fields invalid fields: one shake, one tick',
          (tester) async {
        final form = GlobalKey<FormState>();
        await tester.pumpWidget(_app(Form(
          key: form,
          child: Column(children: [
            for (var i = 0; i < fields; i++)
              AppTextFormField(validator: _minLength),
          ]),
        )));
        form.currentState!.validate();
        await tester.pump();
        final shaking = tester
            .stateList<ErrorShakeState>(find.byType(ErrorShake))
            .where((s) => s.shaking)
            .toList();
        expect(shaking, hasLength(1));
        // The one that shakes is the first field.
        expect(
          shaking.single,
          tester.stateList<ErrorShakeState>(find.byType(ErrorShake)).first,
        );
        expect(haptics, hasLength(1));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('a later, separate error may shake again', (tester) async {
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(_app(Form(
        key: form,
        child: AppTextFormField(validator: _minLength),
      )));
      form.currentState!.validate();
      await tester.pump();
      await tester.pumpAndSettle();
      form.currentState!.reset();
      await tester.pump(const Duration(seconds: 1));
      form.currentState!.validate();
      await tester.pump();
      expect(haptics, hasLength(2));
      await tester.pumpAndSettle();
    });
  });

  group('forgive while editing', () {
    // Any text, in any order: while the field has focus, typing never adds
    // or changes an error; it may only clear one.
    const sequences = [
      ['a', 'ab', 'abc', 'ab', 'a', ''],
      ['x', '', 'xyz', 'x'],
      ['مطو', 'م', 'مطور', ''],
    ];
    for (final seq in sequences) {
      testWidgets('typing ${seq.join(' → ')} while focused', (tester) async {
        final controller = TextEditingController();
        await tester.pumpWidget(_app(Column(children: [
          AppTextFormField(controller: controller, validator: _minLength),
          const TextField(key: ValueKey('other')),
        ])));
        // Blur once with a short value: the error shows (blur-first rule).
        await tester.tap(find.byType(TextField).first);
        await tester.enterText(find.byType(TextField).first, 'a');
        await tester.tap(find.byKey(const ValueKey('other')));
        await tester.pump();
        expect(find.text('too short'), findsOneWidget);

        // Back in the field: errors may only go away while typing.
        await tester.tap(find.byType(TextField).first);
        await tester.pump();
        var shown = find.text('too short').evaluate().isNotEmpty;
        for (final text in seq) {
          await tester.enterText(find.byType(TextField).first, text);
          await tester.pump();
          final now = find.text('too short').evaluate().isNotEmpty;
          if (!shown) expect(now, isFalse, reason: 'no new error at "$text"');
          shown = now;
        }

        // Leaving the field shows the error the rules give.
        await tester.tap(find.byKey(const ValueKey('other')));
        await tester.pump();
        expect(
          find.text('too short').evaluate().isNotEmpty,
          _minLength(seq.last) != null,
        );
        await tester.pumpAndSettle();
      });
    }
  });

  group('sticky text direction', () {
    const ambient = [TextDirection.ltr, TextDirection.rtl];
    const typed = [
      'Flutter مطور',
      'مطور Flutter',
      '123 مطور',
      'React Native و Flutter',
      '(مدير) Project',
    ];
    for (final fallback in ambient) {
      for (final text in typed) {
        test('${fallback.name}: "$text" typed letter by letter never flips',
            () {
          final sticky = StickyTextDirection();
          sticky.resolve('', focused: true, fallback: fallback);
          final dirs = <TextDirection>{};
          for (var i = 1; i <= text.length; i++) {
            dirs.add(sticky.resolve(text.substring(0, i),
                focused: true, fallback: fallback));
          }
          expect(dirs, hasLength(1));
        });
      }
    }

    test('re-decided when not focused, or after clearing the field', () {
      final sticky = StickyTextDirection();
      const f = TextDirection.rtl;
      expect(
          sticky.resolve('abc', focused: true, fallback: f), TextDirection.ltr);
      expect(sticky.resolve('abc مطور', focused: true, fallback: f),
          TextDirection.ltr);
      // Cleared and retyped: decided again from the new first letter.
      sticky.resolve('', focused: true, fallback: f);
      expect(
          sticky.resolve('م', focused: true, fallback: f), TextDirection.rtl);
      // Not focused (e.g. text set by AI or a draft): follows the text.
      expect(sticky.resolve('Hello', focused: false, fallback: f),
          TextDirection.ltr);
    });
  });

  group('unread bell', () {
    for (final counts in [
      [0, 1, 1, 3, 2, 0, 4],
      [5, 4, 3, 2, 1, 0],
      [0, 0, 9, 10, 10],
    ]) {
      testWidgets('rings only when the count rises: $counts', (tester) async {
        var expected = 0;
        int? previous;
        for (final n in counts) {
          await tester.pumpWidget(_app(
            UnreadBell(unreadCount: n, color: const Color(0xFF000000)),
          ));
          if (previous != null && n > previous) expected++;
          expect(
            tester.state<UnreadBellState>(find.byType(UnreadBell)).rises,
            expected,
          );
          previous = n;
          await tester.pump(const Duration(seconds: 3));
        }
      });
    }
  });
}
