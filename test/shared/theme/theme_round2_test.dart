import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/components/app_button.dart';
import 'package:sirati/shared/widgets/components/app_card.dart';
import 'package:sirati/shared/widgets/components/app_input.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

import '../../support/contrast_probe.dart';

/// iOS 26 restyle round 2 (ticket 10): page backgrounds, filled fields,
/// capsule buttons, borderless cards and filled chips, checked on real pumped
/// widgets in AR/EN x light/dark x plain/grouped pages.
void main() {
  const variants = [
    (mode: 'light', arabic: true),
    (mode: 'light', arabic: false),
    (mode: 'dark', arabic: true),
    (mode: 'dark', arabic: false),
  ];

  for (final v in variants) {
    final theme = v.mode == 'light'
        ? AppTheme.lightFor(arabic: v.arabic)
        : AppTheme.darkFor(arabic: v.arabic);
    final c = theme.extension<SiratiColors>()!;
    final lang = v.arabic ? 'ar' : 'en';

    for (final grouped in [false, true]) {
      final kind = grouped ? PageSurfaceKind.grouped : PageSurfaceKind.plain;
      final page = PageSurface.pageColor(c, kind);
      final fill = PageSurface.fillColor(c, kind);
      final label = '${v.mode}, $lang, ${kind.name}';

      Future<void> pump(WidgetTester tester, Widget body) async {
        AppLocale.languageCode.value = lang;
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Widget scaffold = Scaffold(
          appBar: AppBar(title: const Text('Title')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: body,
          ),
        );
        if (grouped) scaffold = GroupedSurface(child: scaffold);
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: scaffold,
        ));
        await tester.pumpAndSettle();
      }

      testWidgets('page and app bar sit on the ${kind.name} page ($label)',
          (tester) async {
        await pump(tester, const Text('Body copy'));
        final body = tester.element(find.text('Body copy'));
        expect(PageSurface.of(body), kind);
        expect(paintedBackgroundsOf(body), [page]);
        final title = tester.element(find.text('Title'));
        expect(paintedBackgroundsOf(title), [page]);
        expectAllTextAa('page $label');
      });

      testWidgets('fields are filled, ringless at rest, ringed on focus '
          '($label)', (tester) async {
        final key = GlobalKey();
        final focus = FocusNode();
        addTearDown(focus.dispose);
        await pump(
          tester,
          RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 400,
              child: TextField(
                focusNode: focus,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'Your name',
                  helperText: 'As on your ID',
                ),
              ),
            ),
          ),
        );
        final rest = await _edgeAndCentre(tester, key);
        expect(rest.edge, fill, reason: 'no resting outline ($label)');
        expect(rest.centre, fill, reason: 'filled with the page fill');
        expectAllTextAa('resting field $label');

        focus.requestFocus();
        await tester.pumpAndSettle();
        final focused = await _edgeAndCentre(tester, key);
        expect(focused.centre, fill);
        expect(focused.edge, isNot(fill), reason: 'focus draws a ring');
        expect(AppContrast.ratio(focused.edge, fill),
            greaterThanOrEqualTo(3.0),
            reason: 'focus ring vs fill ($label)');
        // Label floats inside the fill, never across the field's edge.
        expectAllTextAa('focused field $label');
        _expectTextOnFill(tester, 'Full name', fill);
        _expectTextOnFill(tester, 'Your name', fill);
      });

      testWidgets('field errors show as text and icon, not colour alone '
          '($label)', (tester) async {
        final formKey = GlobalKey<FormState>();
        final ringKey = GlobalKey();
        await pump(
          tester,
          Form(
            key: formKey,
            child: Column(
              children: [
                RepaintBoundary(
                  key: ringKey,
                  child: SizedBox(
                    width: 400,
                    child: AppTextFormField(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      validator: (_) => 'Enter a valid email',
                      autovalidateMode: AutovalidateMode.always,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const AppInput(
                  label: 'Phone',
                  hint: '05XXXXXXXX',
                  helperText: 'Saudi mobile',
                  errorText: 'Enter a mobile number',
                ),
              ],
            ),
          ),
        );
        formKey.currentState!.validate();
        await tester.pumpAndSettle();

        for (final message in ['Enter a valid email', 'Enter a mobile number']) {
          expect(find.text(message), findsOneWidget);
        }
        expect(find.byIcon(Icons.error_outline_rounded), findsNWidgets(2));
        expectAllTextAa('field errors $label');
        expectAllIconsAa('field errors $label');

        final wash = AppFormStyles.errorWash(c, fill);
        final sample = await _edgeAndCentre(tester, ringKey);
        expect(sample.centre, _rgb8(wash), reason: 'soft error wash over the fill');
        expect(AppContrast.ratio(sample.edge, wash), greaterThanOrEqualTo(3.0),
            reason: 'error ring vs wash ($label)');
        _expectTextOnFill(tester, 'Email', wash);
      });

      testWidgets('valid fields keep helper copy AA on the success wash '
          '($label)', (tester) async {
        await pump(
          tester,
          AppTextFormField(
            labelText: 'Email',
            initialValue: 'a@b.co',
            validator: (_) => null,
            autovalidateMode: AutovalidateMode.always,
            showSuccessWhenValid: true,
            successMessage: 'Looks good',
          ),
        );
        // Force the success state the same way a submit does.
        final state = tester.state<FormFieldState<String>>(
          find.byType(AppTextFormField),
        );
        state.didChange('a@b.co');
        await tester.pumpAndSettle();
        expect(find.text('Looks good'), findsOneWidget);
        _expectTextOnFill(tester, 'Email', AppFormStyles.successWash(c, fill));
        expectAllTextAa('valid field $label');
      });

      testWidgets('buttons: teal primary, grey filled secondary capsules, '
          '48dp targets ($label)', (tester) async {
        await pump(
          tester,
          Column(
            children: [
              AppButton.primary(label: 'Save', onPressed: () {}),
              AppButton.secondary(label: 'Preview', onPressed: () {}),
              const AppButton.secondary(label: 'Locked', onPressed: null),
              AppButton.destructive(label: 'Delete', onPressed: () {}),
              OutlinedButton(onPressed: () {}, child: const Text('Themed')),
              ElevatedButton(onPressed: () {}, child: const Text('Go')),
            ],
          ),
        );

        Material materialOf(String text) => tester.widget<Material>(
              find
                  .ancestor(of: find.text(text), matching: find.byType(Material))
                  .first,
            );

        for (final (text, color) in [
          ('Save', c.primary),
          ('Go', c.primary),
          ('Delete', c.error),
          ('Preview', fill),
          ('Locked', fill),
          ('Themed', fill),
        ]) {
          final m = materialOf(text);
          expect(m.color, color, reason: '"$text" fill ($label)');
          expect(m.shape, isA<StadiumBorder>(),
              reason: '"$text" is a capsule ($label)');
          expect((m.shape! as StadiumBorder).side, BorderSide.none,
              reason: '"$text" has no outline ($label)');
          final button = find
              .ancestor(
                of: find.text(text),
                matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
              )
              .first;
          expect(tester.getSize(button).height,
              greaterThanOrEqualTo(AppTouchTarget.min));
        }
        expectAllTextAa('buttons $label');
      });

      testWidgets('cards have no border or shadow and fill like the page '
          '($label)', (tester) async {
        await pump(
          tester,
          Column(
            children: [
              AppCard(onTap: () {}, child: const Text('Legacy card')),
              AppSurfaceCard(onTap: () {}, child: const Text('Surface card')),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Material card'),
                ),
              ),
            ],
          ),
        );
        for (final type in [AppCard, AppSurfaceCard, Card]) {
          final card = find.byType(type);
          for (final box in tester.widgetList<DecoratedBox>(
            find.descendant(of: card, matching: find.byType(DecoratedBox)),
          )) {
            final d = box.decoration;
            if (d is BoxDecoration) {
              expect(d.border, isNull, reason: '$type border ($label)');
              expect(d.boxShadow ?? const [], isEmpty,
                  reason: '$type shadow ($label)');
            }
          }
          final material = tester.widget<Material>(
            find.descendant(of: card, matching: find.byType(Material)).first,
          );
          expect(material.color, fill, reason: '$type fill ($label)');
          expect(material.elevation, 0, reason: '$type elevation ($label)');
          final shape = material.shape;
          if (shape is RoundedRectangleBorder) {
            expect(shape.side, BorderSide.none, reason: '$type ($label)');
          }
        }
        expectAllTextAa('cards $label');
      });

      testWidgets('chips are filled capsules; selected is a teal tint '
          '($label)', (tester) async {
        await pump(
          tester,
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Remote'),
                selected: true,
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('On site'),
                selected: false,
                onSelected: (_) {},
              ),
              ChoiceChip(
                label: const Text('Full time'),
                selected: true,
                onSelected: (_) {},
              ),
              ChoiceChip(
                label: const Text('Part time'),
                selected: false,
                onSelected: (_) {},
              ),
              const Chip(label: Text('Flutter')),
              const FilterChip(
                label: Text('Disabled'),
                selected: false,
                onSelected: null,
              ),
            ],
          ),
        );

        for (final (text, selected) in [
          ('Remote', true),
          ('On site', false),
          ('Full time', true),
          ('Part time', false),
          ('Flutter', false),
          ('Disabled', false),
        ]) {
          final chip = find
              .ancestor(of: find.text(text), matching: find.byType(RawChip))
              .first;
          final ink = tester.widget<Ink>(
            find.descendant(of: chip, matching: find.byType(Ink)).first,
          );
          final decoration = ink.decoration! as ShapeDecoration;
          final bg = decoration.color!;
          expect(bg, selected ? c.primaryLight : fill,
              reason: '"$text" fill ($label)');
          expect(decoration.shape, isA<StadiumBorder>(),
              reason: '"$text" is a capsule ($label)');
          expect((decoration.shape as StadiumBorder).side, BorderSide.none,
              reason: '"$text" has no outline ($label)');
          final ink2 = paragraphOf(
            tester.renderObject(find.text(text)),
          ).text.style!.color!;
          expect(AppContrast.ratio(ink2, bg), greaterThanOrEqualTo(4.5),
              reason: '"$text" label on its fill ($label)');
          if (selected) {
            expect(ink2, c.primaryInk);
            // Selection is not colour alone: the checkmark draws too.
            expect(
              tester.widget<RawChip>(chip).showCheckmark ??
                  theme.chipTheme.showCheckmark,
              isTrue,
            );
          }
        }
      });
    }
  }

  test('grouped theme only re-dresses page-dependent fills', () {
    for (final base in [AppTheme.light, AppTheme.dark]) {
      final c = base.extension<SiratiColors>()!;
      final g = AppTheme.grouped(base);
      expect(g.scaffoldBackgroundColor, c.groupedBackground);
      expect(g.inputDecorationTheme.fillColor, c.groupedCard);
      expect(g.cardTheme.color, c.groupedCard);
      expect(g.chipTheme.backgroundColor, c.groupedCard);
      expect(g.chipTheme.selectedColor, base.chipTheme.selectedColor);
      expect(g.elevatedButtonTheme, base.elevatedButtonTheme);
      expect(g.inputDecorationTheme.focusedBorder,
          base.inputDecorationTheme.focusedBorder);
      expect(
        (g.appBarTheme.backgroundColor! as WidgetStateColor).resolve(const {}),
        c.groupedBackground,
      );
    }
  });
}

