import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/domain/profile_update.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/job_title_picker_field.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _submitted = false;

  /// Once the user edits a field, late server data must not overwrite it.
  bool _nameEdited = false;
  bool _jobTitleEdited = false;
  bool _locationEdited = false;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _prefill(SessionCache.instance.user.value);
    ref.listenManual<AsyncValue<AuthUser?>>(
      settingsUserProvider,
      (_, next) {
        final user = next.value;
        if (user != null) setState(() => _prefill(user));
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _otherCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _prefill(AuthUser? user) {
    if (user == null) return;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone ?? '';
    if (!_nameEdited) _nameCtrl.text = user.name;
    if (!_locationEdited) _locationCtrl.text = user.location ?? '';
    if (!_jobTitleEdited) {
      _selectedId = user.jobTitleId;
      _otherCtrl.text = user.jobTitleOther ?? '';
    }
  }

  JobTitle? _selected(List<JobTitle> titles) {
    for (final t in titles) {
      if (t.id == _selectedId) return t;
    }
    return null;
  }

  Future<void> _save(List<JobTitle> titles) async {
    if (ref.read(profileSaveProvider)) return;
    final en = AppLocale.isEnglish(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      unawaited(HapticFeedback.selectionClick());
      return;
    }

    final selected = _selected(titles);
    final isOther = selected?.isOther ?? false;
    final JobTitleChange jobTitle = !_jobTitleEdited
        ? const JobTitleUnchanged()
        : selected == null
            ? const JobTitleCleared()
            : JobTitleSelected(
                selected.id,
                otherText: isOther ? _otherCtrl.text : null,
              );

    final outcome = await ref
        .read(profileSaveProvider.notifier)
        .save(ProfileUpdate(
          name: _nameCtrl.text,
          jobTitle: jobTitle,
          location: _locationEdited ? _locationCtrl.text : null,
        ));
    if (!mounted) return;
    switch (outcome) {
      case ProfileSaved():
        unawaited(HapticFeedback.lightImpact());
        AppSnackBar.success(
          context,
          en ? 'Profile updated.' : 'تم تحديث الملف الشخصي.',
        );
        Navigator.of(context).pop();
      case ProfileRejected(:final error):
        AppSnackBar.fromException(context, error);
      case ProfileSaveFailed():
        AppSnackBar.error(
          context,
          en ? 'Could not update profile.' : 'تعذر تحديث الملف الشخصي.',
        );
      case ProfileSaveIgnored():
        break;
    }
  }

  String? _errorText(
    ProfileFieldError? error, {
    required bool en,
    required String requiredEn,
    required String requiredAr,
    required int max,
  }) =>
      switch (error) {
        null => null,
        ProfileFieldError.required => en ? requiredEn : requiredAr,
        ProfileFieldError.tooLong =>
          en ? 'Must be at most $max characters' : 'يجب ألا يتجاوز $max حرفاً',
      };

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final userAsync = ref.watch(settingsUserProvider);
    final titlesAsync = ref.watch(jobTitlesProvider);
    final saving = ref.watch(profileSaveProvider);
    final cached = SessionCache.instance.user.value;

    Widget body;
    if (userAsync.isLoading && !userAsync.hasValue && cached == null) {
      body = const Padding(
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
    } else if (userAsync.hasError && !userAsync.hasValue && cached == null) {
      final error = userAsync.error;
      body = AppErrorState(
        english: en,
        message: error is ApiException
            ? error.displayMessage
            : (en ? 'Could not load profile.' : 'تعذر تحميل الملف الشخصي.'),
        onRetry: () => ref.invalidate(settingsUserProvider),
        exception: error is ApiException ? error : null,
      );
    } else {
      final user = userAsync.value ?? cached;
      final titles = titlesAsync.value ?? const <JobTitle>[];
      final selected = _selected(titles);
      final isOther = selected?.isOther ?? false;
      final autovalidate = _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled;
      final labelStyle = AppTextStyles.titleSm(context.sirati)
          .copyWith(color: context.sirati.textPrimary);
      Widget label(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(text, textAlign: TextAlign.start, style: labelStyle),
          );
      // Rows above (the "Other" job title field) appear once titles load, so
      // every field is keyed and controller-backed: an index-matched field
      // must never keep a neighbour's text.
      Widget readOnlyField(
        String id,
        TextEditingController controller,
        IconData icon, {
        bool ltr = false,
      }) =>
          AppTextFormField(
            key: ValueKey('profile-$id'),
            controller: controller,
            enabled: false,
            readOnly: true,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: TextAlign.start,
            prefixIcon: Icon(icon),
          );

      body = Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            label(en ? 'Full name' : 'الاسم الكامل'),
            AppTextFormField(
              controller: _nameCtrl,
              showSuccessWhenValid: true,
              successMessage: en ? 'Looks good' : 'يبدو جيداً',
              autovalidateMode: autovalidate,
              autofillHints: const [AutofillHints.name],
              textAlign: TextAlign.start,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _nameEdited = true,
              onFieldSubmitted: (_) => unawaited(_save(titles)),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              hintText: en ? 'Your name' : 'اسمك',
              validator: (v) => _errorText(
                ProfileRules.name(v),
                en: en,
                requiredEn: 'Name is required',
                requiredAr: 'الاسم مطلوب',
                max: ProfileRules.nameMax,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            label(en ? 'Job title' : 'المسمى الوظيفي'),
            JobTitlePickerField(
              titles: titles,
              value: selected,
              english: en,
              loading: titlesAsync.isLoading && !titlesAsync.hasValue,
              submitted: _submitted,
              onChanged: (title) => setState(() {
                _jobTitleEdited = true;
                _selectedId = title?.id;
                if (title?.isOther != true) _otherCtrl.clear();
              }),
            ),
            if (titlesAsync.hasError && !titlesAsync.hasValue) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      en
                          ? "Couldn't load job titles"
                          : 'تعذر تحميل المسميات الوظيفية',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.sirati.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(jobTitlesProvider),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: context.sirati.primaryInk,
                    ),
                    child: Text(en ? 'Retry' : 'إعادة المحاولة'),
                  ),
                ],
              ),
            ],
            if (isOther) ...[
              const SizedBox(height: AppSpacing.md),
              label(en ? 'Your job title' : 'المسمى الوظيفي الخاص بك'),
              AppTextFormField(
                controller: _otherCtrl,
                showSuccessWhenValid: true,
                successMessage: en ? 'Looks good' : 'يبدو جيداً',
                autovalidateMode: autovalidate,
                textAlign: TextAlign.start,
                maxLength: ProfileRules.jobTitleOtherMax,
                onChanged: (_) => _jobTitleEdited = true,
                hintText:
                    en ? 'e.g. Logistics Consultant' : 'مثال: مستشار لوجستي',
                prefixIcon: const Icon(Icons.edit_outlined),
                validator: (v) => _errorText(
                  ProfileRules.jobTitleOther(v, isOther: isOther),
                  en: en,
                  requiredEn: 'Please enter your job title',
                  requiredAr: 'يرجى كتابة المسمى الوظيفي عند اختيار أخرى.',
                  max: ProfileRules.jobTitleOtherMax,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            label(en ? 'Email' : 'البريد الإلكتروني'),
            readOnlyField(
              'email',
              _emailCtrl,
              Icons.mail_outline_rounded,
              ltr: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              en
                  ? 'Email cannot be changed here.'
                  : 'لا يمكن تغيير البريد من هنا.',
              textAlign: TextAlign.start,
              style: AppTextStyles.bodySm(context.sirati)
                  .copyWith(color: context.sirati.textHint),
            ),
            if ((user?.phone ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              label(en ? 'Phone' : 'الجوال'),
              readOnlyField('phone', _phoneCtrl, Icons.phone_iphone_outlined,
                  ltr: true),
            ],
            const SizedBox(height: AppSpacing.md),
            label(en ? 'City/Country' : 'المدينة/الدولة'),
            AppTextFormField(
              key: const ValueKey('profile-location'),
              controller: _locationCtrl,
              autovalidateMode: autovalidate,
              textAlign: TextAlign.start,
              textInputAction: TextInputAction.done,
              maxLength: ProfileRules.locationMax,
              onChanged: (_) => _locationEdited = true,
              onFieldSubmitted: (_) => unawaited(_save(titles)),
              prefixIcon: const Icon(Icons.place_outlined),
              hintText: en ? 'Riyadh, Saudi Arabia' : 'الرياض، السعودية',
              validator: (v) => _errorText(
                ProfileRules.location(v),
                en: en,
                requiredEn: '',
                requiredAr: '',
                max: ProfileRules.locationMax,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: en ? 'Save changes' : 'حفظ التغييرات',
              loadingLabel: en ? 'Saving...' : 'جارٍ الحفظ...',
              isLoading: saving,
              icon: Icons.check_rounded,
              onPressed: () => unawaited(_save(titles)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(title: Text(en ? 'Profile' : 'الملف الشخصي')),
      body: body,
    );
  }
}
