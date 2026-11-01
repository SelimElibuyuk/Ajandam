import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/week.dart';

class WeekScreen extends StatelessWidget {
  const WeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final days = weekDays(now);
    final first = DateFormat('d MMM', 'tr').format(days.first);
    final last = DateFormat('d MMM', 'tr').format(days.last);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$first – $last', style: theme.textTheme.headlineSmall),
          Text('Bu hafta', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: days.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) => _DayRow(
                day: days[index],
                isToday: isSameDay(days[index], now),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.isToday});

  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isToday ? theme.colorScheme.primary : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE', 'tr').format(day),
                  style: theme.textTheme.labelMedium?.copyWith(color: color),
                ),
                Text(
                  '${day.day}',
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
          Text('Boş', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
