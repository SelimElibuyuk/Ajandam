import 'dates.dart';
import 'recurrence.dart';

enum ParseField { date, time, duration, repeat }

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
    this.endDate,
    this.recurrence,
    this.repeatFor,
    this.repeatCount,
  });

  final String title;
  final List<ParsedSpan> spans;
  final DateTime? date;
  final int? hour;
  final int? minute;
  final int? durationMin;

  /// Birkaç gün süren tüm gün etkinliğin son günü: “5-10 kasım tatil”.
  final DateTime? endDate;

  /// Tekrar kuralı. Bitişi yazılan süreye veya sayıya bağlıysa
  /// [recurrenceFrom] ile ilk güne göre tamamlanır.
  final Recurrence? recurrence;

  /// “4 hafta boyunca”: birim ve miktar.
  final (Frequency, int)? repeatFor;

  /// “10 kez”
  final int? repeatCount;

  /// İlk tekrar günü [first] iken bitişi hesaplanmış kural.
  Recurrence? recurrenceFrom(DateTime first) {
    final rule = recurrence;
    if (rule == null || rule.until != null) return rule;
    final count = repeatCount;
    if (count != null) {
      final days = rule.daysIn(first, first, addDays(first, 366 * 10));
      final last = days.take(count).lastOrNull;
      return last == null ? rule : rule.withUntil(last);
    }
    final span = repeatFor;
    if (span == null) return rule;
    final (unit, n) = span;
    return rule.withUntil(switch (unit) {
      Frequency.daily => addDays(first, n - 1),
      Frequency.weekly => addDays(first, n * 7 - 1),
      Frequency.monthly => DateTime(first.year, first.month + n, first.day - 1),
      Frequency.yearly => DateTime(first.year + n, first.month, first.day - 1),
    });
  }

  bool get hasTime => hour != null;

  /// Saat aralığı, süre veya gün aralığı yazılan girdi etkinliktir.
  bool get isEvent => (hasTime && durationMin != null) || endDate != null;

  /// Tarih yazılmadıysa [base] gününü kullanır. Saat bugün geçmişse yarına
  /// kayar. Tekrarda ilk tekrar gününe kayar.
  DateTime resolveDay(DateTime base, DateTime now) {
    final rule = recurrence;
    final day = _day(base, now);
    return rule == null ? day : rule.align(day);
  }

  DateTime _day(DateTime base, DateTime now) {
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

/// Sayıya gelen çekim eki: 14:00'te, 3'e, saat 5te, saat 5 de
const _numSuffix = r"(?:['’]?(?:te|de|ta|da|ye|ya|e|a)|\s(?:te|de|ta|da))?";

/// Aralığın başı ve sonu: 14'ten, 16'ya
const _fromSuffix = r"['’]?(?:dan|den|tan|ten)";
const _toSuffix = r"['’]?(?:ya|ye|a|e)";

/// “14 mart tarihine kadar”, “cumaya kadar”
const _untilTail =
    r"(?:['’]?[a-z]*)?\s+(?:tarihine\s+|gunune\s+)?kadar(?![a-z0-9])";

const _qualifierAlt = 'ogleden sonra|ogleden once|ogle|oglen|sabah|aksam|gece';
const _qualifier = '(?<q>$_qualifierAlt)';

/// “saat gece 10”: “saat” günün bölümünden önce de söylenir.
const _saatBefore = '(?:saat\\s+(?=(?:$_qualifierAlt)\\s))?';

/// Yazıyla söylenen saatler: “saat on bir”, “sabah dokuzda”.
const _hourWords = {
  'on bir': 11,
  'on iki': 12,
  'on': 10,
  'bir': 1,
  'iki': 2,
  'uc': 3,
  'dort': 4,
  'bes': 5,
  'alti': 6,
  'yedi': 7,
  'sekiz': 8,
  'dokuz': 9,
};
const _hourWordAlt =
    r'on\s+bir|on\s+iki|on|bir|iki|uc|dort|bes|alti|yedi|sekiz|dokuz';

/// “beşi çeyrek geçe”: belirtme hâlindeki saatler.
const _hourWordsAcc = {
  'on biri': 11,
  'on ikiyi': 12,
  'biri': 1,
  'ikiyi': 2,
  'ucu': 3,
  'dordu': 4,
  'besi': 5,
  'altiyi': 6,
  'yediyi': 7,
  'sekizi': 8,
  'dokuzu': 9,
  'onu': 10,
};

/// “dörde çeyrek kala”: yönelme hâlindeki saatler.
const _hourWordsDat = {
  'on bire': 11,
  'on ikiye': 12,
  'bire': 1,
  'ikiye': 2,
  'uce': 3,
  'dorde': 4,
  'bese': 5,
  'altiya': 6,
  'yediye': 7,
  'sekize': 8,
  'dokuza': 9,
  'ona': 10,
};

/// Uzun biçim önce denensin diye uzunluğa göre sıralı seçenekler.
String _wordAlt(Iterable<String> words) =>
    (words.toList()..sort((a, b) => b.length.compareTo(a.length)))
        .map((w) => w.replaceAll(' ', r'\s+'))
        .join('|');

final _hourAccAlt = _wordAlt([..._hourWordsAcc.keys, ..._hourWords.keys]);
final _hourDatAlt = _wordAlt([..._hourWordsDat.keys, ..._hourWords.keys]);

/// Yazıyla sayılar: “yirmi beş”, “on”, “üç”.
const _ones = {
  'bir': 1,
  'iki': 2,
  'uc': 3,
  'dort': 4,
  'bes': 5,
  'alti': 6,
  'yedi': 7,
  'sekiz': 8,
  'dokuz': 9,
};
const _tens = {'on': 10, 'yirmi': 20, 'otuz': 30, 'kirk': 40, 'elli': 50};
const _onesAlt = 'bir|iki|uc|dort|bes|alti|yedi|sekiz|dokuz';
const _numberWordAlt =
    '(?:on|yirmi|otuz|kirk|elli)(?:\\s+(?:$_onesAlt))?|$_onesAlt';

/// “yirmi beş” → 25, “14” → 14
int? _numberValue(String text) {
  final asInt = int.tryParse(text);
  if (asInt != null) return asInt;
  var total = 0;
  for (final part in text.split(RegExp(r'\s+'))) {
    final v = _tens[part] ?? _ones[part];
    if (v == null) return null;
    total += v;
  }
  return total;
}

/// Saat aralığının bağlacı: “10 ile 11”, “10 ve 11”, “10'la 11”, “10 ila 11”
const _rangeAnd = r"(?:\s+(?:ile|ve|ila)|['’]?(?:la|le|yla|yle))";

/// “10-12 sayfa” gibi sayı aralıklarından sonra gelen birimler.
const _measureWords = {
  'sayfa',
  'kisi',
  'kisilik',
  'km',
  'kg',
  'kilo',
  'gr',
  'gram',
  'metre',
  'm',
  'cm',
  'lt',
  'litre',
  'dakika',
  'dk',
  'saniye',
  'sn',
  'saat',
  'gun',
  'hafta',
  'ay',
  'yil',
  'tane',
  'adet',
  'soru',
  'set',
  'tekrar',
  'bolum',
  'unite',
  'lira',
  'tl',
  'dolar',
  'euro',
  'yas',
  'yasinda',
  'kat',
  'numara',
  'no',
  'kez',
  'kere',
  'defa',
  'sefer',
  'puan',
  'paket',
  'kutu',
  'bardak',
  'porsiyon',
};

const _marketWords = {
  'alisverisi',
  'alisverisine',
  'yeri',
  'yerine',
  'yerinde',
  'yerinden',
  'tezgahi',
  'arabasi',
  'cantasi',
  'poseti',
  'pazarlik',
};

const _counts = {'bir': 1, 'iki': 2, 'uc': 3, 'dort': 4, 'bes': 5, 'alti': 6};
const _countAlt = r'(?<n>\d{1,2}|iki|uc|dort|bes|alti)';
const _amountAlt = r'(?<n>\d{1,3}|bir|iki|uc|dort|bes|alti)';
const _units = {
  'gun': Frequency.daily,
  'hafta': Frequency.weekly,
  'ay': Frequency.monthly,
  'yil': Frequency.yearly,
  'sene': Frequency.yearly,
};
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

/// “salı ve perşembe”, “pazartesi, çarşamba, cuma”
final _weekdayItem = '(?:$_weekdayAlt)(?:\\s+gun(?:u|leri))?';
final _weekdayList =
    '$_weekdayItem(?:(?:\\s*,\\s*|\\s+ve\\s+|\\s+)$_weekdayItem)*';

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
    final fixes = _typoFixes(text);
    if (fixes.isEmpty) return _Run(text, _fold(text), now, disabled).run();
    // Düzeltme yalnızca tarih/saat olarak anlaşılırsa kalır; “salt” gibi
    // başlıkta kalan sözcükler kendi hâline döner.
    var result = _runFixed(text, fixes, now, disabled);
    final kept = [
      for (final f in fixes)
        if (result.$1.spans.any((s) => s.start <= f.at && f.fixedEnd <= s.end))
          f,
    ];
    if (kept.length != fixes.length) {
      if (kept.isEmpty) return _Run(text, _fold(text), now, disabled).run();
      result = _runFixed(text, kept, now, disabled);
    }
    return _mapBack(result.$1, kept);
  }

  (ParsedInput, String) _runFixed(
    String text,
    List<_Fix> fixes,
    DateTime now,
    Set<ParseField> disabled,
  ) {
    final out = StringBuffer();
    var at = 0;
    var shift = 0;
    for (final f in fixes) {
      out.write(text.substring(at, f.start));
      f.at = f.start + shift;
      out.write(f.word);
      f.fixedEnd = f.at + f.word.length;
      shift += f.word.length - (f.end - f.start);
      at = f.end;
    }
    out.write(text.substring(at));
    final fixed = out.toString();
    return (_Run(fixed, _fold(fixed), now, disabled).run(), fixed);
  }

  /// Düzeltilmiş metindeki aralıkları özgün metne çevirir.
  ParsedInput _mapBack(ParsedInput r, List<_Fix> fixes) {
    int map(int p, {required bool end}) {
      var shift = 0;
      for (final f in fixes) {
        if (p <= f.at) break;
        if (p < f.fixedEnd) return end ? f.end : f.start;
        shift = f.fixedEnd - f.end;
      }
      return p - shift;
    }

    return ParsedInput(
      title: r.title,
      spans: [
        for (final s in r.spans)
          ParsedSpan(map(s.start, end: false), map(s.end, end: true), s.field),
      ],
      date: r.date,
      hour: r.hour,
      minute: r.minute,
      durationMin: r.durationMin,
      endDate: r.endDate,
      recurrence: r.recurrence,
      repeatFor: r.repeatFor,
      repeatCount: r.repeatCount,
    );
  }
}

