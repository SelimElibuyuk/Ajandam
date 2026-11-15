import '../../domain/dates.dart';
import '../../domain/recurrence.dart';
import '../db/app_database.dart';
import 'device_calendar.dart';

/// Ajandam görevleri takvimde etkinlik olarak durur; açıklamanın bu satırı
/// onları görev yapar.
const taskMarker = 'Ajandam görevi';

/// Tamamlanan görevin başlığına eklenir, Google'da da görünsün diye.
const donePrefix = '✓ ';
const untitled = '(Başlıksız)';

/// Saatli görev takvimde bu kadar yer kaplar.
const taskMinutes = 15;

const _hourMs = 3600000;

/// Bir girdinin takvimle eşlenen alanları. Satırla takvimin karşılaştırması
/// bunun üzerinden yapılır; görev ömrü, önem ve hatırlatma gibi alanlar
/// yalnızca uygulamada kalır.
class EventFields {
  const EventFields({
    required this.kind,
    required this.title,
    required this.done,
    required this.allDay,
    this.notes,
    this.startAt,
    this.endAt,
    this.date,
    this.endDate,
    this.rrule,
  });

  final String kind;
  final String title;
  final String? notes;
  final bool done;
  final bool allDay;
  final int? startAt;
  final int? endAt;
  final String? date;
  final String? endDate;
  final String? rrule;

  bool get isTask => kind == 'task';

  factory EventFields.fromRow(Item r) => EventFields(
    kind: r.kind,
    title: r.title,
    notes: r.notes,
    done: r.doneAt != null,
    allDay: r.allDay,
    startAt: r.startAt,
    endAt: r.endAt,
    date: r.date,
    endDate: r.endDate,
    rrule: r.rrule,
  );

  @override
  bool operator ==(Object other) =>
      other is EventFields &&
      other.kind == kind &&
      other.title == title &&
      other.notes == notes &&
      other.done == done &&
      other.allDay == allDay &&
      other.startAt == startAt &&
      other.endAt == endAt &&
      other.date == date &&
      other.endDate == endDate &&
      other.rrule == rrule;

  @override
  int get hashCode => Object.hash(
    kind,
    title,
    notes,
    done,
    allDay,
    startAt,
    endAt,
    date,
    endDate,
    rrule,
  );
}

/// Takvimdeki satırdan girdinin alanları. Seri kuralı uygulamanın
/// anlayabileceği biçimde değilse [rrule] boş kalır; çağıran bunu
/// [supportedRule] ile ayrıca denetler.
EventFields fieldsFromRemote(RemoteEvent e) {
  final lines = (e.description ?? '').split('\n');
  final isTask = lines.any((l) => l.trim() == taskMarker);
  final notes = lines.where((l) => l.trim() != taskMarker).join('\n').trim();
  var title = (e.title ?? '').trim();
  final done = title.startsWith(donePrefix.trim());
  if (done) title = title.substring(donePrefix.trim().length).trim();
  if (title.isEmpty) title = untitled;
  if (title.length > 200) title = title.substring(0, 200);

  final kind = isTask ? 'task' : 'event';
  String? rrule;
  if (e.rrule != null) {
    final first = e.allDay ? utcDay(e.start) : localDay(e.start);
    rrule = supportedRule(e.rrule!, first)?.toRrule();
  }

  if (e.allDay) {
    final first = utcDay(e.start);
    var last = addDays(utcDay(e.end), -1);
    if (!last.isAfter(first)) last = first;
    return EventFields(
      kind: kind,
      title: title,
      notes: notes.isEmpty ? null : notes,
      done: done,
      // Saatsiz görev satırda tüm gün sayılmaz.
      allDay: !isTask,
      date: dayKey(first),
      endDate: !isTask && last.isAfter(first) ? dayKey(last) : null,
      rrule: rrule,
    );
  }
  return EventFields(
    kind: kind,
    title: title,
    notes: notes.isEmpty ? null : notes,
    done: done,
    allDay: false,
    startAt: e.start,
    endAt: isTask ? null : (e.end > e.start ? e.end : e.start + _hourMs),
    rrule: rrule,
  );
}

