import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../domain/settings.dart';
import '../../domain/week.dart';
import '../quick_add/quick_add_sheet.dart';

const _centerPage = 1000;

final _rangeFormat = DateFormat('d MMM', 'tr');
final _weekdayFormat = DateFormat('EEE', 'tr');

class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  final _pages = PageController(initialPage: _centerPage);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pages,
      itemBuilder: (context, page) => _WeekPage(
        offset: page - _centerPage,
        onBackToToday: () => _pages.animateToPage(
          _centerPage,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      ),
    );
  }
}

class _WeekPage extends ConsumerWidget {
  const _WeekPage({required this.offset, required this.onBackToToday});

  final int offset;
  final VoidCallback onBackToToday;

  String get _subtitle => switch (offset) {
    0 => 'Bu hafta',
    1 => 'Gelecek hafta',
    -1 => 'Geçen hafta',
    _ => offset > 0 ? '$offset hafta sonra' : '${-offset} hafta önce',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final days = weekDays(
      addDays(today, offset * 7),
      firstWeekday: settings.weekStart,
    );
    final first = _rangeFormat.format(days.first);
    final last = _rangeFormat.format(days.last);
    final items = ref.watch(weekItemsProvider(dayKey(days.first))).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$first – $last',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text(_subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              if (offset != 0)
                TextButton(
                  onPressed: onBackToToday,
                  child: const Text('Bugün'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
            itemCount: days.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final day = days[index];
              return _DayRow(
                day: day,
                isToday: day == today,
                items: DayGroups.from(
                  items?.where((i) => i.day == day) ?? const [],
                  day,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.isToday,
    required this.items,
  });

  final DateTime day;
  final bool isToday;
  final DayGroups items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isToday ? theme.colorScheme.primary : null;
    final lines = [...items.timed, ...items.untimed];

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/day/${dayKey(day)}'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
        decoration: BoxDecoration(
          color: isToday
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _weekdayFormat.format(day),
                    style: theme.textTheme.labelMedium?.copyWith(color: color),
                  ),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: lines.isEmpty
                    ? Text(
                        'Boş',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [for (final item in lines) _Line(item: item)],
                      ),
              ),
            ),
            IconButton(
              tooltip: 'Ekle',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => showQuickAdd(context, day: day),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.item});

  final AgendaItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = item.start == null ? '' : '${hhmm(item.start!)} ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        '$time${item.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: item.isDone ? theme.colorScheme.outline : null,
          decoration: item.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}
