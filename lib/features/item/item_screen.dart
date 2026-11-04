import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../domain/recurrence.dart';
import '../../domain/settings.dart';
import '../../ui/labels.dart';
import '../../ui/recurrence_picker.dart';

class ItemScreen extends ConsumerWidget {
  const ItemScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider(id));
    return item.when(
      loading: () => const Scaffold(),
      error: (error, _) =>
          const Scaffold(body: Center(child: Text('Girdi yüklenemedi.'))),
      data: (data) => data == null
          ? Scaffold(
              appBar: AppBar(),
              body: const Center(child: Text('Bu girdi artık yok.')),
            )
          : _ItemForm(key: ValueKey(id), item: data),
    );
  }
}

class _ItemForm extends ConsumerStatefulWidget {
  const _ItemForm({super.key, required this.item});

  final AgendaItem item;

  @override
  ConsumerState<_ItemForm> createState() => _ItemFormState();
}

const _durations = [0, 15, 30, 45, 60, 90, 120, 180];

class _ItemFormState extends ConsumerState<_ItemForm> {
  late final _title = TextEditingController(text: widget.item.title);
  late final _notes = TextEditingController(text: widget.item.notes);
  late DateTime _day = widget.item.day;
  late TimeOfDay? _time = widget.item.start == null
      ? null
      : TimeOfDay.fromDateTime(widget.item.start!);
  late int _duration =
      widget.item.end?.difference(widget.item.start!).inMinutes ?? 0;
  late int? _reminder = widget.item.reminderMin;
  late bool _important = widget.item.important;
  late ItemKind _kind = widget.item.kind;
  late DateTime? _endDay = widget.item.endDay;
  late Recurrence? _recurrence = widget.item.recurrence;
  bool _showError = false;

