import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_cards.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_list_field.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';

/// Step 4: education (required) and certifications (optional), one card per
/// qualification or certificate (Salem review, issue 3).
class EducationStep extends StatelessWidget {
  const EducationStep({super.key, required this.props, required this.language});

  final WizardStepProps props;

  /// CV language: the period's "Present" is written in it.
  final String language;

  @override
  Widget build(BuildContext context) {
    final english = props.english;
    final f = props.fields;

    return WizardStepForm(
      props: props,
      title: english ? 'Education & Certifications' : 'التعليم والشهادات',
      icon: Icons.school_rounded,
      children: [
        FieldGroup(
          label: english ? 'Education *' : 'التعليم *',
          child: EntryListField<EducationEntry>(
            key: const ValueKey('education-entries'),
            controller: f.education,
            english: english,
            autovalidateMode: props.autovalidateMode,
            parse: parseEducation,
            serialize: (entries) => serializeEducation(entries, language),
            problems: educationProblems,
            blank: const EducationEntry(),
            isBlank: (e) => e.isBlank,
            addLabel: english ? 'Add another qualification' : 'إضافة مؤهل آخر',
            cardBuilder: (context, entry, onChanged, problems) =>
                educationCard(context, entry, onChanged, problems,
                    english: english),
          ),
        ),
        const SizedBox(height: 18),
        FieldGroup(
          label: english
              ? 'Certifications & Courses (optional)'
              : 'الشهادات والدورات (اختياري)',
          child: EntryListField<CertificationEntry>(
            key: const ValueKey('certification-entries'),
            controller: f.certifications,
            english: english,
            autovalidateMode: props.autovalidateMode,
            parse: parseCertifications,
            serialize: serializeCertifications,
            problems: certificationProblems,
            blank: const CertificationEntry(),
            isBlank: (e) => e.isBlank,
            minimumCount: 0,
            addLabel:
                english ? 'Add another certificate' : 'إضافة شهادة أخرى',
            cardBuilder: (context, entry, onChanged, problems) =>
                certificationCard(context, entry, onChanged, problems,
                    english: english),
          ),
        ),
      ],
    );
  }
}