/// Yazım hatası düzeltmesi: “saı” → “salı”, “yarn” → “yarın”.
class _Fix {
  _Fix(this.start, this.end, this.word);

  final int start;
  final int end;
  final String word;

  /// Düzeltilmiş metindeki konumu.
  int at = 0;
  int fixedEnd = 0;
}

/// Bir harf eksik, fazla, yanlış veya yer değiştirmiş yazılabilen sözcükler.
const _fuzzyWords = [
  'pazartesi', 'sali', 'carsamba', 'persembe', 'cuma', 'cumartesi', 'pazar', //
  'ocak', 'subat', 'mart', 'nisan', 'mayis', 'haziran', 'temmuz', 'agustos',
  'eylul', 'ekim', 'kasim', 'aralik', //
  'yarin', 'bugun', 'haftaya', 'aksam', 'sabah', 'ogleden', 'ceyrek', 'bucuk',
  'gece', 'kala', 'dakika',
];

/// Gerçek sözcük olup bir anahtar sözcüğe benzeyenler düzeltilmez.
const _fuzzyStop = {
  'sal',
  'salt',
  'sale',
  'sala',
  'ali',
  'yari',
  'yarim',
  'yaris',
  'yarik',
  'karin',
  'sarin',
  'kasik',
  'asim',
  'kazim',
  'ekip',
  'ekin',
  'eki',
  'kim',
  'haftada',
  'bugu',
  'kuma',
  'puma',
  'duma',
  'saba',
  'kale',
  'kal',
  'kalan',
  'ala',
  'hece',
  'gene',
  'gec',
  'ece',
  'part',
  'art',
  'mat',
  'azar',
  'aksa',
  'aksan',
  'kama',
  'kara',
  'kafa',
  'cena',
  'cami',
  'bucak',
  'insan',
  'mayin',
};

