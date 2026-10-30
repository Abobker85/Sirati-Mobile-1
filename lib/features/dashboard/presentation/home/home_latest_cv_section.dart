import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/features/ats_scanner/presentation/cv_analysis_screen.dart';
import 'package:sirati/features/cv_builder/application/my_cvs_controller.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/generated_cv.dart';
import 'package:sirati/shared/services/cv_api_service_provider.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Select by real update timestamps; a missing score is never shown as zero.
final latestDashboardCvProvider =
    FutureProvider.autoDispose.family<GeneratedCv?, bool>((ref, english) async {
  final list = await ref.watch(myCvsProvider(english).future);
  final items = list.items.where((cv) => cv.id != null).toList()
    ..sort(
      (a, b) => (b.updatedAt ?? DateTime(1970)).compareTo(
        a.updatedAt ?? DateTime(1970),
      ),
    );
  if (items.isEmpty) return null;
  return ref.read(cvApiServiceProvider).getGeneratedCv(items.first.id!);
});

/// "My latest CV" on Home (approved board): the newest CV with Edit and ATS
/// check, or an empty state that starts the first one; then the honesty
/// line that closes the page.
class HomeLatestCvSection extends ConsumerWidget {
  const HomeLatestCvSection({super.key, required this.onViewAll});

  static const editKey = ValueKey('home-cv-edit');
  static const checkKey = ValueKey('home-cv-check');
  static const createKey = ValueKey('home-cv-create');
  static const viewAllKey = ValueKey('home-cv-view-all');

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final english = AppLocale.isEnglish(context);
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final state = ref.watch(latestDashboardCvProvider(english));
    final cv = state.value;

    final Widget body;
    if (state.isLoading && !state.hasValue) {
      body = _Frame(
        child:
            Text(l.savedCvsLoading, style: TextStyle(color: c.textSecondary)),
      );
    } else if (state.hasError && !state.hasValue) {
      body = _Frame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.homeHeroLatestCvError,
              style: TextStyle(color: c.textSecondary),
            ),
            TextButton(
              onPressed: () {
                ref.invalidate(myCvsProvider(english));
                ref.invalidate(latestDashboardCvProvider(english));
              },
              child: Text(l.retry),
            ),
          ],
        ),
      );
    } else if (cv == null) {
      body = const _EmptyCv();
    } else {
      body = _CvCard(cv: cv, english: english);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l.homeMyCvTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (cv != null)
              HomeViewAllButton(key: viewAllKey, onPressed: onViewAll),
          ],
        ),
        const SizedBox(height: 8),
        body,
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, size: 16, color: c.primaryInk),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l.homeHonesty,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "View all" with a chevron, as used by Home's section headers.
class HomeViewAllButton extends StatelessWidget {
  const HomeViewAllButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      iconAlignment: IconAlignment.end,
      icon: const Icon(Icons.chevron_right_rounded, size: 18),
      label: Text(AppLocalizations.of(context).homeJobsViewAll),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }
}

class _CvCard extends ConsumerWidget {
  const _CvCard({required this.cv, required this.english});

  final GeneratedCv cv;
  final bool english;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final rows = ref.watch(myCvsProvider(english)).value?.items;
    final savedRow = rows?.where((item) => item.id == cv.id).firstOrNull;
    final updatedAt = savedRow?.updatedAt;
    // The list endpoint sends a ready phrase ("Last updated: …") and no
    // timestamp; only a timestamp is formatted here.
    final edited = updatedAt != null
        ? l.homeMyCvEdited(
            AppFormat.relativeTime(updatedAt.toLocal(), l),
          )
        : savedRow?.updatedLabel.trim() ?? '';
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 44),
      shape: const StadiumBorder(),
      side: BorderSide(color: c.primaryInk),
      foregroundColor: c.primaryInk,
    ).copyWith(
      // Pressed: the button fills with the light brand tint.
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.pressed) ? c.primaryLight : null,
      ),
    );

    return _Frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: c.primaryInk,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.targetJobTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (edited.isNotEmpty)
                      Text(
                        edited,
                        style: TextStyle(color: c.textSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                key: HomeLatestCvSection.editKey,
                style: buttonStyle,
                onPressed: () async {
                  final updated = await Navigator.of(context).push<GeneratedCv>(
                    MaterialPageRoute(
                      builder: (_) => CvGeneratorScreen(initialCv: cv),
                    ),
                  );
                  // Saved changes show on Home at once.
                  if (updated != null) {
                    ref.invalidate(myCvsProvider(english));
                    ref.invalidate(latestDashboardCvProvider(english));
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l.homeMyCvEdit),
              ),
              OutlinedButton.icon(
                key: HomeLatestCvSection.checkKey,
                style: buttonStyle,
                onPressed: () => unawaited(
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CvAnalysisScreen(initialCvId: cv.id),
                    ),
                  ),
                ),
                icon: const Icon(Icons.document_scanner_outlined, size: 18),
                label: Text(l.homeMyCvCheck),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCv extends StatelessWidget {
  const _EmptyCv();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    return _Frame(
      child: Column(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  Icon(Icons.post_add_rounded, color: c.primaryInk, size: 30),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.homeMyCvEmptyTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.homeMyCvEmptyBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: HomeLatestCvSection.createKey,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              shape: const StadiumBorder(),
            ),
            onPressed: () =>
                unawaited(Navigator.pushNamed(context, AppRoutes.createCv)),
            icon: const Icon(Icons.note_add_outlined, size: 18),
            label: Text(l.homeHeroCreateYourCv),
          ),
        ],
      ),
    );
  }
}
