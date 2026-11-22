import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/models/cv_document.dart';

import 'cert_harness.dart';

void main() {
  for (final year in ['2024', '1987', '7']) {
    testWidgets('clearing the issue year key by key clears it ($year)',
        (tester) async {
      final c = certController(Certification(
        id: 'c1',
        name: const LocalizedText(ar: 'AWS'),
        issueDate: year,
      ));
      await pumpCertEditor(tester, c);
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      final i = fields.indexWhere((f) => f.controller?.text == year);
      expect(i, isNonNegative);
      final field = find.byType(TextField).at(i);
      for (var n = year.length - 1; n >= 0; n--) {
        await tester.enterText(field, year.substring(0, n));
        await tester.pump();
      }
      expect(c.document.certifications!.single.issueDate, isNull,
          reason: 'field is empty but the document keeps a year');
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
