import 'package:sirati/shared/models/job_news.dart';

/// How the user applies to a job, after the client-side guard.
sealed class ApplyDestination {
  const ApplyDestination();

  /// Resolves [item]'s destination. A link must pass [isApplyLinkAllowed]
  /// even when the server sent it (old cached payloads carried Telegram
  /// links), and the source post (`url`) is never used as a fallback.
  factory ApplyDestination.of(JobNews item) {
    final link = item.applyUrl?.trim() ?? '';
    final email = item.applyEmail?.trim() ?? '';
    final method = item.applyMethod;

    if ((method == 'url' || method.isEmpty) && isApplyLinkAllowed(link)) {
      return ApplyLink(Uri.parse(link));
    }
    if ((method == 'email' || method.isEmpty) && isApplyEmail(email)) {
      return ApplyEmail(email.toLowerCase());
    }
    return const ApplyNone();
  }
}

final class ApplyLink extends ApplyDestination {
  const ApplyLink(this.uri);
  final Uri uri;

  /// Host shown to the user before leaving the app ("www." dropped).
  String get displayHost =>
      uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
}

/// Wraps Latin [text] (a host, an email) in a left-to-right isolate so it
/// keeps its order inside an Arabic sentence.
String ltrIsolate(String text) =>
    '${String.fromCharCode(0x2066)}$text${String.fromCharCode(0x2069)}';

final class ApplyEmail extends ApplyDestination {
  const ApplyEmail(this.address);
  final String address;
}

final class ApplyNone extends ApplyDestination {
  const ApplyNone();
}

/// Hosts (and their subdomains) that are never an application page:
/// Telegram, social profiles and URL shorteners. Mirrors the server's
/// `ApplyLinkExtractor`.
const _deniedHosts = {
  't.me',
  'telegram.me',
  'telegram.org',
  'telegram.dog',
  'telesco.pe',
  'instagram.com',
  'instagr.am',
  'snapchat.com',
  'x.com',
  'twitter.com',
  'facebook.com',
  'fb.com',
  'fb.me',
  'tiktok.com',
  'youtube.com',
  'youtu.be',
  'threads.net',
  'whatsapp.com',
  'wa.me',
  'bit.ly',
  'lik.ad',
  't.co',
  'cutt.ly',
  'tinyurl.com',
  'goo.gl',
  'rb.gy',
  'shorturl.at',
  'is.gd',
  'ow.ly',
  'buff.ly',
  'rebrand.ly',
  'linktr.ee',
  'clck.ru',
  's.id',
  'tiny.cc',
  'v.gd',
  'cutt.us',
  'bit.do',
  't.ly',
  'short.gy',
  'lnkd.in',
  'surl.li',
  'shorturl.asia',
  'urlz.fr',
  'qr.ae',
};

bool isApplyLinkAllowed(String? raw) {
  final uri = Uri.tryParse(raw?.trim() ?? '');
  if (uri == null || uri.scheme.toLowerCase() != 'https' || !uri.hasAuthority) {
    return false;
  }
  if (uri.userInfo.isNotEmpty || uri.hasPort) return false;

  var host = uri.host.toLowerCase();
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);
  if (!host.contains('.') || _looksLikeIp(host)) return false;
  for (final denied in _deniedHosts) {
    if (host == denied || host.endsWith('.$denied')) return false;
  }

  // Hashtag searches (`?q=%23tag`) and search/hashtag pages.
  final q = uri.queryParameters['q'];
  if (q != null && q.startsWith('#')) return false;
  if (RegExp(r'^/(search|hashtag)(/|$)').hasMatch(uri.path.toLowerCase())) {
    return false;
  }

  if (host == 'linkedin.com' || host.endsWith('.linkedin.com')) {
    return uri.path.toLowerCase().contains('/jobs/');
  }
  return !_looksLikeShortener(host, uri);
}

/// Known application hosts (government, Jadarat, ATS, forms). Mirrors the
/// server's `ApplyLinkExtractor::APPLY_HOSTS`.
const _applyHosts = {
  'jadarat.sa',
  'qiwa.sa',
  'gov.sa',
  'edu.sa',
  'forms.gle',
  'forms.office.com',
  'forms.cloud.microsoft',
  'greenhouse.io',
  'lever.co',
  'workable.com',
  'smartrecruiters.com',
  'taleo.net',
  'myworkdayjobs.com',
  'successfactors.com',
  'successfactors.eu',
  'bayt.com',
  'recruitee.com',
  'bamboohr.com',
  'zohorecruit.com',
};

final _applyPath = RegExp(
    r'/(?:careers?|jobs?|vacanc(?:y|ies)|apply|application|recruit(?:ment|ing)?|forms?|employment|join-?us|opportunit(?:y|ies))(?:/|$|\.)',
    caseSensitive: false);

/// Unlisted shorteners: a very short host and one code-like path segment (a
/// digit, or a capital after a small letter), whatever the query. Plain words,
/// known apply hosts, careers-style subdomains and careers paths are not.
/// Mirrors the server's `looksLikeShortener`.
bool _looksLikeShortener(String host, Uri uri) {
  for (final known in _applyHosts) {
    if (host == known || host.endsWith('.$known')) return false;
  }
  if (RegExp(r'^(?:careers?|jobs?|recruit(?:ment|ing)?|hr|apply)[.\-]')
      .hasMatch(host)) {
    return false;
  }
  if (_applyPath.hasMatch(uri.path)) return false;
  final bare = host.startsWith('www.') ? host.substring(4) : host;
  final segment = RegExp(r'^/([A-Za-z0-9_\-]{3,32})/?$').firstMatch(uri.path);
  return bare.length <= 10 &&
      segment != null &&
      RegExp(r'\d|[a-z][A-Z]').hasMatch(segment.group(1)!);
}

bool _looksLikeIp(String host) =>
    RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) || host.contains(':');

final _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$');

bool isApplyEmail(String? raw) => _emailPattern.hasMatch(raw?.trim() ?? '');
