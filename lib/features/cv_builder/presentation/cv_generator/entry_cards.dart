import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_list_field.dart';

String? _problemText(
  Set<EntryProblem> problems,
  EntryProblem problem, {
  required bool english,
}) {
  if (!problems.contains(problem)) return null;
  return switch (problem) {
    EntryProblem.missingTitle ||
    EntryProblem.missingOrganisation ||
    EntryProblem.missingDescription =>
      english ? 'Required' : 'مطلوب',
    EntryProblem.missingStart => english ? 'Choose a start date' : 'اختر تاريخ البداية',
    EntryProblem.missingEnd => english
        ? 'Choose an end date or tick "currently"'
        : 'اختر تاريخ النهاية أو حدّد "حالياً"',
    EntryProblem.endBeforeStart =>
      english ? 'Ends before it starts' : 'النهاية قبل البداية',
  };
}

/// Start and end side by side, with the "currently" switch below.
class _Period extends StatelessWidget {
  const _Period({
    required this.english,
    required this.start,
    required this.end,
    required this.current,
    required this.currentLabel,
    required this.problems,
    required this.onStart,
    required this.onEnd,
    required this.onCurrent,
  });

  final bool english;
  final YearMonth? start;
  final YearMonth? end;
  final bool current;
  final String currentLabel;
  final Set<EntryProblem> problems;
  final ValueChanged<YearMonth> onStart;
  final ValueChanged<YearMonth> onEnd;
  final ValueChanged<bool> onCurrent;

  @override
  Widget build(BuildContext context) {
    final endError = _problemText(problems, EntryProblem.missingEnd,
            english: english) ??
        _problemText(problems, EntryProblem.endBeforeStart, english: english);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MonthYearButton(
                key: const ValueKey('entry-start'),
                label: english ? 'From *' : 'من *',
                value: start,
                english: english,
                onChanged: onStart,
                error: _problemText(problems, EntryProblem.missingStart,
                    english: english),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MonthYearButton(
                key: const ValueKey('entry-end'),
                label: english ? 'To' : 'إلى',
                value: current ? null : end,
                english: english,
                enabled: !current,
                onChanged: onEnd,
                error: current ? null : endError,
              ),
            ),
          ],
        ),
        CheckboxListTile(
          key: const ValueKey('entry-current'),
          value: current,
          onChanged: (v) => onCurrent(v ?? false),
          title: Text(currentLabel),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        ),
      ],
    );
  }
}

Widget experienceCard(
  BuildContext context,
  ExperienceEntry e,
  ValueChanged<ExperienceEntry> onChanged,
  Set<EntryProblem> problems, {
  required bool english,
}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntryTextInput(
          key: const ValueKey('entry-title'),
          label: english ? 'Job title *' : 'المسمى الوظيفي *',
          hint: english ? 'e.g. Sales specialist' : 'مثال: أخصائي مبيعات',
          value: e.title,
          error: _problemText(problems, EntryProblem.missingTitle,
              english: english),
          onChanged: (v) => onChanged(e.copyWith(title: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-company'),
          label: english ? 'Company *' : 'جهة العمل *',
          value: e.company,
          error: _problemText(problems, EntryProblem.missingOrganisation,
              english: english),
          onChanged: (v) => onChanged(e.copyWith(company: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-location'),
          label: english ? 'City (optional)' : 'المدينة (اختياري)',
          value: e.location,
          onChanged: (v) => onChanged(e.copyWith(location: v)),
        ),
        _Period(
          english: english,
          start: e.start,
          end: e.end,
          current: e.current,
          currentLabel:
              english ? 'I currently work here' : 'أعمل هنا حالياً',
          problems: problems,
          onStart: (v) => onChanged(e.copyWith(start: v)),
          onEnd: (v) => onChanged(e.copyWith(end: v)),
          onCurrent: (v) => onChanged(e.copyWith(current: v, clearEnd: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-description'),
          label: english
              ? 'Duties and achievements *'
              : 'المهام والإنجازات *',
          hint: english
              ? 'One per line, with numbers where you can'
              : 'سطر لكل إنجاز، وبالأرقام إن أمكن',
          value: e.description,
          maxLines: 8,
          error: _problemText(problems, EntryProblem.missingDescription,
              english: english),
          onChanged: (v) => onChanged(e.copyWith(description: v)),
        ),
      ],
    );

Widget educationCard(
  BuildContext context,
  EducationEntry e,
  ValueChanged<EducationEntry> onChanged,
  Set<EntryProblem> problems, {
  required bool english,
}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntryTextInput(
          key: const ValueKey('entry-degree'),
          label: english ? 'Degree and major *' : 'المؤهل والتخصص *',
          hint: english
              ? 'e.g. BSc Computer Science'
              : 'مثال: بكالوريوس علوم الحاسب',
          value: e.degree,
          error: _problemText(problems, EntryProblem.missingTitle,
              english: english),
          onChanged: (v) => onChanged(e.copyWith(degree: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-institution'),
          label: english ? 'University or institute *' : 'الجامعة أو المعهد *',
          value: e.institution,
          error: _problemText(problems, EntryProblem.missingOrganisation,
              english: english),
          onChanged: (v) => onChanged(e.copyWith(institution: v)),
        ),
        _Period(
          english: english,
          start: e.start,
          end: e.end,
          current: e.current,
          currentLabel: english ? 'I am studying here now' : 'أدرس هنا حالياً',
          problems: problems,
          onStart: (v) => onChanged(e.copyWith(start: v)),
          onEnd: (v) => onChanged(e.copyWith(end: v)),
          onCurrent: (v) => onChanged(e.copyWith(current: v, clearEnd: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-details'),
          label: english
              ? 'Grade, honours, projects (optional)'
              : 'المعدل، مرتبة الشرف، المشاريع (اختياري)',
          value: e.details,
          maxLines: 4,
          onChanged: (v) => onChanged(e.copyWith(details: v)),
        ),
      ],
    );

Widget certificationCard(
  BuildContext context,
  CertificationEntry e,
  ValueChanged<CertificationEntry> onChanged,
  Set<EntryProblem> problems, {
  required bool english,
}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntryTextInput(
          key: const ValueKey('entry-cert-name'),
          label: english ? 'Certificate or course *' : 'الشهادة أو الدورة *',
          value: e.name,
          error: _problemText(problems, EntryProblem.missingTitle,
              english: english),
          onChanged: (v) => onChanged(e.copyWith(name: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-cert-issuer'),
          label: english ? 'Issued by' : 'الجهة المانحة',
          value: e.issuer,
          onChanged: (v) => onChanged(e.copyWith(issuer: v)),
        ),
        MonthYearButton(
          key: const ValueKey('entry-cert-date'),
          label: english ? 'Date' : 'التاريخ',
          value: e.date,
          english: english,
          onChanged: (v) => onChanged(e.copyWith(date: v)),
        ),
      ],
    );
