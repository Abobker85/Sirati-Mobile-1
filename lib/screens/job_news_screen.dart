import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_locale.dart';
import '../models/job_news.dart';
import '../services/mobile_content_service.dart';
import '../theme/app_theme.dart';
import '../services/api_exception.dart';
import '../services/session_cache.dart';
import '../utils/app_format.dart';
import '../widgets/loading/app_async_body.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/motion.dart';
import '../widgets/offline_cache_banner.dart';
import '../widgets/screen_header.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

/// Prefer computed relative time from [JobNews.publishedAt]; fall back to API label digits.
String _jobPublishedText(JobNews item, {required bool english}) {
  if (item.publishedAt != null) {
    return AppFormat.relativeTime(item.publishedAt!, english: english);
  }
  final label = item.publishedLabel?.trim() ?? '';
  if (label.isEmpty) return '';
  return AppFormat.digits(label, english: english);
}

String _jobValidUntilText(JobNews item, {required bool english}) {
  if (item.validUntil != null) {
    return AppFormat.shortDate(item.validUntil!, english: english);
  }
  final label = item.validUntilLabel?.trim() ?? '';
  if (label.isEmpty) return '';
  return AppFormat.digits(label, english: english);
}

class JobNewsScreen extends StatefulWidget {
  final bool isActive;

  const JobNewsScreen({super.key, this.isActive = true});

  @override
  State<JobNewsScreen> createState() => _JobNewsScreenState();
}

