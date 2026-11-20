import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/app_list_tile.dart';
import 'package:sirati/shared/widgets/components/app_sheet.dart';

/// Native name of the selected app language (picker subtitle).
String currentLanguageName() =>
    AppLocale.recordFor(AppLocale.languageCode.value)?.nativeName ??
    AppLocale.languageCode.value;

/// Bottom sheet listing every enabled language (cached list; `ar` and `en`
/// always present, also offline). Selecting one applies and persists it.
Future<void> showLanguagePicker(BuildContext context) async {
  final code = await showGlassBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const LanguagePickerSheet(),
  );
  if (code != null) unawaited(AppLocale.setLanguage(code));
}

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = AppLocale.languageCode.value;
    final languages = AppLocale.pickerLanguages;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.language,
                style: AppTypography.of(context, AppTypography.sectionTitle),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  // Opaque card: the rows do not depend on the sheet's glass.
                  AppListSection(
                    separatorIndent: AppListSection.textSeparatorIndent,
                    children: [
                      for (final language in languages)
                        _LanguageOption(
                          language: language,
                          selected: language.code == selected,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.language, required this.selected});

  final RemoteLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      key: ValueKey('language-option-${language.code}'),
      selected: selected,
      title: language.nativeName,
      // The name in its own script and direction; the row keeps the app's.
      titleDirection: language.direction,
      showChevron: false,
      trailing: selected
          ? Icon(Icons.check_rounded, color: context.sirati.primaryInk)
          : null,
      onTap: () => Navigator.of(context).pop(language.code),
    );
  }
}
