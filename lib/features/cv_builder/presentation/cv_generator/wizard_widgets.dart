import 'package:flutter/material.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator/cv_form_controllers.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Everything a wizard step needs from the screen, bundled so each step's
/// constructor stays small and steps never reach into screen state.
class WizardStepProps {
  const WizardStepProps({
    required this.english,
    required this.formKey,
    required this.submitted,
    required this.showErrorBanner,
    required this.onDismissErrorBanner,
    required this.fields,
    required this.enhancingField,
    required this.fieldResults,
    required this.onEnhance,
    required this.onDismissResult,
    required this.onPrimaryAction,
    this.enhanceBeats = const {},
  });

  final bool english;
  final GlobalKey<FormState> formKey;

  /// True once the user tried to leave this step; turns on live validation.
  final bool submitted;
  final bool showErrorBanner;
  final VoidCallback onDismissErrorBanner;
  final CvFormControllers fields;

  /// Field currently being AI-enhanced, or null.
  final String? enhancingField;
  final Map<String, Map<String, dynamic>> fieldResults;
  final void Function(String field) onEnhance;
  final void Function(String field) onDismissResult;

  /// Next / Generate — also fired by keyboard Done on a step's last field.
  final VoidCallback onPrimaryAction;

  /// Monotonic UI-only counters incremented when an AI enhancement completes
  /// for a field, used to trigger a brief visual confirmation pulse.
  final Map<String, int> enhanceBeats;

  AutovalidateMode get autovalidateMode => submitted
      ? AutovalidateMode.onUserInteraction
      : AutovalidateMode.disabled;

  bool isEnhancing(String field) => enhancingField == field;
}

/// Form wrapper shared by all steps: heading, error banner, then fields.
class WizardStepForm extends StatelessWidget {
  const WizardStepForm({
    super.key,
    required this.props,
    required this.title,
    required this.icon,
    required this.children,
  });

  final WizardStepProps props;
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: props.formKey,
      autovalidateMode: props.autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(text: title, icon: icon),
          const SizedBox(height: 18),
          if (props.showErrorBanner)
            AppFormErrorBanner(
              message: AppLocalizations.of(context).cvWizardReviewFields,
              onDismiss: props.onDismissErrorBanner,
            ),
          ...children,
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Semantics(
      header: true,
      child: Row(
        children: [
          // A calm teal tile, no outline (iOS 26 restyle).
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: c.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: c.primaryInk),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The fill a card's contents use: the other one of the page's two fills,
/// so fields, grey capsules and chips inside a card keep an edge against
/// it. On a grouped page the card takes the grouped card fill and its
/// contents the plain card fill; on a plain page it is the other way round.
class NestedFillScope extends StatelessWidget {
  const NestedFillScope({super.key, required this.child});

  final Widget child;

  /// The surface kind inside a card that sits on [outer].
  static PageSurfaceKind innerKind(PageSurfaceKind outer) =>
      outer == PageSurfaceKind.grouped
          ? PageSurfaceKind.plain
          : PageSurfaceKind.grouped;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final inner = innerKind(PageSurface.of(context));
    final fill = PageSurface.fillColor(c, inner);
    final base = Theme.of(context);
    final secondary = AppTheme.secondaryButtonStyle(c, fill);
    return Theme(
      data: base.copyWith(
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          fillColor: fill,
          hoverColor: c.pressed(fill),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style:
              (base.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
            backgroundColor: secondary.backgroundColor,
            overlayColor: secondary.overlayColor,
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: fill,
          disabledColor: fill,
        ),
        cardTheme: base.cardTheme.copyWith(color: fill),
      ),
      child: PageSurface(kind: inner, child: child),
    );
  }
}

/// One grouped section of a step: a borderless rounded card in the page's
/// card fill, holding a few related fields. The fields inside use the other
/// fill ([NestedFillScope]) so they keep an edge against the card.
class WizardSection extends StatelessWidget {
  const WizardSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PageSurface.fillOf(context),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardAll),
      child: NestedFillScope(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Label above a field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.sirati.textSecondary,
        ),
      ),
    );
  }
}

/// Label + field, the unit every step is built from.
class FieldGroup extends StatelessWidget {
  const FieldGroup({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Smoothly resizes around AI enhancement result cards and pulses an AA-safe
/// confirmation border whenever [beat] increments, without mutating form text.
class AiEnhancedBeatFrame extends StatelessWidget {
  const AiEnhancedBeatFrame({
    super.key,
    required this.beat,
    required this.child,
  });

  final int beat;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MotionSettings.reduce(context);
    final c = context.sirati;
    final sized = reduce
        ? child
        : AnimatedSize(
            duration: MotionDurations.medium,
            curve: MotionCurves.enter,
            alignment: AlignmentDirectional.topStart,
            child: child,
          );
    if (reduce) return sized;

    // One stable tree for every beat: a changed key or wrapper type here
    // would rebuild [child] (losing the field's focus and the AnimatedSize
    // resize). The tween runs from the previous beat to the new one, and the
    // glow is how far it still has to go.
    final target = beat <= 0 ? 0.0 : beat.toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: target <= 0 ? 0.0 : target - 1, end: target),
      duration: MotionDurations.morph,
      curve: MotionCurves.settle,
      builder: (context, value, inner) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: c.primaryInk.withValues(
              alpha: (target - value).clamp(0.0, 1.0) * 0.45,
            ),
            width: 1.5,
          ),
        ),
        child: inner,
      ),
      child: sized,
    );
  }
}
