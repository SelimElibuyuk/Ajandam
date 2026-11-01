import 'dates.dart';
import 'item.dart';
import 'settings.dart';

/// Widget'ta bir kutuya dokunuldu; kalıcı kayda işlenmeyi bekliyor.
class WidgetAction {
  const WidgetAction({required this.id, required this.done, required this.at});

  final String id;
  final bool done;
  final DateTime at;
}

abstract class WidgetGateway {
  /// Anlık görüntüyü yazar, [refreshTimes] anlarında widget kendini yeniler.
  Future<void> publish(String snapshot, List<DateTime> refreshTimes);

  /// Bekleyen dokunuşları döndürür ve sırayı boşaltır.
  Future<List<WidgetAction>> takeActions();
}

class NoWidget implements WidgetGateway {
  const NoWidget();

  @override
  Future<void> publish(String snapshot, List<DateTime> refreshTimes) async {}

  @override
  Future<List<WidgetAction>> takeActions() async => const [];
}

const _maxTitle = 80;
const _maxPerDay = 30;
const _maxRefreshes = 24;

/// Dünü de içerir: Gece uygulama çalışmasa da widget kalanları gösterebilir.
Map<String, dynamic> buildSnapshot(
  Iterable<AgendaItem> items, {
  required DateTime today,
  required DateTime now,
  required AppSettings settings,
}) {
  final byDay = <DateTime, List<AgendaItem>>{};
  for (final item in items) {
    final carried = item.isTask && !item.isDone && item.day.isBefore(today);
    (byDay[carried ? today : item.day] ??= []).add(item);
  }

  return {
    'generatedAt': now.toUtc().toIso8601String(),
    'tapMode': settings.widgetTapMode,
    'theme': settings.theme,
    'days': [for (var i = -1; i <= 7; i++) _day(addDays(today, i), byDay, now)],
  };
}

Map<String, dynamic> _day(
  DateTime day,
  Map<DateTime, List<AgendaItem>> byDay,
  DateTime now,
) {
  final items = byDay[day] ?? const <AgendaItem>[];
  final groups = DayGroups.from(items, day);
  final ordered = [...groups.overdue, ...groups.timed, ...groups.untimed];
  return {
    'date': dayKey(day),
    'remaining': ordered.where((i) => !i.isFinished(now)).length,
    'items': [for (final item in ordered.take(_maxPerDay)) _item(item)],
  };
}

Map<String, dynamic> _item(AgendaItem item) {
  final title = item.title;
  return {
    'id': item.id,
    'title': title.length > _maxTitle ? title.substring(0, _maxTitle) : title,
    'kind': item.isTask ? 'task' : 'event',
    'done': item.isDone,
    'day': dayKey(item.day),
    if (item.start != null) ...{
      'time': hhmm(item.start!),
      'startMs': item.start!.millisecondsSinceEpoch,
    },
    if (item.end != null) 'endMs': item.end!.millisecondsSinceEpoch,
  };
}

/// Gece yarısı ve bugünün saatli girdileri geçerken görünüm değişir.
List<DateTime> widgetRefreshTimes(Iterable<AgendaItem> items, DateTime now) {
  final moments = <DateTime>{addDays(dayOnly(now), 1)};
  final limit = now.add(const Duration(days: 1));
  for (final item in items) {
    final moment = item.isTask ? item.start : item.end;
    if (moment != null && moment.isAfter(now) && moment.isBefore(limit)) {
      moments.add(moment.add(const Duration(seconds: 30)));
    }
  }
  return (moments.toList()..sort()).take(_maxRefreshes).toList();
}
