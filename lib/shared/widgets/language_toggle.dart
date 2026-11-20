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
  /// Optional overrides; without them the toggle uses the page-aware
  /// [AppSegmentedPalette.of].
  ///
  /// * [backgroundColor] fills the track. An opaque fill keeps the themed
  ///   thumb and its outline edge. A translucent fill (a toggle on a photo or
  ///   brand hero) gets a thumb of that fill laid once more over the track,
  ///   edged by [side].
  /// * [foregroundColor] inks both labels.
  /// * [side] edges the track, and the thumb when given.
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
    final translucent = track != null && track.a < 1;
    final colors = track == null && foregroundColor == null
        ? themed
        : AppSegmentedPalette(
            track: track ?? themed.track,
            thumb: translucent ? Color.alphaBlend(track, track) : themed.thumb,
            selectedInk: foregroundColor ?? themed.selectedInk,
            unselectedInk: foregroundColor ?? themed.unselectedInk,
            trackBorder: side,
            thumbBorder: side == BorderSide.none ? themed.thumbBorder : side,
            thumbShadow: translucent ? const [] : themed.thumbShadow,
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
