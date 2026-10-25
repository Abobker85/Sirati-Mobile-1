import 'package:sirati/shared/navigation/dashboard_tab.dart';

/// Screens a push notification can open on top of the shell.
enum NotificationScreen {
  notifications,
  cvAnalysis,
  history,
  cvGenerator,
  settings,
}

/// Where a tapped push notification should take the user.
sealed class NotificationTarget {
  const NotificationTarget();
}

/// Switch the shell to [tab]; for education, optionally open [educationId].
final class OpenTab extends NotificationTarget {
  const OpenTab(this.tab, {this.educationId});

  final DashboardTab tab;
  final int? educationId;

  @override
  bool operator ==(Object other) =>
      other is OpenTab && other.tab == tab && other.educationId == educationId;

  @override
  int get hashCode => Object.hash(tab, educationId);

  @override
  String toString() => 'OpenTab($tab, educationId: $educationId)';
}

final class OpenScreen extends NotificationTarget {
  const OpenScreen(this.screen);

  final NotificationScreen screen;

  @override
  bool operator ==(Object other) =>
      other is OpenScreen && other.screen == screen;

  @override
  int get hashCode => screen.hashCode;

  @override
  String toString() => 'OpenScreen($screen)';
}

/// Open generated CV [id] (on top of the My CVs tab).
final class OpenGeneratedCv extends NotificationTarget {
  const OpenGeneratedCv(this.id);

  final int id;

  @override
  bool operator ==(Object other) => other is OpenGeneratedCv && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OpenGeneratedCv($id)';
}

/// Open [url] externally. The launcher validates the scheme; an unsafe or
/// missing URL is a no-op there.
final class OpenExternalUrl extends NotificationTarget {
  const OpenExternalUrl(this.url);

  final String? url;

  @override
  bool operator ==(Object other) =>
      other is OpenExternalUrl && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'OpenExternalUrl($url)';
}

/// Resolves a notification payload (`action_type` / `action_url`) to a
/// target. `open_cv` and `job_news` are the action types the server's CV-ready
/// and matching-job pushes use; their urls are in-app routes too. Anything
/// unrecognised falls back to the notifications inbox so a
/// tap is never silently dropped.
NotificationTarget resolveNotificationTarget(Map<String, dynamic> data) {
  final actionType = data['action_type']?.toString();
  final actionUrl = data['action_url']?.toString();
  return switch (actionType) {
    'url' => OpenExternalUrl(actionUrl),
    'screen' || 'open_cv' || 'job_news' => resolveScreenRoute(actionUrl),
    _ => const OpenScreen(NotificationScreen.notifications),
  };
}

/// Maps an in-app route such as `/education/12` or `jobs?ref=push`. A leading
/// `mobile/` (API-style paths such as `/mobile/job-news/5`) is ignored.
NotificationTarget resolveScreenRoute(String? route) {
  const inbox = OpenScreen(NotificationScreen.notifications);
  // Leading slashes are stripped first: `//home` would otherwise parse as a
  // host, not a path.
  final path = (route ?? '').trim().replaceFirst(RegExp('^/+'), '');
  final uri = Uri.tryParse(path);
  var segments =
      uri?.pathSegments.where((s) => s.isNotEmpty).toList() ?? const <String>[];
  if (segments.length > 1 && segments.first.toLowerCase() == 'mobile') {
    segments = segments.sublist(1);
  }
  if (segments.isEmpty) return inbox;

  final root = segments.first.toLowerCase();
  final id = segments.length > 1 ? int.tryParse(segments[1]) : null;

  return switch (root) {
    'home' => const OpenTab(DashboardTab.home),
    'my-cvs' || 'mycvs' || 'cv' => id != null && id > 0
        ? OpenGeneratedCv(id)
        : const OpenTab(DashboardTab.myCvs),
    'education' => OpenTab(
        DashboardTab.education,
        educationId: id != null && id > 0 ? id : null,
      ),
    'job-news' || 'jobs' => const OpenTab(DashboardTab.jobNews),
    'cv-analysis' ||
    'analysis-new' =>
      const OpenScreen(NotificationScreen.cvAnalysis),
    // A specific analysis is reached through history; without an id the
    // user most likely wants to start a new one.
    'analysis' => OpenScreen(
        id != null ? NotificationScreen.history : NotificationScreen.cvAnalysis,
      ),
    'create-cv' ||
    'cv-generator' =>
      const OpenScreen(NotificationScreen.cvGenerator),
    'notifications' => inbox,
    'settings' => const OpenScreen(NotificationScreen.settings),
    _ => inbox,
  };
}
