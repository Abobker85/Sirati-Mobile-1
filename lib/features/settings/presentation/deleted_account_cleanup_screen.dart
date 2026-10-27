import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Signed-out recovery after the server has already deleted the account.
class DeletedAccountCleanupScreen extends StatefulWidget {
  const DeletedAccountCleanupScreen({super.key, required this.retryCleanup});

  final Future<void> Function() retryCleanup;

  @override
  State<DeletedAccountCleanupScreen> createState() =>
      _DeletedAccountCleanupScreenState();
}

class _DeletedAccountCleanupScreenState
    extends State<DeletedAccountCleanupScreen> {
  bool _loading = false;

  Future<void> _retry() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.retryCleanup();
      if (!mounted) return;
      unawaited(
          Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      ));
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        AppLocalizations.of(context).settingsCleanupFailed,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.sirati.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: context.sirati.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.settingsCleanupMessage,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm(context.sirati),
                ),
                const SizedBox(height: AppSpacing.lg),
                SubmitButton(
                  label: l10n.settingsCleanupRetry,
                  loadingLabel: l10n.settingsCleanupClearing,
                  isLoading: _loading,
                  onPressed: () => unawaited(_retry()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
