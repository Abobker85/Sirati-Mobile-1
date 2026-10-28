import 'package:flutter/material.dart';

import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class LanguageToggle extends StatelessWidget {
  /// Overrides for toggles painted on a brand hero instead of a surface.
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide side;

  const LanguageToggle({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.side = BorderSide.none,
  });

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final l10n = AppLocalizations.of(context);
    final tooltip = english ? l10n.switchToArabic : l10n.switchToEnglish;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? context.sirati.surfaceLow,
        shape: CircleBorder(side: side),
        child: InkWell(
          onTap: () {
            AppLocale.toggle(context);
          },
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: AppTouchTarget.min,
            height: AppTouchTarget.min,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    l10n.sharedLanguageToggleShort,
                    style: AppTypography.of(
                      context,
                      AppTypography.bodySm,
                      color: foregroundColor ?? context.sirati.primaryInk,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
