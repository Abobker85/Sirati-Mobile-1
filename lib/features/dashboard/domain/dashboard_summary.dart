import 'package:sirati/shared/services/mobile_content_service.dart';

/// Parsed `/mobile/dashboard` payload.
class DashboardSummary {
  const DashboardSummary({
    required this.name,
    required this.status,
    required this.cvCount,
    required this.analysisCount,
    required this.unreadNotifications,
    required this.latestNewsTitle,
    required this.latestNewsSubtitle,
    required this.offline,
  });

  /// [cachedName] fills the greeting when the payload has no name.
  factory DashboardSummary.fromPayload(
    Map<String, dynamic> data, {
    required bool english,
    String cachedName = '',
  }) {
    final profile = _map(data['profile']);
    final stats = _map(data['stats']);
    final news = _map(data['latest_news']);
    final name = _text(profile['name']);
    return DashboardSummary(
      name: name.isNotEmpty ? name : cachedName.trim(),
      status: _text(profile['status']),
      cvCount: _count(stats['generated_cvs']),
      analysisCount: _count(stats['analyses']),
      unreadNotifications: data.containsKey('unread_notifications')
          ? _count(data['unread_notifications']) ?? 0
          : null,
      latestNewsTitle: _text(news['title']),
      latestNewsSubtitle: _text(news['subtitle']),
      offline: MobileContentService.isOfflinePayload(data),
    );
  }

  final String name;
  final String status;

  /// Real counts only; null when absent or invalid (the card shows nothing).
  final int? cvCount;
  final int? analysisCount;

  /// Null when the payload omits it, so the cached badge count is kept.
  final int? unreadNotifications;

  final String latestNewsTitle;
  final String latestNewsSubtitle;
  final bool offline;

  bool get hasLatestNews => latestNewsTitle.isNotEmpty;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

String _text(Object? value) => value?.toString().trim() ?? '';

/// Non-negative integer or null. Counts can't be negative; a negative or
/// non-numeric value is treated as missing rather than shown.
int? _count(Object? value) {
  final n = switch (value) {
    num() => value.isFinite ? value.toInt() : null,
    String() => int.tryParse(value.trim()),
    _ => null,
  };
  return n == null || n < 0 ? null : n;
}
