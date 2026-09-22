import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/features/cv_builder/presentation/widgets/skill_chips_selector.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

/// Step 2: core skills (chip picker + free text) and professional summary.
class SkillsStep extends StatelessWidget {
  const SkillsStep({super.key, required this.props, required this.jobTitles});

  final WizardStepProps props;
  final List<JobTitle> jobTitles;

  @override
  Widget build(BuildContext context) {
    final english = props.english;
    final f = props.fields;

    return WizardStepForm(
      props: props,
      title: english ? 'Skills & Summary' : 'المهارات والملخص',
      icon: Icons.psychology_rounded,
      children: [
        FieldGroup(
          label: english ? 'Core Skills *' : 'المهارات الأساسية *',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkillChipsSelector(
                controller: f.skills,
                targetJobTitle: f.jobTitle.text,
                english: english,
                allJobTitles: jobTitles,
                enabled: !props.isEnhancing('skills'),
              ),
              const SizedBox(height: 12),
              AiCvField(
                field: 'skills',
                controller: f.skills,
                english: english,
                isLoading: props.isEnhancing('skills'),
                helperText: english
                    ? 'Example: Laravel, PHP, REST APIs, SQL, Git, Docker.'
                    : 'مثال: Laravel، PHP، REST APIs، SQL، Git، Docker.',
                result: props.fieldResults['skills'],
                onEnhance: () => props.onEnhance('skills'),
                onDismissResult: () => props.onDismissResult('skills'),
                child: AppTextFormField(
                  controller: f.skills,
                  textAlign: TextAlign.start,
                  maxLines: 4,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  enabled: !props.isEnhancing('skills'),
                  hintText: english
                      ? 'PHP, Laravel, API, SQL, Git, Agile, Docker'
                      : 'PHP، Laravel، API، SQL، Git، Agile، Docker',
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? (english
                          ? 'Core skills are required.'
                          : 'المهارات الأساسية مطلوبة.')
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FieldGroup(
          label: english
              ? 'Professional Summary (optional)'
              : 'الملخص المهني (اختياري)',
          child: AiCvField(
            field: 'summary',
            controller: f.summary,
            english: english,
            isLoading: props.isEnhancing('summary'),
            helperText: english
                ? 'Example: Backend developer focused on reliable APIs and measurable product outcomes.'
                : 'مثال: مطور Backend متخصص في بناء APIs موثوقة وتحقيق نتائج قابلة للقياس.',
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
              hintText: english
                  ? 'Briefly describe your experience and achievements...'
                  : 'نبذة مختصرة عن خبرتك وإنجازاتك...',
            ),
          ),
        ),
      ],
    );
  }
}
