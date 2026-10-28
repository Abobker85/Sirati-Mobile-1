import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/domain/cv_list.dart';
import 'package:sirati/features/cv_builder/presentation/my_cvs/cv_document_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
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
}
