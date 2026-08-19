import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../models/job_title.dart';
import '../services/analytics_service.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../services/mobile_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/root_navigation.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/auth_form_constraint.dart';
import '../widgets/form_fields.dart';
import '../widgets/job_title_picker_field.dart';
import '../widgets/language_toggle.dart';
import '../widgets/motion.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/submit_button.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _jobTitleOtherController = TextEditingController();
  final _authService = AuthApiService();
  final _contentService = MobileContentService();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _submitted = false;
  bool _showFormBanner = false;
  bool _jobTitlesLoading = true;
  List<JobTitle> _jobTitles = const [];
  JobTitle? _selectedJobTitle;

  @override
  void initState() {
    super.initState();
    unawaited(FirebaseCrashlytics.instance.log('RegisterScreen opened'));
    _loadJobTitles();
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

  Future<void> _loadJobTitles() async {
    try {
      final titles = await _contentService.jobTitles(force: true);
      if (!mounted) return;
      setState(() {
        _jobTitles = titles;
        _jobTitlesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _jobTitlesLoading = false);
    }
  }

  Future<void> _register() async {
    final en = AppLocale.isEnglish(context);
    setState(() {
      _submitted = true;
      _showFormBanner = false;
    });

    final valid = _formKey.currentState!.validate();
    final otherMissing = _selectedJobTitle?.isOther == true &&
        _jobTitleOtherController.text.trim().isEmpty;
    if (!valid || !_agreedToTerms || otherMissing) {
      setState(() => _showFormBanner = true);
      HapticFeedback.selectionClick();
      if (!_agreedToTerms) {
        AppSnackBar.warning(
          context,
          en
              ? 'Please agree to the Terms & Conditions'
              : 'يرجى الموافقة على الشروط والأحكام',
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final session = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordController.text,
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        jobTitleId: _selectedJobTitle?.id,
        jobTitleOther: _selectedJobTitle?.isOther == true
            ? _jobTitleOtherController.text.trim()
            : null,
      );

      if (!mounted) return;
      AnalyticsService.logRegisterSuccess();
      HapticFeedback.lightImpact();
      replaceRoot(
        context,
        EmailVerificationScreen(
          email: session.user.email.isNotEmpty
              ? session.user.email
              : _emailController.text.trim(),
        ),
      );
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: en ? 'Retry' : 'إعادة',
          onRetry: _register,
        );
      }
    } catch (_) {
      if (mounted) {
        _showError(en
            ? 'An unexpected error occurred while creating the account.'
            : 'حدث خطأ غير متوقع أثناء إنشاء الحساب.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AppSnackBar.error(context, message);
  }

  void _continueAsPreview() {
    // Use pushAndRemoveUntil so HomeScreen becomes the root route,
    // preventing the back button from returning to the welcome/auth screens.
    replaceRoot(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);

    return Scaffold(
      backgroundColor: context.sirati.background,
      body: SafeArea(
        child: AuthFormConstraint(
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      tooltip:
                          MaterialLocalizations.of(context).backButtonTooltip,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.sirati.textPrimary,
                        size: 18,
                      ),
                    ),
                    const Spacer(),
                    const LanguageToggle(),
                  ],
                ),
                const SizedBox(height: 8),
                _RegisterHero(english: en),
                const SizedBox(height: 22),
                if (_showFormBanner)
                  AppFormErrorBanner(
                    message: en
                        ? 'Please fix the highlighted fields to continue.'
                        : 'يرجى تصحيح الحقول المحددة للمتابعة.',
                    onDismiss: () => setState(() => _showFormBanner = false),
                  ),
                _FieldLabel(text: en ? 'Full Name' : 'الاسم الكامل'),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _nameController,
                  showSuccessWhenValid: true,
                  successMessage: en ? 'Looks good' : 'يبدو جيداً',
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  textAlign: TextAlign.start,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  hintText: en ? 'Enter your full name' : 'اكتب اسمك الكامل',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? (en
                          ? 'Please enter your full name'
                          : 'يرجى إدخال اسمك الكامل')
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                _FieldLabel(text: en ? 'Email Address' : 'البريد الإلكتروني'),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _emailController,
                  showSuccessWhenValid: true,
                  successMessage: en ? 'Looks good' : 'يبدو جيداً',
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  hintText: 'example@mail.com',
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return en
                          ? 'Please enter your email'
                          : 'يرجى إدخال البريد الإلكتروني';
                    }
                    if (!value.contains('@')) {
                      return en
                          ? 'Email address is invalid'
                          : 'البريد الإلكتروني غير صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _FieldLabel(text: en ? 'Phone Number' : 'رقم الجوال'),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _phoneController,
                  showSuccessWhenValid: true,
                  successMessage: en ? 'Looks good' : 'يبدو جيداً',
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  hintText: '05XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_iphone_outlined),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) {
                      return en
                          ? 'Please enter your phone number'
                          : 'يرجى إدخال رقم الجوال';
                    }
                    // Accept international format (+…) or 8+ digits.
                    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.length < 8) {
                      return en
                          ? 'Enter a valid phone number'
                          : 'أدخل رقم جوال صحيح';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _FieldLabel(text: en ? 'City/Country' : 'المدينة/الدولة'),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _locationController,
                  showSuccessWhenValid: true,
                  successMessage: en ? 'Looks good' : 'يبدو جيداً',
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  textAlign: TextAlign.start,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  hintText: en ? 'Riyadh, Saudi Arabia' : 'الرياض، السعودية',
                  prefixIcon: const Icon(Icons.place_outlined),
                  validator: (value) {
                    if ((value?.trim().isEmpty ?? true)) {
                      return en
                          ? 'Please enter your city or country'
                          : 'يرجى إدخال المدينة أو الدولة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _FieldLabel(
                    text: en
                        ? 'Job title (optional)'
                        : 'المسمى الوظيفي (اختياري)'),
                const SizedBox(height: 6),
                JobTitlePickerField(
                  titles: _jobTitles,
                  value: _selectedJobTitle,
                  english: en,
                  loading: _jobTitlesLoading,
                  submitted: _submitted,
                  errorText: _selectedJobTitle?.isOther == true &&
                          _submitted &&
                          _jobTitleOtherController.text.trim().isEmpty
                      ? (en
                          ? 'Please enter your job title'
                          : 'يرجى كتابة المسمى الوظيفي عند اختيار أخرى.')
                      : null,
                  onChanged: (title) {
                    setState(() {
                      _selectedJobTitle = title;
                      if (title?.isOther != true) {
                        _jobTitleOtherController.clear();
                      }
                    });
                  },
                ),
                if (_selectedJobTitle?.isOther == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(
                      text: en ? 'Your job title' : 'المسمى الوظيفي الخاص بك'),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    controller: _jobTitleOtherController,
                    showSuccessWhenValid: true,
                    successMessage: en ? 'Looks good' : 'يبدو جيداً',
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    textAlign: TextAlign.start,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    maxLength: 120,
                    hintText: en
                        ? 'e.g. Logistics Consultant'
                        : 'مثال: مستشار لوجستي',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    validator: (value) {
                      if (_selectedJobTitle?.isOther != true) return null;
                      if (value == null || value.trim().isEmpty) {
                        return en
                            ? 'Please enter your job title'
                            : 'يرجى كتابة المسمى الوظيفي عند اختيار أخرى.';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _FieldLabel(text: en ? 'Password' : 'كلمة المرور'),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _passwordController,
                  showSuccessWhenValid: true,
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  obscureText: _obscurePassword,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return en
                          ? 'Please enter your password'
                          : 'يرجى إدخال كلمة المرور';
                    }
                    if (value.length < 8) {
                      return en
                          ? 'Password must be at least 8 characters'
                          : 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                PasswordStrengthMeter(
                  password: _passwordController.text,
                  english: en,
                ),
                const SizedBox(height: 14),
                PressScale(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          setState(() => _agreedToTerms = !_agreedToTerms),
                      borderRadius: BorderRadius.circular(10),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              activeColor: context.sirati.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              side: BorderSide(
                                color: context.sirati.borderStrong,
                                width: 1.4,
                              ),
                              onChanged: (value) => setState(
                                  () => _agreedToTerms = value ?? false),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.55,
                                    color: context.sirati.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: en ? 'I agree to ' : 'أوافق على ',
                                    ),
                                    TextSpan(
                                      text: en
                                          ? 'Terms & Conditions'
                                          : 'الشروط والأحكام',
                                      style: TextStyle(
                                        color: context.sirati.primary,
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
                ),
                const SizedBox(height: AppSpacing.xs),
                SubmitButton(
                  label: en ? 'Create Account' : 'إنشاء الحساب',
                  loadingLabel:
                      en ? 'Creating account...' : 'جارٍ إنشاء الحساب...',
                  isLoading: _isLoading,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _register,
                ),
                const SizedBox(height: 14),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: context.sirati.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: en
                              ? 'Already have an account? '
                              : 'لديك حساب بالفعل؟ ',
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              en ? 'Sign In' : 'تسجيل الدخول',
                              style: TextStyle(
                                color: context.sirati.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _SocialDivider(english: en),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialCircle(label: 'G'),
                    SizedBox(width: 14),
                    _SocialCircle(icon: Icons.apple),
                    SizedBox(width: 14),
                    _SocialCircle(label: 'in'),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _continueAsPreview,
                  child: Text(
                    en ? 'Continue without account' : 'المتابعة بدون حساب',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.sirati.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: AppTextStyles.labelMd().copyWith(
          fontWeight: FontWeight.w700,
          color: context.sirati.textSecondary,
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  final bool english;

  const _RegisterHero({required this.english});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SiratiMark(size: 52),
        const SizedBox(height: 10),
        Text(
          english ? 'Join Us Today' : 'انضم إلينا اليوم',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.sirati.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          english
              ? 'Start your career journey and build a professional CV'
              : 'ابدأ رحلتك المهنية وابنِ سيرة ذاتية احترافية',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.6,
            color: context.sirati.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SocialDivider extends StatelessWidget {
  final bool english;

  const _SocialDivider({required this.english});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.sirati.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            english ? 'Or continue with' : 'أو المتابعة عبر',
            style: TextStyle(
              fontSize: 11.5,
              color: context.sirati.textHint,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.sirati.border)),
      ],
    );
  }
}

class _SocialCircle extends StatelessWidget {
  final IconData? icon;
  final String? label;

  const _SocialCircle({this.icon, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: context.sirati.background,
        shape: BoxShape.circle,
        border: Border.all(color: context.sirati.border, width: 1.5),
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: context.sirati.textPrimary, size: 22)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.sirati.textPrimary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
