import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dates.dart';
import '../../domain/item.dart';
import '../../domain/settings.dart';
import '../../domain/week.dart';
import '../../ui/app_chrome.dart';
import '../../ui/item_tile.dart';
import '../quick_add/quick_add_dialog.dart';

/// Bant geçen haftanın başından itibaren bu kadar gün gösterir.
const _bandDays = 30;
const _bandPadding = 16.0;

final _monthFormat = DateFormat('MMMM y', 'tr');
final _weekdayFormat = DateFormat('EEE', 'tr');

class WeekScreen extends ConsumerStatefulWidget {
  const WeekScreen({super.key});

  @override
  ConsumerState<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends ConsumerState<WeekScreen> {
  final _dayKeys = List.generate(7, (_) => GlobalKey());
  ScrollController? _band;
  double _chipWidth = 0;
  DateTime? _shownWeek;

  DateTime _weekOf(DateTime day) => weekDays(
    day,
    firstWeekday:
        (ref.read(settingsProvider).value ?? const AppSettings()).weekStart,
  ).first;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = MediaQuery.sizeOf(context).width;
    // Açılışın ilk anında ekran genişliği 0 gelebilir.
    if (width == 0) return;
    _chipWidth = (width - _bandPadding * 2) / 7;
    _band ??= ScrollController(initialScrollOffset: 7 * _chipWidth);
  }

  @override
  void dispose() {
    _band?.dispose();
    super.dispose();
  }

  /// Dokunulan günü zaman çizgisinde açar, gerekirse haftasına geçer.
  void _openDay(DateTime day) {
    final week = _weekOf(day);
    setState(() => _shownWeek = week);
    final index = daysBetween(week, day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _dayKeys[index].currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _backToThisWeek(DateTime thisWeek) {
    setState(() => _shownWeek = thisWeek);
    _band?.animateTo(
      7 * _chipWidth,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(weekFocusProvider, (_, focus) {
      if (focus != null) _openDay(focus.day);
    });
    final c = context.colors;
    final today = ref.watch(todayProvider);
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final thisWeek = weekDays(today, firstWeekday: settings.weekStart).first;
    final week = _shownWeek ?? thisWeek;
    final days = weekDays(week, firstWeekday: settings.weekStart);
    final focus = addDays(week, 3);
    final bandStart = addDays(thisWeek, -7);
    final bandItems =
        ref.watch(monthItemsProvider(dayKey(bandStart))).value ??
        const <AgendaItem>[];
    final filledDays = {for (final item in bandItems) item.day};
    final items =
        ref.watch(weekItemsProvider(dayKey(week))).value ??
        const <AgendaItem>[];

    return Column(
      children: [
        AppHeader(
          title: Row(
            children: [
              Flexible(
                child: Text(
                  _monthFormat.format(focus),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.headlineSmall,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HAFTA ${isoWeekNumber(focus)}',
                style: context.type.labelMedium?.copyWith(color: c.muted),
              ),
            ],
          ),
          action: week == thisWeek
              ? null
              : TextButton(
                  onPressed: () => _backToThisWeek(thisWeek),
                  child: const Text('Bugün'),
                ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(66),
          child: _chipWidth == 0
              ? null
              : ListView.builder(
                  key: const Key('day-band'),
                  controller: _band,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: _bandPadding),
                  itemExtent: _chipWidth,
                  itemCount: _bandDays,
                  itemBuilder: (context, index) {
                    final day = addDays(bandStart, index);
                    final inWeek =
                        !day.isBefore(week) && day.isBefore(addDays(week, 7));
                    return Opacity(
                      opacity: inWeek ? 1 : 0.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: _DayChip(
                          key: ValueKey(dayKey(day)),
                          day: day,
                          isToday: day == today,
                          hasItems: filledDays.contains(day),
                          onTap: () => _openDay(day),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        Divider(color: c.high, height: 1, indent: 16, endIndent: 16),
        Expanded(
          child: ListView(
            key: ValueKey(dayKey(week)),
            padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
            children: [
              for (var i = 0; i < days.length; i++)
                _dayBlock(days[i], _dayKeys[i], today, items),
            ],
          ),
        ),
        const QuickAddBar(),
      ],
    );
  }

  Widget _dayBlock(
    DateTime day,
    Key key,
    DateTime today,
    List<AgendaItem> items,
  ) {
    final groups = DayGroups.from(items.where((i) => i.day == day), day);
    return _DayBlock(
      key: key,
      day: day,
      isToday: day == today,
      items: [...groups.timed, ...groups.untimed],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.day,
    required this.isToday,
    required this.hasItems,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool hasItems;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
    return Semantics(
      button: true,
      label: DateFormat('d MMMM EEEE', 'tr').format(day),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isToday
                  ? c.high
                  : c.container.withValues(alpha: weekend ? 0.3 : 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday ? c.accent : c.high.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  _weekdayFormat.format(day).toUpperCase(),
                  style: context.type.labelSmall?.copyWith(
                    color: isToday ? c.accentText : c.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: context.type.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: weekend && !isToday ? c.muted : c.text,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: isToday ? 6 : 4,
                  height: isToday ? 6 : 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !hasItems
                        ? Colors.transparent
                        : (isToday ? c.accent : c.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Zaman çizgisindeki bir gün: Solda nokta ve çizgi, sağda girdiler.
class _DayBlock extends ConsumerWidget {
  const _DayBlock({
    super.key,
    required this.day,
    required this.isToday,
    required this.items,
  });

  final DateTime day;
  final bool isToday;
  final List<AgendaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = DateTime.now();
    final lineColor = isToday ? c.accent.withValues(alpha: 0.4) : c.hairline;
    final label = _weekdayFormat.format(day).toUpperCase();

    final content = Stack(
      children: [
        Positioned(
          left: 7,
          top: 8,
          bottom: 0,
          child: Container(width: 1, color: lineColor),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/day/${dayKey(day)}'),
              child: Row(
                children: [
                  _Node(active: isToday),
                  const SizedBox(width: 10),
                  Text(
                    '$label ${day.day}',
                    style: context.type.labelMedium?.copyWith(
                      color: isToday ? c.accentText : c.muted,
                    ),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• Bugün',
                      style: context.type.labelSmall?.copyWith(
                        color: c.accentText,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      tooltip: 'Ekle',
                      padding: EdgeInsets.zero,
                      onPressed: () => showQuickAdd(context, day: day),
                      icon: Icon(Icons.add, size: 16, color: c.muted),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 0, 4),
                      child: Text(
                        'Planlanan görev yok.',
                        style: context.type.bodySmall?.copyWith(
                          color: c.muted.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (final item in items)
                          ItemTile(item: item, now: now, card: false),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: isToday
          ? Container(
              padding: const EdgeInsets.fromLTRB(4, 6, 0, 6),
              decoration: BoxDecoration(
                color: c.low.withValues(alpha: 0.5),
                border: Border(left: BorderSide(color: c.accent, width: 2)),
              ),
              child: content,
            )
          : content,
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface,
        shape: BoxShape.circle,
        border: Border.all(color: active ? c.accent : c.hairline),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? c.accent : c.muted,
        ),
      ),
    );
  }
}
