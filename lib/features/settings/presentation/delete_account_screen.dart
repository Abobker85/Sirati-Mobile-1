import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/auth_session.dart';
import 'package:sirati/shared/services/auth_api_service.dart';
import 'package:sirati/shared/services/auth_api_service_provider.dart';
import 'package:sirati/shared/services/local_session_cleanup.dart';
import 'package:sirati/shared/services/provider_reauth.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/password_visibility_toggle.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Providers this screen can re-authenticate with, in display order.
const _reauthProviders = ['google', 'apple'];

class DeleteAccountScreen extends ConsumerStatefulWidget {
  /// [user] defaults to the signed-in user from [SessionCache].
  const DeleteAccountScreen({super.key, this.user});

  final AuthUser? user;

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

  AuthUser? get _user => widget.user ?? SessionCache.instance.user.value;

  /// Google/Apple-only accounts have no password to type: they confirm by
  /// signing in with a linked provider again. Without one (unexpected) the
  /// password form stays, and "Forgot password" can set one.
  List<String> get _providers {
    final user = _user;
    if (user == null || user.hasPassword) return const [];
    return [
      for (final p in _reauthProviders)
        if (user.socialProviders.contains(p)) p,
    ];
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// The second, explicit "delete forever" confirmation.
  Future<bool> _confirm(AppLocalizations l10n) async {
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
    return second == true && mounted;
  }

  Future<void> _deleteWithPassword() async {
    // One flow at a time: keyboard Done + button must not stack two
    // confirmation dialogs or two delete requests.
    if (_loading || _confirming) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) {
      unawaited(HapticFeedback.selectionClick());
      return;
    }
    if (!await _confirm(l10n)) return;

    await _run(
      l10n,
      (auth) async {
        await auth.deleteAccount(password: _passwordCtrl.text);
        return true;
      },
      errorField: 'password',
      englishFieldError: l10n.settingsDeletePasswordIncorrect,
    );
  }

  Future<void> _deleteWithProvider(String provider) async {
    if (_loading || _confirming) return;
    final l10n = AppLocalizations.of(context);
    final label = _providerName(provider, l10n);
    if (!await _confirm(l10n)) return;

    await _run(
      l10n,
      (auth) async {
        final proof = await ref.read(providerReauthProvider).prove(provider);
        if (proof == null) return false;
        await auth.deleteAccount(
          provider: proof.provider,
          idToken: proof.idToken,
          nonce: proof.nonce,
        );
        return true;
      },
      errorField: 'id_token',
      englishFieldError: l10n.settingsDeleteProviderMismatch(label),
      notConfigured: l10n.authSocialSignInNotConfigured(label),
    );
  }

  /// Runs one delete attempt. [call] returns false when the user backed out
  /// (e.g. closed the provider's sign-in sheet).
  Future<void> _run(
    AppLocalizations l10n,
    Future<bool> Function(AuthApiService auth) call, {
    required String errorField,
    required String englishFieldError,
    String? notConfigured,
  }) async {
    // Arabic keeps the server's own wording for a field error.
    final en = AppLocale.isEnglish(context);
    setState(() => _loading = true);
    final auth = ref.read(authApiServiceProvider);
    try {
      if (!await call(auth) || !mounted) return;
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
      final field = e.errors[errorField];
      if (field != null && field.isNotEmpty) {
        AppSnackBar.error(context, en ? englishFieldError : field.first);
      } else {
        AppSnackBar.fromException(context, e);
      }
    } on ProviderNotConfigured {
      if (mounted) {
        AppSnackBar.error(context, notConfigured ?? l10n.settingsDeleteFailed);
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
    final providers = _providers;

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
            if (providers.isNotEmpty) ...[
              Text(
                l10n.settingsDeleteConfirmWithProvider,
                textAlign: TextAlign.start,
                style: AppTextStyles.titleSm(context.sirati)
                    .copyWith(color: context.sirati.textSecondary),
              ),
              for (final provider in providers) ...[
                const SizedBox(height: AppSpacing.md),
                SubmitButton(
                  label:
                      l10n.settingsDeleteWithProvider(
                          _providerName(provider, l10n)),
                  loadingLabel: l10n.settingsDeleting,
                  isLoading: _loading,
                  icon: Icons.delete_forever_rounded,
                  onPressed: () => unawaited(_deleteWithProvider(provider)),
                ),
              ],
            ] else ...[
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
                onFieldSubmitted: (_) => unawaited(_deleteWithPassword()),
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
                onPressed: () => unawaited(_deleteWithPassword()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Display name of a provider id, from the label catalog.
String _providerName(String provider, AppLocalizations l10n) =>
    switch (provider) {
      'google' => l10n.authSocialGoogle,
      'apple' => l10n.authSocialApple,
      _ => provider,
    };
