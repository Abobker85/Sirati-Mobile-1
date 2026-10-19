import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Read-only recommendations: the API has no selective apply or gain estimate.
class PrioritizedFixes extends StatelessWidget {
  const PrioritizedFixes({super.key, required this.weaknesses});
  final List<AnalysisWeakness> weaknesses;

  @override
  Widget build(BuildContext context) {
    if (weaknesses.isEmpty) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    int rank(String p) => switch (p) {
      'high' => 0,
      'medium' => 1,
      'low' => 2,
      _ => 3,
    };
    final ordered = weaknesses.indexed.toList()
      ..sort((a, b) {
        final priority = rank(a.$2.priority).compareTo(rank(b.$2.priority));
        return priority == 0 ? a.$1.compareTo(b.$1) : priority;
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.atsResultPrioritizedImprovements,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.atsResultImprovementsAvailability,
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
        for (final (_, weakness) in ordered) ...[
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (const {'high', 'medium', 'low'}.contains(weakness.priority))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: c.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      switch (weakness.priority) {
                        'high' => l.atsResultHighPriority,
                        'low' => l.atsResultLowPriority,
                        _ => l.atsResultMediumPriority,
                      },
                      style: TextStyle(
                        color: c.primaryInk,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (weakness.issue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    weakness.issue,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (weakness.fix.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(weakness.fix, style: TextStyle(color: c.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
