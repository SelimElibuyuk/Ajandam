import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get provider => text()();
  TextColumn get email => text()();
  IntColumn get connectedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Calendars extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get googleCalendarId => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// owner | writer | reader
  TextColumn get accessRole => text()();
  TextColumn get syncToken => text().nullable()();
  IntColumn get lastSyncedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'items_date', columns: {#date})
@TableIndex(name: 'items_start_at', columns: {#startAt})
@TableIndex(name: 'items_google_event_id', columns: {#googleEventId})
@TableIndex(name: 'items_updated_at', columns: {#updatedAt})
@TableIndex(name: 'items_series_id', columns: {#seriesId})
class Items extends Table {
  /// uuid v7
  TextColumn get id => text()();

  /// task | event
  TextColumn get kind => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get notes => text().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();

  /// UTC epoch ms
  IntColumn get startAt => integer().nullable()();
  IntColumn get endAt => integer().nullable()();

  /// YYYY-MM-DD, tüm gün girdiler ve saatsiz görevler için
  TextColumn get date => text().nullable()();

  /// YYYY-MM-DD, birkaç gün süren tüm gün etkinliğin son günü
  TextColumn get endDate => text().nullable()();
  TextColumn get timezone => text().nullable()();
  IntColumn get doneAt => integer().nullable()();

  /// 0 normal, 1 önemli
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();
  IntColumn get rolledCount => integer().withDefault(const Constant(0))();

  /// YYYY-MM-DD, görev ömrü sayacının başladığı gün
  TextColumn get lifecycleAnchorDate => text().nullable()();

  /// UTC epoch ms, “10 dk ertele” ile verilen yeni hatırlatma zamanı
  IntColumn get snoozedUntil => integer().nullable()();

  /// RFC 5545 RRULE, yalnızca serinin kendisinde dolu
  TextColumn get rrule => text().nullable()();

  /// Tamamlanan, değiştirilen veya silinen tekrar: serisi ve asıl günü.
  /// Kimliği `seriId~YYYY-MM-DD` biçimindedir.
  TextColumn get seriesId => text().nullable()();
  TextColumn get originalDate => text().nullable()();
  TextColumn get calendarId => text().nullable().references(Calendars, #id)();
  TextColumn get googleEventId => text().nullable()();
  TextColumn get googleEtag => text().nullable()();
  IntColumn get remoteUpdatedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  /// Yumuşak silme: çöp kutusundaki girdiler
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();
  IntColumn get offsetMin => integer()();
  TextColumn get osNotificationId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();

  /// create | update | delete
  TextColumn get op => text()();
  TextColumn get payloadJson => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextTryAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  String get tableName => 'sync_queue';
}

/// Ajandadan ayrı izlenen alışkanlıklar; Google'a yazılmaz.
@DataClassName('HabitRow')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Virgülle ayrılmış haftanın günleri (1 = pazartesi); null ise her gün.
  TextColumn get weekdays => text().nullable()();

  /// Günlük hedef sayı; null ise yaptım/yapmadım.
  IntColumn get target => integer().nullable()();
  IntColumn get color => integer().withDefault(const Constant(0))();

  /// YYYY-MM-DD
  TextColumn get startDate => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Alışkanlığın bir günde yapılan sayısı; satırı olmayan gün yapılmamıştır.
@DataClassName('HabitLogRow')
class HabitLogs extends Table {
  TextColumn get habitId => text().references(Habits, #id)();

  /// YYYY-MM-DD
  TextColumn get date => text()();
  IntColumn get count => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {habitId, date};
}

/// Kaçırılan gün için verilen dondurma kararı; bir kez sorulur.
@DataClassName('HabitFreezeRow')
class HabitFreezes extends Table {
  TextColumn get habitId => text().references(Habits, #id)();

  /// YYYY-MM-DD
  TextColumn get date => text()();

  /// true dondurulmuş, false seri bozulsun denmiş.
  BoolColumn get frozen => boolean()();

  @override
  Set<Column> get primaryKey => {habitId, date};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
