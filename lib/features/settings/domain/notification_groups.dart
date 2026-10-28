import 'package:sirati/features/settings/domain/notification_item.dart';

/// Date sections of the inbox, newest first.
enum NotificationPeriod { today, yesterday, thisWeek, earlier }

/// One date section and its rows, in inbox order.
class NotificationGroup {
  const NotificationGroup(this.period, this.items);

  final NotificationPeriod period;
  final List<NotificationItem> items;

  int get unreadCount => items.where((i) => !i.isRead).length;
}

/// Section for [at] by local calendar day relative to [now]. "This week" is
/// the five days before yesterday. Rows without a date go to
/// [NotificationPeriod.earlier]; rows dated in the future (a skewed clock)
/// count as today.
NotificationPeriod notificationPeriodOf(DateTime? at, DateTime now) {
  if (at == null) return NotificationPeriod.earlier;
  final local = at.isUtc ? at.toLocal() : at;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  // Calendar days, not 24 h spans: DST days are 23 or 25 hours long.
  final daysAgo = DateTime.utc(today.year, today.month, today.day)
      .difference(DateTime.utc(day.year, day.month, day.day))
      .inDays;
  if (daysAgo <= 0) return NotificationPeriod.today;
  if (daysAgo == 1) return NotificationPeriod.yesterday;
  if (daysAgo < 7) return NotificationPeriod.thisWeek;
  return NotificationPeriod.earlier;
}

/// Splits [items] into non-empty date sections. Section order is fixed
/// (today first); rows keep the server's order inside each section.
List<NotificationGroup> groupNotifications(
  List<NotificationItem> items,
  DateTime now,
) {
  final byPeriod = <NotificationPeriod, List<NotificationItem>>{};
  for (final item in items) {
    byPeriod
        .putIfAbsent(notificationPeriodOf(item.createdAt, now), () => [])
        .add(item);
  }
  return [
    for (final period in NotificationPeriod.values)
      if (byPeriod[period] case final rows?) NotificationGroup(period, rows),
  ];
}
