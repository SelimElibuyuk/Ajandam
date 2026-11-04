import 'dates.dart';
import 'item.dart';

/// Geçmiş güne ait tamamlanmamış görevi [today] gününe taşır,
/// taşınacak bir şey yoksa null döner.
AgendaItem? rollover(AgendaItem item, DateTime today) {
  // Tekrarlar kendi gününde kalır, ertesi gün yenisi gelir.
  if (!item.isTask || item.isDone || item.isDeleted) return null;
  if (item.recurrence != null || item.isOccurrence) return null;
  final missed = daysBetween(item.day, today);
  if (missed <= 0) return null;
  return item.movedTo(today, rolledBy: missed);
}
