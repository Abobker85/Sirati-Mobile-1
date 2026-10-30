import 'package:flutter/material.dart';
import 'package:sirati/features/dashboard/presentation/home/home_pressable_card.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// One of Home's three service tiles (approved board): a 48dp icon circle and
/// a label on the card surface. A service that is not ready yet is muted, not
/// tappable, and carries a "soon" chip.
class HomeServiceTile extends StatelessWidget {
  const HomeServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.inkKey,
    this.comingSoon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Key? inkKey;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l = AppLocalizations.of(context);
    final ink = comingSoon ? c.textSecondary : c.primaryInk;

    return HomePressableCard(
      inkKey: inkKey,
      onTap: comingSoon ? null : onTap,
      color: comingSoon ? c.surfaceLow : null,
      semanticsLabel: comingSoon ? l.homeServiceSoonA11y(label) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: comingSoon ? c.surfaceContainer : c.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: ink, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: comingSoon ? c.textSecondary : c.textPrimary,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (comingSoon) ...[
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: c.borderStrong),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          l.homeSoon,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.schedule_rounded,
                          size: 12, color: c.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
