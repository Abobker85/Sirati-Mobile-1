import 'package:flutter/material.dart';
import 'package:sirati/core/utils/app_locale.dart';
import 'package:sirati/core/utils/bidi_text.dart';
import 'package:sirati/l10n/generated/app_localizations.dart';
import 'package:sirati/shared/models/job_title.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

/// Searchable job-title selector used on register + profile screens.
class JobTitlePickerField extends StatelessWidget {
  final List<JobTitle> titles;
  final JobTitle? value;
  final ValueChanged<JobTitle?> onChanged;

  /// Called with the typed search text when the user picks "enter manually"
  /// from an empty search result; [onChanged] has already received "Other".
  final ValueChanged<String>? onManualEntry;
  final bool english;
  final bool enabled;
  final bool submitted;
  final String? errorText;
  final bool loading;

  const JobTitlePickerField({
    super.key,
    required this.titles,
    required this.value,
    required this.onChanged,
    required this.english,
    this.onManualEntry,
    this.enabled = true,
    this.submitted = false,
    this.errorText,
    this.loading = false,
  });

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled || loading) return;

    final selected = await showModalBottomSheet<JobTitle?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.sirati.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _JobTitlePickerSheet(
        titles: titles,
        selected: value,
        english: english,
      ),
    );

    if (selected == null && value == null) return;
    // Bottom sheet pop without selection returns null — ignore unless user
    // explicitly clears via the clear action inside the sheet (sentinel).
    if (selected is _ClearJobTitle) {
      onChanged(null);
      return;
    }
    if (selected is _ManualJobTitle) {
      onChanged(selected.other);
      onManualEntry?.call(selected.query);
      return;
    }
    if (selected != null) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = value?.label(english: english);
    final subtitle = value?.subtitle(english: english);
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: enabled && !loading ? () => _openPicker(context) : null,
          borderRadius: BorderRadius.circular(AppFormStyles.radius),
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              filled: true,
              fillColor: context.sirati.surface,
              hintText: AppLocalizations.of(context).sharedJobTitleSelectHint,
              prefixIcon: const Icon(Icons.work_outline_rounded),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.sirati.textHint,
                    ),
              enabled: enabled && !loading,
              errorText: hasError ? errorText : null,
              errorMaxLines: 100,
            ),
            child: value == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BidiText.hasArabic(label ?? '')
                            ? (label ?? '')
                            : BidiText.isolateLtr(label ?? ''),
                        textAlign: TextAlign.start,
                        style: AppTypography.of(context, AppTypography.bodyLg),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          BidiText.isolateLtr(subtitle),
                          textAlign: TextAlign.start,
                          style: AppTypography.of(context, AppTypography.bodySm,
                              color: context.sirati.textSecondary),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Sentinel returned when the user clears the selection from the sheet.
class _ClearJobTitle extends JobTitle {
  const _ClearJobTitle()
      : super(
          id: -1,
          slug: '__clear__',
          nameAr: '',
          nameEn: '',
          category: '',
          keywords: const [],
          sortOrder: 0,
        );
}

/// Returned when the user chooses to type a title the search did not find.
class _ManualJobTitle extends JobTitle {
  final JobTitle other;
  final String query;

  _ManualJobTitle(this.other, this.query)
      : super(
          id: other.id,
          slug: other.slug,
          nameAr: other.nameAr,
          nameEn: other.nameEn,
          category: other.category,
          keywords: other.keywords,
          sortOrder: other.sortOrder,
        );
}

class _JobTitlePickerSheet extends StatefulWidget {
  final List<JobTitle> titles;
  final JobTitle? selected;
  final bool english;

  const _JobTitlePickerSheet({
    required this.titles,
    required this.selected,
    required this.english,
  });

  @override
  State<_JobTitlePickerSheet> createState() => _JobTitlePickerSheetState();
}

class _JobTitlePickerSheetState extends State<_JobTitlePickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<JobTitle> get _filtered {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return widget.titles;
    return widget.titles
        .where((t) => t.searchBlob().contains(q))
        .toList(growable: false);
  }

  JobTitle? get _otherTitle {
    for (final t in widget.titles) {
      if (t.isOther) return t;
    }
    return null;
  }

  Widget _noMatches(BuildContext context, AppLocalizations l10n) {
    final query = _query.text.trim();
    final other = _otherTitle;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l10n.sharedJobTitleNoMatches,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.sirati.textSecondary),
          ),
        ),
        if (other != null && query.isNotEmpty)
          ListTile(
            leading:
                Icon(Icons.edit_outlined, color: context.sirati.primaryInk),
            title: Text(
              l10n.sharedJobTitleEnterManually(
                BidiText.hasArabic(query) ? query : BidiText.isolateLtr(query),
              ),
              textAlign: TextAlign.start,
              style: AppTypography.of(context, AppTypography.bodyLg,
                  color: context.sirati.primaryInk),
            ),
            onTap: () => Navigator.pop(context, _ManualJobTitle(other, query)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = _filtered;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.sirati.borderStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.sharedJobTitleSheetTitle,
                        textAlign: TextAlign.start,
                        style: AppTextStyles.titleMd(
                          context.sirati,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (widget.selected != null)
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, const _ClearJobTitle()),
                        child: Text(l10n.sharedClear),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppTextFormField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.start,
                  hintText: l10n.sharedJobTitleSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? _noMatches(context, l10n)
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: context.sirati.border),
                        itemBuilder: (context, index) {
                          final title = filtered[index];
                          final selected = widget.selected?.id == title.id;
                          final subtitle =
                              title.subtitle(english: widget.english);
                          return ListTile(
                            selected: selected,
                            selectedColor: context.sirati.primaryInk,
                            title: Text(
                              title.label(english: widget.english),
                              textAlign: TextAlign.start,
                              style: AppTypography.of(
                                  context, AppTypography.bodyLg,
                                  color: selected
                                      ? context.sirati.primaryInk
                                      : context.sirati.textPrimary),
                            ),
                            subtitle: subtitle == null
                                ? null
                                : Text(
                                    BidiText.isolateLtr(subtitle),
                                    textAlign: TextAlign.start,
                                  ),
                            trailing: selected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: context.sirati.primaryInk,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, title),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