/// Satırın takvime yazılacak hali. Tekrar kaydı verilirse ([rrule] olmadan)
/// serinin o gününün istisnası olarak yazılır.
EventWrite writeFromRow(Item r) {
  final task = r.kind == 'task';
  final title = '${r.doneAt != null ? donePrefix : ''}${r.title}';
  final description = task
      ? (r.notes == null || r.notes!.trim().isEmpty
            ? taskMarker
            : '${r.notes!.trim()}\n\n$taskMarker')
      : r.notes;
  final rule = Recurrence.parse(r.rrule);
  final start = r.startAt;
  if (start != null) {
    final end = task
        ? start + taskMinutes * 60000
        : (r.endAt != null && r.endAt! > start ? r.endAt! : start + _hourMs);
    return EventWrite(
      title: title,
      description: description,
      start: start,
      end: end,
      allDay: false,
      rrule: rule == null ? null : googleRrule(rule, timed: true),
    );
  }
  final day = parseDayKey(r.date!);
  final last = r.endDate == null ? day : parseDayKey(r.endDate!);
  return EventWrite(
    title: title,
    description: description,
    start: utcMidnight(day),
    end: utcMidnight(addDays(last, 1)),
    allDay: true,
    rrule: rule == null ? null : googleRrule(rule, timed: false),
  );
}

/// Satırın göründüğü ilk ve son gün.
DateTime rowDay(Item r) =>
    r.startAt != null ? localDay(r.startAt!) : parseDayKey(r.date!);

DateTime rowLastDay(Item r) =>
    r.endDate != null ? parseDayKey(r.endDate!) : rowDay(r);

DateTime localDay(int ms) => dayOnly(DateTime.fromMillisecondsSinceEpoch(ms));

/// Tüm gün etkinliğin günü: UTC gece yarısındaki tarih.
DateTime utcDay(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  return DateTime(d.year, d.month, d.day);
}

int utcMidnight(DateTime day) =>
    DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch;

/// Serinin [day] günündeki tekrarının takvimdeki asıl başlangıcı.
int instanceTime(Item series, DateTime day) {
  final start = series.startAt;
  if (start == null) return utcMidnight(day);
  final s = DateTime.fromMillisecondsSinceEpoch(start);
  return DateTime(
    day.year,
    day.month,
    day.day,
    s.hour,
    s.minute,
  ).millisecondsSinceEpoch;
}

/// İstisna satırının ait olduğu gün.
DateTime instanceDay(int ms, {required bool allDay}) =>
    allDay ? utcDay(ms) : localDay(ms);

