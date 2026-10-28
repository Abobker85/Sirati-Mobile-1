import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/settings/application/settings_controllers.dart';
import 'package:sirati/features/settings/domain/profile_update.dart';
import 'package:sirati/features/settings/presentation/avatar_crop_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/job_titles_provider.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/empty_state.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/job_title_picker_field.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/profile_photo.dart';
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

  static const photoKey = ValueKey('profile-photo-button');

  bool _photoBusy = false;

  /// Gallery, camera or remove; then crop and upload (Salem review, issue 5).
  Future<void> _changePhoto({required bool hasPhoto}) async {
    if (_photoBusy) return;
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('profile-photo-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.settingsPhotoGallery),
              onTap: () => Navigator.of(context).pop('gallery'),
            ),
            ListTile(
              key: const ValueKey('profile-photo-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.settingsPhotoCamera),
              onTap: () => Navigator.of(context).pop('camera'),
            ),
            if (hasPhoto)
              ListTile(
                key: const ValueKey('profile-photo-remove'),
                leading: Icon(Icons.delete_outline_rounded,
                    color: context.sirati.error),
                title: Text(
                  l10n.settingsPhotoRemove,
                  style: TextStyle(color: context.sirati.error),
                ),
                onTap: () => Navigator.of(context).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    final auth = ref.read(authApiServiceProvider);
    try {
      if (choice == 'remove') {
        setState(() => _photoBusy = true);
        await auth.deleteAvatar();
      } else {
        final bytes = await ref.read(profilePhotoPickerProvider)(
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (bytes == null || !mounted) return;
        final cropped = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(
            builder: (_) => AvatarCropScreen(bytes: bytes),
          ),
        );
        if (cropped == null || !mounted) return;
        setState(() => _photoBusy = true);
        await auth.uploadAvatar(cropped);
      }
      ref.invalidate(settingsUserProvider);
      if (mounted) {
        AppSnackBar.success(
          context,
          choice == 'remove'
              ? l10n.settingsPhotoRemoved
              : l10n.settingsPhotoUpdated,
        );
      }
    } on ApiException catch (error) {
      if (mounted) AppSnackBar.fromException(context, error);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          l10n.settingsPhotoUpdateFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Widget _photo(AuthUser? user) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<AuthUser?>(
      valueListenable: SessionCache.instance.user,
      builder: (context, cached, _) {
        final url = cached?.avatarUrl ?? user?.avatarUrl;
        final hasPhoto = url != null && url.isNotEmpty;
        return Column(
          children: [
            Semantics(
              button: true,
              label: l10n.settingsPhotoChange,
              child: InkResponse(
                key: photoKey,
                onTap: () => unawaited(_changePhoto(hasPhoto: hasPhoto)),
                radius: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfilePhoto(url: url, name: _nameCtrl.text, size: 96),
                    if (_photoBusy)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.background, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.photo_camera_rounded,
                              size: 16, color: c.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.settingsPhotoHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm(c).copyWith(color: c.textSecondary),
            ),
          ],
        );
      },
    );
  }

  JobTitle? _selected(List<JobTitle> titles) {
    for (final t in titles) {
      if (t.id == _selectedId) return t;
    }
    return null;
  }

  Future<void> _save(List<JobTitle> titles) async {
    if (ref.read(profileSaveProvider)) return;
    final l10n = AppLocalizations.of(context);
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

    final outcome =
        await ref.read(profileSaveProvider.notifier).save(ProfileUpdate(
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
          l10n.settingsProfileUpdated,
        );
        Navigator.of(context).pop();
      case ProfileRejected(:final error):
        AppSnackBar.fromException(context, error);
      case ProfileSaveFailed():
        AppSnackBar.error(
          context,
          l10n.settingsProfileUpdateFailed,
        );
      case ProfileSaveIgnored():
        break;
    }
  }

  String? _errorText(
    ProfileFieldError? error, {
    required String requiredText,
    required int max,
  }) =>
      switch (error) {
        null => null,
        ProfileFieldError.required => requiredText,
        ProfileFieldError.tooLong =>
          AppLocalizations.of(context).authFieldTooLong(max),
      };

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
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
            : l10n.settingsProfileLoadFailed,
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
            _photo(user),
            const SizedBox(height: AppSpacing.lg),
            label(l10n.settingsProfileFullNameLabel),
            AppTextFormField(
              controller: _nameCtrl,
              showSuccessWhenValid: true,
              successMessage: l10n.authLooksGood,
              autovalidateMode: autovalidate,
              autofillHints: const [AutofillHints.name],
              textAlign: TextAlign.start,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _nameEdited = true,
              onFieldSubmitted: (_) => unawaited(_save(titles)),
              prefixIcon: const Icon(Icons.person_outline_rounded),
              hintText: l10n.settingsProfileNameHint,
              validator: (v) => _errorText(
                ProfileRules.name(v),
                requiredText: l10n.settingsProfileNameRequired,
                max: ProfileRules.nameMax,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            label(l10n.settingsProfileJobTitleLabel),
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
              onManualEntry: (text) => setState(() => _otherCtrl.text = text),
            ),
            if (titlesAsync.hasError && !titlesAsync.hasValue) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsProfileJobTitlesLoadFailed,
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
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ],
            if (isOther) ...[
              const SizedBox(height: AppSpacing.md),
              label(l10n.authJobTitleOtherLabel),
              AppTextFormField(
                controller: _otherCtrl,
                showSuccessWhenValid: true,
                successMessage: l10n.authLooksGood,
                autovalidateMode: autovalidate,
                textAlign: TextAlign.start,
                maxLength: ProfileRules.jobTitleOtherMax,
                onChanged: (_) => _jobTitleEdited = true,
                hintText: l10n.authJobTitleOtherHint,
                prefixIcon: const Icon(Icons.edit_outlined),
                validator: (v) => _errorText(
                  ProfileRules.jobTitleOther(v, isOther: isOther),
                  requiredText: l10n.authJobTitleOtherRequired,
                  max: ProfileRules.jobTitleOtherMax,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            label(l10n.emailLabel),
            readOnlyField(
              'email',
              _emailCtrl,
              Icons.mail_outline_rounded,
              ltr: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.settingsProfileEmailReadOnly,
              textAlign: TextAlign.start,
              style: AppTextStyles.bodySm(context.sirati)
                  .copyWith(color: context.sirati.textHint),
            ),
            if ((user?.phone ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              label(l10n.settingsProfilePhoneLabel),
              readOnlyField('phone', _phoneCtrl, Icons.phone_iphone_outlined,
                  ltr: true),
            ],
            const SizedBox(height: AppSpacing.md),
            label(l10n.authLocationLabel),
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
              hintText: l10n.authLocationHint,
              validator: (v) => _errorText(
                ProfileRules.location(v),
                requiredText: '',
                max: ProfileRules.locationMax,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: l10n.settingsProfileSaveChanges,
              loadingLabel: l10n.authSaving,
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
      appBar: AppBar(title: Text(l10n.settingsProfileTitle)),
      body: body,
    );
  }
}
