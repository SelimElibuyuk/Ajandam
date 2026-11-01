DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// YYYY-MM-DD
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Yaz saati geçişlerinden etkilenmez, saat ve dakika korunur.
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

/// [from] gününden [to] gününe kaç takvim günü olduğunu döndürür.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

String hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';
