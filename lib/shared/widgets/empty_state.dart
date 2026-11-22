import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/offline_view.dart';

/// Centered empty / error state: a grey icon in a soft circle, a bold
/// title, a short grey explanation and, only where one is needed, one
/// action (a second, quieter one only when the screen has two equal ways
/// out, e.g. My CVs: create or upload).
///
/// Use for History tabs, My CVs zero-state, Education empty tabs, etc.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Null draws the button without an icon.
  final IconData? actionIcon;
  final bool scrollable;
  final double topInsetFactor;

  /// Overrides for the circle and glyph. Leave null for the calm grey
  /// default every state shares.
  final Color? iconBackground;
  final Color? iconColor;

  /// Drawn in the circle instead of [icon] (which then only names the state
  /// for code readers), e.g. the 404 compass. It brings its own motion.
  final Widget? illustration;

  /// Quieter second action, drawn as a text button under the first.
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData? secondaryActionIcon;

  /// Keys on the two buttons, for callers whose tests find them.
  final Key? actionKey;
  final Key? secondaryActionKey;

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
    this.illustration,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.secondaryActionIcon,
    this.actionKey,
    this.secondaryActionKey,
  });

  /// Width the explanation wraps at: about two lines of the usual copy.
  static const textMaxWidth = 300.0;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final panel = Semantics(
      container: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStateIcon(
              icon,
              background: iconBackground,
              color: iconColor,
              illustration: illustration,
            ),
            const SizedBox(height: AppSpacing.md + 2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: textMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    // The panel's own label already announces the title.
                    semanticsLabel: '',
                    textAlign: TextAlign.center,
                    style: AppTypography.of(
                      context,
                      AppTypography.titleLg,
                      color: c.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: AppTypography.of(
                        context,
                        AppTypography.bodyMd,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Builder(builder: (context) {
                final style = FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  minimumSize: const Size(0, AppTouchTarget.min),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: const StadiumBorder(),
                  textStyle: AppTypography.of(context, AppTypography.labelLg),
                );
                return actionIcon == null
                    ? FilledButton(
                        key: actionKey,
                        onPressed: onAction,
                        style: style,
                        child: Text(actionLabel!),
                      )
                    : FilledButton.icon(
                        key: actionKey,
                        onPressed: onAction,
                        icon: Icon(actionIcon, size: 18),
                        label: Text(actionLabel!),
                        style: style,
                      );
              }),
            ],
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                key: secondaryActionKey,
                onPressed: onSecondaryAction,
                icon: Icon(
                  secondaryActionIcon ?? Icons.arrow_upward_rounded,
                  size: 18,
                ),
                label: Text(secondaryActionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: c.primaryInk,
                  minimumSize: const Size(0, AppTouchTarget.min),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const StadiumBorder(),
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

/// The soft circle with a grey glyph that heads every empty, error and
/// offline state. Decorative: the state's title says what it means.
class AppStateIcon extends StatelessWidget {
  const AppStateIcon(
    this.icon, {
    super.key,
    this.background,
    this.color,
    this.illustration,
  });

  final IconData icon;

  /// Circle fill; defaults to the page's fill ([PageSurface.fillOf]), so the
  /// circle stands out on plain and grouped pages.
  final Color? background;

  /// Glyph colour; defaults to `textHint` (AA on `cardFill`).
  final Color? color;

  /// Drawn instead of the glyph.
  final Widget? illustration;

  static const size = 80.0;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? PageSurface.fillOf(context),
          shape: BoxShape.circle,
        ),
        child: Center(
          child:
              illustration ?? Icon(icon, size: 34, color: color ?? c.textHint),
        ),
      ),
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
