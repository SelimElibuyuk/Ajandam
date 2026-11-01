import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/providers.dart';
import '../app/theme.dart';
import '../domain/dates.dart';
import '../domain/item.dart';

/// Girdi satırı. [card] kapalıyken hafta çizgisindeki gibi çerçevesiz çizilir.
class ItemTile extends ConsumerWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.now,
    this.card = true,
  });

  final AgendaItem item;
  final DateTime now;
  final bool card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final finished = item.isFinished(now);
    final overdue = item.isOverdue(now);
    final timeColor = overdue ? c.danger : (finished ? c.muted : c.accentText);
    final titleColor = overdue ? c.danger : (finished ? c.muted : c.text);

    final row = Row(
      children: [
        if (item.isTask)
          _DoneBox(
            done: item.isDone,
            color: overdue ? c.danger : c.muted,
            onTap: () => ref.read(itemServiceProvider).toggleDone(item.id),
          )
        else
          _EventMark(finished: finished),
        if (item.start != null)
          SizedBox(
            width: 50,
            child: Text(
              hhmm(item.start!),
              style: context.type.labelMedium?.copyWith(color: timeColor),
            ),
          ),
        Expanded(
          child: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.type.bodyMedium?.copyWith(
              color: titleColor,
              decoration: finished ? TextDecoration.lineThrough : null,
              decorationColor: c.muted,
            ),
          ),
        ),
        if (item.important)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.flag_outlined,
              size: 15,
              color: c.accentText,
              semanticLabel: 'Önemli',
            ),
          ),
        if (item.rolledCount > 0)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _RolledBadge(count: item.rolledCount),
          ),
        const SizedBox(width: 8),
      ],
    );

    if (!card) {
      return InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => context.push('/item/${item.id}'),
        child: row,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: c.hairline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => context.push('/item/${item.id}'),
          child: row,
        ),
      ),
    );
  }
}

const _markWidth = 40.0;
const _markHeight = 44.0;

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
    return Semantics(
      button: true,
      checked: done,
      label: 'Tamamlandı',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: _markWidth,
          height: _markHeight,
          child: Center(
            child: _Box(filled: done, color: color),
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: filled ? c.accent : null,
        borderRadius: BorderRadius.circular(3),
        border: filled ? null : Border.all(color: color),
      ),
      child: filled ? Icon(Icons.check, size: 13, color: c.onAccent) : null,
    );
  }
}

/// Etkinlik elle tamamlanmaz: Süresi geçince kutu kendiliğinden dolu görünür.
class _EventMark extends StatelessWidget {
  const _EventMark({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: _markWidth,
      height: _markHeight,
      child: Center(
        child: finished
            ? _Box(filled: true, color: c.muted)
            : Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(2),
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
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.container,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'taşındı $count',
        style: context.type.labelSmall?.copyWith(color: c.accentText),
      ),
    );
  }
}
