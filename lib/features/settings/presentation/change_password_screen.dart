import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/password_strength_meter.dart';
import 'package:sirati/shared/widgets/password_visibility_toggle.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _confirmKey = GlobalKey<FormFieldState<String>>();

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
    // One request at a time (keyboard Done + button).
    if (_loading) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submitted = true;
      _showBanner = false;
      _currentFieldError = null;
    });
    if (!_formKey.currentState!.validate()) {
      setState(() => _showBanner = true);
      unawaited(HapticFeedback.selectionClick());
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authApiServiceProvider).changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
            confirmation: _confirmCtrl.text,
          );
      if (!mounted) return;
      unawaited(HapticFeedback.lightImpact());
      AppSnackBar.success(context, l10n.settingsPasswordChanged);
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      final fieldErrors = e.errors['current_password'];
      if (fieldErrors != null && fieldErrors.isNotEmpty) {
        setState(() {
          _currentFieldError = l10n.settingsCurrentPasswordIncorrect;
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
        l10n.settingsPasswordChangeFailed,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    final auto = _submitted
        ? AutovalidateMode.onUserInteraction
        : AutovalidateMode.disabled;

    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(
        title: Text(l10n.changePassword),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          children: [
            // Always one slot: inserting a child would shift the fields'
            // positions and drop their state (and their error text).
            if (_showBanner)
              AppFormErrorBanner(
                message: l10n.authFixHighlightedFields,
                onDismiss: () => setState(() => _showBanner = false),
              )
            else
              const SizedBox.shrink(),
            _Label(l10n.settingsCurrentPasswordLabel),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _currentCtrl,
              autovalidateMode: auto,
              obscureText: _obscureCurrent,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: PasswordVisibilityToggle(
                obscured: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              validator: (v) {
                if (_currentFieldError != null) return _currentFieldError;
                if (v == null || v.isEmpty) {
                  return l10n.settingsCurrentPasswordRequired;
                }
                return null;
              },
              onChanged: (_) {
                if (_currentFieldError != null) {
                  setState(() => _currentFieldError = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _Label(l10n.authNewPasswordLabel),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _newCtrl,
              autovalidateMode: auto,
              obscureText: _obscureNew,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: PasswordVisibilityToggle(
                obscured: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              onChanged: (_) {
                setState(() {});
                // A stale "do not match" must clear when the new one changes.
                if (_submitted) _confirmKey.currentState?.validate();
              },
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.settingsNewPasswordRequired;
                }
                if (v.length < 8) {
                  return l10n.authPasswordTooShort(8);
                }
                if (v == _currentCtrl.text) {
                  return l10n.settingsNewPasswordSameAsCurrent;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            PasswordStrengthMeter(password: _newCtrl.text, english: en),
            const SizedBox(height: AppSpacing.md),
            _Label(l10n.settingsConfirmNewPasswordLabel),
            const SizedBox(height: 6),
            AppTextFormField(
              key: _confirmKey,
              controller: _confirmCtrl,
              autovalidateMode: auto,
              obscureText: _obscureConfirm,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => unawaited(_submit()),
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: PasswordVisibilityToggle(
                obscured: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.settingsConfirmNewPasswordRequired;
                }
                if (v != _newCtrl.text) {
                  return l10n.authPasswordsDoNotMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: l10n.settingsUpdatePassword,
              loadingLabel: l10n.settingsUpdatingPassword,
              isLoading: _loading,
              icon: Icons.check_rounded,
              onPressed: () => unawaited(_submit()),
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
      style: AppTextStyles.titleSm(context.sirati)
          .copyWith(color: context.sirati.textSecondary),
    );
  }
}
