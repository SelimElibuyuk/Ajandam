import 'task_lifecycle.dart';

class AppSettings {
  const AppSettings({
    this.weekStart = DateTime.monday,
    this.defaultReminderMin = 15,
    this.autoRollover = true,
    this.lifecycleEnabled = true,
    this.lifecycleTtlDays = 15,
    this.lifecycleIntervalDays = 2,
    this.theme = 'dark',
  });

  final int weekStart;
  final int defaultReminderMin;
  final bool autoRollover;
  final bool lifecycleEnabled;
  final int lifecycleTtlDays;
  final int lifecycleIntervalDays;

  /// system | light | dark
  final String theme;

  LifecycleRule get lifecycle => LifecycleRule(
    enabled: lifecycleEnabled,
    ttlDays: lifecycleTtlDays,
    intervalDays: lifecycleIntervalDays,
  );

  AppSettings copyWith({
    int? weekStart,
    int? defaultReminderMin,
    bool? autoRollover,
    bool? lifecycleEnabled,
    int? lifecycleTtlDays,
    int? lifecycleIntervalDays,
    String? theme,
  }) => AppSettings(
    weekStart: weekStart ?? this.weekStart,
    defaultReminderMin: defaultReminderMin ?? this.defaultReminderMin,
    autoRollover: autoRollover ?? this.autoRollover,
    lifecycleEnabled: lifecycleEnabled ?? this.lifecycleEnabled,
    lifecycleTtlDays: lifecycleTtlDays ?? this.lifecycleTtlDays,
    lifecycleIntervalDays: lifecycleIntervalDays ?? this.lifecycleIntervalDays,
    theme: theme ?? this.theme,
  );
}
