import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import 'day_agenda.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(todayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bugün', style: theme.textTheme.headlineSmall),
              Text(
                DateFormat('d MMMM EEEE', 'tr').format(today),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(child: DayAgenda(day: today)),
      ],
    );
  }
}
