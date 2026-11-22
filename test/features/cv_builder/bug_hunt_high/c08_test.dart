import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/models/cv_document.dart';

import 'cert_harness.dart';

void main() {
  for (final year in ['2027', '2030', '1999']) {
    testWidgets('ticking no-expiry clears an existing expiry ($year)',
        (tester) async {
      final c = certController(Certification(
        id: 'c1',
        name: const LocalizedText(ar: 'AWS'),
        issueDate: '2024',
        expiryDate: year,
      ));
      await pumpCertEditor(tester, c);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(c.document.certifications!.single.expiryDate, isNull,
          reason: 'document still expires in $year');

      // Leave and come back: the tile is rebuilt from the document.
      await tester.pumpWidget(const SizedBox());
      await pumpCertEditor(tester, c);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
