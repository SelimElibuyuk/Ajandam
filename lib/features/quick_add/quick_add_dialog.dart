import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../domain/nlp_parser.dart';
import '../../domain/recurrence.dart';
import '../../domain/reminder_planner.dart';
import '../../domain/settings.dart';
import '../../ui/labels.dart';
import '../../ui/recurrence_picker.dart';
import '../../voice/dictation.dart';
import '../../voice/voice_input.dart';

Future<void> showQuickAdd(
  BuildContext context, {
  DateTime? day,
  bool coldStart = false,
  bool voice = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        QuickAddDialog(day: day, coldStart: coldStart, voice: voice),
  );
}

class QuickAddDialog extends ConsumerStatefulWidget {
  const QuickAddDialog({
    super.key,
    this.day,
    this.coldStart = false,
    this.voice = false,
  });

  final DateTime? day;

  /// Widget'tan açılınca pencere odağı geç gelir, klavye yeniden istenir.
  final bool coldStart;

  /// Açılır açılmaz dinlemeye başlar, klavye açılmaz.
  final bool voice;

  @override
  ConsumerState<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends ConsumerState<QuickAddDialog> {
  final _parser = NlpParser();
  final _focus = FocusNode();
  final _controller = _HighlightController();

  final _disabled = <ParseField>{};
  DateTime? _dayOverride;
  TimeOfDay? _timeOverride;
  (int?,)? _reminderOverride;
  ItemKind? _kindOverride;
  (Recurrence?,)? _repeatOverride;
  bool _showError = false;
  bool _saving = false;
  bool _listening = false;
  late final Dictation _dictation;
  String? _voiceError;
  String _lastText = '';
  ParsedInput _parsed = const ParsedInput(title: '', spans: []);

  @override
  void initState() {
    super.initState();
    _dictation = Dictation(
      ref.read(voiceInputProvider),
      onText: _onDictated,
      onListening: (on) {
        if (mounted) setState(() => _listening = on);
      },
      onError: _onVoiceError,
    );
    _controller.addListener(_onChanged);
    if (widget.voice) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Soğuk açılışta mikrofon, pencere öne gelince kullanılabilir.
        if (widget.coldStart) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        if (mounted) await _toggleVoice();
      });
    } else if (widget.coldStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showKeyboard());
    }
  }

  Future<void> _toggleVoice() async {
    if (_dictation.isListening) {
      await _dictation.stop();
      return;
    }
    setState(() => _voiceError = null);
    await _dictation.start(_controller.text);
  }

  void _onDictated(String text) {
    if (!mounted) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onVoiceError(VoiceError error) {
    if (!mounted) return;
    setState(
      () => _voiceError = switch (error) {
        VoiceError.permission => 'Mikrofon izni verilmedi.',
        VoiceError.network => 'Ses tanıma için internet gerekiyor.',
        VoiceError.unavailable =>
          'Ses tanıma kullanılamıyor. Mikrofon iznini kontrol et.',
        _ => 'Ses tanınamadı, tekrar dene.',
      },
    );
  }

  /// Pencere odağı Flutter'dan sonra gelir; klavye görünene kadar yeniden ister.
  Future<void> _showKeyboard() async {
    for (final wait in const [150, 300, 500, 800, 1200]) {
      await Future<void>.delayed(Duration(milliseconds: wait));
      if (!mounted || MediaQuery.viewInsetsOf(context).bottom > 0) return;
      _focus.unfocus();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _focus.requestFocus();
      await WidgetsBinding.instance.endOfFrame;
      await SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  @override
  void dispose() {
    _dictation.dispose();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// İmleç hareketleri de bildirilir, yalnızca metin değişince çalışır.
  void _onChanged() {
    if (_controller.text == _lastText) return;
    _lastText = _controller.text;
    if (_dictation.isListening && _controller.text != _dictation.written) {
      _dictation.edited(_controller.text);
    }
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

  /// Süreli tekrarın bitişi ilk güne göre hesaplanır: “4 hafta boyunca”.
  Recurrence? get _recurrence => _repeatOverride != null
      ? _repeatOverride!.$1
      : _parsed.recurrenceFrom(_day);

  ItemKind get _kind =>
      _kindOverride ?? (_parsed.isEvent ? ItemKind.event : ItemKind.task);

  DateTime get _day {
    final day = _dayOverride ?? _parsed.resolveDay(_baseDay, DateTime.now());
    final rule = _repeatOverride != null
        ? _repeatOverride!.$1
        : _parsed.recurrence;
    return rule?.align(day) ?? day;
  }

  TimeOfDay? get _time =>
      _timeOverride ??
      (_parsed.hasTime
          ? TimeOfDay(hour: _parsed.hour!, minute: _parsed.minute!)
          : null);

  int? _reminder(AppSettings settings) => _reminderOverride != null
      ? _reminderOverride!.$1
      : settings.defaultReminderMin;

  Future<bool> _pickDay() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: addDays(today, -365),
      lastDate: addDays(today, 365 * 5),
    );
    if (picked != null) setState(() => _dayOverride = picked);
    return picked != null;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _timeOverride = picked);
  }

  /// Yazmak istemeyenler için tarih, ardından saat seçtirir.
  Future<void> _pickDayAndTime() async {
    if (await _pickDay() && mounted) await _pickTime();
    _focus.requestFocus();
  }

  Future<void> _pickReminder(int? current) async {
    final picked = await pickReminder(context, current);
    if (picked != null) setState(() => _reminderOverride = picked);
    _focus.requestFocus();
  }

  Future<void> _pickRepeat() async {
    final picked = await pickRecurrence(context, _recurrence, _day);
    if (picked != null) setState(() => _repeatOverride = picked);
    _focus.requestFocus();
  }

  /// Yazılarak gelen tekrar silinirse kelimeler başlığa döner.
  void _clearRepeat() {
    if (_repeatOverride == null && _parsed.recurrence != null) {
      _disable(ParseField.repeat);
    } else {
      setState(() => _repeatOverride = (null,));
    }
  }

  void _disable(ParseField field) => setState(() {
    _disabled.add(field);
    if (field == ParseField.date) _dayOverride = null;
    if (field == ParseField.time) _timeOverride = null;
    _reparse();
  });

  Future<void> _save(AppSettings settings) async {
    if (_saving) return;
    await _dictation.stop();
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
          kind: _kind,
          endDay: _parsed.endDate,
          recurrence: _recurrence,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final today = ref.watch(todayProvider);
    _controller.highlight = c.accentText;
    final time = _time;
    final kind = _kind;
    final endDate = _parsed.endDate;
    final rule = _recurrence;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uzun girdiler satır kaydırarak tamamen görünür.
            TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: !widget.voice,
              maxLength: 200,
              minLines: 2,
              maxLines: 6,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(settings),
              style: context.type.bodyLarge,
              decoration: InputDecoration(
                hintText: _listening ? 'Dinliyorum…' : 'yarın 14:00 dişçi',
                hintStyle: context.type.bodyLarge?.copyWith(color: c.muted),
                border: InputBorder.none,
                counterText: '',
                errorText: _showError ? 'Başlık yaz' : null,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _chip(
                  hue: ChipHue.accent,
                  label: kind == ItemKind.event ? 'Etkinlik' : 'Görev',
                  icon: kind == ItemKind.event
                      ? Icons.event_outlined
                      : Icons.check_box_outlined,
                  onPressed: () => setState(
                    () => _kindOverride = kind == ItemKind.event
                        ? ItemKind.task
                        : ItemKind.event,
                  ),
                ),
                _chip(
                  hue: ChipHue.accent,
                  label: endDate != null && kind == ItemKind.event
                      ? '${dayLabel(_day, today)} – ${dayLabel(endDate, today)}'
                      : dayLabel(_day, today),
                  onPressed: () async {
                    await _pickDay();
                    _focus.requestFocus();
                  },
                  onDeleted: _parsed.date != null
                      ? () => _disable(ParseField.date)
                      : null,
                ),
                _chip(
                  hue: time == null ? null : ChipHue.time,
                  label: time == null ? 'Saat ekle' : hhmmOf(time),
                  onPressed: () async {
                    await _pickTime();
                    _focus.requestFocus();
                  },
                  onDeleted: time != null
                      ? () => _disable(ParseField.time)
                      : null,
                ),
                _chip(
                  hue: rule == null ? null : ChipHue.repeat,
                  label: rule == null
                      ? 'Tekrar yok'
                      : recurrenceLabel(rule, _day),
                  icon: Icons.repeat,
                  onPressed: _pickRepeat,
                  onDeleted: rule != null ? _clearRepeat : null,
                ),
                if (time != null &&
                    kind == ItemKind.event &&
                    _parsed.durationMin != null)
                  _chip(
                    hue: ChipHue.duration,
                    label: offsetLabel(_parsed.durationMin!),
                    onDeleted: () => _disable(ParseField.duration),
                  ),
                if (time != null)
                  _chip(
                    hue: ChipHue.reminder,
                    label: reminderLabel(_reminder(settings)),
                    onPressed: () => _pickReminder(_reminder(settings)),
                  ),
              ],
            ),
            if (_voiceError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _voiceError!,
                  style: context.type.bodySmall?.copyWith(color: c.danger),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: _listening ? 'Dinlemeyi durdur' : 'Sesle yaz',
                  onPressed: _toggleVoice,
                  visualDensity: VisualDensity.compact,
                  style: _listening
                      ? IconButton.styleFrom(backgroundColor: c.accent)
                      : null,
                  icon: Icon(
                    _listening ? Icons.mic : Icons.mic_none,
                    size: 22,
                    color: _listening ? c.onAccent : c.accentText,
                  ),
                ),
                IconButton(
                  tooltip: 'Tarih ve saat seç',
                  onPressed: _pickDayAndTime,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.edit_calendar_outlined,
                    size: 22,
                    color: c.accentText,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: () => _save(settings),
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// [hue] verilmeyen çip henüz boş bir alandır ve sade kalır.
  Widget _chip({
    required String label,
    ChipHue? hue,
    IconData? icon,
    VoidCallback? onPressed,
    VoidCallback? onDeleted,
  }) {
    final tone = hue == null ? null : context.colors.tone(hue);
    return InputChip(
      avatar: icon == null
          ? null
          : Icon(icon, size: 16, color: tone?.foreground),
      label: Text(label),
      labelStyle: tone == null
          ? null
          : context.type.labelMedium?.copyWith(color: tone.foreground),
      backgroundColor: tone?.background,
      side: tone == null ? null : BorderSide.none,
      deleteIconColor: tone?.foreground,
      onPressed: onPressed,
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

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
