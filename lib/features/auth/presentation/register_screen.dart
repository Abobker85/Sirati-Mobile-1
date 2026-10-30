import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/analytics_service.dart';
import 'package:sirati/core/routing/app_router.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/root_navigation.dart';
import 'package:sirati/features/auth/application/register_controller.dart';
import 'package:sirati/features/auth/domain/registration_rules.dart';
import 'package:sirati/features/auth/presentation/email_verification_screen.dart';
import 'package:sirati/features/auth/presentation/login_screen.dart';
import 'package:sirati/features/auth/presentation/register/register_widgets.dart';
import 'package:sirati/features/auth/presentation/social_sign_in_section.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/auth_hero_page.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/job_title_picker_field.dart';
import 'package:sirati/shared/widgets/password_strength_meter.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jobTitleOtherController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _submitted = false;
  bool _showFormBanner = false;
  JobTitle? _selectedJobTitle;

  bool get _isOther => _selectedJobTitle?.isOther == true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Firebase.apps.isNotEmpty) {
      unawaited(FirebaseCrashlytics.instance.log('RegisterScreen opened'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _jobTitleOtherController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (ref.read(registerControllerProvider)) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitted = true;
      _showFormBanner = false;
    });

    final valid = _formKey.currentState!.validate();
    final otherError = RegistrationRules.jobTitleOther(
      _jobTitleOtherController.text,
      isOther: _isOther,
    );
    if (!valid || !_agreedToTerms || otherError != null) {
      setState(() => _showFormBanner = true);
      unawaited(HapticFeedback.selectionClick());
      if (!_agreedToTerms) {
        AppSnackBar.warning(
          context,
          l10n.authAgreeTermsRequired,
        );
      }
      return;
    }

    final outcome = await ref.read(registerControllerProvider.notifier).submit(
          RegistrationInput(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _phoneController.text,
            location: _locationController.text,
            jobTitleId: _selectedJobTitle?.id,
            jobTitleIsOther: _isOther,
            jobTitleOther: _jobTitleOtherController.text,
          ),
        );
    if (!mounted) return;

    switch (outcome) {
      case RegisterSucceeded(:final email):
        unawaited(AnalyticsService.logRegisterSuccess());
        unawaited(HapticFeedback.lightImpact());
        replaceRoot(context, EmailVerificationScreen(email: email));
      case RegisterRejected(:final error):
        AppSnackBar.fromException(
          context,
          error,
          retryLabel: l10n.authRetry,
          onRetry: _register,
        );
      case RegisterFailedUnexpectedly():
        AppSnackBar.error(
          context,
          l10n.authRegisterUnexpectedError,
        );
      case RegisterIgnored():
        break;
    }
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      unawaited(navigator.pushNamedAndRemoveUntil(
        AppRoutes.splash,
        (route) => false,
      ));
    }
  }

  void _goToLogin() {
    unawaited(Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    ));
  }

  AutovalidateMode get _autovalidate => _submitted
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  String? Function(String?) _validator(
    FieldError? Function(String?) rule, {
    required String requiredText,
    int? max,
  }) {
    return (value) {
      final error = rule(value);
      if (error == null) return null;
      return fieldErrorText(
        error,
        l10n: AppLocalizations.of(context),
        requiredText: requiredText,
        max: max,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    final isLoading = ref.watch(registerControllerProvider);
    final jobTitles = ref.watch(jobTitlesProvider);
    final looksGood = l10n.authLooksGood;
    void next(String _) => FocusScope.of(context).nextFocus();

    final otherError = _submitted
        ? RegistrationRules.jobTitleOther(
            _jobTitleOtherController.text,
            isOther: _isOther,
          )
        : null;
    final otherRequired = l10n.authJobTitleOtherRequired;

    return Scaffold(
      backgroundColor: context.sirati.background,
      body: AuthHeroPage(
        size: AuthHeroSize.compact,
        title: l10n.authRegisterHeroTitle,
        subtitle: l10n.authRegisterHeroSubtitle,
        onBack: _handleBack,
        card: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showFormBanner)
                AppFormErrorBanner(
                  message: l10n.authFixHighlightedFields,
                  onDismiss: () => setState(() => _showFormBanner = false),
                ),
              FieldLabel(text: l10n.authFullNameLabel),
              AppTextFormField(
                controller: _nameController,
                showSuccessWhenValid: true,
                successMessage: looksGood,
                autovalidateMode: _autovalidate,
                textAlign: TextAlign.start,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: next,
                hintText: l10n.authFullNameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                validator: _validator(
                  RegistrationRules.name,
                  requiredText: l10n.authNameRequired,
                  max: RegistrationRules.nameMax,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FieldLabel(text: l10n.authEmailAddressLabel),
              AppTextFormField(
                controller: _emailController,
                showSuccessWhenValid: true,
                successMessage: looksGood,
                autovalidateMode: _autovalidate,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: next,
                hintText: l10n.authRegisterEmailHint,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                validator: _validator(
                  RegistrationRules.email,
                  requiredText: l10n.authEmailRequired,
                  max: RegistrationRules.emailMax,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FieldLabel(text: l10n.authPhoneLabel),
              AppTextFormField(
                controller: _phoneController,
                showSuccessWhenValid: true,
                successMessage: looksGood,
                autovalidateMode: _autovalidate,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: next,
                hintText: l10n.authPhoneHint,
                prefixIcon: const Icon(Icons.phone_iphone_outlined),
                validator: _validator(
                  RegistrationRules.phone,
                  requiredText: l10n.authPhoneRequired,
                  max: RegistrationRules.phoneMax,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FieldLabel(text: l10n.authLocationLabel),
              AppTextFormField(
                controller: _locationController,
                showSuccessWhenValid: true,
                successMessage: looksGood,
                autovalidateMode: _autovalidate,
                textAlign: TextAlign.start,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: next,
                hintText: l10n.authLocationHint,
                prefixIcon: const Icon(Icons.place_outlined),
                validator: _validator(
                  RegistrationRules.location,
                  requiredText: l10n.authLocationRequired,
                  max: RegistrationRules.locationMax,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FieldLabel(
                text: l10n.authJobTitleOptionalLabel,
              ),
              JobTitlePickerField(
                titles: jobTitles.value ?? const [],
                value: _selectedJobTitle,
                english: en,
                loading: jobTitles.isLoading && !jobTitles.hasValue,
                submitted: _submitted,
                errorText: otherError == null
                    ? null
                    : fieldErrorText(
                        otherError,
                        l10n: l10n,
                        requiredText: otherRequired,
                        max: RegistrationRules.jobTitleOtherMax,
                      ),
                onChanged: (title) => setState(() {
                  _selectedJobTitle = title;
                  if (title?.isOther != true) {
                    _jobTitleOtherController.clear();
                  }
                }),
                onManualEntry: (text) => setState(() {
                  _jobTitleOtherController.text = text;
                }),
              ),
              if (_isOther) ...[
                const SizedBox(height: AppSpacing.md),
                FieldLabel(
                  text: l10n.authJobTitleOtherLabel,
                ),
                AppTextFormField(
                  controller: _jobTitleOtherController,
                  showSuccessWhenValid: true,
                  successMessage: looksGood,
                  autovalidateMode: _autovalidate,
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: next,
                  maxLength: RegistrationRules.jobTitleOtherMax,
                  hintText: l10n.authJobTitleOtherHint,
                  prefixIcon: const Icon(Icons.edit_outlined),
                  validator: _validator(
                    (v) => RegistrationRules.jobTitleOther(
                      v,
                      isOther: _isOther,
                    ),
                    requiredText: otherRequired,
                    max: RegistrationRules.jobTitleOtherMax,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              FieldLabel(text: l10n.authPasswordLabel),
              AppTextFormField(
                controller: _passwordController,
                showSuccessWhenValid: true,
                autovalidateMode: _autovalidate,
                obscureText: _obscurePassword,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.start,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => unawaited(_register()),
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip:
                      _obscurePassword ? l10n.showPassword : l10n.hidePassword,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: context.sirati.textHint,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                onChanged: (_) => setState(() {}),
                validator: _validator(
                  RegistrationRules.password,
                  requiredText: l10n.authPasswordRequired,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              PasswordStrengthMeter(
                password: _passwordController.text,
                english: en,
              ),
              const SizedBox(height: 14),
              TermsAgreement(
                agreed: _agreedToTerms,
                onChanged: (value) => setState(() => _agreedToTerms = value),
              ),
              const SizedBox(height: AppSpacing.xs),
              SubmitButton(
                label: l10n.authCreateAccountButton,
                loadingLabel: l10n.authCreatingAccount,
                isLoading: isLoading,
                onPressed: () => unawaited(_register()),
              ),
              const SocialSignInSection(),
            ],
          ),
        ),
        below: [
          const SizedBox(height: AppSpacing.md),
          SignInPrompt(onTap: _goToLogin),
          const SizedBox(height: AppSpacing.xxs),
          TextButton(
            // Preview mode: Home becomes the root route so Back
            // doesn't return to the auth screens.
            onPressed: () => AppRouter.openAfterAuth(context),
            child: Text(
              l10n.authContinueWithoutAccount,
              style: TextStyle(
                fontSize: 12.5,
                color: context.sirati.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
