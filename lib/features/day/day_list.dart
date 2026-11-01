import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../ui/item_tile.dart';

/// Bir günün girdileri. Kaydırma, içine konduğu ekrana aittir.
class DayList extends ConsumerStatefulWidget {
  const DayList({super.key, required this.day});

  final DateTime day;

  @override
  ConsumerState<DayList> createState() => _DayListState();
}

class _DayListState extends ConsumerState<DayList> {
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
      loading: () => const SizedBox(height: 48),
      error: (error, _) => const Text('Liste yüklenemedi.'),
      data: (data) => _build(context, DayGroups.from(data, widget.day)),
    );
  }

  Widget _build(BuildContext context, DayGroups groups) {
    final today = ref.watch(todayProvider);
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            widget.day == today ? 'Bugün boş.' : 'Bu gün boş.',
            style: context.type.bodySmall?.copyWith(
              color: context.colors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final filled = [
      groups.overdue,
      groups.untimed,
      groups.timed,
    ].where((g) => g.isNotEmpty).length;
    final nowLineAt = widget.day == today
        ? groups.timed.indexWhere((i) => i.start!.isAfter(_now))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (groups.overdue.isNotEmpty) ...[
          const _Section('Gecikmiş'),
          for (final item in groups.overdue) ItemTile(item: item, now: _now),
        ],
        if (groups.untimed.isNotEmpty) ...[
          if (filled > 1) const _Section('Saatsiz'),
          for (final item in groups.untimed) ItemTile(item: item, now: _now),
        ],
        if (groups.timed.isNotEmpty) ...[
          if (filled > 1) const _Section('Takvim'),
          for (var i = 0; i < groups.timed.length; i++) ...[
            if (i == nowLineAt) const _NowLine(),
            ItemTile(item: groups.timed[i], now: _now),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        label,
        style: context.type.labelMedium?.copyWith(color: context.colors.muted),
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  const _NowLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Divider(color: context.colors.accent, height: 1),
    );
  }
}
