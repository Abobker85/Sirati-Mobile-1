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
    // brandSurface keeps white text at AA in both themes (primary does not).
    final fg = selected ? c.onBrandSurface : c.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        pressedScale: 0.96,
        child: Material(
          color: selected ? c.brandSurface : c.surface,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? c.brandSurface : c.border),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? Icons.check_rounded : icon,
                      size: 18,
                      color: selected ? fg : iconColor,
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
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.start,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).jobsSearchHint,
          // Keep the search affordance on the physical leading edge of the field
          // (left) in both locales — matches the current product screenshots.
          prefixIcon:
              english ? const Icon(Icons.search_rounded, size: 20) : null,
          suffixIcon:
              english ? null : const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: context.sirati.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.sirati.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.sirati.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.sirati.primary, width: 1.4),
          ),
        ),
        style: TextStyle(
            fontSize: 14, height: 1.3, color: context.sirati.textPrimary),
      ),
    );
  }
}
