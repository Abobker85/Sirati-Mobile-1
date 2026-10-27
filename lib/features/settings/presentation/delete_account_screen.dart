import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/password_visibility_toggle.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _submitted = false;
  bool _confirming = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    // One flow at a time: keyboard Done + button must not stack two
    // confirmation dialogs or two delete requests.
    if (_loading || _confirming) return;
    // Arabic keeps the server's own wording for a wrong password.
    final en = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      unawaited(HapticFeedback.selectionClick());
      return;
    }

    _confirming = true;
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDeleteConfirmTitle),
        content: Text(l10n.settingsDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.sirati.error),
            child: Text(l10n.settingsDeleteForever),
          ),
        ],
      ),
    );
    _confirming = false;
    if (second != true || !mounted) return;

    setState(() => _loading = true);
    final auth = ref.read(authApiServiceProvider);
    try {
      await auth.deleteAccount(password: _passwordCtrl.text);
      if (!mounted) return;
      AppSnackBar.success(
        context,
        l10n.settingsAccountDeleted,
      );
      unawaited(
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      ));
    } on LocalSessionCleanupException {
      if (!mounted) return;
      unawaited(
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
        arguments: PendingLocalSessionCleanup(
          retry: auth.retryLocalSessionCleanup,
        ),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      final pwd = e.errors['password'];
      if (pwd != null && pwd.isNotEmpty) {
        AppSnackBar.error(
          context,
          en ? l10n.settingsDeletePasswordIncorrect : pwd.first,
        );
      } else {
        AppSnackBar.fromException(context, e);
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(
          context,
          l10n.settingsDeleteFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(
        title: Text(l10n.deleteAccount),
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
                color: context.sirati.errorLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: context.sirati.error.withValues(alpha: .25)),
              ),
              child: Text(
                l10n.settingsDeleteWarning,
                textAlign: TextAlign.start,
                style: AppTextStyles.bodySm(context.sirati).copyWith(
                  // Gated pair: onErrorContainer on errorLight.
                  color: context.sirati.onErrorContainer,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.settingsDeleteConfirmWithPassword,
              textAlign: TextAlign.start,
              style: AppTextStyles.titleSm(context.sirati)
                  .copyWith(color: context.sirati.textSecondary),
            ),
            const SizedBox(height: 6),
            AppTextFormField(
              controller: _passwordCtrl,
              autovalidateMode: _submitted
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => unawaited(_delete()),
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: PasswordVisibilityToggle(
                obscured: _obscure,
                onToggle: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) => (v == null || v.isEmpty)
                  ? l10n.settingsDeletePasswordRequired
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            SubmitButton(
              label: l10n.settingsDeleteMyAccount,
              loadingLabel: l10n.settingsDeleting,
              isLoading: _loading,
              icon: Icons.delete_forever_rounded,
              onPressed: () => unawaited(_delete()),
            ),
          ],
        ),
      ),
    );
  }
}
