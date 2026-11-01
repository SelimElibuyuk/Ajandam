/// [focus] gününü içeren haftanın 7 gününü döndürür.
List<DateTime> weekDays(DateTime focus, {int firstWeekday = DateTime.monday}) {
  final offset = (focus.weekday - firstWeekday) % 7;
  return [
    for (var i = 0; i < 7; i++)
      DateTime(focus.year, focus.month, focus.day - offset + i),
  ];
}

/// Ayı içeren tam haftaların günleri: 28, 35 veya 42 gün.
List<DateTime> monthGrid(DateTime month, {int firstWeekday = DateTime.monday}) {
  final first = DateTime(month.year, month.month);
  final last = DateTime(month.year, month.month + 1, 0);
  final lead = (first.weekday - firstWeekday) % 7;
  final cells = lead + last.day;
  final rows = (cells / 7).ceil();
  return [
    for (var i = 0; i < rows * 7; i++)
      DateTime(first.year, first.month, first.day - lead + i),
  ];
}

/// ISO 8601 hafta numarası.
int isoWeekNumber(DateTime day) {
  final thursday = DateTime(day.year, day.month, day.day + 4 - day.weekday);
  final yearStart = DateTime(thursday.year);
  final ordinal = DateTime.utc(
    thursday.year,
    thursday.month,
    thursday.day,
  ).difference(DateTime.utc(yearStart.year)).inDays;
  return ordinal ~/ 7 + 1;
}

String seasonOf(int month) => switch (month) {
  12 || 1 || 2 => 'Kış',
  3 || 4 || 5 => 'İlkbahar',
  6 || 7 || 8 => 'Yaz',
  _ => 'Güz',
};

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
