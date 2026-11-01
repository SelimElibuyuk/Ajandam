import '../../domain/item_service.dart';
import '../../domain/settings.dart';
import '../db/app_database.dart';

class SettingsRepository implements SettingsStore {
  SettingsRepository(this._db);

  final AppDatabase _db;

  @override
  Future<AppSettings> load() async =>
      _fromRows(await _db.select(_db.settings).get());

  Stream<AppSettings> watch() =>
      _db.select(_db.settings).watch().map(_fromRows);

  Future<void> save(AppSettings s) => _db.batch((batch) {
    batch.insertAllOnConflictUpdate(_db.settings, [
      _row('week_start', s.weekStart),
      _row('default_reminder_min', s.defaultReminderMin),
      _row('auto_rollover', s.autoRollover),
      _row('lifecycle_enabled', s.lifecycleEnabled),
      _row('lifecycle_ttl_days', s.lifecycleTtlDays),
      _row('lifecycle_interval_days', s.lifecycleIntervalDays),
      _row('theme', s.theme),
      _row('widget_body_tap', s.widgetTapMode),
    ]);
  });

  SettingsCompanion _row(String key, Object value) =>
      SettingsCompanion.insert(key: key, value: '$value');

  AppSettings _fromRows(List<Setting> rows) {
    final values = {for (final row in rows) row.key: row.value};
    const d = AppSettings();
    int number(String key, int fallback) =>
        int.tryParse(values[key] ?? '') ?? fallback;
    bool flag(String key, bool fallback) =>
        values[key] == null ? fallback : values[key] == 'true';
    return AppSettings(
      weekStart: number('week_start', d.weekStart),
      defaultReminderMin: number('default_reminder_min', d.defaultReminderMin),
      autoRollover: flag('auto_rollover', d.autoRollover),
      lifecycleEnabled: flag('lifecycle_enabled', d.lifecycleEnabled),
      lifecycleTtlDays: number('lifecycle_ttl_days', d.lifecycleTtlDays),
      lifecycleIntervalDays: number(
        'lifecycle_interval_days',
        d.lifecycleIntervalDays,
      ),
      theme: values['theme'] ?? d.theme,
      widgetTapMode: values['widget_body_tap'] ?? d.widgetTapMode,
    );
  }
}
