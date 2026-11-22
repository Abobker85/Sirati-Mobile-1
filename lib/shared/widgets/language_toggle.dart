import 'package:flutter/material.dart';

import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/widgets/app_segmented_control.dart';

/// Arabic / English switch, built on [AppSegmentedControl].
///
/// The two segments keep a fixed physical order (Arabic, then English): the
/// whole app mirrors when the language changes, and a fixed order lets the
/// thumb slide to the tapped side instead of jumping across with the mirror.
class LanguageToggle extends StatelessWidget {
  /// Track fill override (the sign-in screens pass the page's control
  /// fill). The thumb, its outline edge and the inks stay themed, so the
  /// fill should be one of the page fills the palette is checked against.
  /// Null uses the page-aware [AppSegmentedPalette.of].
  final Color? backgroundColor;

  const LanguageToggle({
    super.key,
    this.backgroundColor,
  });

  /// Short code naming [code]'s language, read through the app's own
  /// localization delegates (so published remote overrides apply).
  ///
  /// Each catalog carries only the code of the OTHER language (what the old
  /// one-button toggle switched to), so the Arabic code is read from the
  /// English catalog and vice versa, by loading that catalog for [context]'s
  /// subtree with [Localizations.override].
  static Widget withShortCode(
    BuildContext context,
    String code,
    Widget Function(BuildContext context, String shortCode) builder,
  ) {
    return Localizations.override(
      context: context,
      locale: Locale(code == 'en' ? 'ar' : 'en'),
      child: Builder(
        builder: (inner) => builder(
          inner,
          AppLocalizations.of(inner).sharedLanguageToggleShort,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Only Arabic or English proper is selected. A remote-only language
    // (whatever its fallback) selects neither, so either segment switches.
    final current = languageCodeOfLocale(
      Localizations.localeOf(context),
      AppLocale.availableCodes,
    );
    final selected = current == 'ar' || current == 'en' ? current : null;
    final themed = AppSegmentedPalette.of(context);
    final track = backgroundColor;
    final colors = track == null
        ? themed
        : AppSegmentedPalette(
            track: track,
            thumb: themed.thumb,
            selectedInk: themed.selectedInk,
            unselectedInk: themed.unselectedInk,
            thumbBorder: themed.thumbBorder,
            thumbShadow: themed.thumbShadow,
          );

    return withShortCode(
      context,
      'ar',
      (context, arCode) => withShortCode(
        context,
        'en',
        (context, enCode) => Directionality(
          textDirection: TextDirection.ltr,
          child: AppSegmentedControl<String>(
            expand: false,
            colors: colors,
            value: selected,
            onChanged: AppLocale.setLanguage,
            segments: [
              AppSegment(
                value: 'ar',
                label: arCode,
                semanticLabel: l10n.languageArabic,
              ),
              AppSegment(
                value: 'en',
                label: enCode,
                semanticLabel: l10n.languageEnglish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
