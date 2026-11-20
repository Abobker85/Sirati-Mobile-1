import 'package:flutter/material.dart';
import 'package:sirati/features/jobs/domain/job_news_filters.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Label for a region key from [JobNewsFilters.regions].
String jobRegionLabel(AppLocalizations l, String region) => switch (region) {
      'central' => l.jobsRegionCentral,
      'eastern' => l.jobsRegionEastern,
      'western' => l.jobsRegionWestern,
      'northern' => l.jobsRegionNorthern,
      'southern' => l.jobsRegionSouthern,
      _ => l.jobsRegionAll,
    };

/// Source / work-mode presets: all, in my field, government, companies,
/// Tamheer & training, remote. One row, scrolls horizontally.
class PresetChips extends StatelessWidget {
  final bool english;
  final String selectedPreset;
  final ValueChanged<String> onSelected;

  const PresetChips({
    super.key,
    required this.english,
    required this.selectedPreset,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.sirati;
    final options = <(String, String, IconData, Color)>[
      (JobNewsFilters.all, l.jobsFilterAll, Icons.apps_rounded, c.primaryInk),
      ('matched', l.jobsPresetMatched, Icons.track_changes_rounded, c.red),
      ('gov', l.jobsPresetGov, Icons.account_balance_rounded, c.amber),
      ('enterprise', l.jobsPresetEnterprise, Icons.apartment_rounded, c.info),
      ('tamheer', l.jobsPresetTamheer, Icons.school_rounded, c.primaryInk),
      (
        JobNewsFilters.remote,
        l.jobsFilterRemote,
        Icons.laptop_mac_rounded,
        c.tertiary
      ),
    ];

    return _ChipRow(
      children: [
        for (final (key, label, icon, tint) in options)
          _FilterPill(
            label: label,
            icon: icon,
            iconColor: tint,
            selected: selectedPreset == key,
            onTap: () => onSelected(key),
          ),
      ],
    );
  }
}

/// Saudi regions; "all regions" first.
class RegionChips extends StatelessWidget {
  final String selectedRegion;
  final ValueChanged<String> onSelected;

  const RegionChips({
    super.key,
    required this.selectedRegion,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _ChipRow(
      children: [
        for (final region in JobNewsFilters.regions)
          _FilterPill(
            label: jobRegionLabel(l, region),
            icon: region == JobNewsFilters.all
                ? Icons.map_outlined
                : Icons.location_on_outlined,
            iconColor: context.sirati.textSecondary,
            selected: selectedRegion == region,
            onTap: () => onSelected(region),
          ),
      ],
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final child in children)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// A 48dp-tall pill. Selected = dark brand fill + check icon, so the state
/// never relies on colour alone.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);
    // brandSurface keeps white text at AA in both themes (primary does not).
    final fg = selected ? c.onBrandSurface : c.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        pressedScale: 0.96,
        child: Material(
          color: selected ? c.brandSurface : c.surface,
          animationDuration: reduce ? Duration.zero : MotionDurations.fast,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? c.brandSurface : c.border),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            splashFactory: reduce ? NoSplash.splashFactory : null,
            highlightColor: reduce ? c.surface.withValues(alpha: 0) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MotionMorph(
                      morphKey: selected,
                      pop: false,
                      child: Icon(
                        selected ? Icons.check_rounded : icon,
                        size: 18,
                        color: selected ? fg : iconColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JobSearchBar extends StatelessWidget {
  final bool english;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const JobSearchBar({
    super.key,
    required this.english,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);
    const searchIcon = Icon(Icons.search_rounded, size: 20);

    return Material(
      type: MaterialType.transparency,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          final clearButton = AnimatedSwitcher(
            duration: reduce ? Duration.zero : MotionDurations.fast,
            switchInCurve: MotionCurves.enter,
            switchOutCurve: MotionCurves.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.75, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: hasText
                ? IconButton(
                    key: const ValueKey('jobs-search-clear'),
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: c.textSecondary,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      splashFactory: reduce ? NoSplash.splashFactory : null,
                      highlightColor:
                          reduce ? c.surface.withValues(alpha: 0) : null,
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('jobs-search-empty')),
          );

          return TextField(
            controller: controller,
            onChanged: onChanged,
            textAlign: TextAlign.start,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).jobsSearchHint,
              // Keep the search affordance on the physical leading edge of the
              // field (left) in both locales — matches the current screenshots.
              prefixIcon: english ? searchIcon : clearButton,
              suffixIcon: english ? clearButton : searchIcon,
              filled: true,
              fillColor: c.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.primary, width: 1.4),
              ),
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              color: c.textPrimary,
            ),
          );
        },
      ),
    );
  }
}
