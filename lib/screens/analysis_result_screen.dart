import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../app_locale.dart';
import '../models/ai_status.dart';
import '../models/cv_analysis.dart';
import '../services/api_exception.dart';
import '../services/cv_api_service.dart';
import '../services/mobile_content_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snack_bar.dart';
import '../widgets/animated_ats_score_bar.dart';
import '../widgets/language_toggle.dart';
import '../widgets/loading/ai_progress_overlay.dart';
import '../widgets/motion.dart';
import '../widgets/submit_button.dart';
import 'generated_cv_screen.dart';

class AnalysisResultScreen extends StatefulWidget {
  final CvAnalysis analysis;
  final CvApiService? apiService;

  const AnalysisResultScreen({
    super.key,
    required this.analysis,
    this.apiService,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen>
    with WidgetsBindingObserver {
  late final CvApiService _apiService = widget.apiService ?? CvApiService();
  final ValueNotifier<bool> _isGenerating = ValueNotifier<bool>(false);
  bool _pollingPaused = false;
  int _aiRequestGen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _pollingPaused = state != AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isGenerating.dispose();
    super.dispose();
  }

  Future<void> _generateImprovedCv() async {
    final english = AppLocale.isEnglish(context);
    final requestId = ++_aiRequestGen;
    _isGenerating.value = true;
    final progress = await AiProgressOverlay.show(
      context,
      kind: AiProgressKind.generation,
      english: english,
      onCancelled: () {
        if (_aiRequestGen == requestId) _aiRequestGen++;
        if (mounted) _isGenerating.value = false;
      },
    );

    try {
      var generatedCv = await _apiService.generateCvFromAnalysis(
        analysisId: widget.analysis.id,
        overrides: const {},
      );
      final poll = await _apiService.pollGeneratedCv(
        generatedCv,
        isCancelled: () => progress.isCancelled || requestId != _aiRequestGen,
        isPaused: () => _pollingPaused,
      );
      generatedCv = poll.value;

      if (!mounted ||
          poll.cancelled ||
          progress.isCancelled ||
          requestId != _aiRequestGen) {
        return;
      }
      await progress.dismiss();
      if (!mounted) return;
      if (poll.timedOut) {
        AppSnackBar.warning(
          context,
          english
              ? 'AI is still working. A usable local CV is ready, and you can retry generation later.'
              : 'لا يزال الذكاء الاصطناعي يعمل. نسخة محلية من سيرتك جاهزة، ويمكنك إعادة محاولة التوليد لاحقاً.',
        );
      } else if (generatedCv.aiStatus == AiStatus.failed) {
        AppSnackBar.error(
          context,
          english
              ? 'AI generation could not be completed: ${generatedCv.aiError ?? 'Please try again.'}'
              : 'تعذر إكمال توليد السيرة بالذكاء الاصطناعي: ${generatedCv.aiError ?? 'يرجى المحاولة مرة أخرى.'}',
          actionLabel: english ? 'Retry' : 'إعادة المحاولة',
          onAction: _generateImprovedCv,
        );
      }
      MobileContentService.invalidateCvRelated();
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => GeneratedCvScreen(generatedCv: generatedCv)),
      );
    } on ApiException catch (exception) {
      if (mounted) AppSnackBar.fromException(context, exception);
    } catch (_) {
      if (mounted) {
        final english = AppLocale.isEnglish(context);
        AppSnackBar.error(
          context,
          english
              ? 'An unexpected error occurred while generating the CV.'
              : 'حدث خطأ غير متوقع أثناء توليد السيرة.',
        );
      }
    } finally {
      await progress.dismiss();
      if (mounted && requestId == _aiRequestGen && !progress.isCancelled) {
        _isGenerating.value = false;
      }
    }
  }

  void _shareAnalysis(bool english) {
    final analysis = widget.analysis;
    Share.share(_shareText(analysis, english));
  }

