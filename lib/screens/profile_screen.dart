import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_locale.dart';
import '../models/auth_session.dart';
import '../services/api_exception.dart';
import '../services/auth_api_service.dart';
import '../services/session_cache.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_fields.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/submit_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _auth = AuthApiService();
  late Future<AuthUser?> _future;
  bool _loading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<AuthUser?> _load() async {
    final cached = SessionCache.instance.user.value;
    if (cached != null) {
      _nameCtrl.text = cached.name;
    }
    try {
      final user = await _auth.me();
      if (user != null) {
        _nameCtrl.text = user.name;
      }
      return user ?? cached;
    } on ApiException {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _save() async {
    final en = AppLocale.isEnglish(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.selectionClick();
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.updateProfile(name: _nameCtrl.text.trim());
      if (!mounted) return;
      HapticFeedback.lightImpact();
      AppSnackBar.success(
        context,
        en ? 'Profile updated.' : 'تم تحديث الملف الشخصي.',
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.fromException(context, e);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          en ? 'Could not update profile.' : 'تعذر تحديث الملف الشخصي.',
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
        title: Text(en ? 'Profile' : 'الملف الشخصي'),
      ),
      body: FutureBuilder<AuthUser?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              SessionCache.instance.user.value == null) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppSkeletonScope(
                child: Column(
                  children: [
                    AppSkeleton(height: 54, radius: 14),
                    SizedBox(height: AppSpacing.md),
                    AppSkeleton(height: 54, radius: 14),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasError && snapshot.data == null) {
            return AppErrorState(
              english: en,
              message: snapshot.error is ApiException
                  ? (snapshot.error as ApiException).displayMessage
                  : (en
                      ? 'Could not load profile.'
                      : 'تعذر تحميل الملف الشخصي.'),
              onRetry: () => setState(() => _future = _load()),
              exception: snapshot.error is ApiException
                  ? snapshot.error as ApiException
                  : null,
            );
          }

          final user = snapshot.data ?? SessionCache.instance.user.value;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
              children: [
                Text(
                  en ? 'Full name' : 'الاسم الكامل',
                  textAlign: TextAlign.start,
                  style: AppTextStyles.titleSm()
                      .copyWith(color: context.sirati.textSecondary),
                ),
                const SizedBox(height: 6),
                AppTextFormField(
                  controller: _nameCtrl,
                  showSuccessWhenValid: true,
                  successMessage: en ? 'Looks good' : 'يبدو جيداً',
                  autovalidateMode: _submitted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  autofillHints: const [AutofillHints.name],
                  textAlign: TextAlign.start,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  hintText: en ? 'Your name' : 'اسمك',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (en ? 'Name is required' : 'الاسم مطلوب')
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  en ? 'Email' : 'البريد الإلكتروني',
                  textAlign: TextAlign.start,
                  style: AppTextStyles.titleSm()
                      .copyWith(color: context.sirati.textSecondary),
                ),
                const SizedBox(height: 6),
                AppTextFormField(
                  initialValue: user?.email ?? '',
                  enabled: false,
                  readOnly: true,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  en
                      ? 'Email cannot be changed here.'
                      : 'لا يمكن تغيير البريد من هنا.',
                  textAlign: TextAlign.start,
                  style: AppTextStyles.bodySm()
                      .copyWith(color: context.sirati.textHint),
                ),
                if ((user?.phone ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    en ? 'Phone' : 'الجوال',
                    textAlign: TextAlign.start,
                    style: AppTextStyles.titleSm()
                        .copyWith(color: context.sirati.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    initialValue: user!.phone,
                    enabled: false,
                    readOnly: true,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    prefixIcon: const Icon(Icons.phone_iphone_outlined),
                  ),
                ],
                if ((user?.location ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    en ? 'Location' : 'الموقع',
                    textAlign: TextAlign.start,
                    style: AppTextStyles.titleSm()
                        .copyWith(color: context.sirati.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  AppTextFormField(
                    initialValue: user!.location,
                    enabled: false,
                    readOnly: true,
                    textAlign: TextAlign.start,
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                SubmitButton(
                  label: en ? 'Save changes' : 'حفظ التغييرات',
                  loadingLabel: en ? 'Saving...' : 'جارٍ الحفظ...',
                  isLoading: _loading,
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
