import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/item.dart';

class ItemTile extends ConsumerWidget {
  const ItemTile({super.key, required this.item, required this.now});

  final AgendaItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overdue = item.isOverdue(now);
    final color = overdue ? theme.colorScheme.error : null;

    return InkWell(
      onTap: () => context.push('/item/${item.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            if (item.isTask)
              _DoneBox(
                done: item.isDone,
                color: color ?? theme.colorScheme.outline,
                onTap: () => ref.read(itemServiceProvider).toggleDone(item.id),
              )
            else
              SizedBox(
                width: 44,
                child: Center(
                  child: Container(
                    width: 3,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            if (item.start != null)
              SizedBox(
                width: 52,
                child: Text(
                  hhmm(item.start!),
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ),
            Expanded(
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: item.isDone ? theme.colorScheme.outline : color,
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.important)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                  semanticLabel: 'Önemli',
                ),
              ),
            if (item.rolledCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _RolledBadge(count: item.rolledCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _DoneBox extends StatelessWidget {
  const _DoneBox({
    required this.done,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      checked: done,
      label: 'Tamamlandı',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? accent : null,
                border: Border.all(color: done ? accent : color, width: 1.5),
              ),
              child: done
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _RolledBadge extends StatelessWidget {
  const _RolledBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'taşındı $count',
        style: TextStyle(fontSize: 11, color: scheme.primary),
      ),
    );
  }
}
