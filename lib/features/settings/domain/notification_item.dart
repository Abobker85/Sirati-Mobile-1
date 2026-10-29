import 'package:sirati/shared/navigation/dashboard_tab.dart';
import 'package:sirati/shared/navigation/notification_target.dart';

/// What a notification is about; drives the inbox icon and filter chips.
enum NotificationCategory { cv, jobs, analysis, learning, general }

/// One row of the in-app notification inbox.
class NotificationItem {
  const NotificationItem({
    required this.id,
    this.type = '',
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.createdLabel,
    required this.actionType,
    required this.actionUrl,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final raw = json['created_at'] ?? json['createdAt'];
    final id = json['id'];
    return NotificationItem(
      id: id is int ? id : int.tryParse(id?.toString() ?? ''),
      type: _text(json['type']),
      title: _text(json['title']),
      body: _text(json['body']),
      isRead: json['is_read'] == true,
      createdAt: raw == null ? null : DateTime.tryParse(raw.toString()),
      createdLabel: _text(json['created_label']),
      actionType: _text(json['action_type']),
      actionUrl: _text(json['action_url']),
    );
  }

  final int? id;

  /// Server kind such as `cv_ready`, `job_match` or a free-text campaign type.
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final String createdLabel;
  final String actionType;
  final String actionUrl;

  /// Whether tapping should navigate: decided by the same resolver as a
  /// tapped push. A row that resolves to the inbox would only reopen it.
  bool get opensSomething =>
      actionUrl.isNotEmpty &&
      target != const OpenScreen(NotificationScreen.notifications);

  NotificationTarget get target => resolveNotificationTarget(routePayload);

  /// A CV generation that did not finish; shown with an error tile.
  bool get isFailure => type == 'cv_failed';

  /// Category from the server type; unknown types (admin campaigns) fall back
  /// to where the notification opens.
  NotificationCategory get category {
    switch (type.toLowerCase()) {
      case 'cv_ready' || 'cv_failed' || 'cv':
        return NotificationCategory.cv;
      case 'job_match' || 'job':
        return NotificationCategory.jobs;
      case 'analysis':
        return NotificationCategory.analysis;
      case 'education' || 'tip':
        return NotificationCategory.learning;
    }
    if (actionUrl.isEmpty) return NotificationCategory.general;
    return switch (target) {
      OpenGeneratedCv() ||
      OpenTab(tab: DashboardTab.myCvs) ||
      OpenScreen(screen: NotificationScreen.cvGenerator) =>
        NotificationCategory.cv,
      OpenTab(tab: DashboardTab.jobNews) => NotificationCategory.jobs,
      OpenScreen(screen: NotificationScreen.cvAnalysis) ||
      OpenScreen(screen: NotificationScreen.history) =>
        NotificationCategory.analysis,
      OpenTab(tab: DashboardTab.education) => NotificationCategory.learning,
      _ => NotificationCategory.general,
    };
  }

  /// Payload in the push-notification shape, so taps reuse the push router.
  Map<String, dynamic> get routePayload => {
        'action_type': actionType,
        'action_url': actionUrl,
      };

  NotificationItem asRead() => NotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        isRead: true,
        createdAt: createdAt,
        createdLabel: createdLabel,
        actionType: actionType,
        actionUrl: actionUrl,
      );

  /// Rows from an inbox payload; non-object rows are dropped.
  static List<NotificationItem> listFrom(Map<String, dynamic> payload) {
    final raw = payload['items'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) NotificationItem.fromJson(item),
    ];
  }
}

String _text(Object? value) => value?.toString().trim() ?? '';
