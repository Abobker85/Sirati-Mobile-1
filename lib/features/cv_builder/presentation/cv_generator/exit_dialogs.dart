import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/theme/app_theme.dart';

enum WizardExitAction { cancel, discard, saveDraft }

/// Edit mode: confirm throwing away unsaved edits. Returns true to discard.
Future<bool> confirmDiscardEdits(BuildContext context) {
  final c = context.sirati;
  final l10n = AppLocalizations.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      title: Text(
        l10n.cvDiscardChangesTitle,
        style: TextStyle(color: c.textPrimary),
      ),
      content: Text(
        l10n.cvDiscardChangesBody,
        style: TextStyle(color: c.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: c.red),
          child: Text(l10n.cvDiscard),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

/// Create mode: save a local draft, discard, or stay.
Future<WizardExitAction> askSaveDraft(BuildContext context) {
  final c = context.sirati;
  final l10n = AppLocalizations.of(context);
  return showDialog<WizardExitAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.surface,
      title: Text(
        l10n.cvSaveProgressTitle,
        style: TextStyle(color: c.textPrimary),
      ),
      content: Text(
        l10n.cvSaveProgressBody,
        style: TextStyle(color: c.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, WizardExitAction.cancel),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, WizardExitAction.discard),
          style: TextButton.styleFrom(foregroundColor: c.red),
          child: Text(l10n.cvDiscard),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, WizardExitAction.saveDraft),
          child: Text(l10n.cvSaveDraft),
        ),
      ],
    ),
  ).then((value) => value ?? WizardExitAction.cancel);
}
