import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/features/cv_builder/domain/cv_form_data.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_cards.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/entry_list_field.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';

/// Step 3: work experience as separate jobs — title, employer, period and
/// achievements each — with the XYZ achievement builder (Salem review,
/// issue 3).
class ExperienceStep extends StatelessWidget {
  const ExperienceStep({
    super.key,
    required this.props,
    required this.language,
    required this.onOpenAchievementBuilder,
  });

  final WizardStepProps props;

  /// CV language: the period's "Present" is written in it.
  final String language;
  final VoidCallback onOpenAchievementBuilder;

  @override
  Widget build(BuildContext context) {
    final english = props.english;
    final c = context.sirati;
    final enhancing = props.isEnhancing('experience');

    return WizardStepForm(
      props: props,
      title: english ? 'Work Experience' : 'الخبرات العملية',
      icon: Icons.work_rounded,
      children: [
        FieldGroup(
          label: english ? 'Experience *' : 'الخبرة العملية *',
          child: AiCvField(
            field: 'experience',
            controller: props.fields.experience,
            english: english,
            isLoading: enhancing,
            minimumCharacters: CvFormData.minExperienceChars,
            helperText: english
                ? 'Add each job separately, newest first.'
                : 'أضف كل وظيفة على حدة، الأحدث أولاً.',
            result: props.fieldResults['experience'],
            onEnhance: () => props.onEnhance('experience'),
            onDismissResult: () => props.onDismissResult('experience'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton.icon(
                    key: const Key('open_achievement_builder_btn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      foregroundColor: c.primaryDark,
                      side: BorderSide(color: c.primary.withValues(alpha: .35)),
                      backgroundColor: c.primaryLight.withValues(alpha: .5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: enhancing ? null : onOpenAchievementBuilder,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      english
                          ? 'XYZ Achievement Builder'
                          : 'صانع الإنجازات المقاسة (معادلة XYZ)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
                EntryListField<ExperienceEntry>(
                  key: const ValueKey('experience-entries'),
                  controller: props.fields.experience,
                  english: english,
                  autovalidateMode: props.autovalidateMode,
                  parse: parseExperience,
                  serialize: (entries) => serializeExperience(entries, language),
                  problems: experienceProblems,
                  blank: const ExperienceEntry(),
                  isBlank: (e) => e.isBlank,
                  minimumCharacters: CvFormData.minExperienceChars,
                  addLabel: english ? 'Add another job' : 'إضافة خبرة أخرى',
                  cardBuilder: (context, entry, onChanged, problems) =>
                      experienceCard(context, entry, onChanged, problems,
                          english: english),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
