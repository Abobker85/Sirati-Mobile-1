import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sirati/theme/app_theme.dart';
import 'package:sirati/widgets/animated_ats_score_bar.dart';
import 'package:sirati/widgets/empty_state.dart';
import 'package:sirati/widgets/form_fields.dart';
import 'package:sirati/widgets/loading/ai_field_loading_overlay.dart';
import 'package:sirati/widgets/loading/app_skeleton.dart';
import 'package:sirati/widgets/motion.dart';
import 'package:sirati/widgets/password_strength_meter.dart';
import 'package:sirati/widgets/submit_button.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );
  }

  testWidgets('AppEmptyState shows title and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      AppEmptyState(
        icon: Icons.description_outlined,
        title: 'No CVs yet',
        subtitle: 'Create one',
        actionLabel: 'Create',
        onAction: () => tapped = true,
        scrollable: false,
      ),
    ));

    expect(find.text('No CVs yet'), findsOneWidget);
    expect(find.text('Create one'), findsOneWidget);
    await tester.tap(find.text('Create'));
    expect(tapped, isTrue);
  });

  testWidgets('AppErrorState shows retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(wrap(
      AppErrorState(
        english: true,
        message: 'Network down',
        onRetry: () => retried = true,
        scrollable: false,
      ),
    ));

    expect(find.text('Could not load'), findsOneWidget);
    expect(find.text('Network down'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('AppSkeleton builds without throwing', (tester) async {
    await tester.pumpWidget(wrap(
      const DashboardSkeleton(horizontalPadding: 16),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AppSkeleton), findsWidgets);
  });

  testWidgets('SubmitButton locks height while loading', (tester) async {
    await tester.pumpWidget(wrap(
      const SubmitButton(
        label: 'Save',
        loadingLabel: 'Saving...',
        isLoading: true,
        onPressed: null,
      ),
    ));

    expect(find.text('Saving...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final box = tester.renderObject<RenderBox>(find.byType(SubmitButton));
    expect(box.size.height, 54);
  });

  test('PasswordStrengthMeter evaluates boundaries', () {
    expect(PasswordStrengthMeter.evaluate(''), PasswordStrength.empty);
    expect(PasswordStrengthMeter.evaluate('1234567'), PasswordStrength.weak);
    expect(PasswordStrengthMeter.evaluate('abcdefgh'), PasswordStrength.medium);
    expect(
        PasswordStrengthMeter.evaluate('Abcdef12!'), PasswordStrength.strong);
  });

  testWidgets('PasswordStrengthMeter exposes one Arabic live-region label',
      (tester) async {
    await tester.pumpWidget(wrap(
      const PasswordStrengthMeter(password: 'Abcdef12!', english: false),
    ));

    expect(find.text('قوية'), findsOneWidget);
    expect(find.bySemanticsLabel('قوة كلمة المرور: قوية'), findsOneWidget);
  });

  testWidgets('AnimatedAtsScoreBar reaches value and exposes percentage',
      (tester) async {
    await tester.pumpWidget(wrap(
      const AnimatedAtsScoreBar(
        value: .72,
        color: AppColors.primary,
        semanticLabel: 'ATS score',
      ),
    ));
    await tester.pumpAndSettle();

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, .72);
    expect(find.bySemanticsLabel('ATS score'), findsOneWidget);
  });

  testWidgets('AiFieldLoadingOverlay blocks interaction while loading',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(
      SizedBox(
        height: 80,
        child: AiFieldLoadingOverlay(
          isLoading: true,
          semanticsLabel: 'Improving content',
          statusMessages: const ['Working…'],
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('Edit'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Edit'), warnIfMissed: false);
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Working…'), findsOneWidget);
  });

  testWidgets('MotionTabStack preserves tab state while transitioning',
      (tester) async {
    var currentIndex = 0;
    late StateSetter updateHost;

    await tester.pumpWidget(wrap(
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return SizedBox(
            height: 220,
            child: MotionTabStack(
              currentIndex: currentIndex,
              children: const [
                TextField(key: ValueKey('motion-tab-field')),
                Center(child: Text('Second tab')),
              ],
            ),
          );
        },
      ),
    ));

    await tester.enterText(
      find.byKey(const ValueKey('motion-tab-field')),
      'Preserved draft',
    );
    updateHost(() => currentIndex = 1);
    await tester.pumpAndSettle();
    updateHost(() => currentIndex = 0);
    await tester.pumpAndSettle();

    expect(find.text('Preserved draft'), findsOneWidget);
  });

  testWidgets('MotionTabStack becomes static when animations are disabled',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: MotionTabStack(
              currentIndex: 0,
              children: [Text('One'), Text('Two')],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(IndexedStack), findsOneWidget);
    expect(find.byType(AnimatedSlide), findsNothing);
  });

  testWidgets('AppTextFormField animates primary focus chrome', (tester) async {
    await tester.pumpWidget(wrap(
      AppTextFormField(hintText: 'Email'),
    ));

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final animated = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(AppTextFormField),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final decoration = animated.decoration! as BoxDecoration;
    expect(decoration.border!.top.color, AppColors.primary);
  });

  testWidgets('MotionNavIcon shows the selected capsule and icon',
      (tester) async {
    await tester.pumpWidget(wrap(
      const MotionNavIcon(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        selected: true,
        selectedBackgroundColor: AppColors.primaryLight,
      ),
    ));

    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(MotionNavIcon),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.primaryLight);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
  });
}
