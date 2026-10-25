import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';

enum DashboardToolTone { ats, jobMatch, create, education }

/// Compact tool entry. Height follows content, including at 2x text size.
class DashboardToolCard extends StatelessWidget {
  const DashboardToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.action,
    this.tone = DashboardToolTone.ats,
  });
  final DashboardToolTone tone;
  final String title;
  final String subtitle;

  /// Call to action under the text; without one the card shows a chevron.
  final String? action;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final secondary = switch (tone) {
      DashboardToolTone.ats || DashboardToolTone.create => false,
      DashboardToolTone.jobMatch || DashboardToolTone.education => true,
    };
    final ink = secondary ? c.tertiary : c.primaryInk;
    final tint = secondary ? c.tertiaryLight : c.primaryLight;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ink),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: ink),
                  ),
                  const Spacer(),
                  if (action == null)
                    DirectionalIcon(
                      Icons.chevron_right_rounded,
                      color: ink,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: c.textSecondary, fontSize: 12),
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                Text(
                  action!,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
