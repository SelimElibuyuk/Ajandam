import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('d MMMM EEEE', 'tr').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bugün', style: theme.textTheme.headlineSmall),
          Text(date, style: theme.textTheme.bodyMedium),
          Expanded(
            child: Center(
              child: Text('Bugün boş.', style: theme.textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
