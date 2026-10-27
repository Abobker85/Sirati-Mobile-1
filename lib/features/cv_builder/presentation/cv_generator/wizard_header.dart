import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Step titles in wizard order.
List<String> wizardStepTitles(AppLocalizations l10n) => [
      l10n.cvWizardStepPersonal,
      l10n.cvWizardStepSkills,
      l10n.cvWizardStepExperience,
      l10n.cvWizardStepEducation,
    ];

const wizardStepIcons = [
  Icons.person_rounded,
  Icons.psychology_rounded,
  Icons.work_rounded,
  Icons.school_rounded,
];

/// "Step X of N", progress bar, and the tappable step dots. Only completed
/// steps (and the current one) can be jumped to.
class WizardHeader extends StatelessWidget {
  const WizardHeader({
    super.key,
    required this.step,
    required this.english,
    required this.onStepTap,
  });

  final int step;
  final bool english;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final steps = wizardStepTitles(l10n);
    final progress = (step + 1) / steps.length;

    return Container(
      color: c.background,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                l10n.cvWizardStepOf(step + 1, steps.length),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  // primaryInk: primary is a fill colour and fails AA as text.
                  color: c.primaryInk,
                ),
              )),
              Expanded(
                  child: Text(
                steps[step],
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              )),
            ],
          ),
          const SizedBox(height: 12),
          WizardProgressBar(progress: progress),
          const SizedBox(height: 14),
          // One equal cell per step holds its dot, its halves of the
          // connectors and its label, so each label sits under its dot.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Connector(
                              visible: i > 0,
                              done: i <= step,
                            ),
                          ),
                          _StepDot(index: i, step: step, onTap: onStepTap),
                          Expanded(
                            child: _Connector(
                              visible: i < steps.length - 1,
                              done: i < step,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        steps[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: i <= step ? c.primaryInk : c.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Half of the line between two step dots; the first and last steps have
/// no outer half.
class _Connector extends StatelessWidget {
  const _Connector({required this.visible, required this.done});

  final bool visible;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;

    return Container(
      height: 2,
      color: !visible
          ? Colors.transparent
          : done
              ? c.primaryContainer
              : c.surfaceHigh,
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.step,
    required this.onTap,
  });

  final int index;
  final int step;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final done = index < step;
    final active = index == step;
    final canJump = index <= step;

    return PressScale(
      enabled: canJump,
      child: GestureDetector(
        onTap: canJump && !active ? () => onTap(index) : null,
        child: AnimatedContainer(
          duration: MotionSettings.reduce(context)
              ? Duration.zero
              : MotionDurations.medium,
          curve: MotionCurves.state,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: done
                ? c.primaryContainer
                : active
                    ? c.amberAccent
                    : c.surfaceHigh,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: done
                ? Icon(Icons.check_rounded, size: 16, color: c.onPrimary)
                : Icon(
                    wizardStepIcons[index],
                    size: 16,
                    color: active ? c.primaryDark : c.textHint,
                  ),
          ),
        ),
      ),
    );
  }
}

/// Thin progress fill that grows from the start edge (left in LTR, right in
/// RTL) and animates between steps.
class WizardProgressBar extends StatefulWidget {
  const WizardProgressBar({super.key, required this.progress});

  final double progress;

  @override
  State<WizardProgressBar> createState() => _WizardProgressBarState();
}

class _WizardProgressBarState extends State<WizardProgressBar> {
  /// Stable tween so rebuilds do not restart; begin tracks last settled value.
  late Tween<double> _tween =
      Tween<double>(begin: 0, end: widget.progress.clamp(0.0, 1.0));

  @override
  void didUpdateWidget(covariant WizardProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.progress.clamp(0.0, 1.0);
    final prev = oldWidget.progress.clamp(0.0, 1.0);
    if (next != prev) {
      _tween = Tween<double>(begin: prev, end: next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.progress.clamp(0.0, 1.0);
    final reduce = MotionSettings.reduce(context);

    Widget fill(double factor) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: factor,
          heightFactor: 1,
          child: ColoredBox(color: context.sirati.primary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: ColoredBox(
          color: context.sirati.border,
          child: reduce
              ? fill(target)
              : TweenAnimationBuilder<double>(
                  // Key forces a new controller when the target step changes.
                  key: ValueKey(target),
                  tween: _tween,
                  duration: MotionDurations.slow,
                  curve: MotionCurves.state,
                  builder: (context, value, _) => fill(value),
                ),
        ),
      ),
    );
  }
}