  String _shareText(CvAnalysis analysis, bool english) {
    final foundKeywords = analysis.keywordsFound.take(8).join(', ');
    final missingKeywords = analysis.keywordsMissing.take(8).join(', ');
    final strengths =
        analysis.strengths.take(3).map((item) => '- $item').join('\n');
    final quickWins =
        analysis.quickWins.take(3).map((item) => '- $item').join('\n');

    if (english) {
      return [
        'Sirati CV Analysis',
        '',
        'Target role: ${analysis.targetJobTitle}',
        'ATS score: ${analysis.scoreTotal}/100 (${analysis.grade})',
        'Job match: ${analysis.jobMatch}%',
        if (foundKeywords.isNotEmpty) 'Keywords found: $foundKeywords',
        if (missingKeywords.isNotEmpty) 'Missing keywords: $missingKeywords',
        if (strengths.isNotEmpty) ...['', 'Strengths:', strengths],
        if (quickWins.isNotEmpty) ...['', 'Quick wins:', quickWins],
      ].join('\n');
    }

    return [
      'تحليل السيرة من سيرتي',
      '',
      'الوظيفة المستهدفة: ${analysis.targetJobTitle}',
      'درجة ATS: ${analysis.scoreTotal}/100 (${analysis.grade})',
      'نسبة التطابق: ${analysis.jobMatch}%',
      if (foundKeywords.isNotEmpty) 'الكلمات الموجودة: $foundKeywords',
      if (missingKeywords.isNotEmpty) 'الكلمات الناقصة: $missingKeywords',
      if (strengths.isNotEmpty) ...['', 'نقاط القوة:', strengths],
      if (quickWins.isNotEmpty) ...['', 'تحسينات سريعة:', quickWins],
    ].join('\n');
  }

  Color _scoreColor(int s) {
    if (s >= 80) return context.sirati.tealDark;
    if (s >= 65) return context.sirati.primary;
    if (s >= 50) return context.sirati.amber;
    return context.sirati.red;
  }

  Color _scoreTrack(int s) {
    if (s >= 80) return context.sirati.tealLight;
    if (s >= 65) return context.sirati.primaryLight;
    if (s >= 50) return context.sirati.amberLight;
    return context.sirati.redLight;
  }

