import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';
import 'package:sirati/shared/widgets/app_list_tile.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/components.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/job_title_picker_field.dart';
import 'package:sirati/shared/widgets/language_toggle.dart';
import 'package:sirati/shared/widgets/loading/ai_field_loading_overlay.dart';
import 'package:sirati/shared/widgets/loading/ai_progress_overlay.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';
import 'package:sirati/shared/widgets/password_strength_meter.dart';
import 'package:sirati/shared/widgets/score_booster_card.dart';
import 'package:sirati/shared/widgets/screen_header.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

import '../support/contrast_probe.dart';

// Acceptance coverage for the production shared components consumed by auth,
// settings, CV editors, dashboard headers and AI generation/analysis callers.
Widget app(
  ThemeData theme,
  TextDirection direction,
  Widget child, {
  bool disableAnimations = true,
  bool? supportsAnnounce,
}) =>
    MaterialApp(
      theme: theme,
      locale: Locale(direction == TextDirection.rtl ? 'ar' : 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, body) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2),
          disableAnimations: disableAnimations,
          supportsAnnounce: supportsAnnounce,
        ),
        child: Directionality(textDirection: direction, child: body!),
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

/// InputDecorator attaches [message] as the field hint, and adds a live
/// region for that same text only when the platform cannot announce
/// (`liveRegion: !MediaQuery.supportsAnnounceOf`).
void expectFieldAnnouncesErrorOnce(
  WidgetTester tester, {
  required String message,
  required Finder fieldFinder,
}) {
  final supportsAnnounce = MediaQuery.supportsAnnounceOf(
    tester.element(fieldFinder),
  );
  final all = nodes(
    tester.binding.renderViews.single.owner!.semanticsOwner!.rootSemanticsNode!,
  ).toList();
  final field = nodes(tester.getSemantics(fieldFinder))
      .singleWhere((node) => node.flagsCollection.isTextField);
  expect(
    field.hint,
    message,
    reason: 'error text must be on the field semantics node',
  );
  final live = all.where((node) => node.flagsCollection.isLiveRegion &&
      [node.label, node.hint, node.value].any((text) => text.contains(message)))
      .toList();
  if (supportsAnnounce) {
    expect(
      live,
      isEmpty,
      reason: 'announce support means the error is not also a live region',
    );
  } else {
    expect(live, hasLength(1));
    final spoken =
        '${live.single.label} ${live.single.hint} ${live.single.value}';
    expect(spoken, contains(message));
  }
}

Iterable<SemanticsNode> nodes(SemanticsNode node) sync* {
  yield node;
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* nodes(child);
  }
}

void textPair(Color ink, Color fill) => expect(
      AppContrast.ratio(Color.alphaBlend(ink, fill), fill),
      greaterThanOrEqualTo(4.5),
      reason: '$ink on $fill',
    );

void uiPair(Color ink, Color fill) => expect(
      AppContrast.ratio(Color.alphaBlend(ink, fill), fill),
      greaterThanOrEqualTo(3),
      reason: '$ink on $fill',
    );

double _indeterminateSweep(WidgetTester tester) {
  final paint = tester.renderObject<RenderCustomPaint>(
    find.descendant(
      of: find.byType(LinearProgressIndicator),
      matching: find.byType(CustomPaint),
    ),
  );
  final painter = paint.painter;
  if (painter == null) {
    fail('indeterminate bar has no painter');
  }
  final value = (painter as dynamic).animationValue;
  if (value is! num) {
    fail('indeterminate bar painter exposes no animation value');
  }
  return value.toDouble();
}

