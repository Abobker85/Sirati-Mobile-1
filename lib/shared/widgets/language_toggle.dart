import 'package:flutter/material.dart';

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
  /// [side] edges the track and thumb. The thumb is the track fill laid twice,
  /// so labels keep the hero's contrast wherever the thumb sits.
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderSide side;

  const LanguageToggle({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.side = BorderSide.none,
  });

  /// Short code naming [code]'s language. Each bundled catalog only carries
  /// the code of the OTHER language (what its old one-button toggle switched
  /// to), so the Arabic code comes from the English catalog and vice versa.
  static String shortCode(String code) => lookupAppLocalizations(
        Locale(code == 'en' ? 'ar' : 'en'),
      ).sharedLanguageToggleShort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final english = AppLocale.isEnglish(context);
    final themed = AppSegmentedPalette.of(context);
    final track = backgroundColor;
    final colors = track == null && foregroundColor == null
        ? themed
        : AppSegmentedPalette(
            track: track ?? themed.track,
            thumb: track == null ? themed.thumb : Color.alphaBlend(track, track),
            selectedInk: foregroundColor ?? themed.selectedInk,
            unselectedInk: foregroundColor ?? themed.unselectedInk,
            trackBorder: side,
            thumbBorder: side,
          );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AppSegmentedControl<String>(
        expand: false,
        colors: colors,
        value: english ? 'en' : 'ar',
        onChanged: AppLocale.setLanguage,
        segments: [
          AppSegment(
            value: 'ar',
            label: shortCode('ar'),
            semanticLabel: l10n.languageArabic,
          ),
          AppSegment(
            value: 'en',
            label: shortCode('en'),
            semanticLabel: l10n.languageEnglish,
          ),
        ],
      ),
    );
  }
}