  String _gradeDesc(int s, bool english) {
    if (s >= 80) {
      return english
          ? 'Excellent - your CV is strong and ready'
          : 'ممتاز - سيرتك قوية ومؤهلة';
    }
    if (s >= 65) {
      return english
          ? 'Very good - a few improvements will help'
          : 'جيد جداً - مع بعض التحسينات';
    }
    if (s >= 50) {
      return english
          ? 'Fair - review and polish needed'
          : 'مقبول - يحتاج مراجعة';
    }
    return english ? 'Weak - needs restructuring' : 'ضعيف - يحتاج إعادة هيكلة';
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final english = AppLocale.isEnglish(context);

    return Directionality(
      textDirection: AppLocale.direction(context),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: context.sirati.background,
          appBar: AppBar(
            title: Text(english ? 'Analysis Results' : 'نتائج التحليل'),
            actions: [
              const LanguageToggle(),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareAnalysis(english),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: english ? 'Score & Criteria' : 'الدرجة والمعايير'),
                Tab(text: english ? 'Recommendations' : 'التوصيات'),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: context.sirati.surface,
                border: Border(top: BorderSide(color: context.sirati.border)),
                boxShadow: context.sirati.softShadow,
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isGenerating,
                builder: (context, isGenerating, _) {
                  return SubmitButton(
                    label: english
                        ? 'Generate Improved CV'
                        : 'توليد سيرة محسّنة بالذكاء الاصطناعي',
                    loadingLabel: english ? 'Generating...' : 'جارٍ التوليد...',
                    isLoading: isGenerating,
                    icon: Icons.auto_awesome_rounded,
                    onPressed: isGenerating ? null : _generateImprovedCv,
                  );
                },
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _ScoreTab(
                score: analysis.scoreTotal,
                grade: analysis.grade,
                jobMatch: analysis.jobMatch,
                jobTitle: analysis.targetJobTitle,
                criteria: analysis.criteria,
                keywordsFound: analysis.keywordsFound,
                keywordsMissing: analysis.keywordsMissing,
                scoreColor: _scoreColor(analysis.scoreTotal),
                scoreTrack: _scoreTrack(analysis.scoreTotal),
                gradeDesc: _gradeDesc(analysis.scoreTotal, english),
                english: english,
              ),
              _RecommendationsTab(
                strengths: analysis.strengths,
                quickWins: analysis.quickWins,
                isGeneratingListenable: _isGenerating,
                onGenerateCv: _generateImprovedCv,
                english: english,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score Tab ─────────────────────────────────────────────────────────────────

class _ScoreTab extends StatelessWidget {
  final int score;
  final String grade;
  final int jobMatch;
  final String jobTitle;
  final List<ScoreCriterion> criteria;
  final List<String> keywordsFound;
  final List<String> keywordsMissing;
  final Color scoreColor;
  final Color scoreTrack;
  final String gradeDesc;
  final bool english;

  const _ScoreTab({
    required this.score,
    required this.grade,
    required this.jobMatch,
    required this.jobTitle,
    required this.criteria,
    required this.keywordsFound,
    required this.keywordsMissing,
    required this.scoreColor,
    required this.scoreTrack,
    required this.gradeDesc,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('analysis-score-tab-list'),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Score Hero ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: context.sirati.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.sirati.border),
          ),
          child: Column(
            children: [
              // Ring — animate once from 0 → score on first paint
              _AnimatedScoreRing(
                score: score,
                scoreColor: scoreColor,
              ),
              const SizedBox(height: 14),
              // Grade badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreTrack,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  english ? 'Grade  $grade' : 'تقدير  $grade',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scoreColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                gradeDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: context.sirati.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 14),
              // Job match row
              Row(
                children: [
                  Icon(
                    Icons.work_outline_rounded,
                    size: 16,
                    color: context.sirati.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      jobTitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.sirati.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.sirati.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$jobMatch%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.sirati.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedAtsScoreBar(
                value: jobMatch / 100,
                color: context.sirati.primary,
                height: 7,
                borderRadius: 6,
                // Primary score: haptic the moment the elastic fill settles.
                celebrateOnComplete: true,
                semanticLabel: english ? 'Job match' : 'تطابق الوظيفة',
              ),
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  english ? 'Job match percentage' : 'نسبة التطابق مع الوظيفة',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.sirati.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Criteria ────────────────────────────────────────────────────────
        SectionTitle(english ? 'Criteria Details' : 'تفاصيل المعايير'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: List.generate(criteria.length, (i) {
              final c = criteria[i];
              final s = c.score.toDouble();
              final m = c.max.toDouble();
              final pct = s / m;
              final Color barColor = pct >= 0.8
                  ? context.sirati.teal
                  : pct >= 0.6
                      ? context.sirati.primary
                      : context.sirati.amber;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.sirati.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${c.score} / ${c.max}',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.sirati.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: barColor.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '${(pct * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: barColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        AnimatedAtsScoreBar(
                          value: pct,
                          color: barColor,
                          height: 6,
                          borderRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  if (i < criteria.length - 1) const Divider(height: 1),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 24),

        // ── Keywords ────────────────────────────────────────────────────────
        SectionTitle(english ? 'Keywords' : 'الكلمات المفتاحية'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Found
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.sirati.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    english
                        ? 'Found  (${keywordsFound.length})'
                        : 'موجودة  (${keywordsFound.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.sirati.tealDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _KeywordGroup(
                keywords: keywordsFound,
                found: true,
                english: english,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 14),
              // Missing
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.sirati.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    english
                        ? 'Missing  (${keywordsMissing.length})'
                        : 'ناقصة  (${keywordsMissing.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.sirati.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _KeywordGroup(
                keywords: keywordsMissing,
                found: false,
                english: english,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Recommendations Tab ───────────────────────────────────────────────────────

class _RecommendationsTab extends StatelessWidget {
  final List<String> strengths;
  final List<String> quickWins;
  final ValueListenable<bool> isGeneratingListenable;
  final VoidCallback onGenerateCv;
  final bool english;

  const _RecommendationsTab({
    required this.strengths,
    required this.quickWins,
    required this.isGeneratingListenable,
    required this.onGenerateCv,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // ── Strengths ────────────────────────────────────────────────────────
        _SectionHeader(
          icon: Icons.thumb_up_alt_rounded,
          iconColor: context.sirati.tealDark,
          iconBg: context.sirati.tealLight,
          label: english ? 'Strengths' : 'نقاط القوة',
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: strengths.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                      english
                          ? 'No strengths are available yet.'
                          : 'لا توجد نقاط قوة متاحة حالياً',
                      style: TextStyle(
                          fontSize: 13, color: context.sirati.textSecondary)),
                )
              : Column(
                  children: List.generate(strengths.length, (i) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: context.sirati.tealLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: context.sirati.tealDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  strengths[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.sirati.textPrimary,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < strengths.length - 1) const Divider(height: 1),
                      ],
                    );
                  }),
                ),
        ),

        const SizedBox(height: 24),

        // ── Quick Wins ────────────────────────────────────────────────────────
        _SectionHeader(
          icon: Icons.bolt_rounded,
          iconColor: context.sirati.amber,
          iconBg: context.sirati.amberLight,
          label: english ? 'Quick Wins' : 'تحسينات سريعة',
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: quickWins.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                      english
                          ? 'No quick wins are available yet.'
                          : 'لا توجد تحسينات سريعة متاحة حالياً',
                      style: TextStyle(
                          fontSize: 13, color: context.sirati.textSecondary)),
                )
              : Column(
                  children: List.generate(quickWins.length, (i) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 1),
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.sirati.amberLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: context.sirati.amber,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  quickWins[i],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.sirati.textPrimary,
                                    height: 1.55,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < quickWins.length - 1) const Divider(height: 1),
                      ],
                    );
                  }),
                ),
        ),

        const SizedBox(height: 28),

        // ── CTA ──────────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.sirati.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.sirati.primaryMid),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.sirati.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 20,
                  color: context.sirati.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      english
                          ? 'Ready to upgrade your CV?'
                          : 'جاهز لترقية سيرتك؟',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.sirati.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      english
                          ? 'We will generate an improved CV from this analysis.'
                          : 'سنولّد لك سيرة ذاتية محسّنة تلقائياً بناءً على نتائج هذا التحليل',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.sirati.primary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: isGeneratingListenable,
          builder: (context, isGenerating, _) {
            return SubmitButton(
              label: english ? 'Generate Improved CV' : 'توليد سيرة محسّنة',
              loadingLabel: english ? 'Generating...' : 'جارٍ التوليد...',
              isLoading: isGenerating,
              icon: Icons.auto_awesome_rounded,
              onPressed: isGenerating ? null : onGenerateCv,
            );
          },
        ),
      ],
    );
  }
}

// ── Shared Private Widgets ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.sirati.textPrimary,
          ),
        ),
      ],
    );
  }
}

