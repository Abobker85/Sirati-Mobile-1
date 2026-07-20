import 'package:flutter/material.dart';

import '../app_locale.dart';
import '../services/api_exception.dart';
import '../services/mobile_content_service.dart';
import '../services/session_cache.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/form_fields.dart';
import '../widgets/loading/app_async_body.dart';
import '../widgets/loading/app_skeleton.dart';
import '../widgets/motion.dart';
import '../widgets/score_booster_card.dart';
import '../widgets/screen_header.dart';
import 'education_detail_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String _selectedType = 'study';
  Future<Map<String, dynamic>>? _future;
  bool? _loadedEnglish;
  String? _loadedType;

  final _fieldOfStudyCtrl = TextEditingController();
  late final ScoreBoosterController _booster;

  @override
  void initState() {
    super.initState();
    _booster = ScoreBoosterController(
      fieldWeights: const {
        'name': 25,
        'role': 30,
        'study': 15,
        'content': 30,
      },
      tipForIncomplete: _tipFor,
    );
  }

  @override
  void dispose() {
    _fieldOfStudyCtrl.dispose();
    _booster.dispose();
    super.dispose();
  }

  ScoreBoosterTip? _tipFor(List<String> incomplete) {
    final english = AppLocale.isEnglish(context);
    if (incomplete.isEmpty) {
      return ScoreBoosterTip(
        message: english
            ? 'Great work — your education profile is ready for ATS scanners.'
            : 'عمل رائع — ملفك التعليمي جاهز لأنظمة ATS.',
        boostPoints: 0,
        icon: Icons.verified_rounded,
      );
    }
    switch (incomplete.first) {
      case 'study':
        return ScoreBoosterTip(
          message: english
              ? 'Adding your field of study will boost your ATS discoverability by +15 points!'
              : 'إضافة تخصصك الدراسي سترفع قابلية اكتشاف سيرتك في أنظمة ATS بمقدار +15 نقطة!',
          boostPoints: 15,
          icon: Icons.school_outlined,
        );
      case 'role':
        return ScoreBoosterTip(
          message: english
              ? 'Set a target role to tailor learning content — about +30 readiness points.'
              : 'حدّد المسمى المستهدف لتخصيص المحتوى — نحو +30 نقطة جاهزية.',
          boostPoints: 30,
          icon: Icons.work_outline_rounded,
        );
      case 'name':
        return ScoreBoosterTip(
          message: english
              ? 'Complete your profile name so learning tips feel personal (+25).'
              : 'أكمل اسم ملفك ليبدو التعلّم شخصياً (+25).',
          boostPoints: 25,
          icon: Icons.person_outline_rounded,
        );
      case 'content':
      default:
        return ScoreBoosterTip(
          message: english
              ? 'Open a study card to deepen skills recruiters search for (+30).'
              : 'افتح بطاقة دراسية لتعميق مهارات يبحث عنها مسؤولو التوظيف (+30).',
          boostPoints: 30,
          icon: Icons.menu_book_outlined,
        );
    }
  }

  void _syncBooster({
    required String name,
    required String targetRole,
    required bool openedContent,
  }) {
    _booster.setAll({
      'name': name.trim().isNotEmpty,
      'role': targetRole.trim().isNotEmpty,
      'study': _fieldOfStudyCtrl.text.trim().length >= 2,
      'content': openedContent,
    });
  }

  void _ensureFuture(bool english) {
    if (_future == null ||
        _loadedEnglish != english ||
        _loadedType != _selectedType) {
      _loadedEnglish = english;
      _loadedType = _selectedType;
      _future = MobileContentService().education(english, type: _selectedType);
    }
  }

  void _selectType(String type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      _future = null;
    });
  }

  void _retry(bool english) {
    setState(() {
      _loadedEnglish = english;
      _loadedType = _selectedType;
      _future = MobileContentService()
          .education(english, type: _selectedType, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final english = AppLocale.isEnglish(context);
    _ensureFuture(english);

    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
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
                onRetry: () => _retry(english),
                fallbackOnEmptyError: _fallback(english),
                errorMessage: (error) => error is ApiException
                    ? error.displayMessage
                    : (english
                        ? 'Could not load education content.'
                        : 'تعذر تحميل محتوى التعلم.'),
                loading: shell(
                  EducationSkeleton(horizontalPadding: horizontalPadding),
                ),
                builder: (data) {
                  final profile = _map(data['profile']);
                  final tabs = _list(data['tabs']);
                  final cards = _list(data['study_cards']);
                  final cachedName =
                      SessionCache.instance.user.value?.name.trim() ?? '';
                  final name = _text(profile['name'], cachedName);
                  final targetRole = _text(
                    data['target_role'] ?? profile['target_role'],
                    '',
                  );

                  // Keep booster in sync without rebuilding the whole list.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _syncBooster(
                      name: name,
                      targetRole: targetRole,
                      openedContent: false,
                    );
                  });

                  return shell(
                    ScoreBoosterScaffold(
                      controller: _booster,
                      bottomInset: AppSpacing.scrollBottomNav - 48,
                      body: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          18,
                          0,
                          AppSpacing.scrollBottomNav + 100,
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            child: ScreenHeader(
                              english: english,
                              title: AppLocale.greeting(name, context),
                              titleSize: 22,
                              avatarLabel: BidiText.avatarInitial(name),
                              unreadCount: SessionCache.instance.unreadCount,
                              onNotifications: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationsScreen()),
                              ),
                              onAvatarTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl + 6),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            child: _EducationHero(
                              english: english,
                              title: _text(
                                  data['title'],
                                  english
                                      ? 'Learning & Development'
                                      : 'التعلم والتطوير'),
                              subtitle: _text(
                                  data['subtitle'],
                                  english
                                      ? 'Content tailored to your target job'
                                      : 'محتوى مخصص حسب وظيفتك المستهدفة'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            child: _EducationTabs(
                              tabs: tabs,
                              selectedType:
                                  _text(data['selected_type'], _selectedType),
                              onSelect: _selectType,
                              english: english,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Quick boost field — blur-validated, feeds ScoreBooster.
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            child: AutofillGroup(
                              child: AppTextFormField(
                                controller: _fieldOfStudyCtrl,
                                labelText: english
                                    ? 'Field of study'
                                    : 'التخصص الدراسي',
                                hintText: english
                                    ? 'e.g. Computer Science'
                                    : 'مثال: علوم الحاسب',
                                autofillHints: const [
                                  AutofillHints.organizationName,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context).unfocus(),
                                prefixIcon:
                                    const Icon(Icons.school_outlined),
                                showSuccessWhenValid: true,
                                successMessage: english
                                    ? 'Nice — ATS loves clear majors'
                                    : 'ممتاز — أنظمة ATS تفضّل التخصص الواضح',
                                validator: (v) {
                                  final t = v?.trim() ?? '';
                                  if (t.isEmpty) {
                                    return english
                                        ? 'Add your field of study'
                                        : 'أضف تخصصك الدراسي';
                                  }
                                  if (t.length < 2) {
                                    return english
                                        ? 'Enter at least 2 characters'
                                        : 'أدخل حرفين على الأقل';
                                  }
                                  return null;
                                },
                                onBecameValid: (_) {
                                  _booster.setFieldComplete('study', true);
                                },
                                onChanged: (v) {
                                  if (v.trim().length < 2) {
                                    _booster.setFieldComplete('study', false);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (cards.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding),
                              child: AppEmptyState(
                                icon: Icons.school_outlined,
                                title: english
                                    ? 'No content in this tab'
                                    : 'لا يوجد محتوى في هذا القسم',
                                subtitle: english
                                    ? 'Try another category or check back later.'
                                    : 'جرّب قسماً آخر أو عد لاحقاً.',
                                scrollable: false,
                              ),
                            )
                          else
                            for (var index = 0;
                                index < cards.length;
                                index++) ...[
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding),
                                child: MotionReveal(
                                  order: index.clamp(0, 5),
                                  child: _StudyCard(
                                    id: _int(cards[index]['id']),
                                    title: _text(cards[index]['title'], ''),
                                    duration:
                                        _text(cards[index]['duration'], ''),
                                    badge: _text(
                                      data['target_label'],
                                      english
                                          ? 'Based on your target job'
                                          : 'حسب وظيفتك المستهدفة',
                                    ),
                                    english: english,
                                    onTap: () {
                                      _booster.setFieldComplete(
                                          'content', true);
                                      _openDetail(context, cards[index]);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm + 2),
                            ],
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

/// Chrome + empty lists only — no fake profile, role, or study items.
Map<String, dynamic> _fallback(bool english) => {
      'profile': const <String, dynamic>{},
      'title': english ? 'Learning & Development' : 'التعلم والتطوير',
      'subtitle': english
          ? 'Content tailored to your target job'
          : 'محتوى مخصص حسب وظيفتك المستهدفة',
      'target_label':
          english ? 'Based on your target job' : 'حسب وظيفتك المستهدفة',
      'tabs': [
        {'label': english ? 'News' : 'أخبار'},
        {'label': english ? 'Certificates' : 'شهادات'},
        {'label': english ? 'Study' : 'دراسة'},
      ],
      'study_cards': const <Map<String, dynamic>>[],
    };

Map<String, dynamic> _map(dynamic value) =>
    value is Map<String, dynamic> ? value : const {};

List<Map<String, dynamic>> _list(dynamic value) =>
    value is List ? value.map(_map).toList() : const [];

String _text(dynamic value, String fallback) =>
    (value?.toString().isNotEmpty ?? false) ? value.toString() : fallback;

int? _int(dynamic value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

void _openDetail(BuildContext context, Map<String, dynamic> data) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EducationDetailScreen(
        id: _int(data['id']),
        fallback: data,
      ),
    ),
  );
}

class _EducationHero extends StatelessWidget {
  final bool english;
  final String title;
  final String subtitle;

  const _EducationHero({
    required this.english,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: AppTextStyles.titleLg(context.sirati).copyWith(
            fontSize: 21,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.start,
          style: AppTextStyles.bodySm(context.sirati).copyWith(
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _EducationTabs extends StatelessWidget {
  final List<Map<String, dynamic>> tabs;
  final String selectedType;
  final ValueChanged<String> onSelect;
  final bool english;

  const _EducationTabs({
    required this.tabs,
    required this.selectedType,
    required this.onSelect,
    required this.english,
  });

  static const _typeKeys = ['news', 'certificates', 'study'];

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final items = tabs.isEmpty
        ? [
            {'label': english ? 'News' : 'أخبار', 'type': 'news'},
            {
              'label': english ? 'Certificates' : 'شهادات',
              'type': 'certificates'
            },
            {'label': english ? 'Study' : 'دراسة', 'type': 'study'},
          ]
        : [
            for (var i = 0; i < tabs.length; i++)
              {
                'label': _text(tabs[i]['label'], ''),
                'type': _text(
                  tabs[i]['type'],
                  i < _typeKeys.length ? _typeKeys[i] : 'study',
                ),
              },
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in items) ...[
            PressScale(
              child: FilterChip(
                selected: selectedType == item['type'],
                label: Text(item['label'] as String),
                onSelected: (_) => onSelect(item['type'] as String),
                selectedColor: c.primaryLight,
                checkmarkColor: c.primaryDark,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selectedType == item['type']
                      ? c.primaryDark
                      : c.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  final int? id;
  final String title;
  final String duration;
  final String badge;
  final bool english;
  final VoidCallback onTap;

  const _StudyCard({
    required this.id,
    required this.title,
    required this.duration,
    required this.badge,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
            boxShadow: c.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge.isNotEmpty)
                Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                ),
              if (badge.isNotEmpty) const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.start,
                style: AppTextStyles.titleMd(c).copyWith(height: 1.5),
              ),
              if (duration.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  duration,
                  style: AppTextStyles.bodySm(c),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
