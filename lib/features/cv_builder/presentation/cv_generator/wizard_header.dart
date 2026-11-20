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

/// The calm step header: the step title with "Step X of N", a thin teal
/// progress line, and the tappable step dots. Only completed steps (and the
/// current one) can be jumped to.
///
/// It sits straight on the page (no band of its own). While the keyboard is
/// open the dot row folds away, so the fields and the footer keep the room
/// on a small phone; the title, count and progress stay.
class WizardHeader extends StatelessWidget {
  const WizardHeader({
    super.key,
    required this.step,
    required this.english,
    required this.onStepTap,
    this.keyboardOpen,
  });

  final int step;
  final bool english;
  final ValueChanged<int> onStepTap;

  /// Whether the keyboard is up. Inside a [Scaffold] body the keyboard inset
  /// is already taken out of [MediaQuery], so the screen passes it in; when
  /// null the header reads [MediaQuery] itself.
  final bool? keyboardOpen;

  /// Key of the dot row, present only while the keyboard is closed.
  static const dotsKey = ValueKey('wizard-step-dots');

  /// Key of the announced title + count line.
  static const statusKey = ValueKey('wizard-step-status');

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final l10n = AppLocalizations.of(context);
    final steps = wizardStepTitles(l10n);
    final progress = (step + 1) / steps.length;
    final count = l10n.cvWizardStepOf(step + 1, steps.length);
    final keyboardOpen =
        this.keyboardOpen ?? MediaQuery.viewInsetsOf(context).bottom > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        children: [
          // One announcement per step change: "Step 2 of 4, Skills".
          Semantics(
            key: statusKey,
            container: true,
            liveRegion: true,
            label: '$count, ${steps[step]}',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      steps[step],
                      // While typing the header is one line; the full title
                      // is in the announced label.
                      maxLines: keyboardOpen ? 1 : null,
                      overflow: keyboardOpen ? TextOverflow.ellipsis : null,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    count,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          WizardProgressBar(progress: progress),
          MotionExpandSlot(
            child: keyboardOpen
                ? const SizedBox(
                    key: ValueKey('wizard-step-dots-folded'),
                    width: double.infinity,
                  )
                : Padding(
                    key: dotsKey,
                    padding: const EdgeInsets.only(top: 14),
                    child: _StepDots(
                      steps: steps,
                      step: step,
                      onStepTap: onStepTap,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.steps,
    required this.step,
    required this.onStepTap,
  });

  final List<String> steps;
  final int step;
  final ValueChanged<int> onStepTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    // One equal cell per step holds its dot, its halves of the connectors
    // and its label, so each label sits under its dot.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Connector(visible: i > 0, done: i <= step),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: i <= step ? c.primaryInk : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Half of the line between two step dots; the first and last steps have
/// no outer half. Fills along the reading direction ([AlignmentDirectional.centerStart]).
class _Connector extends StatelessWidget {
  const _Connector({required this.visible, required this.done});

  final bool visible;
  final bool done;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(height: 2);

    final c = context.sirati;
    final reduce = MotionSettings.reduce(context);
    final target = done ? 1.0 : 0.0;

    Widget fill(double factor) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: factor.clamp(0.0, 1.0),
            heightFactor: 1,
            child: ColoredBox(color: c.primaryContainer),
          ),
        );

    return SizedBox(
      height: 2,
      child: ColoredBox(
        // Hairline track: decorative, the dots and labels carry the state.
        color: c.separator,
        child: reduce
            ? fill(target)
            : TweenAnimationBuilder<double>(
                tween: Tween<double>(end: target),
                duration: MotionDurations.medium,
                curve: MotionCurves.state,
                builder: (_, value, __) => fill(value),
              ),
      ),
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
                    ? c.primaryLight
                    : PageSurface.fillOf(context),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: MotionMorph(
              morphKey: done ? 'done-$index' : 'step-$index',
              child: done
                  ? Icon(Icons.check_rounded, size: 16, color: c.onPrimary)
                  : Icon(
                      wizardStepIcons[index],
                      size: 16,
                      color: active ? c.primaryInk : c.textSecondary,
                    ),
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
          // primaryInk: the teal that keeps 3:1 on the track in both themes.
          child: ColoredBox(color: context.sirati.primaryInk),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 4,
        width: double.infinity,
        child: ColoredBox(
          color: context.sirati.separator,
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
