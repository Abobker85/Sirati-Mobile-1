import 'package:flutter/material.dart';
import 'package:sirati/features/auth/domain/registration_rules.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Localised message for a rejected registration field.
String fieldErrorText(
  FieldError error, {
  required AppLocalizations l10n,
  required String requiredText,
  int? max,
}) =>
    switch (error) {
      FieldError.required => requiredText,
      FieldError.tooLong => l10n.authFieldTooLong(max ?? 0),
      FieldError.tooShort =>
        l10n.authPasswordTooShort(RegistrationRules.passwordMin),
      FieldError.invalidEmail => l10n.authEmailInvalid,
      FieldError.invalidPhone => l10n.authPhoneInvalid,
    };

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: AppTextStyles.labelMd(context.sirati).copyWith(
          fontWeight: FontWeight.w700,
          color: context.sirati.textSecondary,
        ),
      ),
    );
  }
}

/// Checkbox row for accepting the terms; the whole row toggles.
class TermsAgreement extends StatelessWidget {
  const TermsAgreement({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    final l10n = AppLocalizations.of(context);
    return PressScale(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onChanged(!agreed),
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Checkbox(
                  value: agreed,
                  activeColor: colors.primary,
                  checkColor: colors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  side: BorderSide(color: colors.borderStrong, width: 1.4),
                  onChanged: (value) => onChanged(value ?? false),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: colors.textSecondary,
                      ),
                      children: [
                        TextSpan(text: l10n.authTermsAgreePrefix),
                        TextSpan(
                          text: l10n.authTermsLink,
                          style: TextStyle(
                            color: colors.primaryInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Already have an account? Sign In" with a 48dp tap target on the link.
class SignInPrompt extends StatelessWidget {
  const SignInPrompt({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.sirati;
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          l10n.authHaveAccount,
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: colors.primaryInk,
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          child: Text(l10n.signIn),
        ),
      ],
    );
  }
}
