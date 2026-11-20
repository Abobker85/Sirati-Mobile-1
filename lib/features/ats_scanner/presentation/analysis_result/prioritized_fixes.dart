import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

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
        for (final (order, (_, weakness)) in ordered.indexed) ...[
          const SizedBox(height: 12),
          MotionReveal(
            order: order,
            child: _FixCard(weakness: weakness),
          ),
        ],
      ],
    );
  }
}

class _FixCard extends StatefulWidget {
  const _FixCard({required this.weakness});

  final AnalysisWeakness weakness;

  @override
  State<_FixCard> createState() => _FixCardState();
}

class _FixCardState extends State<_FixCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final weakness = widget.weakness;
    final hasFix = weakness.fix.isNotEmpty;
    final hasBadge = const {'high', 'medium', 'low'}.contains(weakness.priority);
    final reduce = MotionSettings.reduce(context);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasBadge || hasFix)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: hasBadge
                      ? Container(
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
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              if (hasFix) ...[
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: reduce ? Duration.zero : MotionDurations.fast,
                  curve: MotionCurves.state,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        if (weakness.issue.isNotEmpty) ...[
          if (hasBadge || hasFix) const SizedBox(height: 8),
          Text(
            weakness.issue,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (hasFix)
          MotionExpandSlot(
            alignment: AlignmentDirectional.topStart,
            child: _expanded
                ? Padding(
                    key: const ValueKey('fix-expanded'),
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      weakness.fix,
                      style: TextStyle(color: c.textSecondary),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('fix-collapsed')),
          ),
      ],
    );

    if (!hasFix) {
      return AppCard(padding: const EdgeInsets.all(16), child: cardContent);
    }

    return PressScale(
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashFactory: reduce ? NoSplash.splashFactory : null,
          highlightColor: reduce ? c.surface.withValues(alpha: 0) : null,
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: cardContent,
          ),
        ),
      ),
    );
  }
}
