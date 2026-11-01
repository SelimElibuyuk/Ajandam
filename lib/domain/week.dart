/// [focus] gününü içeren haftanın 7 gününü döndürür.
List<DateTime> weekDays(DateTime focus, {int firstWeekday = DateTime.monday}) {
  final offset = (focus.weekday - firstWeekday) % 7;
  return [
    for (var i = 0; i < 7; i++)
      DateTime(focus.year, focus.month, focus.day - offset + i),
  ];
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
