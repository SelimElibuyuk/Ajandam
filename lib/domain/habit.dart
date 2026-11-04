import 'dates.dart';

/// Alışkanlık renkleri; ajandanın çelik mavisinden ayrı, koyu ve açık temada
/// okunan tonlar. Alışkanlık sırasını tutar, değeri değil.
const habitColors = [
  0xFF5FA37A,
  0xFFD39A4E,
  0xFFB477C4,
  0xFF4FA3A8,
  0xFFD3706B,
  0xFF9AA552,
];

/// Ajandadan ayrı izlenen, belirli günlerde tekrarlanan iş.
class Habit {
  const Habit({
    required this.id,
    required this.title,
    this.weekdays = const {},
    this.target,
    this.color = 0,
    required this.startDay,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// [DateTime.monday]..[DateTime.sunday]; boşsa her gün.
  final Set<int> weekdays;

  /// Günlük hedef sayı, ör. 8 bardak su. Null ise yaptım/yapmadım.
  final int? target;
  final int color;
  final DateTime startDay;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get goal => target ?? 1;

  bool get isCounted => target != null;

  bool plannedOn(DateTime day) =>
      weekdays.isEmpty || weekdays.contains(day.weekday);

  /// Dokunuş sayıyı bir artırır; hedefe ulaşmışsa sıfırlar, böylece widget'ta
  /// da geri alınabilir.
  int tapped(int count) => count >= goal ? 0 : count + 1;

  Habit copyWith({
    String? title,
    Set<int>? weekdays,
    int? Function()? target,
    int? color,
    int? order,
    DateTime? updatedAt,
  }) => Habit(
    id: id,
    title: title ?? this.title,
    weekdays: weekdays ?? this.weekdays,
    target: target != null ? target() : this.target,
    color: color ?? this.color,
    startDay: startDay,
    order: order ?? this.order,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

/// Bir alışkanlığın günlük sayıları ve bunlardan çıkan seri.
class HabitHistory {
  HabitHistory(this.habit, Map<DateTime, int> counts)
    : _counts = {
        for (final e in counts.entries)
          if (e.value > 0) dayOnly(e.key): e.value,
      };

  final Habit habit;
  final Map<DateTime, int> _counts;

  int countOn(DateTime day) => _counts[dayOnly(day)] ?? 0;

  bool doneOn(DateTime day) => countOn(day) >= habit.goal;

  /// Sayı girilen ilk gün başlangıçtan önce olabilir: geçmiş elle işaretlenir.
  DateTime get _earliest {
    var first = habit.startDay;
    for (final day in _counts.keys) {
      if (day.isBefore(first)) first = day;
    }
    return first;
  }

  /// [last] dahil geriye doğru art arda yapılan planlı günler. Planlı olmayan
  /// günler seriyi bozmaz.
  int streakEndingAt(DateTime last) {
    final earliest = _earliest;
    var count = 0;
    for (var d = dayOnly(last); !d.isBefore(earliest); d = addDays(d, -1)) {
      if (!habit.plannedOn(d)) continue;
      if (!doneOn(d)) break;
      count++;
    }
    return count;
  }

  /// Bugün henüz yapılmadıysa seri dünden sayılır, gün bitmeden bozulmaz.
  int streak(DateTime today) =>
      streakEndingAt(doneOn(today) ? today : addDays(today, -1));

  int longestStreak(DateTime today) {
    var best = 0;
    var run = 0;
    for (var d = _earliest; !d.isAfter(today); d = addDays(d, 1)) {
      if (!habit.plannedOn(d)) continue;
      if (doneOn(d)) {
        run++;
        if (run > best) best = run;
      } else if (d != today) {
        run = 0;
      }
    }
    return best;
  }

  /// Son [days] günün planlı günlerinde yapılma oranı; bugün yapılmadıysa
  /// henüz sayılmaz. Planlı gün yoksa null.
  double? rate(DateTime today, {int days = 30}) {
    var from = addDays(today, 1 - days);
    if (from.isBefore(_earliest)) from = _earliest;
    var planned = 0;
    var done = 0;
    for (var d = from; !d.isAfter(today); d = addDays(d, 1)) {
      if (!habit.plannedOn(d)) continue;
      if (doneOn(d)) {
        done++;
      } else if (d == today) {
        continue;
      }
      planned++;
    }
    return planned == 0 ? null : done / planned;
  }
}

String habitDaysLabel(Set<int> weekdays) {
  if (weekdays.isEmpty || weekdays.length == 7) return 'Her gün';
  if (weekdays.length == 5 && !weekdays.contains(6) && !weekdays.contains(7)) {
    return 'Hafta içi';
  }
  if (weekdays.length == 2 && weekdays.containsAll({6, 7})) {
    return 'Hafta sonu';
  }
  const names = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  return (weekdays.toList()..sort()).map((d) => names[d - 1]).join(', ');
}
