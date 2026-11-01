import 'dates.dart';
import 'item.dart';

/// Geçmiş güne ait tamamlanmamış görevi [today] gününe taşır,
/// taşınacak bir şey yoksa null döner.
AgendaItem? rollover(AgendaItem item, DateTime today) {
  if (!item.isTask || item.isDone || item.isDeleted) return null;
  final missed = daysBetween(item.day, today);
  if (missed <= 0) return null;
  return item.movedTo(today, rolledBy: missed);
}
