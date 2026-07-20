import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/form_fields.dart';
import '../widgets/submit_button.dart';
import 'splash_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _auth = AuthApiService();
  bool _obscure = true;
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final en = AppLocale.isEnglish(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(en ? 'Are you sure?' : 'هل أنت متأكد؟'),
        content: Text(
          en
              ? 'This cannot be undone. All your CVs and analyses will be permanently deleted.'
              : 'لا يمكن التراجع. سيتم حذف جميع السير والتحليلات نهائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(en ? 'Cancel' : 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.sirati.error),
            child: Text(en ? 'Delete forever' : 'حذف نهائي'),
          ),
        ],
      ),
    );
    if (second != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _auth.deleteAccount(password: _passwordCtrl.text);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        en ? 'Account deleted.' : 'تم حذف الحساب.',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final pwd = e.errors['password'];
      if (pwd != null && pwd.isNotEmpty) {
        AppSnackBar.error(
          context,
          en ? 'Password is incorrect.' : pwd.first,
        );
      } else {
        AppSnackBar.fromException(context, e);
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          en ? 'Could not delete account.' : 'تعذر حذف الحساب.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);

    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(
        title: Text(en ? 'Delete account' : 'حذف الحساب'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.sirati.errorLight.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: context.sirati.error.withValues(alpha: .25)),
              ),
              child: Text(
                en
                    ? 'Deleting your account permanently removes your profile, CVs, analyses, and notification history. This action cannot be undone.'
                    : 'حذف الحساب يزيل نهائياً ملفك والسير والتحليلات وسجل الإشعارات. لا يمكن التراجع عن هذا الإجراء.',
                textAlign: TextAlign.start,
                style: AppTextStyles.bodySm().copyWith(
                  color: context.sirati.error,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              en ? 'Confirm with password' : 'أكد بكلمة المرور',
              textAlign: TextAlign.start,
              style: AppTextStyles.titleSm()
                  .copyWith(color: context.sirati.textSecondary),
            ),
            SizedBox(height: 6),
            AppTextFormField(
              controller: _passwordCtrl,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _delete(),
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? (en ? 'Password is required' : 'كلمة المرور مطلوبة')
                  : null,
            ),
            SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: en ? 'Delete my account' : 'احذف حسابي',
              loadingLabel: en ? 'Deleting...' : 'جارٍ الحذف...',
              isLoading: _loading,
              icon: Icons.delete_forever_rounded,
              onPressed: _delete,
            ),
          ],
        ),
      ),
    );
  }
}