/// Gün ve ay adlarından sonra gelebilen ekler.
const _fuzzySuffixes = [
  '',
  'ya',
  'ye',
  'a',
  'e',
  'yi',
  'i',
  'dan',
  'den',
  'tan',
  'ten',
  'da',
  'de',
  'ta',
  'te',
  'nin',
  'in',
  'un',
  'nun',
  'ki',
  'leri',
  'lari',
  'n',
];

/// Türkçe yazımıyla anahtar sözcükler; düzeltilen sözcük yerine konur.
const _fuzzyDisplay = {
  'sali': 'salı',
  'carsamba': 'çarşamba',
  'persembe': 'perşembe',
  'subat': 'şubat',
  'mayis': 'mayıs',
  'agustos': 'ağustos',
  'eylul': 'eylül',
  'kasim': 'kasım',
  'aralik': 'aralık',
  'yarin': 'yarın',
  'bugun': 'bugün',
  'aksam': 'akşam',
  'ogleden': 'öğleden',
  'ceyrek': 'çeyrek',
  'bucuk': 'buçuk',
};

List<_Fix> _typoFixes(String text) {
  final fixes = <_Fix>[];
  final folded = _fold(text);
  for (final m in RegExp(r'[a-z]{3,}').allMatches(folded)) {
    final word = m[0]!;
    if (_fuzzyStop.contains(word) || _isKnown(word)) continue;
    final fix = _closest(word);
    if (fix != null) {
      final (stem, suffix) = fix;
      fixes.add(_Fix(m.start, m.end, '${_fuzzyDisplay[stem] ?? stem}$suffix'));
    }
  }
  return fixes;
}

/// Sözcük olduğu gibi (ekiyle) bir anahtar sözcükse düzeltme gerekmez.
bool _isKnown(String word) {
  for (final k in _fuzzyWords) {
    if (word.startsWith(k) &&
        _fuzzySuffixes.contains(word.substring(k.length))) {
      return true;
    }
  }
  return false;
}

/// Tek harf farkla en yakın anahtar sözcük ve eki.
(String, String)? _closest(String word) {
  for (final suffix in _fuzzySuffixes) {
    if (!word.endsWith(suffix)) continue;
    final stem = word.substring(0, word.length - suffix.length);
    if (stem.length < 3 || _fuzzyStop.contains(stem)) continue;
    for (final k in _fuzzyWords) {
      // Kısa sözcüklerde yalnızca eksik harf affedilir: “saı” → “salı”.
      if (k.length <= 4 && stem.length >= k.length) continue;
      if (_oneEdit(stem, k)) return (k, suffix);
    }
  }
  return null;
}

