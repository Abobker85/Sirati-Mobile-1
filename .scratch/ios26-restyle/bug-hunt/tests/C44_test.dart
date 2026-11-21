import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirati/features/cv_builder/presentation/experience_education_editor.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

// Invariant: validateDateRange reports "end before start" only when the end
// date is certainly earlier than the start. A year-only end covers the whole
// year, and input that is not (yet) a full date is never "before" anything.
void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  String? range(String s, String e) =>
      ExperienceEducationEditor.validateDateRange(s, e, false, l);

  const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec'];
  const arNames = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

  test('valid ranges with a year-only end are accepted', () {
    final failures = <String>[];
    for (var y = 1990; y <= 2030; y++) {
      for (var m = 1; m <= 12; m++) {
        for (final s in ['$y-${m.toString().padLeft(2, '0')}', '$y-$m',
            '$m/$y', '${names[m]} $y', '${arNames[m]} $y']) {
          if (range(s, '$y') != null) failures.add('$s -> $y');
          if (range(s, '${y + 1}') != null) failures.add('$s -> ${y + 1}');
          // control: an end year before the start year is still flagged
          if (range(s, '${y - 1}') == null) failures.add('missed $s -> ${y - 1}');
        }
      }
    }
    expect(failures, isEmpty, reason: '${failures.length} wrong: ${failures.take(8)}');
  });

  test('incomplete or non-date end input is not flagged', () {
    final failures = <String>[];
    for (var y = 1990; y <= 2030; y++) {
      final start = '$y-05';
      final target = '${y + 2}-03';
      for (var i = 1; i < target.length; i++) {
        final partial = target.substring(0, i);
        if (range(start, partial) != null) failures.add('$start -> "$partial"');
      }
      for (final word in ['Present', 'حتى الآن', 'Now', 'ongoing']) {
        if (range(start, word) != null) failures.add('$start -> "$word"');
      }
    }
    expect(failures, isEmpty, reason: '${failures.length} wrong: ${failures.take(8)}');
  });
}
