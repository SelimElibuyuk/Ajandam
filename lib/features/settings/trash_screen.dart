import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../domain/item_service.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(trashProvider).value ?? const <AgendaItem>[];
    final today = ref.watch(todayProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Çöp kutusu')),
      body: items.isEmpty
          ? const Center(child: Text('Çöp kutusu boş.'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                final left = trashDays - daysBetween(item.deletedAt!, today);
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text('$left gün sonra tamamen silinir'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Geri al',
                        icon: const Icon(Icons.restore),
                        onPressed: () =>
                            ref.read(itemServiceProvider).restore(item.id),
                      ),
                      IconButton(
                        tooltip: 'Kalıcı sil',
                        icon: const Icon(Icons.delete_forever_outlined),
                        onPressed: () => _confirmDelete(context, ref, item),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AgendaItem item,
  ) async {
    final service = ref.read(itemServiceProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kalıcı olarak silinsin mi?'),
        content: Text('“${item.title}” geri getirilemez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed == true) await service.deleteForever(item.id);
  }
}
