import 'package:flutter/material.dart';
import 'package:sirati/core/routing/fade_through_page_route.dart';

/// Replaces the entire navigator stack with [page] as the new root.
///
/// Auth entry points (login, register, OTP, splash session restore, logout)
/// must use this exactly once so competing routes cannot leave an empty
/// surface after a delayed session change.
void replaceRoot(BuildContext context, Widget page) {
  // A new root is not a step deeper: fade through, no slide.
  Navigator.of(context).pushAndRemoveUntil(
    FadeThroughPageRoute<void>(builder: (_) => page),
    (route) => false,
  );
}
