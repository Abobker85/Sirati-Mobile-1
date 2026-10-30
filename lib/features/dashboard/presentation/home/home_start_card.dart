import 'package:flutter/material.dart';
import 'package:sirati/features/dashboard/presentation/home/home_pressable_card.dart';
import 'package:sirati/shared/theme/app_theme.dart';

enum HomeStartTone { create, ats }

/// One of Home's two start cards (approved board): an 80dp drawing on the
/// card surface, then a coloured band with the action — brand green to create
/// a CV, deep navy to check one with ATS. The whole card is one target.
class HomeStartCard extends StatelessWidget {
  const HomeStartCard({
    super.key,
    required this.tone,
    required this.title,
    required this.body,
    required this.onTap,
    this.inkKey,
  });

  static const illustrationHeight = 80.0;

  final HomeStartTone tone;
  final String title;
  final String body;
  final VoidCallback onTap;
  final Key? inkKey;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final band = tone == HomeStartTone.create ? c.brandSurface : c.inkSurface;
    final ink = c.onBrandSurface;

    return HomePressableCard(
      inkKey: inkKey,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: illustrationHeight,
            child: _StartIllustration(tone: tone),
          ),
          Container(
            color: band,
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 10, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tone == HomeStartTone.create
                        ? Icons.note_add_outlined
                        : Icons.document_scanner_outlined,
                    color: ink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: TextStyle(
                          color: ink.withValues(alpha: .92),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The start card's drawing: a CV page with a check (create) or a page in a
/// scan frame with sparkles (ATS), between short guide lines.
class _StartIllustration extends StatelessWidget {
  const _StartIllustration({required this.tone});

  final HomeStartTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final create = tone == HomeStartTone.create;
    Widget guide() => Container(
          width: 34,
          height: 2,
          decoration: BoxDecoration(
            color: c.borderStrong,
            borderRadius: BorderRadius.circular(1),
          ),
        );
    Widget sparkle() => Icon(Icons.auto_awesome, size: 16, color: c.primaryInk);

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          create ? guide() : sparkle(),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 56,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.primaryInk, width: 1.6),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  create
                      ? Icons.check_box_rounded
                      : Icons.face_retouching_natural,
                  size: 18,
                  color: c.primaryInk,
                ),
                const SizedBox(height: 4),
                for (final w in const [24.0, 18.0])
                  Container(
                    width: w,
                    height: 2.5,
                    margin: const EdgeInsets.only(top: 3),
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          create ? guide() : sparkle(),
        ],
      ),
    );
  }
}
