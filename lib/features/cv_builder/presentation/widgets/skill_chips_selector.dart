import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sirati/core/utils/bidi_text.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/directional_icon.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

/// Interactive chip-based skill selector with 1-tap contextual suggestions
/// and full two-way synchronization with a [TextEditingController].
class SkillChipsSelector extends StatefulWidget {
  final TextEditingController controller;
  final String targetJobTitle;
  final bool english;
  final List<JobTitle> allJobTitles;
  final bool enabled;

  /// Called after the user adds, removes or clears skills.
  final VoidCallback? onChanged;

  const SkillChipsSelector({
    super.key,
    required this.controller,
    required this.targetJobTitle,
    required this.english,
    this.allJobTitles = const [],
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<SkillChipsSelector> createState() => _SkillChipsSelectorState();
}

class _SkillChipsSelectorState extends State<SkillChipsSelector> {
  final TextEditingController _newSkillCtrl = TextEditingController();
  final FocusNode _newSkillFocus = FocusNode();
  List<String> _skills = [];
  bool _isUpdatingInternally = false;

  @override
  void initState() {
    super.initState();
    _skills = _parseSkills(widget.controller.text);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SkillChipsSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _skills = _parseSkills(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _newSkillCtrl.dispose();
    _newSkillFocus.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_isUpdatingInternally) return;
    final parsed = _parseSkills(widget.controller.text);
    if (_listsEqual(_skills, parsed)) return;
    setState(() => _skills = parsed);
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<String> _parseSkills(String text) {
    if (text.trim().isEmpty) return [];
    final split = text.split(RegExp(r'[,،\n]+'));
    final result = <String>[];
    final seen = <String>{};

    for (final item in split) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (!seen.contains(key)) {
        seen.add(key);
        result.add(trimmed);
      }
    }
    return result;
  }

  void _syncToController() {
    _isUpdatingInternally = true;
    widget.controller.text = _skills.join(', ');
    _isUpdatingInternally = false;
    widget.onChanged?.call();
  }

  void _addSkill(String skill) {
    final trimmed = skill.trim();
    if (trimmed.isEmpty) return;
    final exists = _skills.any((s) => s.toLowerCase() == trimmed.toLowerCase());
    if (exists) return;

    HapticFeedback.selectionClick();
    setState(() {
      _skills.add(trimmed);
      _syncToController();
    });
  }

  void _removeSkill(int index) {
    if (index < 0 || index >= _skills.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _skills.removeAt(index);
      _syncToController();
    });
  }

  void _submitCustomSkill() {
    final text = _newSkillCtrl.text.trim();
    if (text.isEmpty) return;
    // User might paste multiple comma-separated skills in the custom field
    final parts = _parseSkills(text);
    for (final p in parts) {
      _addSkill(p);
    }
    _newSkillCtrl.clear();
  }

  List<String> _computeSuggestions() {
    final title = widget.targetJobTitle.trim().toLowerCase();
    final suggestions = <String>[];
    final seen = <String>{};

    // Keywords of the matching job titles from the server taxonomy only, so
    // every suggestion is editable in the admin.
    if (widget.allJobTitles.isNotEmpty && title.isNotEmpty) {
      for (final jt in widget.allJobTitles) {
        if (jt.nameAr.toLowerCase().contains(title) ||
            jt.nameEn.toLowerCase().contains(title) ||
            title.contains(jt.nameAr.toLowerCase()) ||
            title.contains(jt.nameEn.toLowerCase())) {
          for (final kw in jt.keywords) {
            final t = kw.trim();
            if (t.isNotEmpty && !seen.contains(t.toLowerCase())) {
              seen.add(t.toLowerCase());
              suggestions.add(t);
            }
          }
        }
      }
    }

    // Filter out skills already selected
    final currentSelectedKeys = _skills.map((s) => s.toLowerCase()).toSet();
    return suggestions
        .where((s) => !currentSelectedKeys.contains(s.toLowerCase()))
        .take(12)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final english = widget.english;
    final suggested = _computeSuggestions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Active Skills Cloud ─────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppFormStyles.radius),
            border: Border.all(color: c.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)
                        .cvSkillsSelectedCount(_skills.length),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  if (_skills.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        foregroundColor: c.red,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _skills.clear();
                          _syncToController();
                        });
                      },
                      child: Text(
                        AppLocalizations.of(context).cvSkillsClearAll,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (_skills.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    AppLocalizations.of(context).cvSkillsEmpty,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.asMap().entries.map((entry) {
                    final index = entry.key;
                    final skill = entry.value;
                    final display =
                        english ? skill : BidiText.protectLatinTokens(skill);

                    return Container(
                      key: ValueKey('selected_skill_$index'),
                      padding: const EdgeInsetsDirectional.only(
                        start: 10,
                        end: 4,
                        top: 4,
                        bottom: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: c.primary.withValues(alpha: .2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            display,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: c.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: widget.enabled
                                ? () => _removeSkill(index)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: c.primaryDark.withValues(alpha: .8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              // Quick Custom Add Field
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _newSkillCtrl,
                        focusNode: _newSkillFocus,
                        enabled: widget.enabled,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submitCustomSkill(),
                        style: TextStyle(fontSize: 13, color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context).cvSkillsInputHint,
                          hintStyle: TextStyle(fontSize: 12, color: c.textHint),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: c.surfaceLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: c.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: c.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: c.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: widget.enabled ? _submitCustomSkill : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        AppLocalizations.of(context).addItem,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 1-Tap Suggested Skills ──────────────────────────────────────────
        if (suggested.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: c.primary),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).cvSkillsSuggested,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: c.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: suggested.map((skill) {
              final display =
                  english ? skill : BidiText.protectLatinTokens(skill);

              return ActionChip(
                key: ValueKey('suggested_skill_$skill'),
                onPressed: widget.enabled ? () => _addSkill(skill) : null,
                backgroundColor: c.surface,
                side: BorderSide(color: c.primary.withValues(alpha: .3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                avatar: DirectionalIcon(
                  Icons.add_rounded,
                  size: 15,
                  color: c.primary,
                ),
                label: Text(
                  display,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
