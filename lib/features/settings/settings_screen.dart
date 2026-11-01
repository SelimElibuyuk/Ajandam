import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ayarlar', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text('Sürüm 0.1.0', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
