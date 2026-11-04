import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/dates.dart';
import '../../domain/habit.dart';
import '../../domain/week.dart';
import 'habit_form.dart';

final _weekdayFormat = DateFormat('EEE', 'tr');

Color habitColor(Habit habit) =>
    Color(habitColors[habit.color % habitColors.length]);

/// Dondurulmuş günlerin buz rengi; açık temada simge biraz koyulaşır.
const _ice = Color(0xFF7FB8E0);

Color _iceInk(AppColors c) => c.dark ? _ice : const Color(0xFF3F86B8);

/// Sayılar ve dondurma kararlarıyla geçmiş; yüklenmeyen taraf boş sayılır.
HabitHistory _watchHistory(WidgetRef ref, Habit habit) => HabitHistory(
  habit,
  ref.watch(habitHistoryProvider(habit.id)).value ?? const {},
  ref.watch(habitFreezesProvider(habit.id)).value ?? const {},
);

/// Ay ekranının üstünde ajanda ile alışkanlık takvimleri arasında geçiş.
/// Uzun basmak alışkanlığı düzenler, + yenisini ekler.
class HabitTabs extends ConsumerWidget {
  const HabitTabs({super.key, required this.habits, required this.selected});

  final List<Habit> habits;
  final Habit? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final notifier = ref.read(selectedHabitProvider.notifier);

    Future<void> add() async {
      final id = await showHabitForm(context);
      if (id != null && id.isNotEmpty) notifier.select(id);
    }

