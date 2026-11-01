import 'dates.dart';
import 'item.dart';
import 'task_lifecycle.dart';

enum NotificationType { item, lifecycle, lifecycleGroup }

class PlannedNotification {
  const PlannedNotification({
    required this.key,
    required this.when,
    required this.title,
    required this.body,
    required this.type,
    required this.itemIds,
  });

  /// Aynı içerikle yeniden planlandığında değişmeyen kimlik.
  final String key;
  final DateTime when;
  final String title;
  final String body;
  final NotificationType type;
  final List<String> itemIds;
}

/// Eklenti her planlamada tüm listeyi ana iş parçacığında yeniden yazdığı için
/// yalnızca en yakınlar planlanır; gerisi uygulama açılınca veya saatlik arka
/// plan işinde sıraya girer.
const maxPlanned = 50;

const lifecycleHour = 9;

List<PlannedNotification> planNotifications(
  Iterable<AgendaItem> items,
  LifecycleRule rule,
  DateTime now,
) {
  final open = items.where((i) => !i.isDone && !i.isDeleted).toList();
  final plans = [
    for (final item in open) ?_itemReminder(item, now),
    ..._lifecycleReminders(open, rule, now),
  ]..sort((a, b) => a.when.compareTo(b.when));
  return plans.take(maxPlanned).toList();
}

PlannedNotification? _itemReminder(AgendaItem item, DateTime now) {
  final snoozed = item.snoozedUntil;
  if (snoozed != null && snoozed.isAfter(now)) {
    return _plain(item, snoozed, 'Ertelendi');
  }
  final start = item.start;
  final offset = item.reminderMin;
  if (start == null || offset == null) return null;
  final when = start.subtract(Duration(minutes: offset));
  if (!when.isAfter(now)) return null;
  final lead = offset == 0 ? 'Şimdi' : '${offsetLabel(offset)} sonra';
  return _plain(item, when, '${hhmm(start)} · $lead');
}

PlannedNotification _plain(AgendaItem item, DateTime when, String body) =>
    PlannedNotification(
      key: 'item|${item.id}|${when.millisecondsSinceEpoch}|${item.title}|$body',
      when: when,
      title: item.title,
      body: body,
      type: NotificationType.item,
      itemIds: [item.id],
    );

Iterable<PlannedNotification> _lifecycleReminders(
  List<AgendaItem> open,
  LifecycleRule rule,
  DateTime now,
) sync* {
  final byDay = <DateTime, List<AgendaItem>>{};
  for (final item in open.where(rule.appliesTo)) {
    for (final day in rule.reminderDays(item)) {
      final when = DateTime(day.year, day.month, day.day, lifecycleHour);
      if (when.isAfter(now)) (byDay[day] ??= []).add(item);
    }
  }
  for (final MapEntry(key: day, value: due) in byDay.entries) {
    final when = DateTime(day.year, day.month, day.day, lifecycleHour);
    final ids = [for (final item in due) item.id];
    final left = [for (final item in due) rule.daysLeft(item, day)];
    if (due.length == 1) {
      yield PlannedNotification(
        key:
            'life|${ids.first}|${dayKey(day)}|${due.first.title}|${left.first}',
        when: when,
        title: due.first.title,
        body: 'Silinmesine ${left.first} gün kaldı',
        type: NotificationType.lifecycle,
        itemIds: ids,
      );
    } else {
      final lines = [
        for (var i = 0; i < due.length; i++) '${due[i].title} (${left[i]} gün)',
      ];
      yield PlannedNotification(
        key: 'group|${dayKey(day)}|${ids.join(',')}|${lines.join(',')}',
        when: when,
        title: '${due.length} görev silinmeye yaklaşıyor',
        body: lines.join(', '),
        type: NotificationType.lifecycleGroup,
        itemIds: ids,
      );
    }
  }
}

String offsetLabel(int minutes) {
  if (minutes >= 1440 && minutes % 1440 == 0) return '${minutes ~/ 1440} gün';
  if (minutes >= 60 && minutes % 60 == 0) return '${minutes ~/ 60} saat';
  return '$minutes dk';
}
