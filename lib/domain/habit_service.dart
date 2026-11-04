import 'dart:async';
import 'dart:convert';

import 'dates.dart';
import 'habit.dart';
import 'item_service.dart';
import 'palettes.dart';
import 'settings.dart';

abstract class HabitStore {
  /// Sıraya göre tüm alışkanlıklar.
  Future<List<Habit>> habits();
  Future<Habit?> habitById(String id);
  Future<void> insertHabit(Habit habit);
  Future<void> updateHabit(Habit habit);

  /// Alışkanlığı geçmişiyle birlikte siler.
  Future<void> deleteHabit(String id);

  /// [from]..[to] arasındaki sayılar, alışkanlığa göre.
  Future<Map<String, Map<DateTime, int>>> counts(DateTime from, DateTime to);

  /// Alışkanlığın tüm geçmişi.
  Future<Map<DateTime, int>> history(String habitId);
  Future<void> setCount(String habitId, DateTime day, int count, DateTime at);
}

/// Alışkanlık widget'ında dokunulan gün; sayı mutlak tutulur, iki kez
/// işlense de sonuç değişmez.
class HabitAction {
  const HabitAction({
    required this.habitId,
    required this.day,
    required this.count,
    required this.at,
  });

  final String habitId;
  final DateTime day;
  final int count;
  final DateTime at;
}

abstract class HabitWidgetGateway {
  Future<void> publishHabits(String snapshot);

  /// Bekleyen dokunuşları döndürür ve sırayı boşaltır.
  Future<List<HabitAction>> takeHabitActions();
}

class NoHabitWidget implements HabitWidgetGateway {
  const NoHabitWidget();

  @override
  Future<void> publishHabits(String snapshot) async {}

  @override
  Future<List<HabitAction>> takeHabitActions() async => const [];
}

/// Widget bu kadar günün sayısını taşır; daha eskisi tek bir seri sayısıdır.
const habitWindowDays = 35;
const _maxTitle = 60;
const _publishDelay = Duration(milliseconds: 300);

class HabitService {
  HabitService({
    required this._store,
    required this._settings,
    required this._newId,
    this._widget = const NoHabitWidget(),
    this._deferPublish = false,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final HabitStore _store;
  final SettingsStore _settings;
  final String Function() _newId;
  final HabitWidgetGateway _widget;
  final DateTime Function() _clock;

  /// Arayüzde art arda dokunuşlar widget'ı bir kez yeniler; arka planda süreç
  /// kapanabileceği için hemen yazılır.
  final bool _deferPublish;
  Timer? _publishTimer;

  Future<Habit> create({
    required String title,
    Set<int> weekdays = const {},
    int? target,
    int? color,
  }) async {
    final now = _clock();
    final existing = await _store.habits();
    final habit = Habit(
      id: _newId(),
      title: title.trim(),
      weekdays: weekdays.length == 7 ? const {} : weekdays,
      target: target != null && target > 1 ? target : null,
      color: color ?? existing.length % habitColors.length,
      startDay: dayOnly(now),
      order: existing.isEmpty ? 0 : existing.last.order + 1,
      createdAt: now,
      updatedAt: now,
    );
    await _store.insertHabit(habit);
    await _changed();
    return habit;
  }

  Future<void> save(Habit habit) async {
    await _store.updateHabit(
      habit.copyWith(
        title: habit.title.trim(),
        weekdays: habit.weekdays.length == 7 ? const {} : habit.weekdays,
        target: () => (habit.target ?? 0) > 1 ? habit.target : null,
        updatedAt: _clock(),
      ),
    );
    await _changed();
  }

  Future<void> delete(String id) async {
    await _store.deleteHabit(id);
    await _changed();
  }

  /// Gelecek günler işaretlenmez. Yeni sayıyı döndürür.
  Future<int?> tap(Habit habit, DateTime day, int current) async {
    if (dayOnly(day).isAfter(dayOnly(_clock()))) return null;
    final next = habit.tapped(current);
    await _store.setCount(habit.id, dayOnly(day), next, _clock());
    await _changed();
    return next;
  }

  Future<void> reset(Habit habit, DateTime day) async {
    await _store.setCount(habit.id, dayOnly(day), 0, _clock());
    await _changed();
  }

  /// Widget'ta dokunulan günleri kalıcı kayda işler.
  Future<void> applyWidgetActions() async {
    final actions = await _widget.takeHabitActions();
    if (actions.isEmpty) return;
    final known = {for (final h in await _store.habits()) h.id};
    for (final action in actions) {
      if (!known.contains(action.habitId)) continue;
      await _store.setCount(
        action.habitId,
        dayOnly(action.day),
        action.count,
        action.at,
      );
    }
    await _changed();
  }

  Future<void> publishWidget() async {
    _publishTimer?.cancel();
    _publishTimer = null;
    final now = _clock();
    final today = dayOnly(now);
    final from = addDays(today, 1 - habitWindowDays);
    final habits = await _store.habits();
    final counts = await _store.counts(from, today);
    final settings = await _settings.load();
    final older = <String, int>{};
    for (final habit in habits) {
      // Pencerenin dışındaki seri tek sayı olarak taşınır.
      final history = HabitHistory(habit, await _store.history(habit.id));
      older[habit.id] = history.streakEndingAt(addDays(from, -1));
    }
    await _widget.publishHabits(
      jsonEncode(
        buildHabitSnapshot(
          habits,
          counts,
          older,
          from: from,
          now: now,
          settings: settings,
        ),
      ),
    );
  }

  /// Bekleyen widget yazımını hemen yapar, ör. uygulama arka plana geçerken.
  Future<void> flush() async {
    if (_publishTimer != null) await publishWidget();
  }

  void dispose() => _publishTimer?.cancel();

  Future<void> _changed() async {
    if (!_deferPublish) return publishWidget();
    _publishTimer?.cancel();
    _publishTimer = Timer(_publishDelay, publishWidget);
  }
}

Map<String, dynamic> buildHabitSnapshot(
  List<Habit> habits,
  Map<String, Map<DateTime, int>> counts,
  Map<String, int> olderStreaks, {
  required DateTime from,
  required DateTime now,
  required AppSettings settings,
}) => {
  'generatedAt': now.toUtc().toIso8601String(),
  ...widgetAppearance(settings),
  'windowStart': dayKey(from),
  'habits': [
    for (final habit in habits)
      {
        'id': habit.id,
        'title': habit.title.length > _maxTitle
            ? habit.title.substring(0, _maxTitle)
            : habit.title,
        'color': habitColors[habit.color % habitColors.length],
        'goal': habit.goal,
        'weekdays': (habit.weekdays.toList()..sort()),
        'start': dayKey(habit.startDay),
        'olderStreak': olderStreaks[habit.id] ?? 0,
        'counts': {
          for (final e in (counts[habit.id] ?? const {}).entries)
            if (e.value > 0) dayKey(e.key): e.value,
        },
      },
  ],
};
