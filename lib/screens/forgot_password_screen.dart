import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/form_fields.dart';
import '../widgets/language_toggle.dart';
import '../widgets/submit_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthApiService();
  bool _isLoading = false;
  bool _submitted = false;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _successMessage = null;
    });
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final message = await _authService.forgotPassword(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _successMessage = message);
    } on ApiException catch (exception) {
      if (mounted) {
        AppSnackBar.fromException(
          context,
          exception,
          retryLabel: AppLocale.languageCode.value == 'en' ? 'Retry' : 'إعادة',
          onRetry: _submit,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(english ? 'Reset Password' : 'استعادة كلمة المرور'),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Text(
              english
                  ? 'Enter your email and we will send a password reset link.'
                  : 'أدخل بريدك الإلكتروني وسنرسل لك رابط استعادة كلمة المرور.',
              textAlign: TextAlign.start,
              style:
                  AppTextStyles.titleMd().copyWith(fontSize: 17, height: 1.55),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              english ? 'Email Address' : 'البريد الإلكتروني',
              textAlign: TextAlign.start,
              style:
                  AppTextStyles.labelMd().copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _emailController,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              hintText: 'name@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return english
                      ? 'Please enter your email'
                      : 'يرجى إدخال البريد الإلكتروني';
                }
                if (!email.contains('@')) {
                  return english
                      ? 'Enter a valid email address'
                      : 'أدخل بريداً إلكترونياً صحيحاً';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SubmitButton(
              label: english ? 'Send Reset Link' : 'إرسال الرابط',
              loadingLabel: english ? 'Sending...' : 'جارٍ الإرسال...',
              isLoading: _isLoading,
              icon: Icons.send_outlined,
              onPressed: _submit,
            ),
            if (_successMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppFormSuccessBanner(message: _successMessage!),
            ],
          ],
        ),
      ),
    );
  }
}
