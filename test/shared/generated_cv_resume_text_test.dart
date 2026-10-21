import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/shared/models/generated_cv.dart';

GeneratedCv _cv({
  String name = 'Sara Test',
  String title = 'Web Developer',
  String? email = 'sara@example.test',
  String? phone,
  String markdown = '## Professional Summary\n\nBuilds APIs.',
}) =>
    GeneratedCv.fromJson({
      'id': 1,
      'full_name': name,
      'target_job_title': title,
      'email': email,
      'phone': phone,
      'generated_markdown': markdown,
    });

void main() {
  // The scan must see who the candidate is and how to reach them, because the
  // stored markdown only contains the body sections.
  for (final name in ['Sara Test', 'سارة أحمد', 'سارة Ahmed']) {
    test('resume text starts with the name and keeps the body for "$name"', () {
      final text = _cv(name: name, phone: '+966501234567').resumeText;
      expect(text, startsWith('# $name\n'));
      expect(text, contains('sara@example.test | +966501234567'));
      expect(text, endsWith('## Professional Summary\n\nBuilds APIs.'));
    });
  }

  test('missing contact fields are skipped, not printed as blanks', () {
    final text = _cv(email: null).resumeText;
    expect(text, isNot(contains('|')));
    expect(text, isNot(contains('null')));
  });

  test('blank markdown stays blank so callers keep the fetch fallback', () {
    for (final blank in ['', ' ', '\n\t ']) {
      expect(_cv(markdown: blank).resumeText, isEmpty);
    }
  });
}
