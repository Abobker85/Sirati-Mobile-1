import 'package:flutter/material.dart';

import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/app_list_section.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/lively_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Direction-aware list row.
///
/// Layout (logical order, mirrors with ambient [Directionality]):
/// leading → title/subtitle → trailing (default chevron)
///
/// On its own it draws a bordered rounded card. Inside an [AppListSection]
/// it is a flat row of the section's card: no border or fill of its own, a
/// smaller icon box, and a pressed fill instead of the press scale (a row
/// shrinking inside a shared card would open gaps).
class AppListTile extends StatelessWidget {
  final Widget? leading;
  final IconData? leadingIcon;
  final Color? leadingBackground;
  final Color? leadingIconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? titleColor;

  /// Direction of the title text alone, e.g. a language's own name in a
  /// picker. The row layout keeps the ambient direction.
  final TextDirection? titleDirection;

  /// Announced as selected (e.g. the current choice in a picker).
  final bool selected;

  const AppListTile({
    super.key,
    this.leading,
    this.leadingIcon,
    this.leadingBackground,
    this.leadingIconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showChevron = true,
    this.onTap,
    this.padding,
    this.titleColor,
    this.titleDirection,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final grouped = AppListSection.contains(context);
    final resolvedLeading = leading ??
        (leadingIcon == null
            ? null
            : AppListIcon(
                leadingIcon!,
                background: leadingBackground,
                color: leadingIconColor,
              ));

    final row = Row(
      children: [
        if (resolvedLeading != null) ...[
          ExcludeSemantics(child: resolvedLeading),
          const SizedBox(width: AppListTileMetrics.gap),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                textAlign: TextAlign.start,
                textDirection: titleDirection,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (grouped
                        ? AppTypography.of(context, AppTypography.bodyXl)
                        : AppTextStyles.titleMd(c))
                    .copyWith(color: titleColor ?? c.textPrimary),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                SizedBox(height: grouped ? 2 : 5),
                Text(
                  subtitle!,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: grouped
                      ? AppTypography.of(context, AppTypography.caption,
                          color: c.textSecondary)
                      : AppTextStyles.bodySm(c),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ] else if (showChevron) ...[
          const SizedBox(width: 8),
          // Decorative; whole row is the control when [onTap] is set.
          ExcludeSemantics(
            child: DirectionalIcon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: c.textHint,
            ),
          ),
        ],
      ],
    );

    final content = grouped
        ? Container(
            constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
            padding: padding ??
                const EdgeInsetsDirectional.symmetric(
                  horizontal: AppListSection.rowPadding,
                  vertical: 11,
                ),
            child: row,
          )
        : Container(
            constraints: const BoxConstraints(minHeight: AppTouchTarget.min),
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: row,
          );

    if (onTap == null) {
      return MergeSemantics(
        child: Semantics(selected: selected ? true : null, child: content),
      );
    }

    // One merged node: the button role + the InkWell tap action + the
    // title/subtitle label.
    final control = MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected ? true : null,
        child: grouped
            ? InkWell(
                onTap: onTap,
                splashFactory: NoSplash.splashFactory,
                // The overlay AppContrast checks every ink against.
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.pressed)
                      ? c.pressed(c.groupedCard)
                      : null,
                ),
                child: content,
              )
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: content,
              ),
      ),
    );

    if (grouped) return control;
    return PressScale(
      child: Material(type: MaterialType.transparency, child: control),
    );
  }
}

/// Rounded icon box at the start of a list row. Smaller inside an
/// [AppListSection]; also usable as a `SwitchListTile.secondary` there so
/// switch rows line up with [AppListTile] rows.
class AppListIcon extends StatelessWidget {
  const AppListIcon(this.icon, {super.key, this.background, this.color});

  final IconData icon;

  /// Box fill; defaults to `primaryLight`.
  final Color? background;

  /// Glyph colour; defaults to `primaryInk`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final grouped = AppListSection.contains(context);
    final size = grouped
        ? AppListTileMetrics.groupedIcon
        : AppListTileMetrics.standaloneIcon;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? context.sirati.primaryLight,
        borderRadius: BorderRadius.circular(grouped ? 9 : 12),
      ),
      child: LivelyIcon(
        icon,
        color: color ?? context.sirati.primaryInk,
        size: 18,
      ),
    );
  }
}