Color renderedTextColor(WidgetTester tester, Finder finder) {
  final renderParagraph = tester.renderObject<RenderParagraph>(finder);
  final inlineSpan = renderParagraph.text;
  if (inlineSpan is TextSpan && inlineSpan.style?.color != null) {
    return inlineSpan.style!.color!;
  }
  return DefaultTextStyle.of(tester.element(finder)).style.color!;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('painted shared controls meet contrast, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = dark ? AppTheme.dark : AppTheme.light;
      const direction = TextDirection.ltr;

      // ── A1: AppTextFormField resting & floating/focused label color ──
      await tester.pumpWidget(
        app(
          theme,
          direction,
          AppTextFormField(labelText: 'Email'),
          disableAnimations: false,
        ),
      );
      await tester.pump();
      final deco =
          tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
      final fill = deco.fillColor!;
      final enabled = deco.enabledBorder! as OutlineInputBorder;
      final focusedBorder = deco.focusedBorder! as OutlineInputBorder;
      expect(enabled.borderSide.color.a, 1);
      expect(focusedBorder.borderSide.color.a, 1);
      uiPair(enabled.borderSide.color, fill);
      uiPair(focusedBorder.borderSide.color, fill);

      final restingColor = renderedTextColor(tester, find.text('Email'));
      textPair(restingColor, fill);
      expect(restingColor, theme.extension<SiratiColors>()!.textSecondary);

      await tester.showKeyboard(find.byType(EditableText));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final floatingColor = renderedTextColor(tester, find.text('Email'));
      textPair(floatingColor, fill);
      expect(floatingColor, theme.extension<SiratiColors>()!.primaryInk);

      // ── A1: AppInput resting & floating/focused label color ──
      await tester.pumpWidget(
        app(
          theme,
          direction,
          const AppInput(label: 'Username'),
          disableAnimations: false,
        ),
      );
      await tester.pump();
      final inputDeco =
          tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
      final inputFill =
          inputDeco.fillColor ?? theme.inputDecorationTheme.fillColor!;
      final inputRestingColor =
          renderedTextColor(tester, find.text('Username'));
      textPair(inputRestingColor, inputFill);
      expect(inputRestingColor, theme.extension<SiratiColors>()!.textSecondary);

      await tester.showKeyboard(find.byType(EditableText));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final inputFloatingColor =
          renderedTextColor(tester, find.text('Username'));
      textPair(inputFloatingColor, inputFill);
      expect(inputFloatingColor, theme.extension<SiratiColors>()!.primaryInk);

      // ── A6: Real input hint states ──
      await tester.pumpWidget(
        app(
          theme,
          direction,
          AppTextFormField(hintText: 'Enter keyword'),
        ),
      );
      await tester.pump();
      final formHintColor =
          renderedTextColor(tester, find.text('Enter keyword'));
      textPair(formHintColor, fill);
      expect(formHintColor, theme.extension<SiratiColors>()!.textHint);

      await tester.pumpWidget(
        app(
          theme,
          direction,
          const AppInput(hint: 'Search jobs'),
        ),
      );
      await tester.pump();
      final inputHintColor =
          renderedTextColor(tester, find.text('Search jobs'));
      textPair(inputHintColor, inputFill);
      expect(inputHintColor, theme.extension<SiratiColors>()!.textHint);

      // ── A6: Real input error states ──
      const message = 'Enter a valid value';
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        app(
          theme,
          direction,
          Form(
            key: form,
            child: AppTextFormField(
              labelText: 'Email',
              validator: (_) => message,
            ),
          ),
        ),
      );
      form.currentState!.validate();
      await tester.pump(const Duration(milliseconds: 400));
      final errorDeco =
          tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
      final errorBorder = errorDeco.errorBorder! as OutlineInputBorder;
      expect(errorBorder.borderSide.color.a, 1);
      uiPair(errorBorder.borderSide.color, errorDeco.fillColor!);
      expect(
          errorBorder.borderSide.color, theme.extension<SiratiColors>()!.error);
      final icon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(icon.color!.a, 1);
      uiPair(icon.color!, errorDeco.fillColor!);
      expect(icon.color, theme.extension<SiratiColors>()!.error);
      final errorColor = renderedTextColor(tester, find.text(message));
      textPair(errorColor, errorDeco.fillColor!);
      expectAllTextAa('field error dark=$dark');

      await tester.pumpWidget(
        app(
          theme,
          direction,
          const AppInput(
            label: 'Email',
            errorText: 'Invalid email address',
          ),
        ),
      );
      await tester.pump();
      final appInputErrorIcon = tester.widget<Icon>(
        find.byIcon(Icons.error_outline_rounded),
      );
      expect(appInputErrorIcon.color!.a, 1);
      uiPair(appInputErrorIcon.color!, inputFill);
      expect(appInputErrorIcon.color, theme.extension<SiratiColors>()!.error);
      final appInputErrorColor =
          renderedTextColor(tester, find.text('Invalid email address'));
      textPair(appInputErrorColor, inputFill);

      // ── A6: Real input success state (AppTextFormField) ──
      const successMsg = 'Username available';
      await tester.pumpWidget(
        app(
          theme,
          direction,
          AppTextFormField(
            labelText: 'Username',
            initialValue: 'ValidUser',
            showSuccessWhenValid: true,
            autovalidateMode: AutovalidateMode.always,
            successMessage: successMsg,
          ),
        ),
      );
      await tester.pump();
      final successDeco =
          tester.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
      final successBorder = successDeco.enabledBorder! as OutlineInputBorder;
      expect(successBorder.borderSide.color.a, 1);
      uiPair(successBorder.borderSide.color, successDeco.fillColor!);
      expect(
        successBorder.borderSide.color,
        theme.extension<SiratiColors>()!.success,
      );

      final successIcon = tester.widget<Icon>(
        find.byIcon(Icons.check_circle_rounded),
      );
      expect(successIcon.color!.a, 1);
      uiPair(successIcon.color!, successDeco.fillColor!);
      expect(successIcon.color, theme.extension<SiratiColors>()!.success);

      final successColor = renderedTextColor(tester, find.text(successMsg));
      textPair(successColor, successDeco.fillColor!);
      expect(
        successColor,
        theme.extension<SiratiColors>()!.onSuccessContainer,
      );

      final siratiColors = theme.extension<SiratiColors>()!;
      const submitLabel = 'Sign in';
      await tester.pumpWidget(
        app(
          theme,
          direction,
          SubmitButton(
            label: submitLabel,
            icon: Icons.check,
            onPressed: () {},
          ),
        ),
      );
      await tester.pump();
      final enabledSubmitBg = paintedBackgroundsOf(
          tester.element(find.text(submitLabel))).single;
      expect(enabledSubmitBg, siratiColors.primary);
      expect(
        paintedBackgroundsOf(tester.element(find.text(submitLabel))),
        contains(siratiColors.primary),
      );
      final enabledSubmitFg = renderedTextColor(tester, find.text(submitLabel));
      expect(enabledSubmitFg, siratiColors.onPrimary);
      expect(
        AppContrast.ratio(enabledSubmitFg, enabledSubmitBg),
        greaterThanOrEqualTo(4.5),
      );
      expectAllTextAa('SubmitButton enabled dark=$dark');

      await tester.pumpWidget(
        app(
          theme,
          direction,
          const SubmitButton(label: submitLabel, onPressed: null),
        ),
      );
      await tester.pump();
      final disabledSubmitBg = paintedBackgroundsOf(
          tester.element(find.text(submitLabel))).single;
      expect(disabledSubmitBg, siratiColors.surfaceHigh);
      expect(disabledSubmitBg, isNot(enabledSubmitBg));
      expect(
        paintedBackgroundsOf(tester.element(find.text(submitLabel))),
        contains(siratiColors.surfaceHigh),
      );
      final disabledSubmitFg =
          renderedTextColor(tester, find.text(submitLabel));
      expect(disabledSubmitFg, siratiColors.textSecondary);
      expect(disabledSubmitFg, isNot(enabledSubmitFg));
      expect(
        AppContrast.ratio(disabledSubmitFg, disabledSubmitBg),
        greaterThanOrEqualTo(4.5),
        reason: 'disabled SubmitButton text on its own fill',
      );
      expectAllTextAa('SubmitButton disabled dark=$dark');

      await tester.pumpWidget(
        app(
          theme,
          direction,
          SubmitButton(
            label: submitLabel,
            loadingLabel: 'Signing in',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );
      await tester.pump();
      final loadingSubmit =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        loadingSubmit.style!.backgroundColor!
            .resolve(const <WidgetState>{WidgetState.disabled}),
        siratiColors.primary,
      );
      expect(
        renderedTextColor(tester, find.text('Signing in')),
        siratiColors.onPrimary,
      );
      expectAllTextAa('SubmitButton loading dark=$dark');

      await tester.pumpWidget(
        app(
          theme,
          direction,
          AppButton.secondary(label: 'Details', onPressed: () {}),
        ),
      );
      await tester.pump();
      expectAllTextAa('secondary button dark=$dark');

      // ── B1: AppButton enabled / loading / disabled painted-colour tests ──
      for (final variant in [
        AppButtonVariant.primary,
        AppButtonVariant.destructive,
      ]) {
        final isPrimary = variant == AppButtonVariant.primary;
        final enabledBg = isPrimary ? siratiColors.primary : siratiColors.error;
        final enabledFg =
            isPrimary ? siratiColors.onPrimary : siratiColors.onError;
        const testLabel = 'Action إجراء';

        // 1. Enabled: enabled fill + enabled text
        await tester.pumpWidget(
          app(
            theme,
            direction,
            AppButton(
              label: testLabel,
              variant: variant,
              icon: Icons.check,
              onPressed: () {},
            ),
          ),
        );
        await tester.pump();
        final enabledBtn =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final enabledResolvedBg = enabledBtn.style!.backgroundColor!
            .resolve(const <WidgetState>{})!;
        expect(enabledResolvedBg, enabledBg);
        final enabledText = tester.element(find.text(testLabel));
        expect(paintedBackgroundsOf(enabledText), contains(enabledBg));
        final enabledTextColor =
            renderedTextColor(tester, find.text(testLabel));
        expect(enabledTextColor, enabledFg);
        expect(AppContrast.ratio(enabledTextColor, enabledBg),
            greaterThanOrEqualTo(4.5));
        expectAllTextAa('AppButton $variant enabled dark=$dark');
        expectAllIconsAa('AppButton $variant enabled icon dark=$dark');

        // 2. Loading: keeps enabled fill with a spinner
        await tester.pumpWidget(
          app(
            theme,
            direction,
            AppButton(
              label: testLabel,
              variant: variant,
              isLoading: true,
              onPressed: () {},
            ),
          ),
        );
        await tester.pump();
        final loadingBtn =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final loadingResolvedBg = loadingBtn.style!.backgroundColor!
            .resolve(const <WidgetState>{WidgetState.disabled})!;
        expect(loadingResolvedBg, enabledBg,
            reason: 'loading must keep the enabled fill');
        final loadingText = tester.element(find.text(testLabel));
        expect(paintedBackgroundsOf(loadingText), contains(enabledBg));
        final loadingTextColor =
            renderedTextColor(tester, find.text(testLabel));
        expect(loadingTextColor, enabledFg);
        expect(AppContrast.ratio(loadingTextColor, enabledBg),
            greaterThanOrEqualTo(4.5));
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expectAllTextAa('AppButton $variant loading dark=$dark');
        expectAllProgressIndicatorsAa(
            'AppButton $variant loading indicator dark=$dark');

        // 3. Disabled: neutral surfaceHigh-level fill with textSecondary-level text (text >= 4.5:1 on its own fill)
        await tester.pumpWidget(
          app(
            theme,
            direction,
            AppButton(
              label: testLabel,
              variant: variant,
              icon: Icons.check,
              onPressed: null,
            ),
          ),
        );
        await tester.pump();
        final disabledBtn =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        final disabledResolvedBg = disabledBtn.style!.backgroundColor!
            .resolve(const <WidgetState>{WidgetState.disabled})!;
        expect(disabledResolvedBg, siratiColors.surfaceHigh,
            reason: 'disabled must use neutral surfaceHigh fill');
        expect(disabledResolvedBg, isNot(equals(enabledBg)),
            reason: 'disabled fill must look different from enabled');
        final disabledText = tester.element(find.text(testLabel));
        expect(paintedBackgroundsOf(disabledText),
            contains(siratiColors.surfaceHigh));
        final disabledTextColor =
            renderedTextColor(tester, find.text(testLabel));
        expect(disabledTextColor, siratiColors.textSecondary,
            reason: 'disabled text must use textSecondary');
        expect(disabledTextColor, isNot(equals(enabledFg)),
            reason: 'disabled text must look different from enabled');
        expect(
          AppContrast.ratio(disabledTextColor, disabledResolvedBg),
          greaterThanOrEqualTo(4.5),
          reason: 'disabled text must be >= 4.5:1 on its own fill',
        );
        final disabledIcon = tester.widget<Icon>(find.byIcon(Icons.check));
        expect(disabledIcon.color, siratiColors.textSecondary);
        expectAllTextAa('AppButton $variant disabled dark=$dark');
        expectAllIconsAa('AppButton $variant disabled icon dark=$dark');
      }

      await tester.pumpWidget(
        app(
          theme,
          direction,
          const PasswordStrengthMeter(password: 'longpassword', english: true),
        ),
      );
      await tester.pump();
      expectAllTextAa('password meter dark=$dark');

      await tester.pumpWidget(
        app(
          theme,
          direction,
          ScreenHeader(
            english: true,
            title: 'Home',
            status: 'Active',
            onNotifications: () {},
          ),
        ),
      );
      await tester.pump();
      expectAllTextAa('status chip dark=$dark');

      await tester.pumpWidget(
        app(theme, direction, const AppInput(hint: 'Optional detail')),
      );
      await tester.pump();
      expectAllTextAa('input hint dark=$dark');

      // Scheme contrast invariants checked with strict mathematical ratios
      final scheme = theme.colorScheme;
      textPair(scheme.onSecondary, scheme.secondary);
      textPair(scheme.onSecondaryContainer, scheme.secondaryContainer);
      textPair(scheme.onTertiary, scheme.tertiary);
      textPair(scheme.onTertiaryContainer, scheme.tertiaryContainer);

      // Real SegmentedButton on dark/light scheme surfaces
      await tester.pumpWidget(
        app(
          theme,
          direction,
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 1, label: Text('One')),
              ButtonSegment(value: 2, label: Text('Two')),
            ],
            selected: const {1},
            onSelectionChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expectAllTextAa('SegmentedButton dark=$dark');

      await tester.pumpWidget(
        app(theme, direction, const AppCard(child: Text('Plain card'))),
      );
      await tester.pump();
      final cardBox = tester
          .widget<Container>(
            find
                .descendant(
                  of: find.byType(AppCard),
                  matching: find.byType(Container),
                )
                .first,
          )
          .decoration! as BoxDecoration;
      expect(cardBox.boxShadow ?? const <BoxShadow>[], isEmpty);

      await tester.pumpWidget(
        app(
          theme,
          direction,
          const AppSurfaceCard(child: Text('Surface card')),
        ),
      );
      await tester.pump();
      final surfaceShadow = (tester
              .widget<DecoratedBox>(
                find
                    .descendant(
                      of: find.byType(AppSurfaceCard),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              )
              .decoration as BoxDecoration)
          .boxShadow;
      expect(surfaceShadow ?? const <BoxShadow>[], isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final direction in TextDirection.values) {
      final theme = dark
          ? AppTheme.darkFor(arabic: direction == TextDirection.rtl)
          : AppTheme.lightFor(arabic: direction == TextDirection.rtl);
      final suffix = 'dark=$dark, $direction';

      testWidgets(
        'native actions and editing semantics remain reachable ($suffix)',
        (tester) async {
          final handle = tester.ensureSemantics();
          try {
            var taps = 0;
            var switches = 0;
            final controller = TextEditingController(text: 'Engineer مهندس 42');
            addTearDown(controller.dispose);
            await tester.pumpWidget(
              app(
                theme,
                direction,
                Column(
                  children: [
                    AppButton.primary(
                        label: 'Save حفظ', onPressed: () => taps++),
                    AppInput(label: 'Name الاسم', controller: controller),
                    AppListTile(title: 'Open فتح', onTap: () => taps++),
                    AppListTile(
                      title: 'Enable تفعيل',
                      showChevron: false,
                      trailing: Switch(
                        value: false,
                        onChanged: (_) => switches++,
                      ),
                    ),
                  ],
                ),
              ),
            );
            await tester.pump();
            final root = tester.binding.renderViews.single.owner!
                .semanticsOwner!.rootSemanticsNode!;
            for (final label in ['Save حفظ', 'Open فتح']) {
              final node =
                  nodes(root).singleWhere((node) => node.label == label);
              expect(node.flagsCollection.isButton, isTrue);
              expect(
                node.getSemanticsData().hasAction(SemanticsAction.tap),
                isTrue,
              );
              tester.binding.renderViews.single.owner!.semanticsOwner!
                  .performAction(
                node.id,
                SemanticsAction.tap,
              );
            }
            expect(taps, 2);

            // text field + switch checked on the FIRST tree, before the tree is replaced below
            final field = nodes(
              root,
            ).singleWhere((node) => node.flagsCollection.isTextField);
            expect(field.label, contains('Name الاسم'));
            expect(field.value, controller.text);
            tester.binding.renderViews.single.owner!.semanticsOwner!
                .performAction(
              field.id,
              SemanticsAction.tap,
            );
            await tester.pump();
            expect(
              field.getSemanticsData().hasAction(SemanticsAction.setText),
              isTrue,
            );
            tester.binding.renderViews.single.owner!.semanticsOwner!
                .performAction(
              field.id,
              SemanticsAction.setText,
              'محلل Analyst 73',
            );
            await tester.pump();
            expect(controller.text, 'محلل Analyst 73');
            final toggle = nodes(
              root,
            ).singleWhere(
                (node) => node.flagsCollection.isToggled != Tristate.none);
            tester.binding.renderViews.single.owner!.semanticsOwner!
                .performAction(
              toggle.id,
              SemanticsAction.tap,
            );
            expect(switches, 1);

            // A3: AppListTile button node count and null onTap check
            expect(
              nodes(root).where(
                  (n) => n.flagsCollection.isButton && n.label.trim().isEmpty),
              isEmpty,
            );
            final tileButtons = nodes(root)
                .where((n) =>
                    n.flagsCollection.isButton && n.label.contains('Open فتح'))
                .toList();
            expect(tileButtons.length, 1);

            // A3: Non-tappable AppListTile must not have button semantics
            await tester.pumpWidget(
              app(
                theme,
                direction,
                const AppListTile(
                  title: 'Static Info معلومات ثابته',
                  subtitle: 'Read only للقراءة',
                  onTap: null,
                ),
              ),
            );
            await tester.pump();
            final staticRoot = tester.binding.renderViews.single.owner!
                .semanticsOwner!.rootSemanticsNode!;
            final staticTileNodes = nodes(staticRoot)
                .where((n) => n.label.contains('Static Info معلومات ثابته'))
                .toList();
            expect(staticTileNodes.length, 1);
            expect(staticTileNodes.single.flagsCollection.isButton, isFalse);
            expect(
              staticTileNodes.single
                  .getSemanticsData()
                  .hasAction(SemanticsAction.tap),
              isFalse,
            );

            // A2: AppButton loading semantics: exactly one button node with loading text
            final loadingText = direction == TextDirection.rtl
                ? 'جارٍ التحميل...'
                : 'Loading...';
            var loadingTaps = 0;
            await tester.pumpWidget(
              app(
                theme,
                direction,
                AppButton.primary(
                  label: 'Submit إرسال',
                  isLoading: true,
                  onPressed: () => loadingTaps++,
                ),
              ),
            );
            await tester.pump();
            final loadingRoot = tester.binding.renderViews.single.owner!
                .semanticsOwner!.rootSemanticsNode!;
            final loadingButtons = nodes(loadingRoot)
                .where((n) => n.flagsCollection.isButton)
                .toList();
            expect(loadingButtons.length, 1);
            expect(loadingButtons.single.label, contains('Submit إرسال'));
            expect(loadingButtons.single.label, contains(loadingText));
            expect(
              loadingButtons.single
                  .getSemanticsData()
                  .hasAction(SemanticsAction.tap),
              isFalse,
            );
            await tester.pumpWidget(const SizedBox());
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          } finally {
            handle.dispose();
          }
        },
      );

      testWidgets(
        'validation errors belong to editable live semantics ($suffix)',
        (tester) async {
          final handle = tester.ensureSemantics();
          final form = GlobalKey<FormState>();
          const message = 'Enter a valid value يرجى إدخال قيمة صحيحة';
          try {
            for (final supportsAnnounce in [false, true]) {
              await tester.pumpWidget(
                app(
                  theme,
                  direction,
                  Form(
                    key: form,
                    child: AppTextFormField(
                      labelText: 'Contact التواصل',
                      validator: (_) => message,
                    ),
                  ),
                  supportsAnnounce: supportsAnnounce,
                ),
              );
              form.currentState!.validate();
              await tester.pumpAndSettle();
              final field = tester.widget<TextField>(find.byType(TextField));
              expect(field.decoration!.errorText, message);
              expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
              expectFieldAnnouncesErrorOnce(tester,
                  message: message, fieldFinder: find.byType(TextField));

              await tester.pumpWidget(
                app(
                  theme,
                  direction,
                  const AppInput(
                    label: 'Contact التواصل',
                    errorText: message,
                  ),
                  supportsAnnounce: supportsAnnounce,
                ),
              );
              await tester.pumpAndSettle();
              expectFieldAnnouncesErrorOnce(tester,
                  message: message, fieldFinder: find.byType(TextField));
              expect(tester.takeException(), isNull);
            }
          } finally {
            handle.dispose();
          }
        },
      );

      testWidgets(
        'error semantics rejects unrelated and duplicate errors ($suffix)',
        (tester) async {
          final handle = tester.ensureSemantics();
          try {
            for (final supportsAnnounce in [false, true]) {
              for (final nativeError in [false, true]) {
                final message = direction == TextDirection.rtl
                    ? 'راجع هذا الحقل'
                    : 'Check this field';
                await tester.pumpWidget(app(
                  theme,
                  direction,
                  Column(children: [
                    AppInput(
                      label: 'Contact',
                      errorText: nativeError ? message : null,
                    ),
                    AppFieldError(message: message),
                  ]),
                  supportsAnnounce: supportsAnnounce,
                ));
                await tester.pumpAndSettle();
                expect(
                  () => expectFieldAnnouncesErrorOnce(tester,
                      message: message, fieldFinder: find.byType(TextField)),
                  throwsA(isA<TestFailure>()),
                );
              }
            }
          } finally {
            handle.dispose();
          }
        },
      );

      testWidgets(
        'shared widgets reflow at 200 percent on narrow screens ($suffix)',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final controller = TextEditingController(
            text: 'A sufficiently detailed description for enhancement',
          );
          addTearDown(controller.dispose);
          final booster = ScoreBoosterController(
            fieldWeights: {'contact': 1, 'experience': 1},
            tipForIncomplete: (_) => const ScoreBoosterTip(
                message: 'Add accurate details أضف تفاصيل صحيحة',
                boostPoints: 10),
          )..setFieldComplete('contact', true);
          addTearDown(booster.dispose);
          const job = JobTitle(
              id: 19,
              slug: 'specialist',
              nameAr: 'أخصائي تطوير الأنظمة',
              nameEn: 'Systems Development Specialist',
              category: '',
              keywords: [],
              sortOrder: 0);
          for (final child in <Widget>[
            for (final variant in AppButtonVariant.values)
              for (final loading in [false, true])
                AppButton(
                  label: 'Continue with this information متابعة بهذه المعلومات',
                  variant: variant,
                  isLoading: loading,
                  icon: Icons.check,
                  onPressed: () {},
                ),
            for (final loading in [false, true])
              SubmitButton(
                label: 'Continue with this information متابعة بهذه المعلومات',
                isLoading: loading,
                onPressed: () {},
                icon: Icons.check,
              ),
            const AppInput(
              label: 'Name الاسم',
              errorText: 'Please check this value يرجى مراجعة هذه القيمة',
            ),
            AppTextFormField(labelText: 'Details التفاصيل'),
            AppListTile(
              title: 'A long activity title عنوان النشاط',
              subtitle: 'Details التفاصيل',
              leadingIcon: Icons.work_outline,
              onTap: () {},
            ),
            ScreenHeader(
              english: direction == TextDirection.ltr,
              title: 'Welcome مرحبًا',
              status: 'Your account status حالة حسابك',
              subtitle: 'Your dashboard لوحة المعلومات',
              onAvatarTap: () {},
              onNotifications: () {},
              unreadCount: 12,
            ),
            const LanguageToggle(),
            const OfflineCacheBanner(english: true, surface: 'cvs'),
            ScoreBoosterCard(controller: booster),
            JobTitlePickerField(
                titles: const [job],
                value: job,
                onChanged: (_) {},
                english: direction == TextDirection.ltr),
            AppEmptyState(
                icon: Icons.inbox,
                title: 'No documents لا توجد مستندات',
                actionLabel: 'Create a document أنشئ مستندًا',
                onAction: () {},
                scrollable: false),
            for (final password in ['', 'a', 'longpassword', 'LongPassword9!'])
              PasswordStrengthMeter(
                password: password,
                english: direction == TextDirection.ltr,
              ),
            const AiFieldLoadingOverlay(
              isLoading: true,
              statusMessages: [
                'Processing a longer status جارٍ معالجة الطلب',
              ],
              child: SizedBox(height: 48),
            ),
            AiCvField(
              field: 'summary',
              controller: controller,
              english: direction == TextDirection.ltr,
              isLoading: false,
              minimumCharacters: 80,
              helperText: 'Provide accurate details أضف تفاصيل صحيحة',
              result: const {
                'changes_made': ['Clearer structure صياغة أوضح'],
                'missing_facts': ['Provide a date أضف التاريخ'],
                'unverified_claims': [
                  {'kind': 'date', 'text': '2024 / ٢٠٢٤'}
                ],
                'ats_keywords_added': ['Systems أنظمة'],
              },
              onEnhance: () {},
              onDismissResult: () {},
              child: const AppInput(),
            ),
          ]) {
            await tester.pumpWidget(app(theme, direction, child));
            await tester.pump(const Duration(seconds: 1));
            expect(
              tester.takeException(),
              isNull,
              reason: '${child.runtimeType}, $suffix',
            );
            for (final text in find.byType(Text).evaluate().toList()) {
              await tester.ensureVisible(find.byWidget(text.widget));
              await tester.pump();
              expect(tester.takeException(), isNull,
                  reason: 'scrolling ${child.runtimeType}, $suffix');
            }
            expectAllTextAa('${child.runtimeType}, $suffix');
            expectAllIconsAa('${child.runtimeType}, $suffix');
            expectAllProgressIndicatorsAa('${child.runtimeType}, $suffix');
            if (child is AppButton ||
                child is SubmitButton ||
                child is LanguageToggle ||
                child is AppListTile) {
              final size = tester.getSize(find.byType(child.runtimeType));
              expect(size.height, greaterThanOrEqualTo(AppTouchTarget.min));
              expect(size.width, greaterThanOrEqualTo(AppTouchTarget.min));
            }
            if (child is ScreenHeader) {
              for (final type in [NotificationBellButton, ProfileAvatar]) {
                final size = tester.getSize(find.byType(type));
                expect(size.height, greaterThanOrEqualTo(AppTouchTarget.min));
                expect(size.width, greaterThanOrEqualTo(AppTouchTarget.min));
              }
            }
            for (final element in find.byType(Text).evaluate()) {
              final text = element.widget as Text;
              final style =
                  DefaultTextStyle.of(element).style.merge(text.style);
              expect(style.fontWeight,
                  isIn([FontWeight.w400, FontWeight.w600, FontWeight.w700]));
              final avatar =
                  element.findAncestorWidgetOfExactType<ProfileAvatar>();
              if (avatar != null) {
                expect(style.fontSize, avatar.size * 0.35);
              } else {
                expect(style.fontSize,
                    isIn(AppTypography.all.map((token) => token.size)));
              }
              expect(
                style.height,
                isIn(AppTypography.all.expand(
                    (token) => [token.heightArabic, token.heightLatin])),
              );
            }
          }
          await tester.pumpWidget(const SizedBox());
        },
      );

      testWidgets(
        'snackbar actions meet contrast and 48dp at 200 percent ($suffix)',
        (tester) async {
          tester.view.physicalSize = const Size(390, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(app(theme, direction, const SizedBox()));
          final context = tester.element(find.byType(Scaffold));
          for (final variant in AppSnackBarVariant.values) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            AppSnackBar.show(
              context,
              message: 'Please try again يرجى المحاولة مجددًا',
              variant: variant,
              actionLabel: 'Try again أعد المحاولة',
              onAction: () {},
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expectAllTextAa('snackbar action $suffix $variant');
            expectAllIconsAa('snackbar icons $suffix $variant');
            final size = tester.getSize(
              find.descendant(
                of: find.byType(SnackBar),
                matching: find.byType(TextButton),
              ),
            );
            expect(size.height, greaterThanOrEqualTo(48));
            expect(size.width, greaterThanOrEqualTo(48));
          }
        },
      );

      testWidgets('elapsed time never claims completed AI stages ($suffix)', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(theme, direction, const SizedBox()));
        final context = tester.element(find.byType(Scaffold));
        late AiProgressHandle handle;
        final future = AiProgressOverlay.show(
          context,
          kind: AiProgressKind.generation,
          english: direction == TextDirection.ltr,
        ).then((value) => handle = value);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await future;
        for (final duration in [
          const Duration(seconds: 12),
          const Duration(seconds: 50),
        ]) {
          await tester.pump(duration);
          expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
          expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
          for (final element in find.byIcon(Icons.circle_outlined).evaluate()) {
            final icon = element.widget as Icon;
            expect(icon.color!.a, 1);
            element.visitAncestorElements((ancestor) {
              final widget = ancestor.widget;
              if (widget is Opacity) expect(widget.opacity, 1);
              if (widget is FadeTransition) expect(widget.opacity.value, 1);
              return true;
            });
            for (final background in paintedBackgroundsOf(element)) {
              expect(
                AppContrast.ratio(icon.color!, background),
                greaterThanOrEqualTo(3),
                reason: 'upcoming step icon $suffix',
              );
            }
          }
          expect(
            tester
                .widget<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator),
                )
                .value,
            isNull,
          );
          expectAllTextAa('AI overlay $suffix');
          expectAllProgressIndicatorsAa('AI overlay $suffix');
          expect(tester.takeException(), isNull);
        }
        handle.setPhase(AiProgressPhase.working);
        await tester.pump();
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        await handle.dismiss();
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('reduced motion stops the indeterminate AI bar', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<double> sweepDelta({required bool reduce}) async {
      await tester.pumpWidget(
        app(
          AppTheme.light,
          TextDirection.ltr,
          const SizedBox(),
          disableAnimations: reduce,
        ),
      );
      final context = tester.element(find.byType(Scaffold));
      late AiProgressHandle handle;
      final future = AiProgressOverlay.show(
        context,
        kind: AiProgressKind.analysis,
        english: true,
      ).then((value) => handle = value);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await future;
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        isNull,
      );
      final start = _indeterminateSweep(tester);
      if (reduce) {
        expect(tester.binding.transientCallbackCount, 0,
            reason: 'no overlay animation may keep scheduling ticks');
      }
      await tester.pump(const Duration(milliseconds: 700));
      final delta = (_indeterminateSweep(tester) - start).abs();
      if (reduce) expect(tester.binding.transientCallbackCount, 0);
      await handle.dismiss();
      await tester.pumpWidget(const SizedBox());
      return delta;
    }

    expect(
      await sweepDelta(reduce: false),
      greaterThan(0),
      reason: 'the bar sweeps when motion is allowed',
    );
    expect(await sweepDelta(reduce: true), 0);
  });

  testWidgets('bootstrap status icons follow platform brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    expect(
      AppTheme.bootstrapSystemUiOverlayStyle().statusBarIconBrightness,
      Brightness.light,
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    expect(
      AppTheme.bootstrapSystemUiOverlayStyle().statusBarIconBrightness,
      Brightness.dark,
    );
  });
}
