import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/features/dashboard/application/history_controllers.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/cv_analysis.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/theme/app_theme.dart';

class DashboardRecentActivity extends ConsumerWidget {
  const DashboardRecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cvs = ref.watch(generatedCvsHistoryProvider);
    final analyses = ref.watch(analysesHistoryProvider);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final entries =
        [
          for (final cv in cvs.value?.items ?? const <GeneratedCv>[])
            (
              date: cv.createdAt,
              title: cv.targetJobTitle,
              kind: l.homeHeroLatestCv,
              route: AppRoutes.cv(cv.id),
              icon: Icons.description_outlined,
            ),
          for (final analysis in analyses.value?.items ?? const <CvAnalysis>[])
            (
              date: analysis.createdAt,
              title: analysis.targetJobTitle,
              kind: l.atsInputTitle,
              route: AppRoutes.analysis(analysis.id),
              icon: Icons.analytics_outlined,
            ),
        ]..sort(
          (a, b) =>
              (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cvs.isLoading || analyses.isLoading)
          Text(l.savedCvsLoading, style: TextStyle(color: c.textSecondary)),
        if (cvs.hasError || analyses.hasError)
          TextButton(
            onPressed: () {
              ref.invalidate(generatedCvsHistoryProvider);
              ref.invalidate(analysesHistoryProvider);
            },
            child: Text(l.retry),
          ),
        if (!cvs.isLoading &&
            !analyses.isLoading &&
            !cvs.hasError &&
            !analyses.hasError &&
            entries.isEmpty)
          Text(l.homeActivityEmpty, style: TextStyle(color: c.textSecondary)),
        for (final entry in entries.take(3)) ...[
          Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              leading: Icon(entry.icon, color: c.primaryInk),
              title: Text(
                entry.title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                entry.date == null
                    ? entry.kind
                    : '${entry.kind} · ${MaterialLocalizations.of(context).formatCompactDate(entry.date!)}',
                style: TextStyle(color: c.textSecondary),
              ),
              onTap: () => unawaited(Navigator.pushNamed(context, entry.route)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
