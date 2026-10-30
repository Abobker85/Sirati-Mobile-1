import 'package:flutter/material.dart';
import 'package:sirati/features/jobs/domain/job_news_feed.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Shown while the "in my field" preset is on: names the field the list is
/// based on, or, without a job title on the profile, asks for one (the API
/// returns nothing in that case rather than guessing from city alone).
class MatchedPresetNote extends StatelessWidget {
  final JobNewsProfileContext? profile;
  final VoidCallback onSetJobTitle;

  const MatchedPresetNote({
    super.key,
    required this.profile,
    required this.onSetJobTitle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final field = profile?.careerField ?? '';
    final hasField = (profile?.hasProfile ?? false) && field.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.borderStrong),
      ),
      child: Row(
        children: [
          Icon(Icons.track_changes_rounded, size: 20, color: c.primaryInk),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasField ? l.jobsMatchedBasedOn(field) : l.jobsMatchedNeedsTitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: c.primaryInk,
              ),
            ),
          ),
          if (!hasField) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSetJobTitle,
              style: TextButton.styleFrom(
                foregroundColor: c.primaryInk,
                minimumSize: const Size(48, 48),
              ),
              child: Text(l.jobsMatchedSetTitle),
            ),
          ],
        ],
      ),
    );
  }
}
