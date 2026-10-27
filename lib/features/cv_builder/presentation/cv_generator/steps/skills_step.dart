import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/skill_chips_selector.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

/// Step 2: core skills (chip picker) and professional summary.
class SkillsStep extends StatelessWidget {
  const SkillsStep({super.key, required this.props, required this.jobTitles});

  final WizardStepProps props;
  final List<JobTitle> jobTitles;

  @override
  Widget build(BuildContext context) {
    final english = props.english;
    final l10n = AppLocalizations.of(context);
    final f = props.fields;

    return WizardStepForm(
      props: props,
      title: l10n.cvSkillsStepTitle,
      icon: Icons.psychology_rounded,
      children: [
        FieldGroup(
          label: l10n.cvSkillsCore,
          // One editor for skills: the chips own the text the AI enhances,
          // so a second raw field would only show the same list twice.
          child: AiCvField(
            field: 'skills',
            controller: f.skills,
            english: english,
            isLoading: props.isEnhancing('skills'),
            helperText: l10n.cvSkillsHelper,
            result: props.fieldResults['skills'],
            onEnhance: () => props.onEnhance('skills'),
            onDismissResult: () => props.onDismissResult('skills'),
            child: FormField<String>(
              validator: (_) =>
                  f.skills.text.trim().isEmpty ? l10n.cvSkillsRequired : null,
              builder: (state) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkillChipsSelector(
                    controller: f.skills,
                    targetJobTitle: f.jobTitle.text,
                    english: english,
                    allJobTitles: jobTitles,
                    enabled: !props.isEnhancing('skills'),
                    onChanged: () => state.didChange(f.skills.text),
                  ),
                  if (state.hasError) ...[
                    const SizedBox(height: 6),
                    Text(
                      state.errorText!,
                      style: AppFormStyles.errorTextStyle(context.sirati),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FieldGroup(
          label: l10n.cvSummaryLabel,
          child: AiCvField(
            field: 'summary',
            controller: f.summary,
            english: english,
            isLoading: props.isEnhancing('summary'),
            helperText: l10n.cvSummaryHelper,
            result: props.fieldResults['summary'],
            onEnhance: () => props.onEnhance('summary'),
            onDismissResult: () => props.onDismissResult('summary'),
            child: AppTextFormField(
              controller: f.summary,
              textAlign: TextAlign.start,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => props.onPrimaryAction(),
              enabled: !props.isEnhancing('summary'),
              hintText: l10n.cvSummaryHint,
            ),
          ),
        ),
      ],
    );
  }
}
