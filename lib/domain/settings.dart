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
    this.widgetTapMode = 'week_view',
    this.palette = 'nocturne',
    this.widgetOpacity = 100,
    this.widgetRadius = 16,
  });

  final int weekStart;
  final int defaultReminderMin;
  final bool autoRollover;
  final bool lifecycleEnabled;
  final int lifecycleTtlDays;
  final int lifecycleIntervalDays;

  /// system | light | dark
  final String theme;

  /// Widget gövdesine dokununca: quick_add | week_view
  final String widgetTapMode;

  /// Renk teması, bkz. palettes.dart
  final String palette;

  /// Widget arka planının saydamlığı, 0–100 (100 tam opak).
  final int widgetOpacity;

  /// Widget köşe yuvarlaklığı, dp.
  final int widgetRadius;

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
    String? widgetTapMode,
    String? palette,
    int? widgetOpacity,
    int? widgetRadius,
  }) => AppSettings(
    weekStart: weekStart ?? this.weekStart,
    defaultReminderMin: defaultReminderMin ?? this.defaultReminderMin,
    autoRollover: autoRollover ?? this.autoRollover,
    lifecycleEnabled: lifecycleEnabled ?? this.lifecycleEnabled,
    lifecycleTtlDays: lifecycleTtlDays ?? this.lifecycleTtlDays,
    lifecycleIntervalDays: lifecycleIntervalDays ?? this.lifecycleIntervalDays,
    theme: theme ?? this.theme,
    widgetTapMode: widgetTapMode ?? this.widgetTapMode,
    palette: palette ?? this.palette,
    widgetOpacity: widgetOpacity ?? this.widgetOpacity,
    widgetRadius: widgetRadius ?? this.widgetRadius,
  );
}
