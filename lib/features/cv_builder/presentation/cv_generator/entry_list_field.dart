import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sirati/features/cv_builder/domain/cv_entries.dart';
import 'package:sirati/shared/theme/app_theme.dart';
import 'package:sirati/shared/widgets/form_fields.dart';

/// A list of entry cards that reads and writes one wizard text field
/// (Salem review, issue 3: experience and education like a job application).
///
/// The text field stays the source of truth (drafts, API payload, AI
/// enhancement and the achievement builder all use it); the cards are a
/// structured view of it. Edits are written back in the shape the server
/// parses into CV entries; outside changes to the text are read back in.
class EntryListField<T> extends StatefulWidget {
  const EntryListField({
    super.key,
    required this.controller,
    required this.english,
    required this.parse,
    required this.serialize,
    required this.problems,
    required this.blank,
    required this.isBlank,
    required this.cardBuilder,
    required this.addLabel,
    required this.autovalidateMode,
    this.minimumCount = 1,
    this.minimumCharacters,
  });

  final TextEditingController controller;
  final bool english;
  final List<T> Function(String text) parse;
  final String Function(List<T> entries) serialize;
  final Set<EntryProblem> Function(T entry) problems;
  final T blank;
  final bool Function(T entry) isBlank;
  final Widget Function(
    BuildContext context,
    T entry,
    ValueChanged<T> onChanged,
    Set<EntryProblem> problems,
  ) cardBuilder;
  final String addLabel;
  final AutovalidateMode autovalidateMode;

  /// Complete entries required; 0 makes the section optional.
  final int minimumCount;

  /// Shortest accepted text overall (the API's own minimum).
  final int? minimumCharacters;

  @override
  State<EntryListField<T>> createState() => _EntryListFieldState<T>();
}

class _EntryListFieldState<T> extends State<EntryListField<T>> {
  final _field = GlobalKey<FormFieldState<List<T>>>();
  late List<(int, T)> _entries;
  var _nextId = 0;
  String _written = '';

  /// Only shown once the user tried to continue (or edited after that).
  bool _showProblems = false;

