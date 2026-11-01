import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/db/app_database.dart';
import '../data/repositories/item_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../domain/dates.dart';
import '../domain/item.dart';
import '../domain/item_service.dart';
import '../domain/settings.dart';
import '../notifications/notification_service.dart';

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

final itemServiceProvider = Provider((ref) {
  final service = ItemService(
    store: ref.watch(itemRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
    reminders: ref.watch(reminderGatewayProvider),
    newId: const Uuid().v7,
    deferReplan: true,
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

final itemProvider = StreamProvider.autoDispose.family<AgendaItem?, String>(
  (ref, id) => ref.watch(itemRepositoryProvider).watchItem(id),
);

final trashProvider = StreamProvider.autoDispose<List<AgendaItem>>(
  (ref) => ref.watch(itemRepositoryProvider).watchTrash(),
);
