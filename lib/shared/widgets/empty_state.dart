import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

/// Centered empty-state panel with optional primary action.
///
/// Use for History tabs, My CVs zero-state, Education empty tabs, etc.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final bool scrollable;
  final double topInsetFactor;
  final Color? iconBackground;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add_rounded,
    this.scrollable = true,
    this.topInsetFactor = 0.12,
    this.iconBackground,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Semantics(
      container: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: iconBackground ?? context.sirati.primaryLight,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon,
                  size: 32, color: iconColor ?? context.sirati.primaryInk),
            ),
            const SizedBox(height: AppSpacing.md + 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.of(context, AppTypography.titleLg),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTypography.of(
                  context,
                  AppTypography.bodyMd,
                  color: context.sirati.textSecondary,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: context.sirati.primary,
                  foregroundColor: context.sirati.onPrimary,
                  minimumSize: const Size(0, AppTouchTarget.min),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
                  textStyle: AppTypography.of(context, AppTypography.labelLg),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!scrollable) {
      return Center(child: panel);
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * topInsetFactor,
        ),
        panel,
        const SizedBox(height: 48),
      ],
    );
  }
}

/// Error / offline panel with retry — distinct from empty states.
///
/// If an [errorType] (or [exception]) is provided, the icon, background,
/// and default title auto-adapt to the error class:
/// * `network` → full-screen [OfflineView] (auto-retries; [onOpenSaved])
/// * `timeout` → timer_off
/// * `auth` → lock
/// * `notFound` → search_off
/// * `server` → cloud_off
/// * `validation` / `unknown` → error_outline
class AppErrorState extends StatelessWidget {
  final String message;
  final bool english;

  /// May return a future: [OfflineView] shows a checking state until it
  /// completes and treats a thrown error as "still offline".
  final FutureOr<void> Function()? onRetry;
  final String? title;
  final bool scrollable;
  final ApiErrorType? errorType;
  final ApiException? exception;

  /// Offline only: opens content saved on the device.
  final VoidCallback? onOpenSaved;

  const AppErrorState({
    super.key,
    required this.message,
    required this.english,
    this.onRetry,
    this.title,
    this.scrollable = true,
    this.errorType,
    this.exception,
    this.onOpenSaved,
  });

  @override
  Widget build(BuildContext context) {
    // Prefer explicit type / exception; fall back to unknown (not network)
    // so unwired call sites show a neutral error glyph instead of wifi.
    final type = errorType ?? exception?.type ?? ApiErrorType.unknown;
    if (type == ApiErrorType.network) {
      return OfflineView(onRetry: onRetry, onOpenSaved: onOpenSaved);
    }
    final icon = _iconFor(type);
    final l10n = AppLocalizations.of(context);
    final defaultTitle = _titleFor(type, l10n);

    return AppEmptyState(
      icon: icon,
      title: title ?? defaultTitle,
      subtitle: _clientSubtitleFor(type, l10n) ?? message,
      actionLabel: onRetry == null ? null : l10n.retry,
      onAction: onRetry == null
          ? null
          : () => unawaited(Future.sync(onRetry!).catchError((Object _) {})),
      actionIcon: Icons.refresh_rounded,
      iconBackground: context.sirati.errorLight,
      iconColor: context.sirati.error,
      scrollable: scrollable,
      topInsetFactor: 0.16,
    );
  }

  /// Connection and timeout failures are raised by the client itself, so their
  /// raw message is a fixed (Arabic) developer-facing string; show localized
  /// user copy instead. Server-provided messages for other types pass through.
  static String? _clientSubtitleFor(ApiErrorType type, AppLocalizations l10n) {
    switch (type) {
      case ApiErrorType.network:
        return l10n.sharedErrorNetworkSubtitle;
      case ApiErrorType.timeout:
        return l10n.sharedErrorTimeoutSubtitle;
      default:
        return null;
    }
  }

  static IconData _iconFor(ApiErrorType type) {
    switch (type) {
      case ApiErrorType.network:
        return Icons.wifi_off_rounded;
      case ApiErrorType.timeout:
        return Icons.timer_off_outlined;
      case ApiErrorType.auth:
        return Icons.lock_outline_rounded;
      case ApiErrorType.notFound:
        return Icons.search_off_rounded;
      case ApiErrorType.server:
        return Icons.cloud_off_rounded;
      case ApiErrorType.rateLimited:
        return Icons.hourglass_top_rounded;
      case ApiErrorType.validation:
      case ApiErrorType.unknown:
        return Icons.error_outline_rounded;
    }
  }

  static String _titleFor(ApiErrorType type, AppLocalizations l10n) {
    switch (type) {
      case ApiErrorType.network:
        return l10n.sharedErrorTitleNetwork;
      case ApiErrorType.timeout:
        return l10n.sharedErrorTitleTimeout;
      case ApiErrorType.auth:
        return l10n.sharedErrorTitleAuth;
      case ApiErrorType.notFound:
        return l10n.sharedErrorTitleNotFound;
      case ApiErrorType.server:
        return l10n.sharedErrorTitleServer;
      case ApiErrorType.rateLimited:
        return l10n.sharedErrorTitleRateLimited;
      case ApiErrorType.validation:
      case ApiErrorType.unknown:
        return l10n.sharedErrorTitleUnknown;
    }
  }
}
