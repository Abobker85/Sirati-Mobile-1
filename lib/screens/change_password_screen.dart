import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/form_fields.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/submit_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _auth = AuthApiService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitted = false;
  bool _showBanner = false;
  bool _loading = false;
  String? _currentFieldError;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final english = AppLocale.isEnglish(context);
    setState(() {
      _submitted = true;
      _showBanner = false;
      _currentFieldError = null;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _showBanner = true);
      HapticFeedback.selectionClick();
      return;
    }

    setState(() => _loading = true);
    try {
      final message = await _auth.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
        confirmation: _confirmCtrl.text,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      AppSnackBar.success(
        context,
        english
            ? 'Password changed successfully.'
            : (message.isNotEmpty ? message : 'تم تغيير كلمة المرور بنجاح.'),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      final fieldErrors = e.errors['current_password'];
      if (fieldErrors != null && fieldErrors.isNotEmpty) {
        setState(() {
          _currentFieldError =
              english ? 'Current password is incorrect.' : fieldErrors.first;
          _showBanner = true;
        });
        _formKey.currentState?.validate();
      } else {
        AppSnackBar.fromException(context, e);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        english
            ? 'Could not change password. Try again.'
            : 'تعذر تغيير كلمة المرور. حاول مجدداً.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final auto = _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled;

    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(
        title: Text(en ? 'Change password' : 'تغيير كلمة المرور'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            if (_showBanner)
              AppFormErrorBanner(
                message: en
                    ? 'Please fix the highlighted fields to continue.'
                    : 'يرجى تصحيح الحقول المحددة للمتابعة.',
                onDismiss: () => setState(() => _showBanner = false),
              ),
            _Label(en ? 'Current password' : 'كلمة المرور الحالية'),
            SizedBox(height: 6),
            AppTextFormField(
              controller: _currentCtrl,
              autovalidateMode: auto,
              obscureText: _obscureCurrent,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrent
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              validator: (v) {
                if (_currentFieldError != null) return _currentFieldError;
                if (v == null || v.isEmpty) {
                  return en
                      ? 'Enter your current password'
                      : 'أدخل كلمة المرور الحالية';
                }
                return null;
              },
              onChanged: (_) {
                if (_currentFieldError != null) {
                  setState(() => _currentFieldError = null);
                }
              },
            ),
            SizedBox(height: AppSpacing.md),
            _Label(en ? 'New password' : 'كلمة المرور الجديدة'),
            SizedBox(height: 6),
            AppTextFormField(
              controller: _newCtrl,
              autovalidateMode: auto,
              obscureText: _obscureNew,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNew
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return en ? 'Enter a new password' : 'أدخل كلمة مرور جديدة';
                }
                if (v.length < 8) {
                  return en
                      ? 'Password must be at least 8 characters'
                      : 'يجب أن تكون كلمة المرور 8 أحرف على الأقل';
                }
                if (v == _currentCtrl.text) {
                  return en
                      ? 'New password must differ from current'
                      : 'يجب أن تختلف عن كلمة المرور الحالية';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.xs),
            PasswordStrengthMeter(password: _newCtrl.text, english: en),
            SizedBox(height: AppSpacing.md),
            _Label(en ? 'Confirm new password' : 'تأكيد كلمة المرور الجديدة'),
            SizedBox(height: 6),
            AppTextFormField(
              controller: _confirmCtrl,
              autovalidateMode: auto,
              obscureText: _obscureConfirm,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return en
                      ? 'Confirm your new password'
                      : 'أكد كلمة المرور الجديدة';
                }
                if (v != _newCtrl.text) {
                  return en
                      ? 'Passwords do not match'
                      : 'كلمتا المرور غير متطابقتين';
                }
                return null;
              },
            ),
            SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: en ? 'Update password' : 'تحديث كلمة المرور',
              loadingLabel: en ? 'Updating...' : 'جارٍ التحديث...',
              isLoading: _loading,
              icon: Icons.check_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.start,
      style:
          AppTextStyles.titleSm().copyWith(color: context.sirati.textSecondary),
    );
  }
}
