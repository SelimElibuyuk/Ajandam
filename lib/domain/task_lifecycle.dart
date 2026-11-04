import 'dates.dart';
import 'item.dart';

/// Tamamlanmayan görevlerin ne kadar yaşayacağını belirler (PRD FR-6).
class LifecycleRule {
  const LifecycleRule({
    this.enabled = true,
    this.ttlDays = 15,
    this.intervalDays = 2,
  });

  final bool enabled;
  final int ttlDays;
  final int intervalDays;

  bool appliesTo(AgendaItem item) =>
      enabled &&
      item.isTask &&
      !item.isDone &&
      !item.isDeleted &&
      !item.important &&
      item.recurrence == null &&
      !item.isOccurrence &&
      item.anchorDay != null;

  DateTime expiryDay(AgendaItem item) => addDays(item.anchorDay!, ttlDays);

  int daysLeft(AgendaItem item, DateTime today) =>
      daysBetween(today, expiryDay(item));

  bool isExpired(AgendaItem item, DateTime today) =>
      appliesTo(item) && daysLeft(item, today) <= 0;

  /// Hatırlatma günleri, silinme gününden önce biter.
  List<DateTime> reminderDays(AgendaItem item) => [
    for (var d = intervalDays; d < ttlDays; d += intervalDays)
      addDays(item.anchorDay!, d),
  ];
}
