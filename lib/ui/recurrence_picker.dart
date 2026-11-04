import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/theme.dart';
import '../domain/dates.dart';
import '../domain/recurrence.dart';

const _dayNames = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];
const _dayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// “Her hafta Salı, Perşembe · bitiş 14 Mar”. [first] serinin ilk günüdür.
String recurrenceLabel(Recurrence rule, DateTime first) {
  final n = rule.interval;
  final text = switch (rule.frequency) {
    Frequency.daily => n == 1 ? 'Her gün' : '$n günde bir',
    Frequency.weekly when rule.isWeekdays => 'Hafta içi her gün',
    Frequency.weekly => () {
      final days =
          (rule.weekdays.isEmpty ? {first.weekday} : rule.weekdays).toList()
            ..sort();
      final names = days.map((d) => _dayNames[d - 1]).join(', ');
      return n == 1 ? 'Her hafta $names' : '$n haftada bir $names';
    }(),
    Frequency.monthly =>
      n == 1
          ? 'Her ayın ${first.day}. günü'
          : '$n ayda bir, ayın ${first.day}. günü',
    Frequency.yearly =>
      '${n == 1 ? 'Her yıl' : '$n yılda bir'} '
          '${DateFormat('d MMMM', 'tr').format(first)}',
  };
  final until = rule.until;
  if (until == null) return text;
  return '$text · bitiş ${DateFormat('d MMM', 'tr').format(until)}';
}

/// Seçim yapılırsa tek elemanlı kayıt döner (tekrar yoksa null), vazgeçilirse
/// null.
Future<(Recurrence?,)?> pickRecurrence(
  BuildContext context,
  Recurrence? current,
  DateTime first,
) => showDialog<(Recurrence?,)>(
  context: context,
  builder: (context) => _RecurrenceDialog(current: current, first: first),
);

/// Tekrarlanan girdide değişikliğin kapsamı: true bu ve sonrakiler, false
/// yalnızca bu, null vazgeç.
Future<bool?> askScope(BuildContext context, {required String title}) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Bu girdi tekrarlanıyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Yalnızca bu'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bu ve sonrakiler'),
          ),
        ],
      ),
    );

enum _Choice { none, daily, weekdays, weekly, monthly, yearly }

const _choiceLabels = {
  _Choice.none: 'Yok',
  _Choice.daily: 'Günlük',
  _Choice.weekdays: 'Hafta içi',
  _Choice.weekly: 'Haftalık',
  _Choice.monthly: 'Aylık',
  _Choice.yearly: 'Yıllık',
};

const _units = {
  _Choice.daily: 'günde',
  _Choice.weekly: 'haftada',
  _Choice.monthly: 'ayda',
  _Choice.yearly: 'yılda',
};

class _RecurrenceDialog extends StatefulWidget {
  const _RecurrenceDialog({required this.current, required this.first});

  final Recurrence? current;
  final DateTime first;

  @override
  State<_RecurrenceDialog> createState() => _RecurrenceDialogState();
}

class _RecurrenceDialogState extends State<_RecurrenceDialog> {
  late _Choice _choice = _choiceOf(widget.current);
  late int _interval = widget.current?.interval ?? 1;
  late Set<int> _days = {
    ...(widget.current?.weekdays.isNotEmpty ?? false)
        ? widget.current!.weekdays
        : {widget.first.weekday},
  };
  late DateTime? _until = widget.current?.until;

  static _Choice _choiceOf(Recurrence? rule) {
    if (rule == null) return _Choice.none;
    if (rule.isWeekdays) return _Choice.weekdays;
    return switch (rule.frequency) {
      Frequency.daily => _Choice.daily,
      Frequency.weekly => _Choice.weekly,
      Frequency.monthly => _Choice.monthly,
      Frequency.yearly => _Choice.yearly,
    };
  }

  Recurrence? _result() => switch (_choice) {
    _Choice.none => null,
    _Choice.weekdays => Recurrence(
      Frequency.weekly,
      weekdays: weekdaysMonFri,
      until: _until,
    ),
    _Choice.daily => Recurrence(
      Frequency.daily,
      interval: _interval,
      until: _until,
    ),
    _Choice.weekly => Recurrence(
      Frequency.weekly,
      interval: _interval,
      weekdays: _days,
      until: _until,
    ),
    _Choice.monthly => Recurrence(
      Frequency.monthly,
      interval: _interval,
      until: _until,
    ),
    _Choice.yearly => Recurrence(
      Frequency.yearly,
      interval: _interval,
      until: _until,
    ),
  };

  Future<void> _pickUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _until ?? addDays(widget.first, 30),
      firstDate: widget.first,
      lastDate: addDays(widget.first, 365 * 10),
    );
    if (picked != null) setState(() => _until = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final unit = _units[_choice];

    return AlertDialog(
      title: const Text('Tekrar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final choice in _Choice.values)
                  ChoiceChip(
                    label: Text(_choiceLabels[choice]!),
                    selected: _choice == choice,
                    onSelected: (_) => setState(() {
                      _choice = choice;
                      _interval = 1;
                    }),
                  ),
              ],
            ),
            if (unit != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Azalt',
                    onPressed: _interval > 1
                        ? () => setState(() => _interval--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_interval', style: context.type.titleMedium),
                  IconButton(
                    tooltip: 'Artır',
                    onPressed: _interval < 30
                        ? () => setState(() => _interval++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 4),
                  Text('$unit bir'),
                ],
              ),
            ],
            if (_choice == _Choice.weekly) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(_dayShort[d - 1]),
                      selected: _days.contains(d),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      onSelected: (on) => setState(() {
                        if (on) {
                          _days = {..._days, d};
                        } else if (_days.length > 1) {
                          _days = {..._days}..remove(d);
                        }
                      }),
                    ),
                ],
              ),
            ],
            if (_choice != _Choice.none) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event_busy_outlined, color: c.muted),
                title: Text(
                  _until == null
                      ? 'Bitiş yok'
                      : 'Bitiş ${DateFormat('d MMMM y', 'tr').format(_until!)}',
                ),
                onTap: _pickUntil,
                trailing: _until == null
                    ? null
                    : IconButton(
                        tooltip: 'Bitişi kaldır',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _until = null),
                      ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, (_result(),)),
          child: const Text('Tamam'),
        ),
      ],
    );
  }
}
