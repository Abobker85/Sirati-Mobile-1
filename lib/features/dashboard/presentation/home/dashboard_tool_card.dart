import 'package:flutter/material.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Compact tool entry. Height follows content, including at 2x text size.
class DashboardToolCard extends StatelessWidget {
  const DashboardToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String action;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c.primaryInk),
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
              const SizedBox(height: 12),
              Text(
                action,
                style: TextStyle(
                  color: c.primaryInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
