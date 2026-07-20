import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../services/api_exception.dart';
import '../services/mobile_content_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_format.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading/app_async_body.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/motion.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = MobileContentService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.notifications();
  }

  void _refresh() {
    setState(() => _future = _service.notifications(force: true));
  }

  Future<void> _markAllRead() async {
    await _service.markAllNotificationsRead();
    _refresh();
  }

  Future<void> _markRead(int? id) async {
    if (id == null) return;
    await _service.markNotificationRead(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(english ? 'Notifications' : 'الإشعارات'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(english ? 'Read all' : 'قراءة الكل'),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          return AppAsyncBody<Map<String, dynamic>>(
            snapshot: snapshot,
            english: english,
            onRetry: _refresh,
            fallbackOnEmptyError: const {},
            errorMessage: (error) => error is ApiException
                ? error.displayMessage
                : (english
                    ? 'Could not load notifications.'
                    : 'تعذر تحميل الإشعارات.'),
            loading: const ListScreenSkeleton(
              itemCount: 5,
              padding:
                  EdgeInsets.fromLTRB(AppSpacing.lg, 18, AppSpacing.lg, 32),
            ),
            isEmpty: (data) => _list(data['items']).isEmpty,
            empty: AppEmptyState(
              icon: Icons.notifications_none_rounded,
              title:
                  english ? 'No notifications yet' : 'لا توجد إشعارات حالياً',
              subtitle: english
                  ? 'Updates about jobs and CV activity will show up here.'
                  : 'ستظهر هنا التحديثات حول الوظائف ونشاط سيرتك.',
              scrollable: true,
            ),
            builder: (data) {
              final items = _list(data['items']);
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 18, AppSpacing.lg, 32),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MotionReveal(
                      order: index.clamp(0, 5),
                      child: _NotificationCard(
                        item: item,
                        english: english,
                        onTap: () => _markRead(_int(item['id'])),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool english;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item['is_read'] == true;

    return PressScale(
      child: Material(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRead
                    ? context.sirati.border
                    : context.sirati.primary.withValues(alpha: .28),
              ),
              boxShadow: context.sirati.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _text(item['title'], ''),
                        textAlign: TextAlign.start,
                        style: AppTextStyles.titleSm().copyWith(
                          fontWeight:
                              isRead ? FontWeight.w600 : FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.sirati.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _text(item['body'], ''),
                  textAlign: TextAlign.start,
                  style: AppTextStyles.bodySm(),
                ),
                if (_notificationTime(item, english: english).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _notificationTime(item, english: english),
                    style: AppTextStyles.labelMd().copyWith(
                      color: context.sirati.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};
List<Map<String, dynamic>> _list(dynamic value) =>
    value is List ? value.map(_map).toList() : const [];
String _text(dynamic value, String fallback) =>
    (value?.toString().isNotEmpty ?? false) ? value.toString() : fallback;
int? _int(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

String _notificationTime(Map<String, dynamic> item, {required bool english}) {
  final raw = item['created_at'] ?? item['createdAt'];
  final at = DateTime.tryParse(raw?.toString() ?? '');
  if (at != null) {
    return AppFormat.relativeTime(at, english: english);
  }
  final label = _text(item['created_label'], '');
  if (label.isEmpty) return '';
  return AppFormat.digits(label, english: english);
}
