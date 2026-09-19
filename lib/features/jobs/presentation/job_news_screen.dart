import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/shared/models/job_news.dart';
import 'package:sirati/shared/services/mobile_content_service.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/core/network/api_exception.dart';
import 'package:sirati/shared/services/session_cache.dart';
import 'package:sirati/core/utils/app_format.dart';
import 'package:sirati/core/utils/safe_url.dart';
import 'package:sirati/shared/widgets/loading/app_async_body.dart';
import 'package:sirati/shared/widgets/loading/app_skeleton.dart';
import 'package:sirati/shared/widgets/motion.dart';
import 'package:sirati/shared/widgets/offline_cache_banner.dart';
import 'package:sirati/core/routing/app_routes.dart';
import 'package:sirati/shared/widgets/screen_header.dart';
import 'package:sirati/features/jobs/presentation/widgets/job_title_display.dart';
import 'package:sirati/features/cv_builder/presentation/cv_generator_screen.dart';

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
  String _selectedPreset = 'all';
  String _selectedCategory = 'all';
  String _selectedCity = 'all';
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
      preset: _selectedPreset == 'all' ? null : _selectedPreset,
      city: _selectedCity == 'all' ? null : _selectedCity,
      isRemote: _selectedCity == 'remote' || _selectedPreset == 'remote',
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

  void _selectPreset(String preset) {
    if (_selectedPreset == preset) return;
    setState(() {
      _selectedPreset = preset;
      _reload(force: true);
    });
  }

  void _selectCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _reload(force: true);
    });
  }

  void _selectCity(String city) {
    if (_selectedCity == city) return;
    setState(() {
      _selectedCity = city;
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
                  final profileContext = _map(data['profile_context']);
                  final hasProfile = profileContext['has_profile'] == true;
                  final resultsKey =
                      '$_selectedPreset|$_selectedCategory|$_selectedCity|$_searchQuery|${items.length}|${featured?.id ?? 0}';

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
                                    icon: Icons.work_rounded,
                                    unreadCount:
                                        SessionCache.instance.unreadCount,
                                    onNotifications: () =>
                                        Navigator.of(context).pushNamed(
                                      AppRoutes.notifications,
                                    ),
                                    onAvatarTap: () =>
                                        Navigator.of(context).pushNamed(
                                      AppRoutes.settings,
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
                                  if (hasProfile) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    _ProfileContextBanner(
                                      english: english,
                                      contextData: profileContext,
                                      isMatchedActive:
                                          _selectedPreset == 'matched',
                                      onToggleMatched: () => _selectPreset(
                                          _selectedPreset == 'matched'
                                              ? 'all'
                                              : 'matched'),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.md),
                                  _SearchBar(
                                    english: english,
                                    controller: _searchController,
                                    onChanged: _onSearchChanged,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _PresetChips(
                                    english: english,
                                    selectedPreset: _selectedPreset,
                                    onSelected: _selectPreset,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _CategoryChips(
                                    english: english,
                                    selectedCategory: _selectedCategory,
                                    onSelected: _selectCategory,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  _CityChips(
                                    english: english,
                                    selectedCity: _selectedCity,
                                    onSelected: _selectCity,
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
                                          style: AppTextStyles.titleMd(context.sirati),
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
    final hasMatch = item.matchScore != null;
    final isHighMatch = (item.matchScore ?? 0) >= 80;

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
                  if (item.isVerified) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: context.sirati.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.sirati.primary
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isGov
                                    ? Icons.account_balance_rounded
                                    : item.isEnterprise
                                        ? Icons.business_rounded
                                        : Icons.verified_rounded,
                                size: 14,
                                color: context.sirati.primaryDark,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                item.sourceBadge ??
                                    (english ? 'Verified' : 'جهة موثقة معتمدة'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.sirati.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.isTamheer) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: context.sirati.amberLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: context.sirati.amber
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              english ? 'Tamheer Program' : 'برنامج تمهير 🇸🇦',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: context.sirati.amber,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  JobTitleDisplay(
                    title: item.title,
                    primaryMaxLines: null,
                    secondaryMaxLines: null,
                    primaryStyle: TextStyle(
                      fontSize: 25,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: context.sirati.textPrimary,
                    ),
                    secondaryStyle: TextStyle(
                      fontSize: 17,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: context.sirati.textSecondary,
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
                      if (item.salaryRange != null &&
                          item.salaryRange!.isNotEmpty)
                        _MetaChip(
                          text: '💰 ${item.salaryRange!}',
                          highlight: true,
                        ),
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
                  if (hasMatch) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.sirati.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isHighMatch
                              ? context.sirati.primary
                                  .withValues(alpha: 0.4)
                              : context.sirati.border,
                          width: 1.2,
                        ),
                        boxShadow: context.sirati.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.stars_rounded,
                                  color: context.sirati.primary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                english
                                    ? 'Profile & CV Compatibility'
                                    : 'توافق الوظيفة مع ملفك المهني',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: context.sirati.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isHighMatch
                                      ? const Color(0xFFD7F0E5)
                                      : context.sirati.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${item.matchScore}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isHighMatch
                                        ? const Color(0xFF1E5C41)
                                        : context.sirati.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (item.matchScore ?? 0) / 100.0,
                              minHeight: 8,
                              backgroundColor: context.sirati.surfaceLow,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isHighMatch
                                    ? const Color(0xFF2E7D5B)
                                    : context.sirati.primary,
                              ),
                            ),
                          ),
                          if (item.matchReasons.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            for (final reason in item.matchReasons)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 15,
                                        color: context.sirati.primary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: context.sirati.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (item.skillsRequired.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      english ? 'Key Skills Required' : 'المهارات المطلوبة للوظيفة',
                      style: AppTextStyles.titleMd(context.sirati),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.skillsRequired.map((skill) {
                        final isMatched = item.matchedSkills.any((m) =>
                            m.toLowerCase() == skill.toLowerCase() ||
                            skill.toLowerCase().contains(m.toLowerCase()));
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isMatched
                                ? context.sirati.primaryLight
                                : context.sirati.surfaceLow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isMatched
                                  ? context.sirati.primary
                                      .withValues(alpha: 0.35)
                                  : context.sirati.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMatched) ...[
                                Icon(Icons.check_rounded,
                                    size: 13,
                                    color: context.sirati.primaryDark),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                skill,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isMatched
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isMatched
                                      ? context.sirati.primaryDark
                                      : context.sirati.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    english ? 'Job Description' : 'تفاصيل ومتطلبات الإعلان',
                    style: AppTextStyles.titleMd(context.sirati),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    LocaleFormat.mixedBody(item.body, english: english),
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.75,
                      color: context.sirati.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CvGeneratorScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      english
                          ? 'Tailor My CV for this Job'
                          : 'تخصيص سيرتي الذاتية لهذه الوظيفة 🪄',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.sirati.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (actionUrl != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => launchSafeExternalUrl(actionUrl),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(
                        english
                            ? 'Apply on Official Site'
                            : 'التقديم عبر الموقع الرسمي',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.sirati.primaryDark,
                        side: BorderSide(color: context.sirati.borderStrong),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

    final hasMatch = item.matchScore != null;
    final isHighMatch = (item.matchScore ?? 0) >= 80;

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
                color: isHighMatch
                    ? context.sirati.primary.withValues(alpha: 0.35)
                    : context.sirati.border,
                width: isHighMatch ? 1.4 : 1.0,
              ),
              boxShadow: context.sirati.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Badges (Verified / Tamheer / Match Score / New)
                Row(
                  children: [
                    if (item.isVerified) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.sirati.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isGov
                                  ? Icons.account_balance_rounded
                                  : item.isEnterprise
                                      ? Icons.business_rounded
                                      : Icons.verified_rounded,
                              size: 13,
                              color: context.sirati.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.sourceBadge ??
                                  (english ? 'Verified' : 'موثقة'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.sirati.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (item.isTamheer) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.sirati.amberLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          english ? 'Tamheer' : 'تمهير 🇸🇦',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.sirati.amber,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (hasMatch) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isHighMatch
                              ? const Color(0xFFD7F0E5)
                              : context.sirati.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 13,
                              color: isHighMatch
                                  ? const Color(0xFF1E5C41)
                                  : context.sirati.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.matchScore}% ${english ? 'Match' : 'تطابق'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isHighMatch
                                    ? const Color(0xFF1E5C41)
                                    : context.sirati.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (isNew)
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
                ),
                const SizedBox(height: 10),

                // Title & Save icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: JobTitleDisplay(
                        title: item.title,
                        primaryStyle: AppTextStyles.titleMd(context.sirati),
                        secondaryStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: context.sirati.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.bookmark_border_rounded,
                      size: 20,
                      color: context.sirati.textHint,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Company and location
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: context.sirati.textSecondary,
                    ),
                  ),

                // Match reason snippet if available
                if (item.matchReasons.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.sirati.surfaceLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 14,
                          color: context.sirati.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.matchReasons.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: context.sirati.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Required skills chips
                if (item.skillsRequired.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.skillsRequired.take(3).map((skill) {
                      final isMatched = item.matchedSkills.any((m) =>
                          m.toLowerCase() == skill.toLowerCase() ||
                          skill.toLowerCase().contains(m.toLowerCase()));
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMatched
                              ? context.sirati.primaryLight
                              : context.sirati.surfaceLow,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isMatched
                                ? context.sirati.primary
                                    .withValues(alpha: 0.3)
                                : context.sirati.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isMatched
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isMatched
                                ? context.sirati.primaryDark
                                : context.sirati.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 10),
                // Bottom row: Salary + Published time
                Row(
                  children: [
                    if (item.salaryRange != null &&
                        item.salaryRange!.isNotEmpty) ...[
                      Text(
                        item.salaryRange!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.sirati.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('·',
                          style: TextStyle(color: context.sirati.textHint)),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _jobPublishedText(item, english: english),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.sirati.textHint,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      english ? 'Details →' : 'التفاصيل ←',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.sirati.primary,
                      ),
                    ),
                  ],
                ),
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

class _ProfileContextBanner extends StatelessWidget {
  final bool english;
  final Map<String, dynamic> contextData;
  final bool isMatchedActive;
  final VoidCallback onToggleMatched;

  const _ProfileContextBanner({
    required this.english,
    required this.contextData,
    required this.isMatchedActive,
    required this.onToggleMatched,
  });

  @override
  Widget build(BuildContext context) {
    final careerField = contextData['career_field']?.toString() ?? '';
    final city = contextData['city']?.toString() ?? '';
    final hasCareer = careerField.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.sirati.primaryLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.sirati.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.sirati.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  english ? 'Personalized For You' : 'فرص مهنية مخصصة لك',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.sirati.primaryDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasCareer
                      ? (english
                          ? '$careerField${city.isNotEmpty ? ' · $city' : ''}'
                          : '$careerField${city.isNotEmpty ? ' · $city' : ''}')
                      : (english
                          ? 'Showing jobs tailored to your background.'
                          : 'عرض وظائف متوافقة مع مهاراتك وخبراتك.'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.sirati.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PressScale(
            child: Material(
              color: isMatchedActive
                  ? context.sirati.primaryDark
                  : Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isMatchedActive
                      ? Colors.transparent
                      : context.sirati.primaryDark,
                  width: 1.2,
                ),
              ),
              child: InkWell(
                onTap: onToggleMatched,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isMatchedActive) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        isMatchedActive
                            ? (english ? 'Matched ✓' : 'المطابقة ✓')
                            : (english ? 'Match 🎯' : 'المطابقة 🎯'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isMatchedActive
                              ? Colors.white
                              : context.sirati.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChips extends StatelessWidget {
  final bool english;
  final String selectedPreset;
  final ValueChanged<String> onSelected;

  const _PresetChips({
    required this.english,
    required this.selectedPreset,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [
      _PresetOption('all', english ? 'All' : 'الكل', Icons.dashboard_outlined),
      _PresetOption(
          'matched', english ? 'Best Match' : 'مناسبة لي 🎯', Icons.stars_rounded),
      _PresetOption('gov', english ? 'Government' : 'جهات حكومية 🏛️',
          Icons.account_balance_outlined),
      _PresetOption('enterprise', english ? 'Enterprise' : 'شركات كبرى 🏢',
          Icons.business_outlined),
      _PresetOption('tamheer', english ? 'Tamheer' : 'تمهير وتدريب 🇸🇦',
          Icons.school_outlined),
      _PresetOption('remote', english ? 'Remote' : 'عن بعد 🌐',
          Icons.public_rounded),
    ];

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final preset in presets)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: PressScale(
                  pressedScale: 0.96,
                  child: ChoiceChip(
                    label: Text(preset.label),
                    selected: selectedPreset == preset.key,
                    onSelected: (_) => onSelected(preset.key),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: selectedPreset == preset.key
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedPreset == preset.key
                          ? Colors.white
                          : context.sirati.textSecondary,
                    ),
                    selectedColor: context.sirati.primary,
                    backgroundColor: context.sirati.surface,
                    side: BorderSide(
                      color: selectedPreset == preset.key
                          ? context.sirati.primary
                          : context.sirati.border,
                      width: selectedPreset == preset.key ? 1.2 : 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PresetOption {
  final String key;
  final String label;
  final IconData icon;

  const _PresetOption(this.key, this.label, this.icon);
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

class _CityChips extends StatelessWidget {
  final bool english;
  final String selectedCity;
  final ValueChanged<String> onSelected;

  const _CityChips({
    required this.english,
    required this.selectedCity,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      _CategoryOption('all', english ? 'All Locations' : 'كل المناطق'),
      _CategoryOption('riyadh', english ? 'Riyadh' : 'الرياض'),
      _CategoryOption('jeddah', english ? 'Jeddah' : 'جدة'),
      _CategoryOption('dammam', english ? 'Dammam' : 'الدمام'),
      _CategoryOption('khobar', english ? 'Khobar' : 'الخبر'),
      _CategoryOption('mecca', english ? 'Mecca' : 'مكة'),
      _CategoryOption('medina', english ? 'Medina' : 'المدينة'),
      _CategoryOption('remote', english ? 'Remote' : 'عن بعد 🌐'),
    ];

    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in options)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 6),
                child: PressScale(
                  pressedScale: .98,
                  child: FilterChip(
                    label: Text(option.label),
                    selected: selectedCity == option.key,
                    onSelected: (_) => onSelected(option.key),
                    showCheckmark: false,
                    avatar: option.key == 'remote'
                        ? const Icon(Icons.public_rounded, size: 14)
                        : const Icon(Icons.location_on_outlined, size: 14),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: selectedCity == option.key
                          ? context.sirati.primaryDark
                          : context.sirati.textSecondary,
                    ),
                    selectedColor: context.sirati.primaryLight,
                    backgroundColor: context.sirati.surface,
                    side: BorderSide(
                      color: selectedCity == option.key
                          ? context.sirati.primary
                          : context.sirati.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.sirati.primaryLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        english ? 'New' : 'جديد',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.sirati.primaryDark,
                        ),
                      ),
                    ),
                    if (item.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.isGov
                                  ? Icons.account_balance_rounded
                                  : item.isEnterprise
                                      ? Icons.business_rounded
                                      : Icons.verified_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.sourceBadge ??
                                  (english ? 'Verified' : 'جهة موثقة'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (item.isTamheer)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          english ? 'Tamheer 🇸🇦' : 'تمهير 🇸🇦',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    if (item.matchScore != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 13,
                              color: context.sirati.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.matchScore}% ${english ? 'Match' : 'تطابق'}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: context.sirati.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                JobTitleDisplay(
                  title: item.title,
                  primaryStyle: const TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  secondaryStyle: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: .9),
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
                if (item.skillsRequired.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: item.skillsRequired.take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        english ? 'Apply Now' : 'تقدم الآن',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.sirati.primaryDark,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (item.salaryRange != null &&
                        item.salaryRange!.isNotEmpty)
                      Text(
                        item.salaryRange!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                  ],
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
