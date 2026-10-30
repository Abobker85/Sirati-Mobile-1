import 'package:flutter/material.dart';

import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

/// Recoverable UI for uncaught Flutter errors (SIRATI-16).
///
/// Lives in `core/` so it must not import `shared/` or `features/`.
const _crashBackground =
    Color(0xFFF4F7F6); // ignore: hardcoded_color -- no_theme
const _crashAccent = Color(0xFFD8403A); // ignore: hardcoded_color -- no_theme

/// Server labels when the app's localizations are up; the bundled copy of
/// the same labels when the crash happened before they loaded.
AppLocalizations _labels(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations) ??
    lookupAppLocalizations(Locale(AppLocale.baseLanguage));

class AppCrashView extends StatelessWidget {
  const AppCrashView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = _labels(context);
    return Directionality(
      textDirection: AppLocale.currentDirection,
      child: Material(
        // Shown when the app has crashed, possibly before any theme exists;
        // core may not import the shared palette.
        color: _crashBackground,
        child: SafeArea(
          child: _CrashBody(
            title: l10n.somethingWentWrong,
            message: l10n.crashMessage,
            retryLabel: l10n.retry,
          ),
        ),
      ),
    );
  }
}

/// In-app recoverable panel (has a real [Navigator]).
class AppRecoverableError extends StatelessWidget {
  const AppRecoverableError({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = _labels(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _CrashBody(
        title: l10n.somethingWentWrong,
        message: l10n.crashMessage,
        retryLabel: l10n.retry,
        onRetry: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        },
      ),
    );
  }
}

class _CrashBody extends StatelessWidget {
  const _CrashBody({
    required this.title,
    required this.message,
    required this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: _crashAccent,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
