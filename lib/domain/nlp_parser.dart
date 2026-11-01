import 'dates.dart';

enum ParseField { date, time, duration }

class ParsedSpan {
  const ParsedSpan(this.start, this.end, this.field);

  final int start;
  final int end;
  final ParseField field;
}

class ParsedInput {
  const ParsedInput({
    required this.title,
    required this.spans,
    this.date,
    this.hour,
    this.minute,
    this.durationMin,
  });

  final String title;
  final List<ParsedSpan> spans;
  final DateTime? date;
  final int? hour;
  final int? minute;
  final int? durationMin;

  bool get hasTime => hour != null;

  /// Tarih yazılmadıysa [base] gününü kullanır. Saat bugün geçmişse yarına kayar.
  DateTime resolveDay(DateTime base, DateTime now) {
    if (date != null) return date!;
    final day = dayOnly(base);
    if (hasTime && day == dayOnly(now)) {
      final at = DateTime(day.year, day.month, day.day, hour!, minute!);
      if (!at.isAfter(now)) return addDays(day, 1);
    }
    return day;
  }
}

const _b = r'(?<![a-z0-9])';
const _e = r'(?![a-z0-9])';

/// Sayıya gelen çekim eki: 14:00'te, 3'e, saat 5te
const _numSuffix = r"(?:['’]?(?:te|de|ta|da|ye|ya|e|a))?";
const _nameSuffix = r'(?:ye|ya|e|a|yi|i)?';

const _weekdays = {
  'pazartesi': DateTime.monday,
  'sali': DateTime.tuesday,
  'carsamba': DateTime.wednesday,
  'persembe': DateTime.thursday,
  'cumartesi': DateTime.saturday,
  'cuma': DateTime.friday,
  'pazar': DateTime.sunday,
  'monday': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'friday': DateTime.friday,
  'saturday': DateTime.saturday,
  'sunday': DateTime.sunday,
};

const _months = {
  'ocak': 1,
  'subat': 2,
  'mart': 3,
  'nisan': 4,
  'mayis': 5,
  'haziran': 6,
  'temmuz': 7,
  'agustos': 8,
  'eylul': 9,
  'ekim': 10,
  'kasim': 11,
  'aralik': 12,
  'january': 1,
  'february': 2,
  'march': 3,
  'april': 4,
  'may': 5,
  'june': 6,
  'july': 7,
  'august': 8,
  'september': 9,
  'october': 10,
  'november': 11,
  'december': 12,
};

final _weekdayAlt = _weekdays.keys.join('|');
final _monthAlt = _months.keys.join('|');

/// Ayrıştırıcı her tuş vuruşunda çalıştığı için kurallar bir kez derlenir.
final _compiled = <String, RegExp>{};

/// Türkçe harfleri ve büyük harfleri, uzunluğu değiştirmeden ASCII küçük
/// harfe indirger. Böylece kurallar “yarin” ve “YARIN” için de çalışır.
String _fold(String text) {
  const map = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
    'Ç': 'c',
    'ç': 'c',
  };
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    final ch = String.fromCharCode(unit);
    final lower = map[ch] ?? ch.toLowerCase();
    out.write(lower.length == 1 ? lower : ch);
  }
  return out.toString();
}

/// Cihazda çalışan kural tabanlı ayrıştırıcı: “yarın 14:00 dişçi”.
class NlpParser {
  ParsedInput parse(
    String text,
    DateTime now, {
    Set<ParseField> disabled = const {},
  }) {
    return _Run(text, _fold(text), now, disabled).run();
  }
}

class _Run {
  _Run(this.text, this.folded, this.now, this.disabled);

  final String text;
  final String folded;
  final DateTime now;
  final Set<ParseField> disabled;

  final spans = <ParsedSpan>[];
  DateTime? date;
  int? hour;
  int? minute;
  int? duration;

  DateTime get today => dayOnly(now);

  ParsedInput run() {
    if (!disabled.contains(ParseField.time) &&
        !disabled.contains(ParseField.date)) {
      _relative();
    }
    if (!disabled.contains(ParseField.duration)) _duration();
    if (!disabled.contains(ParseField.time)) _time();
    if (!disabled.contains(ParseField.date)) _date();
    if (hour == null && duration != null) {
      duration = null;
      spans.removeWhere((s) => s.field == ParseField.duration);
    }
    spans.sort((a, b) => a.start.compareTo(b.start));
    return ParsedInput(
      title: _title(),
      spans: List.unmodifiable(spans),
      date: date,
      hour: hour,
      minute: minute,
      durationMin: duration,
    );
  }

