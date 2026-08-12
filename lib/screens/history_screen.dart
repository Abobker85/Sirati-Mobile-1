import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../models/cv_analysis.dart';
import '../models/generated_cv.dart';
import '../services/api_exception.dart';
import '../services/cv_api_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_format.dart';
import '../widgets/animated_ats_score_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading/app_async_body.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/motion.dart';
import 'analysis_result_screen.dart';
import 'cv_analysis_screen.dart';
import 'cv_generator_screen.dart';
import 'generated_cv_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _apiService = CvApiService();
  late Future<_HistoryData> _historyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _historyFuture = _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_HistoryData> _loadHistory() async {
    final analyses = await _apiService.listAnalyses();
    final generatedCvs = await _apiService.listGeneratedCvs();
    return _HistoryData(analyses: analyses, generatedCvs: generatedCvs);
  }

  Future<void> _refresh() async {
    final nextFuture = _loadHistory();
    setState(() => _historyFuture = nextFuture);
    await nextFuture;
  }

  Color _scoreColor(int score) {
    if (score >= 80) return context.sirati.tealDark;
    if (score >= 65) return context.sirati.primary;
    if (score >= 50) return context.sirati.amber;
    return context.sirati.red;
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);

    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: Text(english ? 'History' : 'السجل'),
        // When opened from Home, show a real back affordance; refresh stays trailing.
        automaticallyImplyLeading: canPop,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: english ? 'Refresh' : 'تحديث',
            onPressed: () => setState(() => _historyFuture = _loadHistory()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.sirati.textPrimary,
          unselectedLabelColor: context.sirati.textHint,
          indicatorColor: context.sirati.primary,
          // Logical tab order; Material places the first tab at the start edge.
          tabs: [
            Tab(text: english ? 'Analyses' : 'التحليلات'),
            Tab(text: english ? 'Generated CVs' : 'السير المنشأة'),
          ],
        ),
      ),
      body: FutureBuilder<_HistoryData>(
        future: _historyFuture,
        builder: (context, snapshot) {
          return AppAsyncBody<_HistoryData>(
            snapshot: snapshot,
            english: english,
            onRetry: () => setState(() => _historyFuture = _loadHistory()),
            fallbackOnEmptyError:
                const _HistoryData(analyses: [], generatedCvs: []),
            errorMessage: (error) => error is ApiException
                ? error.displayMessage
                : (english ? 'Could not load history.' : 'تعذر تحميل السجل.'),
            loading: const ListScreenSkeleton(
              itemCount: 5,
              padding: EdgeInsets.all(AppSpacing.md),
            ),
            builder: (data) => RefreshIndicator(
              onRefresh: _refresh,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AnalysisList(
                    analyses: data.analyses,
                    scoreColor: _scoreColor,
                    english: english,
                  ),
                  _GeneratedCvList(
                    cvs: data.generatedCvs,
                    scoreColor: _scoreColor,
                    english: english,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryData {
  final List<CvAnalysis> analyses;
  final List<GeneratedCv> generatedCvs;

  const _HistoryData({required this.analyses, required this.generatedCvs});
}

class _AnalysisList extends StatelessWidget {
  final List<CvAnalysis> analyses;
  final Color Function(int) scoreColor;
  final bool english;

  const _AnalysisList({
    required this.analyses,
    required this.scoreColor,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    if (analyses.isEmpty) {
      return AppEmptyState(
        icon: Icons.analytics_outlined,
        title: english ? 'No analyses yet' : 'لا توجد تحليلات بعد',
        subtitle: english
            ? 'Upload a CV to get your first ATS score and tips.'
            : 'ارفع سيرتك لتحصل على أول درجة ATS ونصائح التحسين.',
        actionLabel: english ? 'Analyze CV' : 'تحليل سيرة',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CvAnalysisScreen()),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: analyses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final analysis = analyses[i];
        final color = scoreColor(analysis.scoreTotal);

        return PressScale(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => AnalysisResultScreen(analysis: analysis)),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.sirati.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.sirati.border),
                boxShadow: context.sirati.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.sirati.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.manage_search,
                            size: 18, color: context.sirati.primary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          LocaleFormat.mixedTitle(analysis.targetJobTitle,
                              english: english),
                          textAlign: TextAlign.start,
                          style: AppTextStyles.titleSm(),
                        ),
                      ),
                      Text('${analysis.scoreTotal}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: color)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedAtsScoreBar(
                    value: analysis.scoreTotal / 100,
                    color: color,
                    height: 5,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      _MetaChip(label: analysis.grade, color: color),
                      const SizedBox(width: 6),
                      _MetaChip(
                          label: analysis.inputMethodLabel,
                          color: context.sirati.textSecondary),
                      const Spacer(),
                      Text(_dateLabel(analysis.createdAt, english: english),
                          style: TextStyle(
                              fontSize: 11,
                              color: context.sirati.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GeneratedCvList extends StatelessWidget {
  final List<GeneratedCv> cvs;
  final Color Function(int) scoreColor;
  final bool english;

  const _GeneratedCvList({
    required this.cvs,
    required this.scoreColor,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    if (cvs.isEmpty) {
      return AppEmptyState(
        icon: Icons.description_outlined,
        title: english ? 'No generated CVs yet' : 'لا توجد سير ذاتية منشأة بعد',
        subtitle: english
            ? 'Build an ATS-ready CV and it will show up here.'
            : 'أنشئ سيرة متوافقة مع ATS وستظهر هنا.',
        actionLabel: english ? 'Create CV' : 'إنشاء سيرة',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CvGeneratorScreen()),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cvs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final cv = cvs[i];
        final color = scoreColor(cv.scoreTotal);

        return PressScale(
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => GeneratedCvScreen(generatedCv: cv)),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.sirati.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.sirati.border),
                boxShadow: context.sirati.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.sirati.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            cv.fullName.characters.isEmpty
                                ? 'س'
                                : cv.fullName.characters.first,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.sirati.primary),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            LocaleFormat.mixedTitle(cv.fullName,
                                english: english),
                            textAlign: TextAlign.start,
                            style: AppTextStyles.titleSm()),
                        const SizedBox(height: 3),
                        Text(
                            LocaleFormat.mixedTitle(cv.targetJobTitle,
                                english: english),
                            textAlign: TextAlign.start,
                            style: AppTextStyles.bodySm()),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _MetaChip(
                                label: cv.language == 'ar' ? 'عربي' : 'English',
                                color: context.sirati.primary),
                            const SizedBox(width: 5),
                            Text(_dateLabel(cv.createdAt, english: english),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.sirati.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('${cv.scoreTotal}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: color)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cv.grade,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

String _dateLabel(DateTime? date, {required bool english}) {
  if (date == null) return '-';
  return AppFormat.relativeTime(date, english: english);
}