/// Tek ekleme, silme, değiştirme veya yan yana iki harfin yer değişimi.
bool _oneEdit(String a, String b) {
  if (a == b || (a.length - b.length).abs() > 1) return false;
  if (a.length == b.length) {
    final diff = [
      for (var i = 0; i < a.length; i++)
        if (a[i] != b[i]) i,
    ];
    if (diff.length == 1) return true;
    return diff.length == 2 &&
        diff[1] == diff[0] + 1 &&
        a[diff[0]] == b[diff[1]] &&
        a[diff[1]] == b[diff[0]];
  }
  final (long, short) = a.length > b.length ? (a, b) : (b, a);
  for (var i = 0; i < long.length; i++) {
    if (long.substring(0, i) + long.substring(i + 1) == short) return true;
  }
  return false;
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
  DateTime? endDate;
  Recurrence? recurrence;
  (Frequency, int)? repeatFor;
  int? repeatCount;

  DateTime get today => dayOnly(now);

  ParsedInput run() {
    if (!disabled.contains(ParseField.date)) _dayOffset();
    if (!disabled.contains(ParseField.time) &&
        !disabled.contains(ParseField.date)) {
      _relative();
    }
    if (!disabled.contains(ParseField.repeat)) {
      _repeatFor();
      if (recurrence == null) _repeat();
      _repeatCount();
      // “2 hafta boyunca ilaç” tek başına her gün demektir.
      if (repeatFor != null) recurrence ??= const Recurrence(Frequency.daily);
    }
    if (!disabled.contains(ParseField.date)) {
      _dateRange();
      _since();
      _until();
    }
    var clock = false;
    if (!disabled.contains(ParseField.time)) {
      _timeRange();
      // “10 dakika kala” süre sanılmasın diye süreden önce bakılır.
      clock = _quarter();
    }
    if (!disabled.contains(ParseField.duration) && duration == null) {
      _duration();
    }
    if (!disabled.contains(ParseField.time) && !clock) _time();
    if (!disabled.contains(ParseField.date)) _date();
    if (hour == null && duration != null) {
      duration = null;
      spans.removeWhere((s) => s.field == ParseField.duration);
    }
    // Saatli gün aralığı her gün tekrarlanan etkinliktir: “5-10 kasım 9-17 kurs”.
    final last = endDate;
    if (last != null && (recurrence != null || hour != null)) {
      recurrence = (recurrence ?? const Recurrence(Frequency.daily)).withUntil(
        last,
      );
      endDate = null;
    }
    spans.sort((a, b) => a.start.compareTo(b.start));
    return ParsedInput(
      title: _title(),
      spans: List.unmodifiable(spans),
      date: date,
      hour: hour,
      minute: minute,
      durationMin: duration,
      endDate: endDate,
      recurrence: recurrence,
      repeatFor: repeatFor,
      repeatCount: repeatCount,
    );
  }

  /// “4 hafta boyunca”, “1 ay süreyle”, “önümüzdeki 10 gün”,
  /// “1 ayın her günü”.
  void _repeatFor() {
    const unit = '(?<u>gun|hafta|ay|yil|sene)';
    bool span(RegExpMatch m, {bool daily = false}) {
      final n = _count(m);
      if (n < 1) return false;
      repeatFor = (_units[m.namedGroup('u')!]!, n);
      if (daily) recurrence = const Recurrence(Frequency.daily);
      return true;
    }

    _scan(
          '$_b$_amountAlt\\s*$unit(?:un|in|lik|luk)?\\s+her\\s+gun(?:u)?$_e',
          ParseField.repeat,
          (m) => span(m, daily: true),
        ) ||
        _scan(
          '$_b$_amountAlt\\s*$unit(?:\\s+|\\s*(?:lik|luk)\\s+)'
          '(?:boyunca|suresince|sureyle|suresiyle|sure\\s+ile)$_e',
          ParseField.repeat,
          (m) => span(m),
        ) ||
        _scan(
          '$_b(?:onumuzdeki|gelecek|sonraki)\\s+$_amountAlt\\s*$unit$_e',
          ParseField.repeat,
          (m) => span(m),
        );
  }

  /// “10 kez”: yalnızca bir tekrarla birlikte anlamlıdır.
  void _repeatCount() {
    final rule = recurrence;
    // “her gün 5 defa su iç” günde beş kez demektir, beş gün değil.
    if (rule == null ||
        (rule.frequency == Frequency.daily && rule.interval == 1)) {
      return;
    }
    _scan('$_b$_amountAlt\\s*(?:kez|kere|defa|sefer)$_e', ParseField.repeat, (
      m,
    ) {
      final n = _count(m);
      if (n < 1) return false;
      repeatCount = n;
      return true;
    });
  }

  void _repeat() {
    const f = ParseField.repeat;
    bool weekly(RegExpMatch m, {int interval = 1, Set<int>? days}) {
      recurrence = Recurrence(
        Frequency.weekly,
        interval: interval,
        weekdays: days ?? _weekdaysIn(m[0]!),
      );
      return interval > 0;
    }

    bool set(Frequency frequency, [int interval = 1]) {
      recurrence = Recurrence(frequency, interval: interval);
      return interval > 0;
    }

    _scan(
          '$_b(?:her\\s+)?$_countAlt\\s+haftada\\s+(?:bir|1)'
          '(?:\\s+(?:$_weekdayList))?$_e',
          f,
          (m) => weekly(m, interval: _count(m)),
        ) ||
        _scan(
          '$_b(?:her\\s+)?$_countAlt\\s+gunde\\s+(?:bir|1)$_e',
          f,
          (m) => set(Frequency.daily, _count(m)),
        ) ||
        _scan('${_b}gun\\s+asiri$_e', f, (_) => set(Frequency.daily, 2)) ||
        _scan(
          '$_b(?:her\\s+)?$_countAlt\\s+ayda\\s+(?:bir|1)$_e',
          f,
          (m) => set(Frequency.monthly, _count(m)),
        ) ||
        _scan(
          '$_b(?:her\\s+hafta\\s*ici(?:\\s+(?:her\\s+)?gun(?:ler)?)?'
          '|hafta\\s*ici\\s+her\\s+gun|hafta\\s*icleri)$_e',
          f,
          (m) => weekly(m, days: weekdaysMonFri),
        ) ||
        _scan(
          '$_b(?:her\\s+hafta\\s*sonu|hafta\\s*sonlari)$_e',
          f,
          (m) => weekly(m, days: {DateTime.saturday, DateTime.sunday}),
        ) ||
        _scan(
          '${_b}her\\s+(?:hafta\\s+)?(?:$_weekdayList)$_e',
          f,
          (m) => weekly(m),
        ) ||
        _scan(
          '$_b(?:(?:$_weekdayAlt)(?:\\s*,\\s*|\\s+ve\\s+))*'
          '(?:$_weekdayAlt)(?:lari|leri)$_e',
          f,
          (m) => weekly(m),
        ) ||
        _scan(
          '$_b(?:her\\s+gun(?:\\s+her\\s+gece)?|hergun)$_e',
          f,
          (_) => set(Frequency.daily),
        ) ||
        // “her sabah 8'de”: saat ayrıca anlaşılır.
        _scan(
          '${_b}her(?=\\s+(?:sabah|aksam|gece|ogle|oglen)$_e)',
          f,
          (_) => set(Frequency.daily),
        ) ||
        _scan(
          '$_b(?:her\\s+hafta|haftada\\s+(?:bir|1))$_e',
          f,
          (m) => weekly(m),
        ) ||
        _scan("${_b}her\\s+ayin\\s+(\\d{1,2})(?:['’]?[a-z]*)?$_e", f, (m) {
          final day = _monthDay(int.parse(m[1]!));
          if (day == null) return false;
          date = day;
          return set(Frequency.monthly);
        }) ||
        _scan(
          '$_b(?:her\\s+ay|ayda\\s+(?:bir|1))$_e',
          f,
          (_) => set(Frequency.monthly),
        ) ||
        _scan(
          '$_b(?:her\\s+(?:yil|sene)|yilda\\s+(?:bir|1))$_e',
          f,
          (_) => set(Frequency.yearly),
        );
  }

  int _count(RegExpMatch m) {
    final n = m.namedGroup('n')!;
    return _counts[n] ?? int.parse(n);
  }

  Set<int> _weekdaysIn(String text) {
    final regex = _compiled[_weekdayAlt] ??= RegExp(_weekdayAlt);
    return {for (final m in regex.allMatches(text)) _weekdays[m[0]!]!};
  }

  /// Bugün veya sonrasında ayın [day]. günü olan ilk tarih.
  DateTime? _monthDay(int day) {
    for (var i = 0; i < 12; i++) {
      final d = DateTime(today.year, today.month + i, day);
      if (d.day == day && !d.isBefore(today)) return d;
    }
    return null;
  }

  /// Tekrarın bitişi, tekrar yoksa son gün: “14 mart tarihine kadar”.
  void _until() {
    bool limit(DateTime? day) {
      if (day == null) return false;
      final rule = recurrence;
      if (rule != null) {
        recurrence = rule.withUntil(day);
      } else {
        date = day;
      }
      return true;
    }

    _scan(
          '$_b(\\d{1,2})[./](\\d{1,2})(?:[./](\\d{4}))?$_untilTail',
          ParseField.date,
          (m) => limit(
            m[3] != null
                ? _valid(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!))
                : _upcoming(int.parse(m[2]!), int.parse(m[1]!)),
          ),
        ) ||
        _scan(
          '$_b(\\d{1,2})\\s+($_monthAlt)(?:\\s+(\\d{4}))?$_untilTail',
          ParseField.date,
          (m) {
            final month = _months[m[2]!]!;
            final day = int.parse(m[1]!);
            return limit(
              m[3] != null
                  ? _valid(int.parse(m[3]!), month, day)
                  : _upcoming(month, day),
            );
          },
        ) ||
        _scan(
          '$_b(?:bu\\s+)?(ay|yil|hafta)(?:in|nin)?\\s+sonuna\\s+kadar$_e',
          ParseField.date,
          (m) => limit(switch (m[1]) {
            'ay' => DateTime(today.year, today.month + 1, 0),
            'yil' => DateTime(today.year, 12, 31),
            _ => addDays(today, 7 - today.weekday),
          }),
        ) ||
        _scan(
          '$_b($_monthAlt)(?:in|nin|un|nun)?\\s+sonuna\\s+kadar$_e',
          ParseField.date,
          (m) {
            final month = _months[m[1]!]!;
            final year = month < today.month ? today.year + 1 : today.year;
            return limit(DateTime(year, month + 1, 0));
          },
        ) ||
        _scan(
          '$_b($_weekdayAlt)$_untilTail',
          ParseField.date,
          (m) => limit(_nextWeekday(_weekdays[m[1]!]!)),
        ) ||
        _scan(
          '$_b(yarin|obur gun)(?:a|e)?\\s+kadar$_e',
          ParseField.date,
          (m) => limit(addDays(today, m[1] == 'yarin' ? 1 : 2)),
        );
  }

  /// Başlangıç günü: “yarından itibaren”, “10 kasımdan başlayarak”,
  /// “pazartesiden itibaren”, “gelecek aydan itibaren”.
  void _since() {
    const tail =
        "['’]?(?:dan|den|tan|ten)\\s+(?:itibaren|baslayarak|baslamak\\s+uzere)"
        '(?![a-z0-9])';
    bool start(DateTime? day) {
      if (day == null) return false;
      date = day;
      return true;
    }

    _scan(
          '$_b(bugun|yarin|obur\\s*gun)$tail',
          ParseField.date,
          (m) => start(
            addDays(today, switch (m[1]) {
              'bugun' => 0,
              'yarin' => 1,
              _ => 2,
            }),
          ),
        ) ||
        _scan(
          '$_b(\\d{1,2})[./](\\d{1,2})(?:[./](\\d{4}))?$tail',
          ParseField.date,
          (m) => start(
            m[3] != null
                ? _valid(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!))
                : _upcoming(int.parse(m[2]!), int.parse(m[1]!)),
          ),
        ) ||
        _scan(
          '$_b(\\d{1,2})\\s+($_monthAlt)(?:\\s+(\\d{4}))?$tail',
          ParseField.date,
          (m) {
            final month = _months[m[2]!]!;
            final day = int.parse(m[1]!);
            return start(
              m[3] != null
                  ? _valid(int.parse(m[3]!), month, day)
                  : _upcoming(month, day),
            );
          },
        ) ||
        _scan('$_b($_weekdayAlt)$tail', ParseField.date, (m) {
          final target = _weekdays[m[1]!]!;
          return start(today.weekday == target ? today : _nextWeekday(target));
        }) ||
        _scan(
          '$_b(?:gelecek|onumuzdeki|sonraki)\\s+(hafta|ay)$tail',
          ParseField.date,
          (m) => start(
            m[1] == 'hafta'
                ? addDays(today, 8 - today.weekday)
                : DateTime(today.year, today.month + 1),
          ),
        );
  }

  /// Birkaç günlük aralık: “5-10 kasım”, “28 kasım - 3 aralık”,
  /// “5 kasımdan 10 kasıma kadar”, “pazartesiden cumaya kadar”.
  void _dateRange() {
    const f = ParseField.date;
    bool range(int d1, int? m1, int d2, int m2, String? year) {
      final y = year == null ? null : int.parse(year);
      final first = y != null
          ? _valid(y, m1 ?? m2, d1)
          : _upcoming(m1 ?? m2, d1);
      if (first == null) return false;
      var last = _valid(y ?? first.year, m2, d2);
      if (last != null && last.isBefore(first)) {
        last = _valid(first.year + 1, m2, d2);
      }
      if (last == null || !last.isAfter(first)) return false;
      date = first;
      endDate = last;
      return true;
    }

    const end = "(?:['’]?[a-z]*)?";
    _scan(
          '$_b(\\d{1,2})\\s*[-–]\\s*(\\d{1,2})\\s+($_monthAlt)'
          '(?:\\s+(\\d{4}))?$end$_e(?:\\s+arasi(?:nda)?$_e)?',
          f,
          (m) => range(
            int.parse(m[1]!),
            null,
            int.parse(m[2]!),
            _months[m[3]!]!,
            m[4],
          ),
        ) ||
        _scan(
          '$_b(\\d{1,2})\\s+($_monthAlt)\\s*[-–]\\s*(\\d{1,2})\\s+($_monthAlt)'
          '(?:\\s+(\\d{4}))?$end$_e',
          f,
          (m) => range(
            int.parse(m[1]!),
            _months[m[2]!]!,
            int.parse(m[3]!),
            _months[m[4]!]!,
            m[5],
          ),
        ) ||
        _scan(
          '$_b(\\d{1,2})(?:\\s+($_monthAlt))?$_fromSuffix\\s+(\\d{1,2})\\s+'
          '($_monthAlt)(?:\\s+(\\d{4}))?$end\\s+kadar$_e',
          f,
          (m) => range(
            int.parse(m[1]!),
            m[2] == null ? null : _months[m[2]!]!,
            int.parse(m[3]!),
            _months[m[4]!]!,
            m[5],
          ),
        ) ||
        _scan(
          '$_b(\\d{1,2})(?:\\s+($_monthAlt))?$_rangeAnd\\s+(\\d{1,2})\\s+'
          '($_monthAlt)$end\\s+arasi(?:nda)?$_e',
          f,
          (m) => range(
            int.parse(m[1]!),
            m[2] == null ? null : _months[m[2]!]!,
            int.parse(m[3]!),
            _months[m[4]!]!,
            null,
          ),
        ) ||
        _scan(
          '$_b($_weekdayAlt)(?:dan|den|tan|ten)\\s+($_weekdayAlt)'
          '(?:ya|ye|a|e)?\\s+kadar$_e',
          f,
          (m) {
            final from = _weekdays[m[1]!]!;
            final to = _weekdays[m[2]!]!;
            final first = today.weekday == from ? today : _nextWeekday(from);
            date = first;
            endDate = addDays(first, (to - from) % 7);
            return to != from;
          },
        );
  }

  /// “14:00-16:00”, “saat 14-16”, “14'ten 16'ya kadar”, “9 ile 11 arası”.
  void _timeRange() {
    const h1 = '(?<h1>\\d{1,2})(?:[:.](?<m1>\\d{2})|\\s*(?<b1>bucuk))?';
    const h2 = '(?<h2>\\d{1,2})(?:[:.](?<m2>\\d{2})|\\s*(?<b2>bucuk))?';
    const start = '$_saatBefore(?:$_qualifier\\s+)?(?:(?<s>saat)\\s+)?$h1';
    // İkinci saatin de günün bölümü olabilir: “sabah 9'dan öğlen 12'ye”.
    const end = '(?:saat\\s+)?(?:(?<q2>$_qualifierAlt)\\s+)?(?:saat\\s+)?$h2';
    const between = '\\s+(?:saatleri\\s+)?arasi(?:nda)?';
    _scan(
          '$_b$start\\s*[-–]\\s*$end'
          '(?:(?<a>$between))?(?![./]\\d)$_numSuffix$_e',
          ParseField.time,
          (m) => _setRange(m, strict: true),
        ) ||
        _scan(
          '$_b$start$_fromSuffix\\s+$end(?:$_toSuffix)?(?:\\s+kadar)?$_e',
          ParseField.time,
          (m) => _setRange(m, strict: false),
        ) ||
        _scan(
          '$_b$start$_rangeAnd\\s+$end$between$_e',
          ParseField.time,
          (m) => _setRange(m, strict: false),
        );
  }

  /// [at] konumundan sonraki kelime bir ölçü birimi mi.
  bool _unitFollows(int at) {
    final next = RegExp(r'^\s*([a-z]+)').firstMatch(folded.substring(at));
    return next != null && _measureWords.contains(next[1]);
  }

  /// Tireli yalın sayılar (“14-16 ders”) ancak gündüz saatine benziyorsa ve
  /// ardından “sayfa”, “kişi” gibi bir birim gelmiyorsa saattir; “3-4 kişi”
  /// saat değildir.
  bool _setRange(RegExpMatch m, {required bool strict}) {
    final q = m.namedGroup('q');
    final q2 = m.namedGroup('q2') ?? q;
    final m1 = m.namedGroup('m1');
    final m2 = m.namedGroup('m2');
    var start = int.parse(m.namedGroup('h1')!);
    var end = int.parse(m.namedGroup('h2')!);
    if (strict &&
        m1 == null &&
        m2 == null &&
        q2 == null &&
        m.namedGroup('b1') == null &&
        m.namedGroup('b2') == null &&
        m.namedGroup('s') == null &&
        m.namedGroup('a') == null &&
        !(start >= 7 && end <= 23 && end > start && !_unitFollows(m.end))) {
      return false;
    }
    final startMin = m1 != null
        ? int.parse(m1)
        : (m.namedGroup('b1') != null ? 30 : 0);
    final endMin = m2 != null
        ? int.parse(m2)
        : (m.namedGroup('b2') != null ? 30 : 0);
    if (start > 24 || end > 24 || startMin > 59 || endMin > 59) return false;
    if (q != null) {
      start = _applyQualifier(q, start);
    } else if (m1 == null) {
      start = _guessAfternoon(start);
    }
    if (q2 != null) {
      end = _applyQualifier(q2, end);
    } else if (m2 == null) {
      end = _guessAfternoon(end);
    }
    final from = start * 60 + startMin;
    var to = end * 60 + endMin;
    if (to <= from) to += end < 12 && to + 12 * 60 > from ? 12 * 60 : 24 * 60;
    hour = start % 24;
    minute = startMin;
    if (!disabled.contains(ParseField.duration)) duration = to - from;
    return true;
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

  /// Güne göre önce/sonra: “çarşambadan önce” salı, “salıdan sonra” çarşamba,
  /// “cumadan 2 gün önce”, “haftaya çarşambadan önce”, “yarından sonra”.
  /// Gün adı, yalın gün adı gibi çözülür, sonra kaydırılır.
  void _dayOffset() {
    const ablative = "(?:\\s+gunu(?:n)?)?['’]?(?:dan|den|tan|ten|nden)";
    const amount = '(?:\\s+(?<n>\\d{1,3}|$_numberWordAlt)\\s+(?<u>gun|hafta))?';
    int? shift(RegExpMatch m) {
      final n = m.namedGroup('n');
      if (n == null) return 1;
      final v = _numberValue(n);
      if (v == null || v < 1) return null;
      return m.namedGroup('u') == 'hafta' ? v * 7 : v;
    }

    _scan(
          '$_b(?:(?<p>haftaya|gelecek\\s+hafta|onumuzdeki\\s+hafta|next\\s+week'
          '|gelecek|onumuzdeki|bu)\\s+)?(?<d>$_weekdayAlt)$ablative'
          '$amount\\s+(?<w>once|sonra)$_e',
          ParseField.date,
          (m) {
            final n = shift(m);
            if (n == null) return false;
            final target = _weekdays[m.namedGroup('d')!]!;
            final p = m.namedGroup('p');
            final base = p == null || p == 'bu'
                ? _nextWeekday(target)
                : _weekdayNextWeek(target);
            date = addDays(base, m.namedGroup('w') == 'once' ? -n : n);
            return true;
          },
        ) ||
        _scan(
          "$_b(?<d>bugun|yarin|obur\\s*gun)['’]?(?:den|dan)$amount\\s+sonra$_e",
          ParseField.date,
          (m) {
            final n = shift(m);
            if (n == null) return false;
            final d = m.namedGroup('d')!;
            final base = d == 'bugun' ? 0 : (d == 'yarin' ? 1 : 2);
            date = addDays(today, base + n);
            return true;
          },
        );
  }

  void _relative() {
    _scan(
      '$_b(\\d+|yarim|$_numberWordAlt)\\s*(dakika|dk|saat|gun|hafta|ay)'
      '\\s+sonra$_e',
      ParseField.date,
      (m) {
        final unit = m[2]!;
        final half = m[1] == 'yarim';
        final n = half ? 0 : _numberValue(m[1]!)!;
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
    _scan(
          '$_b(?:saat\\s+)?gece\\s*yarisi(?:nda|na)?$_e',
          ParseField.time,
          (_) => _setTime(0, null, null),
        ) ||
        _spelledHour() ||
        _half() ||
        _scan(
          '$_b$_saatBefore$qualifier\\s+$clock$_numSuffix$_e',
          ParseField.time,
          (m) {
            return _setTime(
              _applyQualifier(m[1]!, int.parse(m[2]!)),
              m[3],
              m[4],
            );
          },
        ) ||
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

  /// Yazıyla saat yalnızca “saat”ten sonra veya günün bölümünden sonra “-de”
  /// ekiyle anlaşılır; “akşam bir şey al” saat değildir.
  bool _spelledHour() {
    bool set(RegExpMatch m) {
      final word = m.namedGroup('w')!.replaceAll(RegExp(r'\s+'), ' ');
      final h = _hourWords[word]!;
      final q = m.namedGroup('q');
      return _setTime(
        q != null ? _applyQualifier(q, h) : _guessAfternoon(h),
        null,
        m.namedGroup('b'),
      );
    }

    return _scan(
          '$_b$_saatBefore(?:(?<q>$_qualifierAlt)\\s+)?saat\\s+'
          '(?<w>$_hourWordAlt)(?<b>\\s*bucuk)?$_numSuffix$_e',
          ParseField.time,
          set,
        ) ||
        _scan(
          '$_b(?<q>$_qualifierAlt)\\s+(?<w>$_hourWordAlt)(?<b>\\s*bucuk)?'
          "['’]?(?:te|de|ta|da)$_e",
          ParseField.time,
          set,
        );
  }

  /// “10'u çeyrek geçe”, “11'e 10 var”, “akşam 7'ye çeyrek kala”,
  /// “beşi on geçe”, “altıya yirmi kala”, “15 kala 6”. Eksiz saat
  /// (“saat 3 çeyrek geçe”) yalnızca “saat” veya “çeyrek” ile anlaşılır;
  /// “on iki gece” on iki gecedir, saat değil.
  bool _quarter() {
    const prefix = '$_saatBefore(?:(?<q>$_qualifierAlt)\\s+)?(?<s>saat\\s+)?';
    const amount =
        '(?<n>\\d{1,2}|ceyrek|$_numberWordAlt)(?:\\s+(?:dakika|dk))?';
    int? minutes(RegExpMatch m) {
      final n = m.namedGroup('n')!;
      final value = n == 'ceyrek' ? 15 : _numberValue(n);
      return value != null && value > 0 && value < 60 ? value : null;
    }

    /// Saat ve eki var mı; ek yoksa “saat” veya “çeyrek” gerekir.
    int? hourOf(RegExpMatch m, Map<String, int> cased) {
      final digits = m.namedGroup('h');
      final word = m.namedGroup('hw')?.replaceAll(RegExp(r'\s+'), ' ');
      int h;
      bool suffixed;
      if (digits != null) {
        h = int.parse(digits);
        suffixed = m.namedGroup('hs') != null;
      } else {
        final c = cased[word];
        suffixed = c != null;
        h = c ?? _hourWords[word]!;
      }
      if (h < 1 || h > 24) return null;
      if (!suffixed &&
          m.namedGroup('s') == null &&
          m.namedGroup('n') != 'ceyrek') {
        return null;
      }
      final q = m.namedGroup('q');
      return q != null ? _applyQualifier(q, h) : _guessAfternoon(h);
    }

    bool before(int h, int n) {
      final at = (h * 60 - n) % (24 * 60);
      return _setTime(at ~/ 60, '${at % 60}', null);
    }

    return _scan(
          // Ek ayrı da yazılabilir: “2 yi çeyrek geçe”.
          "$_b$prefix(?:(?<h>\\d{1,2})(?<hs>(?:['’]|\\s)?(?:u|i|yu|yi))?"
          '|(?<hw>$_hourAccAlt))\\s+$amount\\s+gece(?:de)?$_e',
          ParseField.time,
          (m) {
            final n = minutes(m);
            final h = hourOf(m, _hourWordsAcc);
            if (n == null || h == null) return false;
            return _setTime(h, '$n', null);
          },
        ) ||
        _scan(
          "$_b$prefix(?:(?<h>\\d{1,2})(?<hs>(?:['’]|\\s)?(?:e|a|ye|ya))?"
          '|(?<hw>$_hourDatAlt))\\s+$amount\\s+(?<k>var|kala)$_e',
          ParseField.time,
          (m) {
            final n = minutes(m);
            final h = hourOf(m, _hourWordsDat);
            if (n == null || h == null) return false;
            // “ona iki var” saat değildir; yazıyla saatte “var” çeyrekle olur.
            if (m.namedGroup('k') == 'var' &&
                m.namedGroup('hw') != null &&
                m.namedGroup('n') != 'ceyrek') {
              return false;
            }
            return before(h, n);
          },
        ) ||
        // “saat 2 çeyrekte”, “2'yi çeyrekte”: çeyrek geçe.
        _scan(
          "$_b$prefix(?:(?<h>\\d{1,2})(?<hs>(?:['’]|\\s)?(?:u|i|yu|yi))?"
          '|(?<hw>$_hourAccAlt))\\s+(?<n>ceyrek)(?:te|de|ta|da)$_e',
          ParseField.time,
          (m) {
            final h = hourOf(m, _hourWordsAcc);
            return h != null && _setTime(h, '15', null);
          },
        ) ||
        // “15 kala 6”, “çeyrek kala beş”
        _scan(
          '$_b(?:(?<q>$_qualifierAlt)\\s+)?$amount\\s+kala\\s+(?<s>saat\\s+)?'
          '(?:(?<h>\\d{1,2})|(?<hw>$_hourWordAlt))$_numSuffix$_e',
          ParseField.time,
          (m) {
            if (_unitFollows(m.end)) return false;
            final n = minutes(m);
            final word = m.namedGroup('hw')?.replaceAll(RegExp(r'\s+'), ' ');
            final raw = word != null
                ? _hourWords[word]!
                : int.parse(m.namedGroup('h')!);
            if (n == null || raw < 1 || raw > 24) return false;
            final q = m.namedGroup('q');
            return before(
              q != null ? _applyQualifier(q, raw) : _guessAfternoon(raw),
              n,
            );
          },
        );
  }

  /// “3 buçuk”, “üç buçukta”, “akşam dokuz buçuk”, “saat yarımda” (12:30).
  bool _half() {
    const tail = r'bucu(?:k(?:ta|da)?|ga)';
    const prefix = '$_saatBefore(?:(?<q>$_qualifierAlt)\\s+)?(?:saat\\s+)?';
    bool set(RegExpMatch m, int h) {
      if (_unitFollows(m.end)) return false;
      final q = m.namedGroup('q');
      return _setTime(
        q != null ? _applyQualifier(q, h) : _guessAfternoon(h),
        '30',
        null,
      );
    }

    return _scan(
          '$_b$prefix(?<h>\\d{1,2})\\s*$tail$_e',
          ParseField.time,
          (m) => set(m, int.parse(m.namedGroup('h')!)),
        ) ||
        _scan(
          '$_b$prefix(?<w>$_hourWordAlt)\\s+$tail$_e',
          ParseField.time,
          (m) => set(
            m,
            _hourWords[m.namedGroup('w')!.replaceAll(RegExp(r'\s+'), ' ')]!,
          ),
        ) ||
        _scan(
          '$_b$_saatBefore(?:(?:(?<q>$_qualifierAlt)\\s+)(?:saat\\s+)?'
          '|saat\\s+)yarim(?:da)?$_e(?!\\s+saat)',
          ParseField.time,
          (m) {
            final q = m.namedGroup('q');
            if (q == null || q == 'gece' || q.startsWith('ogle')) {
              return _setTime(q == 'gece' ? 0 : 12, '30', null);
            }
            return false;
          },
        );
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
          // “pazara gittim”, “pazar alışverişi” gibi cümleler gün değildir.
          if (m[1] == 'pazar' && m[2] == null) {
            if (!m[0]!.endsWith('pazar')) return false;
            final next = RegExp(r'^\s*([a-z]+)')
                .firstMatch(folded.substring(m.end));
            if (next != null && _marketWords.contains(next[1])) return false;
          }
          // Günleri tekrar belirlediyse yalın gün adı başlığın parçasıdır.
          if (m[2] == null && (recurrence?.weekdays.isNotEmpty ?? false)) {
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
    final d = _valid(year, month, day);
    if (d == null) return false;
    date = d;
    return true;
  }

  bool _setUpcoming(int month, int day) {
    final d = _upcoming(month, day);
    if (d == null) return false;
    date = d;
    return true;
  }

  static DateTime? _valid(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    final d = DateTime(year, month, day);
    return d.day == day ? d : null;
  }

  /// Bu yıl geçtiyse gelecek yıl.
  DateTime? _upcoming(int month, int day) {
    final thisYear = _valid(today.year, month, day);
    if (thisYear == null) return null;
    return thisYear.isBefore(today)
        ? _valid(today.year + 1, month, day)
        : thisYear;
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
