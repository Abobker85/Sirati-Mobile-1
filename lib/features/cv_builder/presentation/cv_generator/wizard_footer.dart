import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/wizard_widgets.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/widgets/components/glass_surface.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/submit_button.dart';

/// Fixed Back / Next-or-Generate bar, outside the scroll view so it stays put
/// across step transitions and above the keyboard.
///
/// A glass bar along the bottom edge (no shadow: it sits on an edge) with a
/// teal Next capsule and a grey Back capsule. The capsules inside use the
/// card-contents fill ([NestedFillScope]) so Back keeps its grey on the
/// near-white glass.
class WizardFooter extends StatelessWidget {
  const WizardFooter({
    super.key,
    required this.english,
    required this.step,
    required this.stepCount,
    required this.isEditMode,
    required this.isLoading,
    required this.onBack,
    required this.onPrimary,
  });

  final bool english;
  final int step;
  final int stepCount;
  final bool isEditMode;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onPrimary;

  /// Key of the glass bar.
  static const glassKey = ValueKey('wizard-footer-glass');

  @override
  Widget build(BuildContext context) {
    final isLast = step == stepCount - 1;
    final reduce = MotionSettings.reduce(context);
    final showBack = step > 0;
    const gap = 12.0;

    return GlassSurface(
      key: glassKey,
      borderRadius: BorderRadius.zero,
      elevated: false,
      child: SafeArea(
        top: false,
        child: NestedFillScope(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullWidth = constraints.maxWidth;
                final backTargetWidth =
                    ((fullWidth - gap) / 3).clamp(0.0, double.infinity);

                Widget buildRow(double t) {
                  final clamped = t.clamp(0.0, 1.0);
                  final backSlotWidth = backTargetWidth * clamped;
                  final gapWidth = gap * clamped;
                  final primaryWidth = (fullWidth - backSlotWidth - gapWidth)
                      .clamp(0.0, fullWidth);

                  return Row(
                    children: [
                      if (clamped > 0.0)
                        ClipRect(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: clamped,
                            child: SizedBox(
                              width: backTargetWidth,
                              child: Opacity(
                                opacity: clamped,
                                child: IgnorePointer(
                                  ignoring: !showBack,
                                  child: PressScale(
                                    enabled: showBack,
                                    child: OutlinedButton.icon(
                                      onPressed: showBack ? onBack : null,
                                      icon: const DirectionalIcon(
                                        Icons.arrow_back_rounded,
                                        size: 18,
                                      ),
                                      // One line: a narrow cell at large
                                      // text trims the label rather than
                                      // growing the bar (the full word is
                                      // still read out).
                                      label: Text(
                                        AppLocalizations.of(context).back,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (gapWidth > 0.0) SizedBox(width: gapWidth),
                      SizedBox(
                        width: primaryWidth,
                        child: MotionStateSwitcher(
                          stateKey: isLast,
                          child: SubmitButton(
                            label: isLast
                                ? (isEditMode
                                    ? AppLocalizations.of(context)
                                        .cvWizardUpdate
                                    : AppLocalizations.of(context)
                                        .cvWizardGenerate)
                                : AppLocalizations.of(context).next,
                            loadingLabel:
                                AppLocalizations.of(context).cvWizardGenerating,
                            isLoading: isLoading,
                            icon: isLast
                                ? Icons.auto_awesome
                                : Icons.arrow_forward_rounded,
                            onPressed: onPrimary,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (reduce) {
                  return buildRow(showBack ? 1.0 : 0.0);
                }
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: showBack ? 1.0 : 0.0),
                  duration: MotionDurations.medium,
                  curve: MotionCurves.enter,
                  builder: (_, t, __) => buildRow(t),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
