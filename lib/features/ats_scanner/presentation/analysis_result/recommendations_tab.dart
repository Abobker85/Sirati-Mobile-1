import 'package:flutter/material.dart';
import 'package:sirati/features/ats_scanner/presentation/analysis_result/prioritized_fixes.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Second tab: strengths, numbered quick wins, and the upgrade CTA.
class RecommendationsTab extends StatelessWidget {
  const RecommendationsTab({
    super.key,
    required this.strengths,
    required this.quickWins,
    required this.english,
    this.embedded = false,
    this.weaknesses = const [],
    this.hidden = AnalysisHiddenCounts.none,
  });

  final List<AnalysisWeakness> weaknesses;

  /// Items the server withheld from each list; shown as "N more".
  final AnalysisHiddenCounts hidden;
  final List<String> strengths;
  final List<String> quickWins;
  final bool english;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return ListView(
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (weaknesses.isNotEmpty) ...[
          PrioritizedFixes(weaknesses: weaknesses),
          const SizedBox(height: 24),
        ],
        if (hidden.weaknesses > 0) ...[
          HiddenItemsNote(count: hidden.weaknesses),
          const SizedBox(height: 24),
        ],
        _SectionHeader(
          icon: Icons.thumb_up_alt_rounded,
          iconColor: c.tealDark,
          iconBg: c.tealLight,
          label: AppLocalizations.of(context).jobMatchStrengths,
        ),
        const SizedBox(height: 12),
        _ItemList(
          items: strengths,
          hidden: hidden.strengths,
          emptyText: AppLocalizations.of(context).atsNoStrengths,
          markerBuilder: (context, _) => const _CheckMarker(),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          icon: Icons.bolt_rounded,
          iconColor: c.onWarningContainer,
          iconBg: c.amberLight,
          label: AppLocalizations.of(context).atsQuickWins,
        ),
        const SizedBox(height: 12),
        _ItemList(
          items: quickWins,
          hidden: hidden.quickWins,
          emptyText: AppLocalizations.of(context).atsNoQuickWins,
          markerBuilder: (context, i) => _NumberMarker(number: i + 1),
        ),
        const SizedBox(height: 28),
        _UpgradeCta(english: english),
      ],
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.items,
    this.hidden = 0,
    required this.emptyText,
    required this.markerBuilder,
  });

  final List<String> items;
  final int hidden;
  final String emptyText;
  final Widget Function(BuildContext context, int index) markerBuilder;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: items.isEmpty && hidden == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                emptyText,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        markerBuilder(context, i),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            items[i],
                            style: TextStyle(
                              fontSize: 13,
                              color: c.textPrimary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1) const Divider(height: 1),
                ],
                if (hidden > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: HiddenItemsNote(count: hidden),
                  ),
              ],
            ),
    );
  }
}

/// "+N more hidden" under a list the server trimmed (free tier).
class HiddenItemsNote extends StatelessWidget {
  const HiddenItemsNote({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Row(
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: c.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).atsHiddenMore(count),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckMarker extends StatelessWidget {
  const _CheckMarker();

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: c.tealLight, shape: BoxShape.circle),
      child: Icon(Icons.check_rounded, size: 13, color: c.tealDark),
    );
  }
}

class _NumberMarker extends StatelessWidget {
  const _NumberMarker({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      margin: const EdgeInsets.only(top: 1),
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.amberLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          // onWarningContainer, not amber: amber on amberLight is ~3:1 and
          // fails AA for this 11px numeral.
          color: c.onWarningContainer,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.sirati.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpgradeCta extends StatelessWidget {
  const _UpgradeCta({required this.english});

  final bool english;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.primaryMid),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: c.primaryInk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).atsUpgradeTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    // primaryDark on primaryLight is ~3.7:1 in dark mode.
                    color: c.primaryInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).atsUpgradeBody,
                  style: TextStyle(
                    fontSize: 12,
                    // primaryInk, not primary: primary is a fill colour and
                    // sits near 2.6:1 on primaryLight (fails AA for text).
                    color: c.primaryInk,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
