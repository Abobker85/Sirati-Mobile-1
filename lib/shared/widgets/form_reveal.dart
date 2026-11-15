import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/shared/widgets/motion.dart';

/// Validates the form behind [formKey] like [FormState.validate], and when
/// something is wrong takes the user calmly to the first problem: the
/// top-most invalid field scrolls into view and, if it is a text field,
/// gets the focus once the scroll has ended. The user never has to hunt
/// for the message.
///
/// Returns whether the form is valid. The rules and messages are the
/// form's own; only where the user ends up changes.
bool validateAndReveal(GlobalKey<FormState> formKey) {
  final form = formKey.currentState;
  if (form == null) return true;
  final invalid = form.validateGranularly();
  if (invalid.isEmpty) return true;
  final first = topMostField(invalid);
  if (first != null) unawaited(revealField(first.context));
  return false;
}

/// The field drawn highest on screen (then the one nearest the reading
/// start), or null when none is laid out.
FormFieldState<Object?>? topMostField(
    Iterable<FormFieldState<Object?>> fields) {
  FormFieldState<Object?>? best;
  Offset? bestAt;
  for (final field in fields) {
    final box = field.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) continue;
    final at = box.localToGlobal(Offset.zero);
    final rtl = Directionality.maybeOf(field.context) == TextDirection.rtl;
    final x = rtl ? -(at.dx + box.size.width) : at.dx;
    if (bestAt == null ||
        at.dy < bestAt.dy - .5 ||
        ((at.dy - bestAt.dy).abs() <= .5 && x < bestAt.dx)) {
      best = field;
      bestAt = Offset(x, at.dy);
    }
  }
  return best;
}

/// Scrolls [context] into view a quarter of the way down the viewport (or
/// at [alignment]), then focuses the first text field inside it.
Future<void> revealField(
  BuildContext context, {
  double alignment = .25,
  bool focus = true,
}) async {
  if (!context.mounted) return;
  if (Scrollable.maybeOf(context) != null) {
    final reduce = MotionSettings.reduce(context);
    await Scrollable.ensureVisible(
      context,
      alignment: alignment,
      duration: reduce ? Duration.zero : MotionDurations.slow,
      curve: MotionCurves.enter,
    );
  }
  if (!focus || !context.mounted) return;
  firstTextFocusIn(context)?.requestFocus();
}

/// The focus node of the first editable text inside [context], if any.
FocusNode? firstTextFocusIn(BuildContext context) {
  FocusNode? found;
  void visit(Element element) {
    if (found != null) return;
    final widget = element.widget;
    if (widget is EditableText) {
      found = widget.focusNode;
      return;
    }
    element.visitChildren(visit);
  }

  (context as Element).visitChildren(visit);
  return found;
}
