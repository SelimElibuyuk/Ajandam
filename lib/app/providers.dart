import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/db/app_database.dart';
import '../data/repositories/habit_repository.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/dates.dart';
import '../domain/habit.dart';
import '../domain/habit_service.dart';
import '../domain/item.dart';
import '../domain/item_service.dart';
import '../domain/settings.dart';
import '../domain/widget_snapshot.dart';
import '../notifications/notification_service.dart';
import '../voice/voice_input.dart';
import '../widget_bridge/home_widget_bridge.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final itemRepositoryProvider = Provider(
  (ref) => ItemRepository(ref.watch(databaseProvider)),
);

final settingsRepositoryProvider = Provider(
  (ref) => SettingsRepository(ref.watch(databaseProvider)),
);

final reminderGatewayProvider = Provider<ReminderGateway>(
  (ref) => NotificationService.instance,
);

final widgetGatewayProvider = Provider<WidgetGateway>(
  (ref) => const HomeWidgetBridge(),
);

final widgetLinksProvider = Provider((ref) => const WidgetLinks());

final voiceInputProvider = Provider<VoiceInput>((ref) => SpeechVoiceInput());

/// Hafta ekranını bir güne getirme isteği, ör. widget'tan gelince.
class WeekFocus {
  const WeekFocus(this.day);

  final DateTime day;
}

class WeekFocusNotifier extends Notifier<WeekFocus?> {
  @override
  WeekFocus? build() => null;

  void show(DateTime day) => state = WeekFocus(day);
}

final weekFocusProvider = NotifierProvider<WeekFocusNotifier, WeekFocus?>(
  WeekFocusNotifier.new,
);

final itemServiceProvider = Provider((ref) {
  final service = ItemService(
    store: ref.watch(itemRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    reminders: ref.watch(reminderGatewayProvider),
    newId: const Uuid().v7,
    deferReplan: true,
    widget: ref.watch(widgetGatewayProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// Bugünün tarihi, gece yarısı kendiliğinden güncellenir.
final todayProvider = NotifierProvider<TodayNotifier, DateTime>(
  TodayNotifier.new,
);

class TodayNotifier extends Notifier<DateTime> {
  Timer? _timer;

  @override
  DateTime build() {
    ref.onDispose(() => _timer?.cancel());
    _schedule();
    return dayOnly(DateTime.now());
  }

  void _schedule() {
    _timer?.cancel();
    final now = DateTime.now();
    final tomorrow = addDays(dayOnly(now), 1);
    _timer = Timer(tomorrow.difference(now), () {
      refresh();
      _schedule();
    });
  }

  void refresh() {
    final today = dayOnly(DateTime.now());
    if (today != state) state = today;
  }
}

final dayItemsProvider = StreamProvider.autoDispose
    .family<List<AgendaItem>, String>((ref, key) {
      final day = parseDayKey(key);
      final today = ref.watch(todayProvider);
      return ref
          .watch(itemRepositoryProvider)
          .watchDays(day, day, overdueBefore: day == today ? today : null);
    });

/// Haftanın ilk gününe göre 7 günün girdileri.
final weekItemsProvider = StreamProvider.autoDispose
    .family<List<AgendaItem>, String>((ref, key) {
      final first = parseDayKey(key);
      return ref
          .watch(itemRepositoryProvider)
          .watchDays(first, addDays(first, 6));
    });

/// Ay ızgarasının ilk gününe göre görünen tüm günlerin girdileri.
final monthItemsProvider = StreamProvider.autoDispose
    .family<List<AgendaItem>, String>((ref, key) {
      final first = parseDayKey(key);
      return ref
          .watch(itemRepositoryProvider)
          .watchDays(first, addDays(first, 41));
    });

final itemProvider = StreamProvider.autoDispose.family<AgendaItem?, String>(
  (ref, id) => ref.watch(itemRepositoryProvider).watchItem(id),
);

final trashProvider = StreamProvider.autoDispose<List<AgendaItem>>(
  (ref) => ref.watch(itemRepositoryProvider).watchTrash(),
);

final habitRepositoryProvider = Provider(
  (ref) => HabitRepository(ref.watch(databaseProvider)),
);

final habitWidgetProvider = Provider<HabitWidgetGateway>(
  (ref) => const HomeWidgetBridge(),
);

final habitServiceProvider = Provider((ref) {
  final service = HabitService(
    store: ref.watch(habitRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    newId: const Uuid().v7,
    widget: ref.watch(habitWidgetProvider),
    deferPublish: true,
  );
  ref.onDispose(service.dispose);
  return service;
});

final habitsProvider = StreamProvider<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchHabits(),
);

final habitHistoryProvider = StreamProvider.autoDispose
    .family<Map<DateTime, int>, String>(
      (ref, id) => ref.watch(habitRepositoryProvider).watchHistory(id),
    );

final habitFreezesProvider = StreamProvider.autoDispose
    .family<Map<DateTime, bool>, String>(
      (ref, id) => ref.watch(habitRepositoryProvider).watchFreezeDecisions(id),
    );

/// Bu oturumda dondurma sorusu sorulan alışkanlık boşlukları; dışarı dokunup
/// kapatılsa da yeniden çizimde tekrar sorulmaz.
final freezeAskedProvider = Provider<Set<String>>((ref) => <String>{});

/// Ay ekranında gösterilen takvim: null ise ajanda, değilse alışkanlık.
class SelectedHabitNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedHabitProvider = NotifierProvider<SelectedHabitNotifier, String?>(
  SelectedHabitNotifier.new,
);
