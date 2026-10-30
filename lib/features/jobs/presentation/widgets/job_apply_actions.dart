import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/features/jobs/domain/apply_destination.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/widgets/app_snack_bar.dart';

/// Opens [destination] for [item]: the employer page, or the mail app with
/// the job title as subject. [ApplyNone] does nothing; callers don't offer it.
Future<void> openJobApplication(
  BuildContext context,
  JobNews item,
  ApplyDestination destination,
) async {
  final l = AppLocalizations.of(context);
  switch (destination) {
    case ApplyLink(:final uri):
      final opened = await launchSafeExternalUrl(uri.toString());
      if (!opened && context.mounted) {
        AppSnackBar.error(context, l.jobsOpenApplyFailed);
      }
    case ApplyEmail(:final address):
      final opened = await launchMailto(address, subject: item.title);
      if (!opened && context.mounted) {
        AppSnackBar.error(context, l.jobsOpenEmailFailed);
      }
    case ApplyNone():
      break;
  }
}

Future<void> copyApplicationEmail(BuildContext context, String address) async {
  await Clipboard.setData(ClipboardData(text: address));
  if (context.mounted) {
    AppSnackBar.success(context, AppLocalizations.of(context).jobsEmailCopied);
  }
}
