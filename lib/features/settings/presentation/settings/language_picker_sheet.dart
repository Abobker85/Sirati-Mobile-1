import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/core/l10n/remote_l10n_models.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Native name of the selected app language (picker subtitle).
String currentLanguageName() =>
    AppLocale.recordFor(AppLocale.languageCode.value)?.nativeName ??
    AppLocale.languageCode.value;

/// Bottom sheet listing every enabled language (cached list; `ar` and `en`
/// always present, also offline). Selecting one applies and persists it.
Future<void> showLanguagePicker(BuildContext context) async {
  final code = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
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
                style: AppTypography.of(context, AppTypography.titleSm),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final language in languages)
                    _LanguageOption(
                      language: language,
                      selected: language.code == selected,
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
    final colors = context.sirati;
    return ListTile(
      key: ValueKey('language-option-${language.code}'),
      selected: selected,
      title: Directionality(
        textDirection: language.direction,
        child: Text(
          language.nativeName,
          textAlign: TextAlign.start,
          style: AppTypography.of(
            context,
            AppTypography.bodyMd,
            color: colors.textPrimary,
          ),
        ),
      ),
      trailing:
          selected ? Icon(Icons.check_rounded, color: colors.primaryInk) : null,
      onTap: () => Navigator.of(context).pop(language.code),
    );
  }
}
