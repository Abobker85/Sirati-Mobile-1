import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_list_field.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

String? _problemText(
  Set<EntryProblem> problems,
  EntryProblem problem,
  AppLocalizations l10n,
) {
  if (!problems.contains(problem)) return null;
  return switch (problem) {
    EntryProblem.missingTitle ||
    EntryProblem.missingOrganisation ||
    EntryProblem.missingDescription =>
      l10n.cvEntryRequired,
    EntryProblem.missingStart => l10n.cvEntryChooseStart,
    EntryProblem.missingEnd => l10n.cvEntryChooseEnd,
    EntryProblem.endBeforeStart => l10n.cvEntryEndBeforeStart,
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
    final endError = _problemText(
            problems, EntryProblem.missingEnd, AppLocalizations.of(context)) ??
        _problemText(problems, EntryProblem.endBeforeStart,
            AppLocalizations.of(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MonthYearButton(
                key: const ValueKey('entry-start'),
                label: AppLocalizations.of(context).cvEntryFrom,
                value: start,
                english: english,
                onChanged: onStart,
                error: _problemText(problems, EntryProblem.missingStart,
                    AppLocalizations.of(context)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MonthYearButton(
                key: const ValueKey('entry-end'),
                label: AppLocalizations.of(context).cvEntryTo,
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
          label: AppLocalizations.of(context).cvEntryJobTitle,
          hint: AppLocalizations.of(context).cvEntryJobTitleHint,
          value: e.title,
          error: _problemText(problems, EntryProblem.missingTitle,
              AppLocalizations.of(context)),
          onChanged: (v) => onChanged(e.copyWith(title: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-company'),
          label: AppLocalizations.of(context).cvEntryCompany,
          value: e.company,
          error: _problemText(problems, EntryProblem.missingOrganisation,
              AppLocalizations.of(context)),
          onChanged: (v) => onChanged(e.copyWith(company: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-location'),
          label: AppLocalizations.of(context).cvEntryCity,
          value: e.location,
          onChanged: (v) => onChanged(e.copyWith(location: v)),
        ),
        _Period(
          english: english,
          start: e.start,
          end: e.end,
          current: e.current,
          currentLabel: AppLocalizations.of(context).cvEntryWorkCurrent,
          problems: problems,
          onStart: (v) => onChanged(e.copyWith(start: v)),
          onEnd: (v) => onChanged(e.copyWith(end: v)),
          onCurrent: (v) => onChanged(e.copyWith(current: v, clearEnd: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-description'),
          label: AppLocalizations.of(context).cvEntryDuties,
          hint: AppLocalizations.of(context).cvEntryDutiesHint,
          value: e.description,
          maxLines: 8,
          error: _problemText(problems, EntryProblem.missingDescription,
              AppLocalizations.of(context)),
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
          label: AppLocalizations.of(context).cvEntryDegree,
          hint: AppLocalizations.of(context).cvEntryDegreeHint,
          value: e.degree,
          error: _problemText(problems, EntryProblem.missingTitle,
              AppLocalizations.of(context)),
          onChanged: (v) => onChanged(e.copyWith(degree: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-institution'),
          label: AppLocalizations.of(context).cvEntryInstitution,
          value: e.institution,
          error: _problemText(problems, EntryProblem.missingOrganisation,
              AppLocalizations.of(context)),
          onChanged: (v) => onChanged(e.copyWith(institution: v)),
        ),
        _Period(
          english: english,
          start: e.start,
          end: e.end,
          current: e.current,
          currentLabel: AppLocalizations.of(context).cvEntryStudyCurrent,
          problems: problems,
          onStart: (v) => onChanged(e.copyWith(start: v)),
          onEnd: (v) => onChanged(e.copyWith(end: v)),
          onCurrent: (v) => onChanged(e.copyWith(current: v, clearEnd: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-details'),
          label: AppLocalizations.of(context).cvEntryEducationDetails,
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
          label: AppLocalizations.of(context).cvEntryCertName,
          value: e.name,
          error: _problemText(problems, EntryProblem.missingTitle,
              AppLocalizations.of(context)),
          onChanged: (v) => onChanged(e.copyWith(name: v)),
        ),
        EntryTextInput(
          key: const ValueKey('entry-cert-issuer'),
          label: AppLocalizations.of(context).cvEntryCertIssuer,
          value: e.issuer,
          onChanged: (v) => onChanged(e.copyWith(issuer: v)),
        ),
        MonthYearButton(
          key: const ValueKey('entry-cert-date'),
          label: AppLocalizations.of(context).cvEntryCertDate,
          value: e.date,
          english: english,
          onChanged: (v) => onChanged(e.copyWith(date: v)),
        ),
      ],
    );