    return SizedBox(
      height: 36,
      child: ListView(
        key: const Key('habit-tabs'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Tab(
            label: 'Ajanda',
            color: c.accent,
            selected: selected == null,
            onTap: () => notifier.select(null),
          ),
          for (final habit in habits)
            _Tab(
              label: habit.title,
              color: habitColor(habit),
              selected: selected?.id == habit.id,
              onTap: () => notifier.select(habit.id),
              onLongPress: () async {
                final id = await showHabitForm(context, habit: habit);
                if (id == '') notifier.select(null);
              },
            ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: SizedBox(
              width: 36,
              child: IconButton(
                tooltip: 'Alışkanlık ekle',
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: c.hairline),
                  ),
                ),
                onPressed: add,
                icon: Icon(Icons.add, size: 18, color: c.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? c.high : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: selected ? color : c.hairline),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.bodyMedium?.copyWith(
                        color: selected ? c.text : c.textSoft,
                        fontWeight: selected ? FontWeight.w500 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alışkanlığın ay takvimi; yalnızca gösterir, işaretleme bugün kutusundan.
/// Art arda yapılan günler zincir gibi birbirine bağlanır.
class HabitMonthGrid extends ConsumerWidget {
  const HabitMonthGrid({
    super.key,
    required this.habit,
    required this.month,
    required this.firstWeekday,
    required this.today,
  });

  final Habit habit;
  final DateTime month;
  final int firstWeekday;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final days = monthGrid(month, firstWeekday: firstWeekday);
    final history = _watchHistory(ref, habit);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.low,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final day in days.take(7))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _weekdayFormat.format(day),
                      textAlign: TextAlign.center,
                      style: context.type.labelSmall?.copyWith(
                        color: habit.plannedOn(day) ? c.textSoft : c.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var week = 0; week < days.length ~/ 7; week++)
            Row(
              children: [
                for (final day in days.skip(week * 7).take(7))
                  Expanded(
                    child: _HabitDay(
                      day: day,
                      habit: habit,
                      history: history,
                      inMonth: day.month == month.month,
                      today: today,
                      firstWeekday: firstWeekday,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HabitDay extends StatelessWidget {
  const _HabitDay({
    required this.day,
    required this.habit,
    required this.history,
    required this.inMonth,
    required this.today,
    required this.firstWeekday,
  });

  final DateTime day;
  final Habit habit;
  final HabitHistory history;
  final bool inMonth;
  final DateTime today;
  final int firstWeekday;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = habitColor(habit);
    final count = history.countOn(day);
    final done = count >= habit.goal;
    final frozen = history.frozenOn(day);
    final chained = done || frozen;
    final planned = habit.plannedOn(day);
    final future = day.isAfter(today);
    final isToday = day == today;
    final missed =
        planned &&
        !done &&
        !frozen &&
        !future &&
        !isToday &&
        !day.isBefore(habit.startDay);
    final lastWeekday = (firstWeekday + 5) % 7 + 1;
    DateTime neighbour(int step) =>
        DateTime(day.year, day.month, day.day + step);
    // Bağ yalnızca aynı satırdaki komşuya çizilir; dondurulan günden de geçer.
    bool linked(int step) {
      if (!chained) return false;
      if (day.weekday == (step < 0 ? firstWeekday : lastWeekday)) return false;
      final other = neighbour(step);
      return history.doneOn(other) || history.frozenOn(other);
    }

    // Buza değen bağ buz renginde.
    Color chainColor(int step) =>
        (frozen || history.frozenOn(neighbour(step)) ? _ice : color).withValues(
          alpha: 0.35,
        );

    final Color textColor;
    if (done) {
      textColor = Colors.white;
    } else if (frozen) {
      textColor = c.text;
    } else if (isToday) {
      textColor = c.accentText;
    } else if (!planned || future) {
      textColor = c.muted;
    } else {
      textColor = c.text;
    }

    final cell = AspectRatio(
      aspectRatio: 1.15,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = (box.maxHeight - 6).clamp(0.0, box.maxWidth - 6);
          return Stack(
            alignment: Alignment.center,
            children: [
              // Zincir: dün de yapıldıysa sola, yarın da yapıldıysa sağa bağ.
              if (linked(-1))
                Positioned(
                  left: 0,
                  right: box.maxWidth / 2,
                  child: Container(height: size * 0.32, color: chainColor(-1)),
                ),
              if (linked(1))
                Positioned(
                  left: box.maxWidth / 2,
                  right: 0,
                  child: Container(height: size * 0.32, color: chainColor(1)),
                ),
              Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? color
                      : frozen
                      ? Color.alphaBlend(_ice.withValues(alpha: 0.3), c.low)
                      : count > 0
                      ? color.withValues(alpha: 0.25)
                      : null,
                  border: frozen
                      ? Border.all(color: _ice)
                      : isToday && !done
                      ? Border.all(color: c.accent, width: 1.5)
                      : missed
                      ? Border.all(color: c.hairline)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: context.type.labelMedium?.copyWith(
                        color: textColor,
                        fontWeight: done ? FontWeight.w600 : null,
                      ),
                    ),
                    if (frozen)
                      Icon(Icons.ac_unit, size: 9, color: _iceInk(c))
                    else if (habit.isCounted && count > 0 && !done)
                      Text(
                        '$count/${habit.goal}',
                        style: context.type.labelSmall?.copyWith(
                          fontSize: 8,
                          height: 1,
                          color: c.textSoft,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final shown = Opacity(
      opacity: !inMonth ? 0.3 : (planned ? 1 : 0.45),
      child: cell,
    );
    final label =
        '${DateFormat('d MMMM', 'tr').format(day)}, '
        '${done
            ? 'yapıldı'
            : frozen
            ? 'donduruldu'
            : (habit.isCounted ? '$count/${habit.goal}' : 'yapılmadı')}';
    return Semantics(
      label: label,
      child: ExcludeSemantics(child: shown),
    );
  }
}

/// Takvimin altında seri, oran ve bugünün durumu.
class HabitSummary extends ConsumerWidget {
  const HabitSummary({super.key, required this.habit, required this.today});

  final Habit habit;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final history = _watchHistory(ref, habit);
    final loaded =
        ref.watch(habitHistoryProvider(habit.id)).hasValue &&
        ref.watch(habitFreezesProvider(habit.id)).hasValue;
    if (loaded) _offerFreeze(context, ref, history);
    final count = history.countOn(today);
    final rate = history.rate(today);
    final planned = habit.plannedOn(today);
    final rights = history.freezeRights(today).rights;
    final rule =
        '${habitDaysLabel(habit.weekdays)}'
        '${habit.isCounted ? ' · günde ${habit.goal}' : ''}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title, style: context.type.headlineSmall),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          rule,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.labelMedium?.copyWith(
                            color: c.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FreezeRights(rights: rights),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Düzenle',
              onPressed: () async {
                final id = await showHabitForm(context, habit: habit);
                if (id == '') {
                  ref.read(selectedHabitProvider.notifier).select(null);
                }
              },
              icon: Icon(Icons.edit_outlined, size: 20, color: c.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Stat(label: 'SERİ', value: '${history.streak(today)} gün'),
            const SizedBox(width: 8),
            _Stat(
              label: 'EN UZUN',
              value: '${history.longestStreak(today)} gün',
            ),
            const SizedBox(width: 8),
            _Stat(
              label: '30 GÜN',
              value: rate == null ? '—' : '%${(rate * 100).round()}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TodayButton(
          habit: habit,
          count: count,
          planned: planned,
          onTap: () => ref.read(habitServiceProvider).tap(habit, today, count),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            ref.read(habitServiceProvider).reset(habit, today);
          },
        ),
      ],
    );
  }

  /// Kaçırılan günler için dondurma teklifi; her alışkanlık için oturumda bir
  /// kez sorulur. Dışarı dokunup kapatmak karar sayılmaz.
  void _offerFreeze(BuildContext context, WidgetRef ref, HabitHistory history) {
    final offer = history.freezeOffer(today);
    if (offer == null) return;
    final asked = ref.read(freezeAskedProvider);
    // Aynı boşluk oturumda bir kez sorulur; uygulama açıkken yeni bir boşluk
    // oluşursa yeniden sorulabilir.
    if (!asked.add('${habit.id}@${dayKey(offer.days.first)}')) return;
    final service = ref.read(habitServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      final frozen = await _askFreeze(context, offer, today);
      if (frozen == true) {
        await service.freeze(habit);
      } else if (frozen == false) {
        await service.declineFreeze(habit);
      }
    });
  }
}

Future<bool?> _askFreeze(
  BuildContext context,
  FreezeOffer offer,
  DateTime today,
) {
  final n = offer.days.length;
  final missed = n > 1
      ? '$n gün yapılmadı.'
      : offer.days.single == addDays(today, -1)
      ? 'Dün yapılmadı.'
      : '${DateFormat('d MMMM', 'tr').format(offer.days.single)} yapılmadı.';
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.colors;
      return AlertDialog(
        title: const Text('Seriyi dondur?'),
        content: Text(
          '$missed $n dondurma hakkı kullanıp ${offer.streak} günlük serini '
          'koruyabilirsin. (Kalan hak: ${offer.rights})',
          style: context.type.bodyMedium?.copyWith(color: c.textSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Bozulsun', style: TextStyle(color: c.muted)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.ac_unit, size: 16),
            label: const Text('Dondur'),
          ),
        ],
      );
    },
  );
}

/// Biriken dondurma hakları; seriyi korumak için kullanılır.
class _FreezeRights extends StatelessWidget {
  const _FreezeRights({required this.rights});

  final int rights;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Dondurma hakkı: $rights',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.ac_unit,
              size: 12,
              color: rights > 0 ? _iceInk(c) : c.muted,
            ),
            const SizedBox(width: 3),
            Text(
              '$rights hak',
              style: context.type.labelMedium?.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bugünün durumu; ilk bakışta basılabilir olduğu anlaşılsın diye sağda
/// alışkanlık renginde bir eylem düğmesi taşır.
class _TodayButton extends StatelessWidget {
  const _TodayButton({
    required this.habit,
    required this.count,
    required this.planned,
    required this.onTap,
    required this.onLongPress,
  });

  final Habit habit;
  final int count;
  final bool planned;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = habitColor(habit);
    final done = count >= habit.goal;
    final action = done
        ? 'Geri al'
        : habit.isCounted
        ? '+1'
        : 'Yaptım';

    return Semantics(
      button: true,
      child: Material(
        color: done ? color.withValues(alpha: 0.18) : c.container,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color, width: done ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? color : c.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        done
                            ? 'Bugün yapıldı'
                            : planned
                            ? 'Bugün yapılmadı'
                            : 'Bugün planlı değil',
                        style: context.type.bodyLarge,
                      ),
                      if (habit.isCounted)
                        Text(
                          '$count/${habit.goal}',
                          style: context.type.labelMedium?.copyWith(
                            color: done ? color : c.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: done ? Colors.transparent : color,
                    borderRadius: BorderRadius.circular(8),
                    border: done ? Border.all(color: color) : null,
                  ),
                  child: Text(
                    action,
                    style: context.type.labelLarge?.copyWith(
                      color: done ? color : Colors.white,
                    ),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.low,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.type.labelSmall?.copyWith(color: c.muted),
            ),
            const SizedBox(height: 4),
            Text(value, style: context.type.titleMedium),
          ],
        ),
      ),
    );
  }
}
