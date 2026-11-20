import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_template_picker.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/my_cvs_tools.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_template.dart';
import 'package:sirati/shared/theme/app_theme.dart';

import '../../support/contrast_probe.dart';

void main() {
  for (final (mode, theme) in [
    ('light', AppTheme.lightFor(arabic: false)),
    ('dark', AppTheme.darkFor(arabic: false)),
  ]) {
    // Unscored (chip + scan link), low (warning banner) and high scores.
    for (final (draft, score) in [
      (false, 92),
      (false, 41),
      (false, null),
      (true, null),
    ]) {
      testWidgets(
          'CV card texts are AA in $mode mode (draft: $draft, score: $score)',
          (tester) async {
        final item = CvListItem.fromJson({
          'id': 1,
          'title': 'Backend Developer CV',
          'is_draft': draft,
          'score_total': score,
          'updated_label': '2 days ago',
        });
        await tester.pumpWidget(MaterialApp(
          theme: theme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                CvDocumentCard(
                  item: item,
                  onOpen: () {},
                  onEdit: () {},
                  onDelete: () {},
                  onDownload: () {},
                  onScan: () {},
                ),
              ],
            ),
          ),
        ));

        expectAllTextAa('$mode, draft: $draft, score: $score');
      });
    }
  }

  // iOS 26 restyle (ticket 15): borderless, shadowless grey cards on the
  // white page; nothing inside them is filled with the card's own grey.
  for (final language in ['ar', 'en']) {
    for (final dark in [false, true]) {
      final label = '$language/${dark ? 'dark' : 'light'}';
      for (final (id, draft, score) in [
        (7, false, 92),
        (8, false, 41),
        (9, false, null),
        (null, true, null),
      ]) {
        testWidgets(
            '$label: CV card is a borderless grey card '
            '(id: $id, score: $score)', (tester) async {
          final item = CvListItem.fromJson({
            'id': id,
            'title': 'مطور Backend Developer CV',
            'is_draft': draft,
            'score_total': score,
            'updated_label': '2 days ago',
          });
          await tester.pumpWidget(_host(
            language: language,
            dark: dark,
            child: CvDocumentCard(
              item: item,
              onOpen: () {},
              onEdit: () {},
              onDelete: () {},
              onDownload: () {},
              onScan: () {},
            ),
          ));
          final c = tester.element(find.byType(CvDocumentCard)).sirati;
          final card =
              tester.widget<Container>(find.byKey(CvDocumentCard.cardKey(id)));
          final box = card.decoration! as BoxDecoration;
          expect(box.color, c.cardFill);
          expect(box.border, isNull);
          expect(box.boxShadow ?? const [], isEmpty);
          // Every painted box inside the card differs from the card fill,
          // so no inner tile or chip melts into it.
          for (final inner in tester.widgetList<Container>(find.descendant(
              of: find.byKey(CvDocumentCard.cardKey(id)),
              matching: find.byType(Container)))) {
            if (identical(inner, card)) continue;
            final d = inner.decoration;
            if (d is BoxDecoration && d.color != null) {
              expect(d.color, isNot(c.cardFill), reason: '$label inner box');
              expect(d.border, isNull, reason: '$label inner box');
            }
          }
          // Open: a tinted capsule without an outline (a grey one would
          // vanish into the card).
          final open = tester
              .widget<OutlinedButton>(find.byKey(CvDocumentCard.openKey(id)));
          final states = <WidgetState>{
            if (id == null) WidgetState.disabled,
          };
          expect(open.style!.side?.resolve(states), BorderSide.none);
          final fill = open.style!.backgroundColor!.resolve(states)!;
          expect(fill, isNot(c.cardFill));
          final ink = open.style!.foregroundColor!.resolve(states)!;
          expect(AppContrast.ratio(ink, fill), greaterThanOrEqualTo(4.5));
          expectAllTextAa('$label card $id');
        });
      }

      testWidgets(
          '$label: design picker rows are unoutlined white rows; '
          'the chosen one is tinted and AA', (tester) async {
        CvTemplate template(int id, String slug, {bool isDefault = false}) =>
            CvTemplate(
              id: id,
              slug: slug,
              name: 'Design $id',
              nameAr: 'تصميم $id',
              nameEn: 'Design $id',
              previewImageUrl: null,
              languageDirection: 'both',
              supportedLanguages: const ['ar', 'en'],
              supportedSections: const [],
              isDefault: isDefault,
              isPremium: false,
            );
        await tester.pumpWidget(MaterialApp(
          theme: dark
              ? AppTheme.darkFor(arabic: language == 'ar')
              : AppTheme.lightFor(arabic: language == 'ar'),
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              // The sheet page the picker opens on.
              backgroundColor: context.sirati.groupedBackground,
              body: CvTemplatePicker(
                english: language == 'en',
                templates: [
                  template(1, 'classic', isDefault: true),
                  template(2, 'modern'),
                ],
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
        final c = tester.element(find.byType(CvTemplatePicker)).sirati;
        final rows = tester
            .widgetList<Material>(find.descendant(
                of: find.byType(CvTemplatePicker),
                matching: find.byWidgetPredicate(
                    (w) => w is Material && w.shape is RoundedRectangleBorder)))
            .toList();
        expect(rows, hasLength(2));
        expect(rows[0].color, c.primaryLight, reason: 'default is chosen');
        expect((rows[0].shape! as RoundedRectangleBorder).side.color,
            c.primaryInk);
        expect(rows[1].color, c.groupedCard);
        expect(
            (rows[1].shape! as RoundedRectangleBorder).side, BorderSide.none);
        expectAllTextAa('$label picker');
      });

      testWidgets('$label: tools are borderless tiles on the page',
          (tester) async {
        await tester.pumpWidget(_host(
          language: language,
          dark: dark,
          child: MyCvsToolsCard(
            onCreate: () {},
            onScan: () {},
            onUpload: () {},
            onTarget: () {},
          ),
        ));
        final c = tester.element(find.byType(MyCvsToolsCard)).sirati;
        for (final key in [
          MyCvsToolsCard.scanKey,
          MyCvsToolsCard.uploadKey,
          MyCvsToolsCard.targetKey,
          MyCvsToolsCard.createKey,
        ]) {
          final material = tester.widget<Material>(find
              .descendant(of: find.byKey(key), matching: find.byType(Material))
              .first);
          expect(material.color,
              key == MyCvsToolsCard.createKey ? c.brandSurface : c.cardFill);
          final shape = material.shape! as RoundedRectangleBorder;
          expect(shape.side, BorderSide.none);
        }
        for (final box in tester.widgetList<Container>(find.descendant(
            of: find.byType(MyCvsToolsCard),
            matching: find.byType(Container)))) {
          final d = box.decoration;
          if (d is BoxDecoration) {
            expect(d.border, isNull);
            expect(d.boxShadow ?? const [], isEmpty);
          }
        }
        expectAllTextAa('$label tools');
      });
    }
  }
}

Widget _host(
        {required String language,
        required bool dark,
        required Widget child}) =>
    MaterialApp(
      theme: dark
          ? AppTheme.darkFor(arabic: language == 'ar')
          : AppTheme.lightFor(arabic: language == 'ar'),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ListView(children: [child])),
    );