  bool get _isEvent => _kind == ItemKind.event;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: addDays(today, -365 * 2),
      lastDate: addDays(today, 365 * 5),
    );
    if (picked == null) return;
    setState(() {
      // Tek günlük haftalık tekrar, yeni güne taşınır.
      final rule = _recurrence;
      if (rule != null &&
          rule.frequency == Frequency.weekly &&
          rule.weekdays.length <= 1 &&
          picked.weekday != _day.weekday) {
        _recurrence = Recurrence(
          Frequency.weekly,
          interval: rule.interval,
          weekdays: {picked.weekday},
          until: rule.until,
        );
      }
      final end = _endDay;
      if (end != null) _endDay = addDays(end, daysBetween(_day, picked));
      _day = picked;
    });
  }

  Future<void> _pickEndDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDay ?? addDays(_day, 1),
      firstDate: addDays(_day, 1),
      lastDate: addDays(_day, 365),
    );
    if (picked != null) setState(() => _endDay = picked);
  }

  Future<void> _pickRepeat() async {
    final picked = await pickRecurrence(context, _recurrence, _day);
    if (picked != null) setState(() => _recurrence = picked.$1);
  }

  void _setKind(ItemKind kind) => setState(() {
    _kind = kind;
    if (kind == ItemKind.event && _duration == 0) _duration = 60;
  });

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      if (_time == null) {
        _reminder ??= (ref.read(settingsProvider).value ?? const AppSettings())
            .defaultReminderMin;
      }
      _time = picked;
    });
  }

  Future<void> _pickReminder() async {
    final picked = await pickReminder(context, _reminder);
    if (picked != null) setState(() => _reminder = picked.$1);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    final time = _time;
    final start = time == null
        ? null
        : DateTime(_day.year, _day.month, _day.day, time.hour, time.minute);
    final end = _endDay;
    final notes = _notes.text.trim();
    final item = widget.item;
    final edited = item.copyWith(
      kind: _kind,
      title: title,
      notes: notes.isEmpty ? null : notes,
      day: _day,
      start: start,
      end: _isEvent && start != null
          ? start.add(Duration(minutes: _duration > 0 ? _duration : 60))
          : null,
      endDay: _isEvent && start == null && end != null && end.isAfter(_day)
          ? end
          : null,
      reminderMin: start == null ? null : _reminder,
      important: _important,
      recurrence: _recurrence,
    );
    final service = ref.read(itemServiceProvider);
    if (!item.isOccurrence) {
      await service.save(edited);
    } else if (_recurrence != item.recurrence) {
      // Kural değişirse yalnızca bu tekrar için anlamı olmaz.
      await service.saveFollowing(edited);
    } else {
      final following = await askScope(context, title: 'Değişiklik');
      if (following == null) return;
      await (following ? service.saveFollowing(edited) : service.save(edited));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(itemServiceProvider);
    final original = widget.item;
    if (original.isOccurrence) {
      final following = await askScope(context, title: 'Silme');
      if (following == null || !mounted) return;
      if (following) {
        Navigator.pop(context);
        await service.deleteFollowing(original);
        messenger.showSnackBar(
          const SnackBar(content: Text('Bu ve sonraki tekrarlar silindi')),
        );
        return;
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    await service.delete(original.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Çöp kutusuna taşındı'),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () => service.undoDelete(original),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final today = ref.watch(todayProvider);
    final rule = settings.lifecycle;
    final options = {..._durations, _duration}.toList()..sort();
    final service = ref.read(itemServiceProvider);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
          TextButton(onPressed: _save, child: const Text('Kaydet')),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _title,
              maxLength: 200,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.titleLarge,
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              decoration: InputDecoration(
                hintText: 'Başlık',
                border: InputBorder.none,
                counterText: '',
                errorText: _showError ? 'Başlık yaz' : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<ItemKind>(
              segments: const [
                ButtonSegment(
                  value: ItemKind.task,
                  label: Text('Görev'),
                  icon: Icon(Icons.check_box_outlined),
                ),
                ButtonSegment(
                  value: ItemKind.event,
                  label: Text('Etkinlik'),
                  icon: Icon(Icons.event_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (kinds) => _setKind(kinds.single),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(dayLabel(_day, today)),
            onTap: _pickDay,
          ),
          if (_isEvent && _time == null)
            ListTile(
              leading: const Icon(Icons.date_range_outlined),
              title: Text(
                _endDay == null
                    ? 'Bitiş günü ekle'
                    : 'Bitiş ${dayLabel(_endDay!, today)}',
              ),
              onTap: _pickEndDay,
              trailing: _endDay == null
                  ? null
                  : IconButton(
                      tooltip: 'Bitiş gününü kaldır',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _endDay = null),
                    ),
            ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(_time == null ? 'Saat ekle' : hhmmOf(_time!)),
            onTap: _pickTime,
            trailing: _time == null
                ? null
                : IconButton(
                    tooltip: 'Saati kaldır',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _time = null;
                      _duration = 0;
                    }),
                  ),
          ),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(
              _recurrence == null
                  ? 'Tekrar yok'
                  : recurrenceLabel(_recurrence!, _day),
            ),
            onTap: _pickRepeat,
            trailing: _recurrence == null
                ? null
                : IconButton(
                    tooltip: 'Tekrarı kaldır',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _recurrence = null),
                  ),
          ),
          if (_time != null && _isEvent)
            ListTile(
              leading: const Icon(Icons.timelapse),
              title: const Text('Süre'),
              trailing: DropdownButton<int>(
                value: _duration,
                underline: const SizedBox.shrink(),
                items: [
                  for (final option in options)
                    DropdownMenuItem(
                      value: option,
                      child: Text(option == 0 ? 'Yok' : '$option dk'),
                    ),
                ],
                onChanged: (value) => setState(() => _duration = value ?? 0),
              ),
            ),
          if (_time != null)
            ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(reminderLabel(_reminder)),
              onTap: _pickReminder,
            ),
          SwitchListTile(
            secondary: const Icon(Icons.flag_outlined),
            title: const Text('Önemli'),
            subtitle: const Text('Önemli görevler otomatik silinmez'),
            value: _important,
            onChanged: (value) => setState(() => _important = value),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Not',
                border: InputBorder.none,
              ),
            ),
          ),
          if (rule.appliesTo(item)) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.hourglass_bottom),
              title: Text(
                'Silinmesine ${rule.daysLeft(item, today)} gün kaldı',
              ),
              trailing: TextButton(
                onPressed: () => service.extend([item.id]),
                child: const Text('Süreyi uzat'),
              ),
            ),
          ],
          if (item.isTask) ...[
            const Divider(),
            ListTile(
              leading: Icon(
                item.isDone ? Icons.undo : Icons.check_circle_outline,
              ),
              title: Text(item.isDone ? 'Tamamlanmadı yap' : 'Tamamlandı'),
              onTap: () => service.toggleDone(item.id),
            ),
          ],
        ],
      ),
    );
  }
}