void _showKeywordAdvice(
  BuildContext context,
  String keyword,
  bool english,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: context.sirati.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final c = context.sirati;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: c.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      english
                          ? 'ATS Keyword: $keyword'
                          : 'كلمة مفتاحية: $keyword',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                english
                    ? 'Applicant Tracking Systems (ATS) scan for "$keyword" in your work experience and skills. Adding it in context with measurable results will increase your resume ranking.'
                    : 'تبحث أنظمة فرز السير الذاتية (ATS) عن كلمة "$keyword" في قسم الخبرات والمهارات. إضافتها ضمن سياق إنجازاتك المقاسة يرفع نسبة تطابق سيرتك بشكل ملحوظ.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(english ? 'Got it' : 'فهمت ذلك'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _KeywordChip extends StatelessWidget {
  final String label;
  final bool found;
  final VoidCallback? onTap;

  const _KeywordChip({
    required this.label,
    required this.found,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: found ? context.sirati.tealLight : context.sirati.redLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: found
              ? context.sirati.tealDark.withValues(alpha: .18)
              : context.sirati.red.withValues(alpha: .18),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: found ? context.sirati.tealDark : context.sirati.red,
        ),
      ),
    );

    if (onTap == null) return chip;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: chip,
    );
  }
}

class _KeywordGroup extends StatefulWidget {
  final List<String> keywords;
  final bool found;
  final bool english;

  static const initialVisibleCount = 18;

  const _KeywordGroup({
    required this.keywords,
    required this.found,
    required this.english,
  });

  @override
  State<_KeywordGroup> createState() => _KeywordGroupState();
}

class _KeywordGroupState extends State<_KeywordGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.keywords.isEmpty) {
      return Text(
        widget.english ? 'No keywords yet.' : 'لا توجد كلمات مفتاحية حالياً',
        style: TextStyle(fontSize: 12, color: context.sirati.textSecondary),
      );
    }

    final overflowCount =
        widget.keywords.length - _KeywordGroup.initialVisibleCount;
    final visibleKeywords = _expanded || overflowCount <= 0
        ? widget.keywords
        : widget.keywords.take(_KeywordGroup.initialVisibleCount);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final keyword in visibleKeywords)
          _KeywordChip(
            label: keyword,
            found: widget.found,
            onTap: widget.found
                ? null
                : () => _showKeywordAdvice(context, keyword, widget.english),
          ),
        if (overflowCount > 0)
          _KeywordOverflowButton(
            expanded: _expanded,
            remainingCount: overflowCount,
            english: widget.english,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
      ],
    );
  }
}

class _KeywordOverflowButton extends StatelessWidget {
  final bool expanded;
  final int remainingCount;
  final bool english;
  final VoidCallback onPressed;

  const _KeywordOverflowButton({
    required this.expanded,
    required this.remainingCount,
    required this.english,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
      onPressed: onPressed,
      child: Text(
        expanded
            ? (english ? 'Show less' : 'عرض أقل')
            : (english ? '+$remainingCount more' : '+$remainingCount أخرى'),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: context.sirati.primary,
        ),
      ),
    );
  }
}

/// Animates score ring once from 0 → [score] on first appear.
class _AnimatedScoreRing extends StatelessWidget {
  final int score;
  final Color scoreColor;

  const _AnimatedScoreRing({
    required this.score,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final target = (score.clamp(0, 100)) / 100.0;
    final reduce = MotionSettings.reduce(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? target : 0, end: target),
      duration: reduce ? Duration.zero : MotionDurations.slow * 2,
      curve: MotionCurves.enter,
      builder: (context, value, _) {
        final display = (value * 100).round();
        return SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: context.sirati.border,
                valueColor: AlwaysStoppedAnimation(scoreColor),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$display',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.sirati.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
