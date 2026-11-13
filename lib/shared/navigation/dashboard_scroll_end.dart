import 'package:flutter/widgets.dart';
import 'package:sirati/shared/theme/app_theme.dart';

/// Bottom padding for a dashboard tab's scroll list.
///
/// The shell's glass bar floats over the page (`extendBody`), and the shell
/// reports the bar's height as bottom padding. The list pads by that much plus
/// [extra], so the last item can scroll clear of the bar while everything
/// above it still slides underneath. Tabs must not consume that padding with a
/// bottom [SafeArea].
double dashboardScrollEnd(
  BuildContext context, {
  double extra = AppSpacing.scrollBottomTab,
}) =>
    MediaQuery.paddingOf(context).bottom + extra;
