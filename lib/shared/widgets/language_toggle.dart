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
  /// Overrides for toggles painted on a brand hero instead of a surface:
  /// [backgroundColor] fills the track, [foregroundColor] inks both labels and
  /// [side] edges the track and thumb. The thumb paints the (translucent)
  /// track fill once more over the track, so it reads darker and labels keep
  /// the hero's contrast wherever it sits. Pass a translucent
  /// [backgroundColor] or a visible [side], or the thumb cannot be seen.
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide side;

  const LanguageToggle({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.side = BorderSide.none,
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
    final colors = track == null && foregroundColor == null
        ? themed
        : AppSegmentedPalette(
            track: track ?? themed.track,
            thumb:
                track == null ? themed.thumb : Color.alphaBlend(track, track),
            selectedInk: foregroundColor ?? themed.selectedInk,
            unselectedInk: foregroundColor ?? themed.unselectedInk,
            trackBorder: side,
            thumbBorder: side,
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
