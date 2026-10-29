import 'package:url_launcher/url_launcher.dart';

/// Returns a launchable https URI, or null when [raw] is unsafe/malformed.
Uri? parseSafeExternalUrl(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'https') return uri;
  if (scheme == 'http' &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
    return uri;
  }
  return null;
}

/// Opens the mail app addressed to [address]; false when [address] is not a
/// plain email or no mail app opens. Kept apart from [launchSafeExternalUrl],
/// which only opens https pages.
Future<bool> launchMailto(String address, {String? subject}) async {
  final trimmed = address.trim();
  if (!RegExp(
          r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$')
      .hasMatch(trimmed)) {
    return false;
  }
  final uri = Uri(
    scheme: 'mailto',
    path: trimmed,
    query: subject == null || subject.trim().isEmpty
        ? null
        : 'subject=${Uri.encodeComponent(subject.trim())}',
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> launchSafeExternalUrl(String? raw) async {
  final uri = parseSafeExternalUrl(raw);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
