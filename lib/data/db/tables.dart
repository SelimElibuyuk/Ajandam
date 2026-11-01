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
  TextColumn get timezone => text().nullable()();
  IntColumn get doneAt => integer().nullable()();

  /// 0 normal, 1 önemli
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();
  IntColumn get rolledCount => integer().withDefault(const Constant(0))();

  /// YYYY-MM-DD, görev ömrü sayacının başladığı gün
  TextColumn get lifecycleAnchorDate => text().nullable()();

  /// RFC 5545 (P1)
  TextColumn get rrule => text().nullable()();
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

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
