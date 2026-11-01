import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../ui/item_tile.dart';

/// Bir günün listesi: saatsizler üstte, saatliler altta, şu anki saat çizgisi.
class DayAgenda extends ConsumerStatefulWidget {
  const DayAgenda({super.key, required this.day});

  final DateTime day;

  @override
  ConsumerState<DayAgenda> createState() => _DayAgendaState();
}

class _DayAgendaState extends ConsumerState<DayAgenda> {
  late DateTime _now = DateTime.now();
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(dayItemsProvider(dayKey(widget.day)));
    return items.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => const Center(child: Text('Liste yüklenemedi.')),
      data: (data) => _build(context, DayGroups.from(data, widget.day)),
    );
  }

  Widget _build(BuildContext context, DayGroups groups) {
    final today = ref.watch(todayProvider);
    if (groups.isEmpty) {
      return Center(
        child: Text(
          widget.day == today
              ? 'Bugün boş. + ile ekle'
              : 'Bu gün boş. + ile ekle',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final nowLineAt = widget.day == today
        ? groups.timed.indexWhere((i) => i.start!.isAfter(_now))
        : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        if (groups.overdue.isNotEmpty) ...[
          const _Section('Gecikmiş'),
          for (final item in groups.overdue) ItemTile(item: item, now: _now),
        ],
        if (groups.untimed.isNotEmpty) ...[
          const _Section('Saatsiz'),
          for (final item in groups.untimed) ItemTile(item: item, now: _now),
        ],
        if (groups.timed.isNotEmpty) ...[
          const _Section('Takvim'),
          for (var i = 0; i < groups.timed.length; i++) ...[
            if (i == nowLineAt) const _NowLine(),
            ItemTile(item: groups.timed[i], now: _now),
          ],
          if (nowLineAt == -1) const _NowLine(),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 2),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Divider(
        color: Theme.of(context).colorScheme.error,
        thickness: 1,
        height: 5,
      ),
    );
  }
}
