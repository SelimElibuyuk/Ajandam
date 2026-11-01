import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../domain/settings.dart';
import '../../domain/week.dart';
import '../../ui/app_chrome.dart';
import '../day/day_list.dart';

final _monthFormat = DateFormat('MMMM y', 'tr');
final _dayFormat = DateFormat('d MMMM EEEE', 'tr');
final _weekdayFormat = DateFormat('EEE', 'tr');

class MonthScreen extends ConsumerStatefulWidget {
  const MonthScreen({super.key});

  @override
  ConsumerState<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends ConsumerState<MonthScreen> {
  late DateTime _month = _firstOfMonth(ref.read(todayProvider));
  DateTime? _selected;

  static DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

  void _shiftMonth(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final selected = _selected ?? today;

    return Column(
      children: [
        AppHeader(
          title: Text('Ajandam', style: context.type.headlineSmall),
          action: selected == today && _month == _firstOfMonth(today)
              ? null
              : TextButton(
                  onPressed: () => setState(() {
                    _selected = null;
                    _month = _firstOfMonth(today);
                  }),
                  child: const Text('Bugün'),
                ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            _monthFormat.format(_month),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.type.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          seasonOf(_month.month),
                          style: context.type.labelSmall?.copyWith(
                            color: c.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Arrow(
                    icon: Icons.chevron_left,
                    label: 'Önceki ay',
                    onTap: () => _shiftMonth(-1),
                  ),
                  _Arrow(
                    icon: Icons.chevron_right,
                    label: 'Sonraki ay',
                    onTap: () => _shiftMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Takvim üzerinde kaydırma ay değiştirir, ekran geçişine gitmez.
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v.abs() > 100) _shiftMonth(v < 0 ? 1 : -1);
                },
                child: _MonthGrid(
                  month: _month,
                  firstWeekday: settings.weekStart,
                  today: today,
                  selected: selected,
                  onSelect: (day) => setState(() => _selected = day),
                ),
              ),
              const SizedBox(height: 16),
              _DayTitle(day: selected, isToday: selected == today),
              const SizedBox(height: 10),
              DayList(day: selected),
            ],
          ),
        ),
        QuickAddBar(day: selected),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: label,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: context.colors.textSoft),
    );
  }
}

class _DayTitle extends ConsumerWidget {
  const _DayTitle({required this.day, required this.isToday});

  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final count = ref.watch(dayItemsProvider(dayKey(day))).value?.length ?? 0;
    final suffix = count == 0 ? '' : ' • $count Görev';
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_dayFormat.format(day)}$suffix',
            style: context.type.headlineSmall,
          ),
        ),
        if (isToday)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: c.container,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              'Bugün',
              style: context.type.labelSmall?.copyWith(color: c.accentText),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends ConsumerWidget {
  const _MonthGrid({
    required this.month,
    required this.firstWeekday,
    required this.today,
    required this.selected,
    required this.onSelect,
  });

  final DateTime month;
  final int firstWeekday;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final days = monthGrid(month, firstWeekday: firstWeekday);
    final items =
        ref.watch(monthItemsProvider(dayKey(days.first))).value ??
        const <AgendaItem>[];
    final now = DateTime.now();
    final byDay = <DateTime, List<AgendaItem>>{};
    for (final item in items) {
      (byDay[item.day] ??= []).add(item);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.low,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final day in days.take(7))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _weekdayFormat.format(day),
                      textAlign: TextAlign.center,
                      style: context.type.labelSmall?.copyWith(
                        color: _isWeekend(day) ? c.muted : c.textSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var week = 0; week < days.length ~/ 7; week++)
            Row(
              children: [
                for (final day in days.skip(week * 7).take(7))
                  Expanded(
                    child: _DayCell(
                      day: day,
                      inMonth: day.month == month.month,
                      isToday: day == today,
                      isSelected: day == selected,
                      items: byDay[day] ?? const [],
                      now: now,
                      onTap: () => onSelect(day),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

bool _isWeekend(DateTime day) =>
    day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.items,
    required this.now,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<AgendaItem> items;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Color textColor;
    if (isSelected) {
      textColor = c.onAccent;
    } else if (isToday) {
      textColor = c.accentText;
    } else if (_isWeekend(day)) {
      textColor = c.muted;
    } else {
      textColor = c.text;
    }

    final cell = AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? c.accent : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: context.type.labelMedium?.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w500 : null,
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final item in items.take(3))
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? c.onAccent
                            : (item.isFinished(now) ? c.muted : c.accent),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!inMonth) return Opacity(opacity: 0.3, child: cell);
    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat('d MMMM', 'tr').format(day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(child: cell),
      ),
    );
  }
}
