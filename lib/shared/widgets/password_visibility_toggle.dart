import 'package:flutter/material.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';

/// Eye button for a password field, labelled for screen readers in both
/// states.
class PasswordVisibilityToggle extends StatelessWidget {
  const PasswordVisibilityToggle({
    super.key,
    required this.obscured,
    required this.onToggle,
  });

  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: obscured ? l10n.showPassword : l10n.hidePassword,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: onToggle,
    );
  }
}