  /// Boşta kalan aralıklarda eşleşmeleri gezer, [accept] true dönerse işaretler.
  bool _scan(
    String pattern,
    ParseField field,
    bool Function(RegExpMatch m) accept,
  ) {
    final regex = _compiled[pattern] ??= RegExp(pattern);
    for (final m in regex.allMatches(folded)) {
      final free = spans.every((s) => m.end <= s.start || m.start >= s.end);
      if (free && accept(m)) {
        spans.add(ParsedSpan(m.start, m.end, field));
        return true;
      }
    }
    return false;
  }

  void _relative() {
    _scan(
      '$_b(\\d+|bir|yarim)\\s*(dakika|dk|saat|gun|hafta|ay)\\s+sonra$_e',
      ParseField.date,
      (m) {
        final unit = m[2]!;
        final half = m[1] == 'yarim';
        final n = half ? 0 : (m[1] == 'bir' ? 1 : int.parse(m[1]!));
        switch (unit) {
          case 'dakika' || 'dk':
            _setMoment(now.add(Duration(minutes: n)));
          case 'saat':
            _setMoment(now.add(Duration(minutes: half ? 30 : n * 60)));
          case 'gun':
            date = addDays(today, n);
          case 'hafta':
            date = addDays(today, n * 7);
          default:
            date = DateTime(today.year, today.month + n, today.day);
        }
        return !half || unit == 'saat';
      },
    );
  }

  void _setMoment(DateTime at) {
    date = dayOnly(at);
    hour = at.hour;
    minute = at.minute;
  }

  void _duration() {
    const h = r'(?:saat|hours?|hrs?)(?:lik|luk)?';
    const m = r'(?:dakika|dk|mins?|minutes?)(?:lik|luk)?';
    var total = 0;
    bool add(int minutes) {
      total += minutes;
      return true;
    }

    if (!_scan('$_b(\\d+)\\s*$h\\s+(\\d+)\\s*$m$_e', ParseField.duration, (x) {
      return add(int.parse(x[1]!) * 60 + int.parse(x[2]!));
    })) {
      _scan('$_b(\\d+)\\s*bucuk\\s*$h$_e', ParseField.duration, (x) {
            return add(int.parse(x[1]!) * 60 + 30);
          }) ||
          _scan('$_b(\\d+(?:[.,]\\d+)?)\\s*$h$_e', ParseField.duration, (x) {
            final hours = double.parse(x[1]!.replaceAll(',', '.'));
            return add((hours * 60).round());
          }) ||
          _scan('$_b(\\d+)\\s*$m$_e', ParseField.duration, (x) {
            return add(int.parse(x[1]!));
          }) ||
          _scan('${_b}yarim saat(?:lik)?$_e', ParseField.duration, (_) {
            return add(30);
          }) ||
          _scan('${_b}bir saat(?:lik)?$_e', ParseField.duration, (_) {
            return add(60);
          });
    }
    if (total > 0) duration = total;
  }

  void _time() {
    final qualifier =
        r'(ogleden sonra|ogleden once|ogle|oglen|sabah|aksam|gece)';
    final clock = '(?:saat\\s+)?(\\d{1,2})(?:[:.](\\d{2}))?(\\s*bucuk)?';
    _scan('$_b$qualifier\\s+$clock$_numSuffix$_e', ParseField.time, (m) {
          return _setTime(_applyQualifier(m[1]!, int.parse(m[2]!)), m[3], m[4]);
        }) ||
        _scan(
          '${_b}saat\\s+(\\d{1,2})(?:[:.](\\d{2}))?(\\s*bucuk)?$_numSuffix$_e',
          ParseField.time,
          (m) => _setTime(_guessAfternoon(int.parse(m[1]!)), m[2], m[3]),
        ) ||
        _scan('$_b(\\d{1,2})(?::(\\d{2}))?\\s*(am|pm)$_e', ParseField.time, (
          m,
        ) {
          var h = int.parse(m[1]!) % 12;
          if (m[3] == 'pm') h += 12;
          return _setTime(h, m[2], null);
        }) ||
        _scan(
          '$_b(\\d{1,2})[:.](\\d{2})(?![./]\\d)$_numSuffix$_e',
          ParseField.time,
          (m) => _setTime(int.parse(m[1]!), m[2], null),
        ) ||
        _scan(
          "$_b(\\d{1,2})['’](?:te|de|ta|da)$_e",
          ParseField.time,
          (m) => _setTime(_guessAfternoon(int.parse(m[1]!)), null, null),
        ) ||
        _scan('${_b}at (\\d{1,2})$_e', ParseField.time, (m) {
          return _setTime(_guessAfternoon(int.parse(m[1]!)), null, null);
        });
  }

  bool _setTime(int h, String? min, String? half) {
    final mins = half != null ? 30 : (min == null ? 0 : int.parse(min));
    if (h > 24 || mins > 59) return false;
    hour = h % 24;
    minute = mins;
    return true;
  }

