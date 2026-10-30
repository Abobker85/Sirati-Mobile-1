import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/ai_cv_field.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/loading/ai_field_loading_overlay.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Step 1: contact details, target role, optional job description, and the
/// CV output language.
class PersonalStep extends StatelessWidget {
  const PersonalStep({
    super.key,
    required this.props,
    required this.language,
    required this.onLanguageChanged,
    required this.isEnhancingJobDescription,
    required this.onEnhanceJobDescription,
  });

  final WizardStepProps props;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final bool isEnhancingJobDescription;
  final VoidCallback onEnhanceJobDescription;

  @override
  Widget build(BuildContext context) {
    final english = props.english;
    final l10n = AppLocalizations.of(context);
    final f = props.fields;
    void next(String _) => FocusScope.of(context).nextFocus();

    return WizardStepForm(
      props: props,
      title: l10n.cvPersonalStepTitle,
      icon: Icons.person_rounded,
      children: [
        FieldGroup(
          label: l10n.cvPersonalFullName,
          child: AppTextFormField(
            controller: f.name,
            textAlign: TextAlign.start,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: next,
            hintText: l10n.cvPersonalFullNameHint,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? l10n.cvPersonalFullNameRequired
                : null,
          ),
        ),
        const SizedBox(height: 14),
        FieldGroup(
          label: l10n.emailLabel,
          child: AppTextFormField(
            controller: f.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: next,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            hintText: l10n.cvPersonalEmailHint,
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return l10n.cvPersonalEmailRequired;
              }
              if (!email.contains('@')) {
                return l10n.cvPersonalEmailInvalid;
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 14),
        FieldGroup(
          label: l10n.cvPersonalPhone,
          child: AppTextFormField(
            controller: f.phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: next,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            hintText: l10n.cvPersonalPhoneHint,
            prefixIcon: const Icon(Icons.phone_outlined),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? l10n.cvPersonalPhoneRequired
                : null,
          ),
        ),
        const SizedBox(height: 14),
        FieldGroup(
          label: l10n.cvPersonalLinkedin,
          child: AppTextFormField(
            controller: f.linkedin,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: next,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            hintText: l10n.cvPersonalLinkedinHint,
            prefixIcon: const Icon(Icons.link_rounded),
          ),
        ),
        const SizedBox(height: 14),
        FieldGroup(
          label: l10n.cvPersonalTargetJob,
          child: AppTextFormField(
            controller: f.jobTitle,
            textAlign: TextAlign.start,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: next,
            hintText: l10n.cvPersonalTargetJobHint,
            prefixIcon: const Icon(Icons.work_outline_rounded),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? l10n.cvPersonalTargetJobRequired
                : null,
          ),
        ),
        const SizedBox(height: 14),
        FieldGroup(
          label: l10n.cvPersonalJobDescription,
          child: _JobDescriptionField(
            controller: f.jobDescription,
            english: english,
            isEnhancing: isEnhancingJobDescription,
            onEnhance: onEnhanceJobDescription,
            onDone: props.onPrimaryAction,
          ),
        ),
        const SizedBox(height: 18),
        FieldLabel(l10n.cvPersonalCvLanguage),
        const SizedBox(height: 8),
        _LanguagePicker(value: language, onChanged: onLanguageChanged),
      ],
    );
  }
}

class _JobDescriptionField extends StatelessWidget {
  const _JobDescriptionField({
    required this.controller,
    required this.english,
    required this.isEnhancing,
    required this.onEnhance,
    required this.onDone,
  });

  final TextEditingController controller;
  final bool english;
  final bool isEnhancing;
  final VoidCallback onEnhance;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AiFieldLoadingOverlay(
          isLoading: isEnhancing,
          semanticsLabel: l10n.cvPersonalEnhancingJobDescription,
          child: AppTextFormField(
            controller: controller,
            textAlign: TextAlign.start,
            maxLines: 5,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onDone(),
            enabled: !isEnhancing,
            hintText: l10n.cvPersonalJobDescriptionHint,
            prefixIcon: const Icon(Icons.assignment_outlined),
          ),
        ),
        const SizedBox(height: 10),
        // Rebuild only the button row as the user types, not the whole step.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final enabled = !isEnhancing &&
                AiCvField.isSufficientForEnhancement(value.text);
            final showHint =
                value.text.trim().isNotEmpty && !enabled && !isEnhancing;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SubmitButton(
                  label: l10n.cvEnhance,
                  loadingLabel: l10n.cvEnhancing,
                  isLoading: isEnhancing,
                  outlined: true,
                  height: 48,
                  icon: Icons.auto_fix_high_rounded,
                  onPressed: enabled ? onEnhance : null,
                ),
                if (showHint) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: context.sirati.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l10n.cvPersonalWriteMore,
                          style: TextStyle(
                            color: context.sirati.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.sirati.border),
      ),
      child: Row(
        children: [
          for (final (code, label) in [
            ('en', l10n.languageEnglish),
            ('ar', l10n.languageArabic),
          ])
            Expanded(
              child: _LanguageOption(
                label: label,
                selected: value == code,
                onTap: () => onChanged(code),
              ),
            ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.sirati.primary : null,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              color: selected
                  ? context.sirati.onPrimary
                  : context.sirati.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
