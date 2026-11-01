import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/nlp_parser.dart';
import '../../domain/reminder_planner.dart';
import '../../domain/settings.dart';
import '../../ui/labels.dart';

Future<void> showQuickAdd(BuildContext context, {DateTime? day}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => QuickAddSheet(day: day),
  );
}

class QuickAddSheet extends ConsumerStatefulWidget {
  const QuickAddSheet({super.key, this.day});

  final DateTime? day;

  @override
  ConsumerState<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends ConsumerState<QuickAddSheet> {
  final _parser = NlpParser();
  final _focus = FocusNode();
  final _controller = _HighlightController();

  final _disabled = <ParseField>{};
  DateTime? _dayOverride;
  TimeOfDay? _timeOverride;
  (int?,)? _reminderOverride;
  bool _showError = false;
  bool _saving = false;
  String _lastText = '';
  ParsedInput _parsed = const ParsedInput(title: '', spans: []);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// İmleç hareketleri de bildirilir, yalnızca metin değişince çalışır.
  void _onChanged() {
    if (_controller.text == _lastText) return;
    _lastText = _controller.text;
    setState(_reparse);
  }

  void _reparse() {
    _parsed = _parser.parse(
      _controller.text,
      DateTime.now(),
      disabled: _disabled,
    );
    _controller.spans = _parsed.spans;
    if (_parsed.title.isNotEmpty) _showError = false;
  }

  DateTime get _baseDay => widget.day ?? ref.read(todayProvider);

  DateTime get _day =>
      _dayOverride ?? _parsed.resolveDay(_baseDay, DateTime.now());

  TimeOfDay? get _time =>
      _timeOverride ??
      (_parsed.hasTime
          ? TimeOfDay(hour: _parsed.hour!, minute: _parsed.minute!)
          : null);

  int? _reminder(AppSettings settings) => _reminderOverride != null
      ? _reminderOverride!.$1
      : settings.defaultReminderMin;

  Future<void> _pickDay() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: addDays(today, -365),
      lastDate: addDays(today, 365 * 5),
    );
    if (picked != null) setState(() => _dayOverride = picked);
    _focus.requestFocus();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _timeOverride = picked);
    _focus.requestFocus();
  }

  Future<void> _pickReminder(int? current) async {
    final picked = await pickReminder(context, current);
    if (picked != null) setState(() => _reminderOverride = picked);
    _focus.requestFocus();
  }

  void _disable(ParseField field) => setState(() {
    _disabled.add(field);
    if (field == ParseField.date) _dayOverride = null;
    if (field == ParseField.time) _timeOverride = null;
    _reparse();
  });

  Future<void> _save(AppSettings settings) async {
    if (_saving) return;
    final title = _parsed.title;
    if (title.isEmpty) {
      setState(() => _showError = true);
      _focus.requestFocus();
      return;
    }
    _saving = true;
    final day = _day;
    final time = _time;
    await ref
        .read(itemServiceProvider)
        .create(
          title: title.length > 200 ? title.substring(0, 200) : title,
          day: day,
          start: time == null
              ? null
              : DateTime(day.year, day.month, day.day, time.hour, time.minute),
          durationMin: _parsed.durationMin,
          reminderMin: _reminder(settings),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final today = ref.watch(todayProvider);
    _controller.highlight = theme.colorScheme.primary;
    final time = _time;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(settings),
            decoration: InputDecoration(
              hintText: 'yarın 14:00 dişçi',
              border: InputBorder.none,
              counterText: '',
              errorText: _showError ? 'Başlık yaz' : null,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    _chip(
                      label: dayLabel(_day, today),
                      onPressed: _pickDay,
                      onDeleted: _parsed.date != null
                          ? () => _disable(ParseField.date)
                          : null,
                    ),
                    _chip(
                      label: time == null ? 'Saat ekle' : hhmmOf(time),
                      onPressed: _pickTime,
                      onDeleted: time != null
                          ? () => _disable(ParseField.time)
                          : null,
                    ),
                    if (time != null && _parsed.durationMin != null)
                      _chip(
                        label: offsetLabel(_parsed.durationMin!),
                        onDeleted: () => _disable(ParseField.duration),
                      ),
                    if (time != null)
                      _chip(
                        label: reminderLabel(_reminder(settings)),
                        onPressed: () => _pickReminder(_reminder(settings)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _save(settings),
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    VoidCallback? onPressed,
    VoidCallback? onDeleted,
  }) => InputChip(
    label: Text(label),
    onPressed: onPressed,
    onDeleted: onDeleted,
    visualDensity: VisualDensity.compact,
  );
}

String hhmmOf(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Anlaşılan tarih ve saat ifadelerini metnin içinde renklendirir.
class _HighlightController extends TextEditingController {
  List<ParsedSpan> spans = const [];
  Color highlight = Colors.blue;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final length = text.length;
    final composing = withComposing && value.isComposingRangeValid
        ? value.composing
        : TextRange.empty;
    final cuts = <int>{0, length};
    for (final s in spans) {
      if (s.end <= length) cuts.addAll([s.start, s.end]);
    }
    if (composing.isValid) cuts.addAll([composing.start, composing.end]);
    final points = cuts.toList()..sort();

    return TextSpan(
      style: style,
      children: [
        for (var i = 0; i + 1 < points.length; i++)
          TextSpan(
            text: text.substring(points[i], points[i + 1]),
            style: TextStyle(
              color: spans.any((s) => s.start <= points[i] && points[i] < s.end)
                  ? highlight
                  : null,
              decoration:
                  composing.isValid &&
                      composing.start <= points[i] &&
                      points[i] < composing.end
                  ? TextDecoration.underline
                  : null,
            ),
          ),
      ],
    );
  }
}