class _JobNewsScreenState extends State<JobNewsScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  Future<Map<String, dynamic>>? _jobNewsFuture;
  bool? _loadedEnglish;
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final english = AppLocale.isEnglish(context);
    if (_loadedEnglish != english || _jobNewsFuture == null) {
      _loadedEnglish = english;
      _reload();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload({bool force = false}) {
    final english = _loadedEnglish ?? AppLocale.isEnglish(context);
    _jobNewsFuture = MobileContentService().jobNews(
      english,
      category: _selectedCategory == 'all' ? null : _selectedCategory,
      query: _searchQuery,
      force: force,
    );
  }

  Future<void> _refresh({bool force = true}) async {
    setState(() {
      _isRefreshing = true;
      _reload(force: force);
    });
    try {
      await _jobNewsFuture;
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void didUpdateWidget(covariant JobNewsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When user revisits Jobs tab, always force refresh to reflect backend
    // updates immediately instead of waiting for app restart or cache expiry.
    if (widget.isActive && !oldWidget.isActive) {
      unawaited(_refresh(force: true));
    }
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _reload(force: true);
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _reload(force: true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _jobNewsFuture,
        builder: (context, snapshot) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = constraints.maxWidth >= 1100
                  ? 920.0
                  : constraints.maxWidth >= 780
                      ? 760.0
                      : constraints.maxWidth;
              final horizontalPadding =
                  AppSpacing.pageGutter(constraints.maxWidth);

              Widget shell(Widget child) => Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: child,
                    ),
                  );

              return AppAsyncBody<Map<String, dynamic>>(
                snapshot: snapshot,
                english: english,
                onRetry: () => setState(() => _reload(force: true)),
                fallbackOnEmptyError: _fallback(english),
                errorMessage: (error) => error is ApiException
                    ? error.displayMessage
                    : (english
                        ? 'Could not load job news.'
                        : 'تعذر تحميل أخبار الوظائف.'),
                loading: shell(
                  JobNewsSkeleton(horizontalPadding: horizontalPadding),
                ),
                builder: (data) {
                  final items =
                      _list(data['items']).map(JobNews.fromJson).toList();
                  final featured = items.isNotEmpty ? items.first : null;
                  final latest =
                      items.length > 1 ? items.skip(1).toList() : items;
                  final offline = MobileContentService.isOfflinePayload(data);
                  final resultsKey =
                      '$_selectedCategory|$_searchQuery|${items.length}|${featured?.id ?? 0}';

                  return shell(
                    RefreshIndicator(
                      color: context.sirati.primary,
                      onRefresh: () => _refresh(force: true),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                                horizontalPadding, 18, horizontalPadding, 0),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ScreenHeader(
                                    english: english,
                                    title: _text(data['title'],
                                        english ? 'Job News' : 'أخبار الوظائف'),
                                    avatarLabel: english ? 'J' : 'و',
                                    unreadCount:
                                        SessionCache.instance.unreadCount,
                                    onNotifications: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NotificationsScreen()),
                                    ),
                                    onAvatarTap: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const SettingsScreen()),
                                    ),
                                  ),
                                  if (offline) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    OfflineCacheBanner(
                                      english: english,
                                      surface: 'news',
                                    ),
                                  ],
                                  if (_isRefreshing ||
                                      (snapshot.connectionState ==
                                              ConnectionState.waiting &&
                                          snapshot.hasData))
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(top: 10, bottom: 2),
                                      child:
                                          LinearProgressIndicator(minHeight: 3),
                                    ),
                                  const SizedBox(height: AppSpacing.lg),
                                  _SearchBar(
                                    english: english,
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _CategoryChips(
                                    english: english,
                                    selectedCategory: _selectedCategory,
                                    onSelected: _selectCategory,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Featured + section title animate on filter;
                                  // list rows are built lazily below.
                                  AnimatedSwitcher(
                                    duration: MotionSettings.reduce(context)
                                        ? Duration.zero
                                        : MotionDurations.medium,
                                    switchInCurve: MotionCurves.enter,
                                    switchOutCurve: MotionCurves.exit,
                                    child: Column(
                                      key: ValueKey(resultsKey),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (featured != null)
                                          MotionReveal(
                                            order: 0,
                                            child: _FeaturedJobCard(
                                              item: featured,
                                              english: english,
                                              onTap: () =>
                                                  Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      JobNewsDetailScreen(
                                                          item: featured),
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (featured != null)
                                          const SizedBox(height: AppSpacing.lg),
                                        Text(
                                          english
                                              ? 'Latest Postings'
                                              : 'آخر الإعلانات',
                                          textAlign: TextAlign.start,
                                          style: AppTextStyles.titleMd(),
                                        ),
                                        const SizedBox(height: AppSpacing.sm),
                                        if (latest.isEmpty)
                                          _EmptyNews(english: english),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (latest.isNotEmpty)
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                  horizontalPadding, 0, horizontalPadding, 112),
                              sliver: SliverList.builder(
                                itemCount: latest.length,
                                itemBuilder: (context, index) {
                                  final item = latest[index];
                                  // +1 after featured (order 0); > max skips controllers.
                                  final order = index + 1;
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm),
                                    child: MotionReveal(
                                      order: order,
                                      child: _JobNewsCard(
                                        item: item,
                                        english: english,
                                        isNew: index == 0,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                JobNewsDetailScreen(item: item),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            const SliverPadding(
                              padding: EdgeInsets.only(bottom: 112),
                              sliver: SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class JobNewsDetailScreen extends StatelessWidget {
  final JobNews item;

  const JobNewsDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    final actionUrl = item.actionUrl;

    return Scaffold(
      appBar: AppBar(title: Text(english ? 'Job Details' : 'تفاصيل الخبر')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    LocaleFormat.mixedTitle(item.title, english: english),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: context.sirati.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((item.company ?? '').isNotEmpty)
                        _MetaChip(
                            text: LocaleFormat.mixedTitle(item.company!,
                                english: english)),
                      if ((item.location ?? '').isNotEmpty)
                        _MetaChip(text: item.location!),
                      if (_jobPublishedText(item, english: english).isNotEmpty)
                        _MetaChip(
                            text: _jobPublishedText(item, english: english)),
                      if (_jobValidUntilText(item, english: english).isNotEmpty)
                        _MetaChip(
                          text: _jobValidUntilText(item, english: english),
                          highlight: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    LocaleFormat.mixedBody(item.body, english: english),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.75,
                      color: context.sirati.textPrimary,
                    ),
                  ),
                  if (actionUrl != null) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(actionUrl),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.send_rounded),
                      label: Text(english ? 'Apply Now' : 'تقدّم الآن'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JobNewsCard extends StatelessWidget {
  final JobNews item;
  final bool english;
  final bool isNew;
  final VoidCallback onTap;

  const _JobNewsCard({
    required this.item,
    required this.english,
    required this.isNew,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [item.company ?? '', item.location ?? '']
        .where((value) => value.isNotEmpty)
        .join(' · ');

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
              border: Border.all(color: context.sirati.border),
              boxShadow: context.sirati.softShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              LocaleFormat.mixedTitle(item.title,
                                  english: english),
                              textAlign: TextAlign.start,
                              style: AppTextStyles.titleMd(),
                            ),
                          ),
                          if (isNew) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.sirati.primaryLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                english ? 'New' : 'جديد',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.sirati.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: context.sirati.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _jobPublishedText(item, english: english),
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: context.sirati.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.bookmark_border_rounded,
                    size: 18, color: context.sirati.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String text;
  final bool highlight;

  const _MetaChip({required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    if (!highlight) {
      return Chip(label: Text(text));
    }
    return Chip(
      label: Text(
        text,
        style: TextStyle(
          color: context.sirati.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: context.sirati.primaryLight,
      side: BorderSide(color: context.sirati.borderStrong),
    );
  }
}

class _EmptyNews extends StatelessWidget {
  final bool english;

  const _EmptyNews({required this.english});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.sirati.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.sirati.border),
      ),
      child: Text(
        english
            ? 'No job news is published yet.'
            : 'لا توجد أخبار وظائف منشورة حالياً.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 15, color: context.sirati.textSecondary),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool english;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.english,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.start,
        decoration: InputDecoration(
          hintText: english
              ? 'Search for a job or company...'
              : 'ابحث عن وظيفة أو شركة...',
          // Keep the search affordance on the physical leading edge of the field
          // (left) in both locales — matches the current product screenshots.
          prefixIcon:
              english ? const Icon(Icons.search_rounded, size: 18) : null,
          suffixIcon:
              english ? null : const Icon(Icons.search_rounded, size: 18),
          filled: true,
          fillColor: context.sirati.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.sirati.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.sirati.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.sirati.primary, width: 1.4),
          ),
        ),
        style: TextStyle(
            fontSize: 13.5, height: 1.3, color: context.sirati.textPrimary),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final bool english;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryChips({
    required this.english,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _CategoryOption('all', english ? 'All' : 'الكل'),
      _CategoryOption('tech', english ? 'Tech' : 'تقنية'),
      _CategoryOption('finance', english ? 'Finance' : 'تمويل'),
      _CategoryOption('health', english ? 'Health' : 'صحة'),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final option in options)
            PressScale(
              pressedScale: .98,
              child: ChoiceChip(
                label: Text(option.label),
                selected: selectedCategory == option.key,
                onSelected: (_) => onSelected(option.key),
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selectedCategory == option.key
                      ? Colors.white
                      : context.sirati.textSecondary,
                ),
                selectedColor: context.sirati.primary,
                backgroundColor: context.sirati.primaryLight,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryOption {
  final String key;
  final String label;

  const _CategoryOption(this.key, this.label);
}

class _FeaturedJobCard extends StatelessWidget {
  final JobNews item;
  final bool english;
  final VoidCallback onTap;

  const _FeaturedJobCard({
    required this.item,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.sirati.primary, context.sirati.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.sirati.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    english ? 'New' : 'جديد',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.sirati.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  LocaleFormat.mixedTitle(item.title, english: english),
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  LocaleFormat.mixedTitle(item.company ?? '', english: english),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: .88),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if ((item.location ?? '').isNotEmpty) item.location!,
                    _jobPublishedText(item, english: english),
                  ].where((s) => s.isNotEmpty).join(' · '),
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: .75),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    english ? 'Apply Now' : 'تقدم الآن',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.sirati.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Map<String, dynamic> _fallback(bool english) => {
      'title': english ? 'Job News' : 'أخبار الوظائف',
      'subtitle': english
          ? 'Fresh opportunities and hiring updates.'
          : 'فرص وتحديثات توظيف جديدة.',
      'items': const [],
    };

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};
List<Map<String, dynamic>> _list(dynamic value) =>
    value is List ? value.map(_map).toList() : const [];
String _text(dynamic value, String fallback) =>
    (value?.toString().isNotEmpty ?? false) ? value.toString() : fallback;