  @override
  void initState() {
    super.initState();
    _readText();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant EntryListField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _readText();
    }
    if (widget.autovalidateMode != AutovalidateMode.disabled) {
      _showProblems = true;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _readText() {
    final parsed = widget.parse(widget.controller.text);
    _entries = [
      for (final entry in parsed.isEmpty ? [widget.blank] : parsed)
        (_nextId++, entry),
    ];
    _written = widget.controller.text;
  }

  /// Text changed outside the cards (draft restore, AI, achievement builder).
  void _onTextChanged() {
    if (widget.controller.text == _written) return;
    setState(_readText);
    _field.currentState?.didChange(_values);
  }

  List<T> get _values => [for (final (_, e) in _entries) e];

  void _write() {
    _written = widget.serialize(_values);
    if (widget.controller.text != _written) widget.controller.text = _written;
    _field.currentState?.didChange(_values);
  }

  void _update(int id, T entry) {
    setState(() {
      _entries = [
        for (final (i, e) in _entries) i == id ? (i, entry) : (i, e),
      ];
    });
    _write();
  }

  void _add() {
    setState(() => _entries = [..._entries, (_nextId++, widget.blank)]);
    HapticFeedback.selectionClick();
  }

  void _remove(int id) {
    setState(() {
      _entries = [
        for (final entry in _entries)
          if (entry.$1 != id) entry,
      ];
      if (_entries.isEmpty) _entries = [(_nextId++, widget.blank)];
    });
    _write();
  }

  String? _validate(List<T>? _) {
    final english = widget.english;
    final filled = _values.where((e) => !widget.isBlank(e)).toList();
    if (filled.any((e) => widget.problems(e).isNotEmpty)) {
      return english
          ? 'Complete the highlighted fields.'
          : 'أكمل الحقول المحددة.';
    }
    if (filled.length < widget.minimumCount) {
      return english
          ? 'Add at least one entry.'
          : 'أضف إدخالاً واحداً على الأقل.';
    }
    final minimum = widget.minimumCharacters;
    if (minimum != null && widget.serialize(_values).length < minimum) {
      return english
          ? 'Add a little more detail: what you did and what it achieved.'
          : 'أضف تفاصيل أكثر: ماذا أنجزت وما النتيجة.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return FormField<List<T>>(
      key: _field,
      initialValue: _values,
      autovalidateMode: widget.autovalidateMode,
      validator: (value) {
        final error = _validate(value);
        if (error != null && !_showProblems) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _showProblems = true);
          });
        }
        return error;
      },
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, (id, entry)) in _entries.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            _EntryCard(
              key: ValueKey('entry-$id'),
              index: index,
              english: widget.english,
              onRemove: _entries.length > 1 || !widget.isBlank(entry)
                  ? () => _remove(id)
                  : null,
              child: widget.cardBuilder(
                context,
                entry,
                (next) => _update(id, next),
                _showProblems && !widget.isBlank(entry)
                    ? widget.problems(entry)
                    : const {},
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('entry-add'),
            onPressed: _add,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: c.primaryInk,
              side: BorderSide(color: c.primaryInk),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(widget.addLabel),
          ),
          if (state.hasError) ...[
            const SizedBox(height: 8),
            Text(
              state.errorText!,
              style: TextStyle(color: c.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.index,
    required this.english,
    required this.onRemove,
    required this.child,
  });

  final int index;
  final bool english;
  final VoidCallback? onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    // Material, not a decorated box: the "currently" tile paints its ink on it.
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: c.primaryInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    key: ValueKey('entry-remove-$index'),
                    tooltip: english ? 'Remove' : 'حذف',
                    onPressed: onRemove,
                    icon: Icon(Icons.delete_outline_rounded, color: c.error),
                  ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// A text input inside an entry card. Keeps its own controller so typing
/// never fights the rebuilt entry value.
class EntryTextInput extends StatefulWidget {
  const EntryTextInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.hint,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final String? hint;
  final int maxLines;

  @override
  State<EntryTextInput> createState() => _EntryTextInputState();
}

class _EntryTextInputState extends State<EntryTextInput> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant EntryTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextFormField(
            controller: _controller,
            labelText: widget.label,
            hintText: widget.hint,
            textAlign: TextAlign.start,
            minLines: widget.maxLines > 1 ? 3 : 1,
            maxLines: widget.maxLines,
            keyboardType: widget.maxLines > 1 ? TextInputType.multiline : null,
            textInputAction: widget.maxLines > 1
                ? TextInputAction.newline
                : TextInputAction.next,
            onChanged: widget.onChanged,
          ),
          if (widget.error != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 4, start: 4),
              child: Text(
                widget.error!,
                style: TextStyle(color: c.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// Month/year button that opens [showMonthYearPicker].
class MonthYearButton extends StatelessWidget {
  const MonthYearButton({
    super.key,
    required this.label,
    required this.value,
    required this.english,
    required this.onChanged,
    this.enabled = true,
    this.error,
  });

  final String label;
  final YearMonth? value;
  final bool english;
  final ValueChanged<YearMonth> onChanged;
  final bool enabled;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.sirati;
    final text = value == null
        ? (english ? 'Choose' : 'اختر')
        : monthYearLabel(value!, english: english);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: TextStyle(color: c.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: enabled
                ? () async {
                    final picked = await showMonthYearPicker(
                      context,
                      initial: value,
                      english: english,
                    );
                    if (picked != null) onChanged(picked);
                  }
                : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              alignment: AlignmentDirectional.centerStart,
              foregroundColor: c.textPrimary,
              disabledForegroundColor: c.textSecondary,
              side: BorderSide(color: error != null ? c.error : c.borderStrong),
            ),
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(text),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child:
                  Text(error!, style: TextStyle(color: c.error, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

const _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsAr = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', //
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String monthYearLabel(YearMonth value, {required bool english}) {
  final month = value.month;
  if (month == null) return '${value.year}';
  return '${(english ? _monthsEn : _monthsAr)[month - 1]} ${value.year}';
}

/// Month and year in one dialog: a year dropdown and a grid of months.
Future<YearMonth?> showMonthYearPicker(
  BuildContext context, {
  required YearMonth? initial,
  required bool english,
}) {
  final now = DateTime.now();
  var year = initial?.year ?? now.year;
  var month = initial?.month ?? now.month;
  final years = [for (var y = now.year + 6; y >= 1960; y--) y];
  return showDialog<YearMonth>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final c = context.sirati;
        return AlertDialog(
          title: Text(english ? 'Month and year' : 'الشهر والسنة'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  key: const ValueKey('month-year-year'),
                  initialValue: year,
                  items: [
                    for (final y in years)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (y) => setDialogState(() => year = y ?? year),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var m = 1; m <= 12; m++)
                      ChoiceChip(
                        key: ValueKey('month-year-month-$m'),
                        label: Text((english ? _monthsEn : _monthsAr)[m - 1]),
                        selected: month == m,
                        selectedColor: c.primaryLight,
                        onSelected: (_) => setDialogState(() => month = m),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(english ? 'Cancel' : 'إلغاء'),
            ),
            FilledButton(
              key: const ValueKey('month-year-done'),
              onPressed: () =>
                  Navigator.of(context).pop(YearMonth(year, month)),
              child: Text(english ? 'Done' : 'تم'),
            ),
          ],
        );
      },
    ),
  );
}