/// Uygulamanın tekrar modeli günlük, haftalık (günlerle), aylık (ayın aynı
/// günü) ve yıllık tekrarları taşır. Başka kurallar (ör. “ayın ikinci salısı”)
/// null döner; onlar takvimden tek tek tekrar olarak okunur.
Recurrence? supportedRule(String rrule, DateTime first) {
  final fields = <String, String>{};
  for (final part in rrule.replaceFirst('RRULE:', '').split(';')) {
    final at = part.indexOf('=');
    if (at <= 0) continue;
    fields[part.substring(0, at).toUpperCase()] = part.substring(at + 1);
  }
  const allowed = {
    'FREQ',
    'INTERVAL',
    'BYDAY',
    'UNTIL',
    'COUNT',
    'WKST',
    'BYMONTHDAY',
    'BYMONTH',
  };
  if (fields.keys.any((k) => !allowed.contains(k))) return null;
  final freq = fields['FREQ'];
  if (!{'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY'}.contains(freq)) return null;

  final byDay = fields['BYDAY'];
  if (byDay != null) {
    if (freq != 'WEEKLY') return null;
    final ok = byDay
        .split(',')
        .every((d) => RegExp(r'^(MO|TU|WE|TH|FR|SA|SU)$').hasMatch(d));
    if (!ok) return null;
  }
  final monthDay = fields['BYMONTHDAY'];
  if (monthDay != null) {
    if (freq != 'MONTHLY' && freq != 'YEARLY') return null;
    if (int.tryParse(monthDay) != first.day) return null;
  }
  final month = fields['BYMONTH'];
  if (month != null) {
    if (freq != 'YEARLY' || int.tryParse(month) != first.month) return null;
  }

  final base = Recurrence.parse(
    [
      'FREQ=$freq',
      if (fields['INTERVAL'] != null) 'INTERVAL=${fields['INTERVAL']}',
      if (byDay != null) 'BYDAY=$byDay',
    ].join(';'),
  );
  if (base == null) return null;

  final until = fields['UNTIL'];
  if (until != null) {
    final day = _untilDay(until);
    if (day == null) return null;
    return base.withUntil(day);
  }
  final count = int.tryParse(fields['COUNT'] ?? '');
  if (count != null) {
    if (count <= 0) return null;
    final days = base
        .daysIn(first, first, addDays(first, 366 * 30))
        .take(count)
        .toList();
    if (days.isEmpty) return null;
    return base.withUntil(days.last);
  }
  return base;
}

DateTime? _untilDay(String value) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$')
      .firstMatch(value.trim());
  if (m == null) return null;
  int g(int i) => int.parse(m.group(i)!);
  if (m.group(7) != null) {
    final utc = DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6));
    return dayOnly(utc.toLocal());
  }
  return DateTime(g(1), g(2), g(3));
}

/// Google'ın beklediği RRULE: saatli seride UNTIL, son günün sonunun UTC
/// zamanı olur.
String googleRrule(Recurrence rule, {required bool timed}) {
  final base = rule.withUntil(null).toRrule();
  final until = rule.until;
  if (until == null) return base;
  if (!timed) return '$base;UNTIL=${_digits(until)}';
  final end = DateTime(until.year, until.month, until.day, 23, 59, 59).toUtc();
  final time =
      '${end.hour.toString().padLeft(2, '0')}'
      '${end.minute.toString().padLeft(2, '0')}'
      '${end.second.toString().padLeft(2, '0')}';
  return '$base;UNTIL=${_digits(end)}T${time}Z';
}

String _digits(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

/// EXDATE ile çıkarılmış tekrar günleri.
Set<DateTime> exdateDays(String? exdate, {required bool allDay}) {
  if (exdate == null) return const {};
  final out = <DateTime>{};
  for (final m in RegExp(
    r'(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?',
  ).allMatches(exdate)) {
    int g(int i) => int.parse(m.group(i)!);
    if (m.group(7) != null && !allDay) {
      out.add(
        dayOnly(DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6)).toLocal()),
      );
    } else {
      out.add(DateTime(g(1), g(2), g(3)));
    }
  }
  return out;
}

/// Yazılan etkinliğin takvimden okununca vereceği özet.
String writtenFingerprint(EventWrite w) => fingerprint(
  RemoteEvent(
    key: '',
    calendarId: 0,
    title: w.title,
    description: w.description,
    start: w.start,
    end: w.end,
    allDay: w.allDay,
    rrule: w.rrule,
  ),
);

/// Takvim satırının değişip değişmediğini anlamak için özeti (FNV-1a 64).
String fingerprint(RemoteEvent e) {
  final text = [
    e.title,
    e.description,
    e.start,
    e.end,
    e.allDay,
    e.rrule,
    e.exdate,
    e.rdate,
    e.canceled,
  ].join('\u0001');
  var hash = 0xcbf29ce484222325;
  for (final unit in text.codeUnits) {
    hash ^= unit;
    hash *= 0x100000001b3;
  }
  return hash.toUnsigned(64).toRadixString(16);
}