  /// “saat 3” günlük konuşmada öğleden sonra demektir.
  int _guessAfternoon(int h) => h >= 1 && h <= 6 ? h + 12 : h;

  int _applyQualifier(String qualifier, int h) {
    switch (qualifier) {
      case 'ogleden sonra' || 'aksam':
        return h < 12 ? h + 12 : h;
      case 'ogle' || 'oglen':
        return h <= 5 ? h + 12 : h;
      case 'gece':
        if (h == 12) return 0;
        return h >= 7 && h < 12 ? h + 12 : h;
      default:
        return h;
    }
  }

  void _date() {
    _scan(
          '$_b(\\d{1,2})[./](\\d{1,2})[./](\\d{4})$_e',
          ParseField.date,
          (m) => _setDate(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!)),
        ) ||
        _scan(
          '$_b(\\d{1,2})/(\\d{1,2})$_e',
          ParseField.date,
          (m) => _setUpcoming(int.parse(m[2]!), int.parse(m[1]!)),
        ) ||
        _scan(
          "$_b(\\d{1,2})\\s+($_monthAlt)$_nameSuffix$_e(?:\\s+(\\d{4})$_e)?",
          ParseField.date,
          (m) {
            final month = _months[m[2]!]!;
            final day = int.parse(m[1]!);
            return m[3] != null
                ? _setDate(int.parse(m[3]!), month, day)
                : _setUpcoming(month, day);
          },
        ) ||
        _scan("${_b}ayin\\s+(\\d{1,2})(?:['’]?[a-z]*)?", ParseField.date, (m) {
          final day = int.parse(m[1]!);
          final later = day <= today.day;
          return _setDate(today.year, today.month + (later ? 1 : 0), day);
        }) ||
        _scan(
          '$_b(haftaya|gelecek hafta|onumuzdeki hafta|next week|gelecek|onumuzdeki|next|bu|this)\\s+'
          '($_weekdayAlt)(?:\\s+gunu)?$_nameSuffix$_e',
          ParseField.date,
          (m) {
            final target = _weekdays[m[2]!]!;
            final near = m[1] == 'bu' || m[1] == 'this';
            date = near ? _nextWeekday(target) : _weekdayNextWeek(target);
            return true;
          },
        ) ||
        _scan(
          '$_b(haftaya|gelecek hafta|onumuzdeki hafta|next week)$_e',
          ParseField.date,
          (_) {
            date = addDays(today, 7);
            return true;
          },
        ) ||
        _scan(
          '$_b(bugun|today|yarin|tomorrow|obur gun|oburgun|ertesi gun)'
          '(?:e|a)?$_e',
          ParseField.date,
          (m) {
            final word = m[1]!;
            final ahead = word == 'bugun' || word == 'today'
                ? 0
                : (word == 'yarin' || word == 'tomorrow' ? 1 : 2);
            date = addDays(today, ahead);
            return true;
          },
        ) ||
        _scan('$_b($_weekdayAlt)(\\s+gunu)?$_nameSuffix$_e', ParseField.date, (
          m,
        ) {
          // “pazara gittim” gibi cümleler gün değildir.
          if (m[1] == 'pazar' && m[2] == null && !m[0]!.endsWith('pazar')) {
            return false;
          }
          date = _nextWeekday(_weekdays[m[1]!]!);
          return true;
        });
  }

  DateTime _nextWeekday(int target) {
    final ahead = (target - today.weekday) % 7;
    return addDays(today, ahead == 0 ? 7 : ahead);
  }

  DateTime _weekdayNextWeek(int target) =>
      addDays(today, 7 - (today.weekday - DateTime.monday) + target - 1);

  bool _setDate(int year, int month, int day) {
    final d = DateTime(year, month, day);
    if (d.day != day) return false;
    date = d;
    return true;
  }

  bool _setUpcoming(int month, int day) {
    if (month < 1 || month > 12) return false;
    final thisYear = DateTime(today.year, month, day);
    return _setDate(
      thisYear.isBefore(today) ? today.year + 1 : today.year,
      month,
      day,
    );
  }

  String _title() {
    final out = StringBuffer();
    var at = 0;
    final ordered = [...spans]..sort((a, b) => a.start.compareTo(b.start));
    for (final s in ordered) {
      out.write(text.substring(at, s.start));
      out.write(' ');
      at = s.end;
    }
    out.write(text.substring(at));
    var title = out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    title = title.replaceFirst(RegExp(r'^[,;:\-–]+\s*'), '');
    title = title.replaceFirst(RegExp(r'\s*[,;:\-–]+$'), '');
    if (spans.isNotEmpty) {
      title = title.replaceFirst(RegExp(r'^(için|icin)\s+'), '');
    }
    return title;
  }
}