/// Pixels of the field captured under [key]: the centre of its top edge
/// (where a ring draws) and a point inside the fill clear of any text.
Future<({Color edge, Color centre})> _edgeAndCentre(
  WidgetTester tester,
  GlobalKey key,
) async {
  final editable = find.descendant(
    of: find.byKey(key),
    matching: find.byType(EditableText),
  );
  final container =
      InputDecorator.containerOf(tester.element(editable.first))!;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final origin = boundary.globalToLocal(container.localToGlobal(Offset.zero));
  final size = container.size;
  final pixels = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (image.width, data!);
  });
  final (width, data) = pixels!;
  Color at(Offset p) {
    final i = (p.dy.floor() * width + p.dx.floor()) * 4;
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  }

  return (
    // Rings are at least 1.5 px wide, so the field's first pixel row is
    // fully covered by one.
    edge: at(origin + Offset(size.width / 2, .5)),
    // Just inside the end corner radius, mid height: clear of copy.
    centre: at(origin + Offset(size.width - 8, size.height / 2)),
  );
}

/// [text] paints inside the field's fill (not across its edge) and the probe
/// resolves it onto [fill].
void _expectTextOnFill(WidgetTester tester, String text, Color fill) {
  final element = tester.element(find.text(text));
  final container = InputDecorator.containerOf(element)!;
  final box = container.localToGlobal(Offset.zero) & container.size;
  final rect = tester.getRect(find.text(text));
  expect(box.contains(rect.topLeft) && box.contains(rect.bottomRight), isTrue,
      reason: '"$text" lies inside its field ($rect in $box)');
  expect(paintedBackgroundsOf(element), [fill], reason: '"$text"');
}

/// [color] as an 8-bit-per-channel pixel, the precision a capture carries.
Color _rgb8(Color color) => Color.fromARGB(
      (color.a * 255).round(),
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    );
