import 'dates.dart';

enum Frequency { daily, weekly, monthly, yearly }

const weekdaysMonFri = {
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
};

const _rruleDays = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

/// Tekrar kuralı. RFC 5545 RRULE olarak saklanır, Google Takvim de bunu kullanır.
/// Ay ve yıl tekrarı ilk günün gün ve ayını izler, o gün olmayan aylar atlanır.
class Recurrence {
  const Recurrence(
    this.frequency, {
    this.interval = 1,
    this.weekdays = const {},
    this.until,
  });

  final Frequency frequency;
  final int interval;

  /// Haftalık tekrarın günleri, boşsa ilk günün haftanın günü.
  final Set<int> weekdays;

  /// Son tekrar günü, dahil.
  final DateTime? until;

  bool get isWeekdays =>
      frequency == Frequency.weekly &&
      interval == 1 &&
      weekdays.length == 5 &&
      weekdays.containsAll(weekdaysMonFri);

  Set<int> _days(DateTime first) =>
      weekdays.isEmpty ? {first.weekday} : weekdays;

  /// [first] serinin ilk günüdür.
  bool occursOn(DateTime day, DateTime first) {
    if (day.isBefore(dayOnly(first))) return false;
    if (until != null && day.isAfter(until!)) return false;
    switch (frequency) {
      case Frequency.daily:
        return daysBetween(first, day) % interval == 0;
      case Frequency.weekly:
        if (!_days(first).contains(day.weekday)) return false;
        final weeks = daysBetween(_monday(first), _monday(day)) ~/ 7;
        return weeks % interval == 0;
      case Frequency.monthly:
        final months = (day.year - first.year) * 12 + day.month - first.month;
        return day.day == first.day && months % interval == 0;
      case Frequency.yearly:
        return day.month == first.month &&
            day.day == first.day &&
            (day.year - first.year) % interval == 0;
    }
  }

  /// [from]-[to] arasındaki tekrar günleri.
  Iterable<DateTime> daysIn(DateTime first, DateTime from, DateTime to) sync* {
    var day = dayOnly(from.isBefore(first) ? first : from);
    final last = until != null && until!.isBefore(to) ? until! : dayOnly(to);
    while (!day.isAfter(last)) {
      if (occursOn(day, first)) yield day;
      day = addDays(day, 1);
    }
  }

  /// Seçilen gün tekrar günlerinden değilse ilk uygun güne kayar.
  DateTime align(DateTime day) {
    if (frequency != Frequency.weekly || weekdays.isEmpty) return day;
    var d = day;
    while (!weekdays.contains(d.weekday)) {
      d = addDays(d, 1);
    }
    return d;
  }

  /// [day] gününden önce biten seri.
  Recurrence endingBefore(DateTime day) => Recurrence(
    frequency,
    interval: interval,
    weekdays: weekdays,
    until: addDays(dayOnly(day), -1),
  );

  Recurrence withUntil(DateTime? until) => Recurrence(
    frequency,
    interval: interval,
    weekdays: weekdays,
    until: until,
  );

  String toRrule() {
    final parts = ['FREQ=${frequency.name.toUpperCase()}'];
    if (interval > 1) parts.add('INTERVAL=$interval');
    if (frequency == Frequency.weekly && weekdays.isNotEmpty) {
      final days = weekdays.toList()..sort();
      parts.add('BYDAY=${days.map((d) => _rruleDays[d - 1]).join(',')}');
    }
    if (until != null) parts.add('UNTIL=${dayKey(until!).replaceAll('-', '')}');
    return parts.join(';');
  }

  static Recurrence? parse(String? rrule) {
    if (rrule == null || rrule.isEmpty) return null;
    final fields = {
      for (final part in rrule.split(';'))
        if (part.contains('='))
          part.substring(0, part.indexOf('=')): part.substring(
            part.indexOf('=') + 1,
          ),
    };
    final frequency = Frequency.values.where(
      (f) => f.name.toUpperCase() == fields['FREQ'],
    );
    if (frequency.isEmpty) return null;
    final until = fields['UNTIL'];
    return Recurrence(
      frequency.first,
      interval: int.tryParse(fields['INTERVAL'] ?? '') ?? 1,
      weekdays: {
        for (final day in (fields['BYDAY'] ?? '').split(','))
          if (_rruleDays.contains(day)) _rruleDays.indexOf(day) + 1,
      },
      until: until == null || until.length < 8
          ? null
          : DateTime(
              int.parse(until.substring(0, 4)),
              int.parse(until.substring(4, 6)),
              int.parse(until.substring(6, 8)),
            ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Recurrence &&
      other.frequency == frequency &&
      other.interval == interval &&
      other.until == until &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode => Object.hash(
    frequency,
    interval,
    until,
    Object.hashAllUnordered(weekdays),
  );

  @override
  String toString() => toRrule();
}

DateTime _monday(DateTime d) => addDays(dayOnly(d), 1 - d.weekday);

/// Tekrarın kimliği: seri kimliği ve asıl günü.
String occurrenceId(String seriesId, DateTime day) =>
    '$seriesId~${dayKey(day)}';
