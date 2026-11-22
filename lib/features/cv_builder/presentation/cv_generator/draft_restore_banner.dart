import 'package:flutter/material.dart';
import 'package:sirati/core/utils/locale_format.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// "Continue where you left off?" offer shown in create mode when a local
/// draft with real content exists: a borderless card at the top of the step.
class DraftRestoreBanner extends StatelessWidget {
  const DraftRestoreBanner({
    super.key,
    required this.english,
    required this.savedAt,
    required this.onStartFresh,
    required this.onRestore,
  });

  final bool english;
  final DateTime? savedAt;
  final VoidCallback onStartFresh;
  final VoidCallback onRestore;

  /// Key of the card.
  static const cardKey = ValueKey('draft-restore-card');

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final at = savedAt;
    final relative = at != null
        ? LocaleFormat.relativeSavedAt(at, l10n)
        : l10n.cvDraftAvailable;

    // A borderless card in the page's own card fill, at the top of the
    // step's content (the list's padding insets it). Its buttons use the
    // card-contents fill so "Start fresh" stays a visible grey capsule.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        key: cardKey,
        color: PageSurface.fillOf(context),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
        child: NestedFillScope(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: c.primaryInk),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cvDraftContinueTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            relative,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onStartFresh,
                        style: OutlinedButton.styleFrom(
                          minimumSize:
                              const Size.fromHeight(AppTouchTarget.min),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        child: Text(l10n.cvDraftStartFresh),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: onRestore,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          minimumSize:
                              const Size.fromHeight(AppTouchTarget.min),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        child: Text(l10n.cvDraftRestore),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
