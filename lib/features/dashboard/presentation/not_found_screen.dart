import 'package:flutter/material.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/compass_needle.dart';
import 'package:sirati/shared/widgets/empty_state.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: context.sirati.background,
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: AppEmptyState(
        icon: Icons.map_outlined,
        // Swings, then points down at the way home.
        illustration: const CompassNeedle(),
        actionIcon: Icons.home_rounded,
        title: l10n.dashboardNotFoundTitle,
        subtitle: l10n.dashboardNotFoundSubtitle,
        actionLabel: l10n.dashboardNotFoundGoHome,
        onAction: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.home,
            (route) => false,
          );
        },
      ),
    );
  }
}
