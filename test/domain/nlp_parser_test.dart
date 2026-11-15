import 'package:ajandam/domain/nlp_parser.dart';
import 'package:ajandam/domain/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Salı, 3 Kasım 2026, 10:00
  final now = DateTime(2026, 11, 3, 10);
  final parser = NlpParser();

  ParsedInput p(String text, {Set<ParseField> disabled = const {}}) =>
      parser.parse(text, now, disabled: disabled);

  void expectTime(ParsedInput r, int hour, [int minute = 0]) {
    expect([r.hour, r.minute], [hour, minute]);
  }

  group('PRD örnekleri', () {
    test('yarın 14:00 dişçi', () {
      final r = p('yarın 14:00 dişçi');
      expect(r.title, 'dişçi');
      expect(r.date, DateTime(2026, 11, 4));
      expectTime(r, 14);
    });

    test('yarın 10:00 toplantı', () {
      final r = p('yarın 10:00 toplantı');
      expect(r.title, 'toplantı');
      expectTime(r, 10);
    });

    test('cuma', () {
      expect(p('cuma market').date, DateTime(2026, 11, 6));
    });

    test('haftaya salı', () {
      final r = p('haftaya salı rapor');
      expect(r.date, DateTime(2026, 11, 10));
      expect(r.title, 'rapor');
    });

    test('öğleden sonra 3', () {
      final r = p('öğleden sonra 3 berber');
      expectTime(r, 15);
      expect(r.title, 'berber');
    });

    test('2 saat süresi', () {
      final r = p('yarın 14:00 2 saat sunum');
      expect(r.durationMin, 120);
      expectTime(r, 14);
      expect(r.title, 'sunum');
    });
  });

  group('tarih', () {
    test('bugün ve öbür gün', () {
      expect(p('bugün ara').date, DateTime(2026, 11, 3));
      expect(p('öbür gün ara').date, DateTime(2026, 11, 5));
    });

    test('bugünkü gün adı gelecek haftayı gösterir', () {
      expect(p('salı spor').date, DateTime(2026, 11, 10));
    });

    test('ekli gün adları', () {
      final r = p('cumaya randevu');
      expect(r.date, DateTime(2026, 11, 6));
      expect(r.title, 'randevu');
      expect(p('pazartesiye toplantı').date, DateTime(2026, 11, 9));
    });

    test('cumartesi cuma ile karışmaz', () {
      expect(p('cumartesi piknik').date, DateTime(2026, 11, 7));
    });

    test('pazar günü ve pazara ayrımı', () {
      expect(p('pazar günü kahvaltı').date, DateTime(2026, 11, 8));
      final r = p('pazara git');
      expect(r.date, isNull);
      expect(r.title, 'pazara git');
    });

    test('haftaya tek başına 7 gün sonradır', () {
      expect(p('haftaya rapor').date, DateTime(2026, 11, 10));
    });

    test('ay adı ve geçmiş tarih gelecek yıla gider', () {
      expect(p('15 aralık tatil').date, DateTime(2026, 12, 15));
      expect(p('5 ocak tatil').date, DateTime(2027, 1, 5));
      expect(p('1 kasıma kadar').date, DateTime(2027, 11, 1));
    });

    test('ayın 15i', () {
      expect(p("ayın 15'i kira").date, DateTime(2026, 11, 15));
      final r = p('ayın 1i kira');
      expect(r.date, DateTime(2026, 12, 1));
      expect(r.title, 'kira');
    });

    test('sayısal tarih', () {
      expect(p('12/11 sunum').date, DateTime(2026, 11, 12));
      expect(p('25.12.2026 tatil').date, DateTime(2026, 12, 25));
    });

    test('geçersiz tarih yok sayılır', () {
      final r = p('31 şubat deneme');
      expect(r.date, isNull);
      expect(r.title, '31 şubat deneme');
    });

    test('saate benzeyen tam tarih saat sanılmaz', () {
      final r = p('16.10.2026 eski iş');
      expect(r.date, DateTime(2026, 10, 16));
      expect(r.hasTime, isFalse);
      expect(r.title, 'eski iş');
    });

    test('N gün sonra', () {
      expect(p('3 gün sonra ara').date, DateTime(2026, 11, 6));
      expect(p('2 hafta sonra ara').date, DateTime(2026, 11, 17));
    });

    test('Türkçe karakter kullanmadan yazılabilir', () {
      expect(p('yarin ara').date, DateTime(2026, 11, 4));
      expect(p('persembe ara').date, DateTime(2026, 11, 5));
      expectTime(p('ogleden sonra 4 ara'), 16);
    });

    test('büyük harfle yazılabilir', () {
      final r = p('YARIN SALI TOPLANTI');
      expect(r.date, DateTime(2026, 11, 4));
    });
  });

  group('saat', () {
    test('noktalı ve ekli saat', () {
      expectTime(p('14.30 kahve'), 14, 30);
      final r = p("yarın 14:00'te dişçi");
      expectTime(r, 14);
      expect(r.title, 'dişçi');
    });

    test('saat kelimesi ile', () {
      expectTime(p('saat 9 spor'), 9);
      expectTime(p('saat 15 spor'), 15);
      expectTime(p("saat 3'te spor"), 15);
      expectTime(p('saat 3 buçukta spor'), 15, 30);
    });

    test('günün bölümleri', () {
      expectTime(p('sabah 9 koşu'), 9);
      expectTime(p('akşam 7 yemek'), 19);
      expectTime(p('gece 11 film'), 23);
      expectTime(p('öğlen 1 yemek'), 13);
    });

    test('ekli yalın saat', () {
      expectTime(p("4'te çay"), 16);
      expectTime(p("11'de çay"), 11);
    });

    test('tek başına günün bölümü saat sayılmaz', () {
      final r = p('akşam yemeği hazırla');
      expect(r.hasTime, isFalse);
      expect(r.title, 'akşam yemeği hazırla');
    });

    test('geçersiz saat yok sayılır', () {
      expect(p('25:00 deneme').hasTime, isFalse);
    });

    test('N saat sonra şimdiye eklenir', () {
      final r = p('2 saat sonra ara');
      expectTime(r, 12);
      expect(r.date, DateTime(2026, 11, 3));
      expect(r.durationMin, isNull);
      expect(r.title, 'ara');
    });

    test('30 dakika sonra', () {
      expectTime(p('30 dk sonra ara'), 10, 30);
      expectTime(p('yarım saat sonra ara'), 10, 30);
    });
  });

  group('süre', () {
    test('dakika ve bileşik süre', () {
      expect(p('14:00 45 dk görüşme').durationMin, 45);
      expect(p('14:00 1 saat 30 dk görüşme').durationMin, 90);
      expect(p('14:00 yarım saat görüşme').durationMin, 30);
      expect(p('14:00 1,5 saat görüşme').durationMin, 90);
      expect(p('14:00 2 saatlik görüşme').durationMin, 120);
    });

    test('saat olmadan süre başlıkta kalır', () {
      final r = p('2 saat kitap oku');
      expect(r.durationMin, isNull);
      expect(r.title, '2 saat kitap oku');
    });
  });

  group('İngilizce', () {
    test('tomorrow 3pm', () {
      final r = p('tomorrow 3pm dentist');
      expect(r.date, DateTime(2026, 11, 4));
      expectTime(r, 15);
      expect(r.title, 'dentist');
    });

    test('friday at 9', () {
      final r = p('friday at 9 gym');
      expect(r.date, DateTime(2026, 11, 6));
      expectTime(r, 9);
    });
  });

  group('başlık ve aralıklar', () {
    test('metnin ortasındaki ifade çıkarılır', () {
      expect(p('dişçi yarın 14:00').title, 'dişçi');
      expect(p('anneme ara, yarın').title, 'anneme ara');
    });

    test('için kelimesi başta kalmaz', () {
      expect(p('yarın için market').title, 'market');
    });

    test('aralıklar özgün metni gösterir', () {
      const text = 'yarın 14:00 dişçi';
      final r = p(text);
      expect(
        [for (final s in r.spans) text.substring(s.start, s.end)],
        ['yarın', '14:00'],
      );
    });

    test('kapatılan alan başlıkta kalır', () {
      final r = p('pazar 14:00 kahvaltı', disabled: {ParseField.date});
      expect(r.date, isNull);
      expect(r.title, 'pazar kahvaltı');
      expectTime(r, 14);
    });

    test('ayrıştırılacak bir şey yoksa metin aynen kalır', () {
      final r = p('süt al');
      expect(r.title, 'süt al');
      expect(r.spans, isEmpty);
    });
  });

  group('resolveDay', () {
    test('tarih yoksa verilen gün kullanılır', () {
      final base = DateTime(2026, 11, 8);
      expect(p('süt al').resolveDay(base, now), base);
    });

    test('bugün geçmiş saat yarına kayar', () {
      final today = DateTime(2026, 11, 3);
      expect(p('09:00 koşu').resolveDay(today, now), DateTime(2026, 11, 4));
      expect(p('11:00 koşu').resolveDay(today, now), today);
    });

    test('başka günde geçmiş saat kaymaz', () {
      final base = DateTime(2026, 11, 8);
      expect(p('09:00 koşu').resolveDay(base, now), base);
    });
  });

  group('saat aralığı', () {
    test('iki nokta ile', () {
      final r = p('14:00-16:00 toplantı');
      expect(r.title, 'toplantı');
      expectTime(r, 14);
      expect(r.durationMin, 120);
      expect(r.isEvent, isTrue);
    });

    test('saat 3-5 öğleden sonradır', () {
      final r = p('saat 3-5 ders');
      expectTime(r, 15);
      expect(r.durationMin, 120);
      expect(r.title, 'ders');
    });

    test('ten ya kadar', () {
      final r = p("yarın 14'ten 16:30'a kadar sınav");
      expectTime(r, 14);
      expect(r.durationMin, 150);
      expect(r.title, 'sınav');
    });

    test('ile arası', () {
      final r = p('9 ile 11 arası kahvaltı');
      expectTime(r, 9);
      expect(r.durationMin, 120);
    });

    test('akşam 7-9', () {
      final r = p('akşam 7-9 sinema');
      expectTime(r, 19);
      expect(r.durationMin, 120);
    });

    test('sayı aralığı saat sanılmaz', () {
      final r = p('3-4 sayfa oku');
      expect(r.hour, isNull);
      expect(r.title, '3-4 sayfa oku');
    });

    test('gece yarısını geçen aralık', () {
      final r = p('22:00-01:00 nöbet');
      expectTime(r, 22);
      expect(r.durationMin, 180);
    });
  });

  group('tekrar', () {
    test('kullanıcının örneği', () {
      final r = p('her hafta cuma saat 5 de 14 mart tarihine kadar spor');
      expect(r.title, 'spor');
      expectTime(r, 17);
      expect(
        r.recurrence,
        Recurrence(
          Frequency.weekly,
          weekdays: const {DateTime.friday},
          until: DateTime(2027, 3, 14),
        ),
      );
      expect(r.resolveDay(now, now), DateTime(2026, 11, 6));
    });

    test('her gün', () {
      final r = p('her gün 9:00 ilaç');
      expect(r.recurrence, const Recurrence(Frequency.daily));
      expect(r.title, 'ilaç');
      expect(r.resolveDay(now, now), DateTime(2026, 11, 4));
    });

    test('her sabah 8de', () {
      final r = p("her sabah 8'de yürüyüş");
      expect(r.recurrence, const Recurrence(Frequency.daily));
      expectTime(r, 8);
      expect(r.title, 'yürüyüş');
    });

    test('hafta içi her gün', () {
      final r = p('hafta içi her gün 8:30 servis');
      expect(r.recurrence!.isWeekdays, isTrue);
      expectTime(r, 8, 30);
    });

    test('birden çok gün ve saat aralığı', () {
      final r = p('her salı ve perşembe 18:00-19:30 spor');
      expect(r.recurrence!.weekdays, {DateTime.tuesday, DateTime.thursday});
      expect(r.durationMin, 90);
      expect(r.title, 'spor');
      // Bugün salı ve saat geçmedi.
      expect(r.resolveDay(now, now), DateTime(2026, 11, 3));
    });

    test('cumaları', () {
      final r = p('cumaları halı saha');
      expect(r.recurrence!.weekdays, {DateTime.friday});
      expect(r.title, 'halı saha');
    });

    test('iki haftada bir', () {
      final r = p('2 haftada bir pazartesi temizlik');
      expect(r.recurrence!.interval, 2);
      expect(r.recurrence!.weekdays, {DateTime.monday});
      expect(r.title, 'temizlik');
    });

    test('gün aşırı', () {
      expect(p('gün aşırı koşu').recurrence!.interval, 2);
    });

    test('her ayın 5i', () {
      final r = p("her ayın 5'i kira");
      expect(r.recurrence, const Recurrence(Frequency.monthly));
      expect(r.date, DateTime(2026, 11, 5));
      expect(r.title, 'kira');
    });

    test('her yıl', () {
      final r = p('her yıl 12 mart doğum günü');
      expect(r.recurrence, const Recurrence(Frequency.yearly));
      expect(r.date, DateTime(2027, 3, 12));
      expect(r.title, 'doğum günü');
    });

    test('ay sonuna kadar', () {
      final r = p('her gün ay sonuna kadar antibiyotik');
      expect(r.recurrence!.until, DateTime(2026, 11, 30));
      expect(r.title, 'antibiyotik');
    });

    test('kapatılınca tekrar anlaşılmaz', () {
      final r = p('her gün ilaç', disabled: {ParseField.repeat});
      expect(r.recurrence, isNull);
      expect(r.title, 'her gün ilaç');
    });
  });

  group('kadar', () {
    test('tekrar yoksa son gün olur', () {
      final r = p('cumaya kadar rapor');
      expect(r.date, DateTime(2026, 11, 6));
      expect(r.title, 'rapor');
    });
  });

  group('gün aralığı', () {
    test('5-10 kasım', () {
      final r = p('5-10 kasım tatil');
      expect(r.date, DateTime(2026, 11, 5));
      expect(r.endDate, DateTime(2026, 11, 10));
      expect(r.title, 'tatil');
      expect(r.isEvent, isTrue);
    });

    test('ay atlayan aralık', () {
      final r = p('28 aralık - 3 ocak kayak');
      expect(r.date, DateTime(2026, 12, 28));
      expect(r.endDate, DateTime(2027, 1, 3));
    });

    test('dan a kadar', () {
      final r = p('5 kasımdan 10 kasıma kadar fuar');
      expect(r.endDate, DateTime(2026, 11, 10));
      expect(r.title, 'fuar');
    });

    test('pazartesiden cumaya kadar', () {
      final r = p('pazartesiden cumaya kadar kurs');
      expect(r.date, DateTime(2026, 11, 9));
      expect(r.endDate, DateTime(2026, 11, 13));
    });

    test('saatli aralık her gün tekrarlanır', () {
      final r = p('5-10 kasım 9-17 arası kurs');
      expect(r.endDate, isNull);
      expect(
        r.recurrence,
        Recurrence(Frequency.daily, until: DateTime(2026, 11, 10)),
      );
      expect(r.date, DateTime(2026, 11, 5));
      expectTime(r, 9);
      expect(r.durationMin, 8 * 60);
    });
  });

  group('süreli tekrar', () {
    Recurrence? rule(ParsedInput r) => r.recurrenceFrom(r.resolveDay(now, now));

    test('4 hafta boyunca her gün', () {
      final r = p('4 hafta boyunca her gün 9:00 ilaç');
      expect(r.title, 'ilaç');
      expect(r.resolveDay(now, now), DateTime(2026, 11, 4));
      expect(
        rule(r),
        Recurrence(Frequency.daily, until: DateTime(2026, 12, 1)),
      );
    });

    test('1 ayın her günü', () {
      final r = p('1 ayın her günü vitamin');
      expect(r.title, 'vitamin');
      expect(
        rule(r),
        Recurrence(Frequency.daily, until: DateTime(2026, 12, 2)),
      );
    });

    test('tek başına süre her gün demektir', () {
      final r = p('2 hafta boyunca antibiyotik');
      expect(r.title, 'antibiyotik');
      expect(rule(r)!.frequency, Frequency.daily);
      expect(rule(r)!.until, DateTime(2026, 11, 16));
    });

    test('bir ay süreyle her pazartesi', () {
      final r = p('bir ay süreyle her pazartesi fizik tedavi');
      expect(r.title, 'fizik tedavi');
      expect(r.resolveDay(now, now), DateTime(2026, 11, 9));
      expect(rule(r)!.weekdays, {DateTime.monday});
      expect(rule(r)!.until, DateTime(2026, 12, 8));
    });

    test('önümüzdeki 10 gün her sabah 8de', () {
      final r = p("önümüzdeki 10 gün her sabah 8'de yürüyüş");
      expect(r.title, 'yürüyüş');
      expectTime(r, 8);
      expect(rule(r)!.until, DateTime(2026, 11, 13));
    });

    test('10 kez', () {
      final r = p('her salı 10 kez kurs');
      expect(r.title, 'kurs');
      expect(rule(r)!.until, DateTime(2027, 1, 5));
    });

    test('tekrar yoksa kez sayısı başlıkta kalır', () {
      final r = p('3 kez ara');
      expect(r.recurrence, isNull);
      expect(r.title, '3 kez ara');
    });

    test('yazılan bitiş tarihi önceliklidir', () {
      final r = p('her gün 14 mart tarihine kadar ilaç');
      expect(rule(r)!.until, DateTime(2027, 3, 14));
    });
  });

  group('eklenen ifadeler', () {
    Recurrence? rule(ParsedInput r) => r.recurrenceFrom(r.resolveDay(now, now));

    test('yalın saat aralığı', () {
      final r = p('14-16 ders');
      expectTime(r, 14);
      expect(r.durationMin, 120);
      expect(r.title, 'ders');
      expect(p('9-17 iş').durationMin, 8 * 60);
    });

    test('birimli sayı aralığı saat değildir', () {
      expect(p('10-12 sayfa oku').hour, isNull);
      expect(p('8-10 kişi yemek').hour, isNull);
    });

    test('günde kaç kez tekrar sayısı değildir', () {
      final r = p('her gün 5 defa su iç');
      expect(rule(r), const Recurrence(Frequency.daily));
      expect(r.title, '5 defa su iç');
    });

    test('pazar alışverişi gün değildir', () {
      final r = p('cumaları pazar alışverişi');
      expect(r.title, 'pazar alışverişi');
      expect(r.resolveDay(now, now), DateTime(2026, 11, 6));
      expect(p('pazar alışverişi').date, isNull);
    });

    test('ay adı sonuna kadar', () {
      final r = p('her gün mart sonuna kadar ilaç');
      expect(rule(r)!.until, DateTime(2027, 3, 31));
      expect(r.title, 'ilaç');
      expect(
        rule(p('her gün bu ayın sonuna kadar ilaç'))!.until,
        DateTime(2026, 11, 30),
      );
    });

    test('itibaren', () {
      final r = p('yarından itibaren her gün ilaç');
      expect(r.resolveDay(now, now), DateTime(2026, 11, 4));
      expect(r.title, 'ilaç');

      final week = p('pazartesiden itibaren 4 hafta boyunca her gün koşu');
      expect(week.resolveDay(now, now), DateTime(2026, 11, 9));
      expect(rule(week)!.until, DateTime(2026, 12, 6));
      expect(week.title, 'koşu');

      final friday = p('10 kasımdan başlayarak her cuma yüzme');
      expect(friday.resolveDay(now, now), DateTime(2026, 11, 13));
      expect(friday.title, 'yüzme');

      expect(
        p('gelecek aydan itibaren her pazartesi').resolveDay(now, now),
        DateTime(2026, 12, 7),
      );
    });
  });

  group('konuşma dilinde saatler', () {
    void expectRange(String text, String title, int h, int m, int? minutes) {
      final r = p(text);
      expect(r.title, title, reason: text);
      expect([r.hour, r.minute], [h, m], reason: text);
      expect(r.durationMin, minutes, reason: text);
    }

    test('ve, ila, la bağlaçları', () {
      expectRange('yarın 10 ve 11 arasında toplantı', 'toplantı', 10, 0, 60);
      expectRange('saat 10 ve 11 arasında toplantı', 'toplantı', 10, 0, 60);
      expectRange('10:30 ve 12:00 arasında sınav', 'sınav', 10, 30, 90);
      expectRange("10'la 11 arası ders", 'ders', 10, 0, 60);
      expectRange('10 ila 11 arasında ders', 'ders', 10, 0, 60);
      expectRange('saat 10 ile saat 11 arası ders', 'ders', 10, 0, 60);
      expectRange('saat 10 ile 11 saatleri arasında ders', 'ders', 10, 0, 60);
    });

    test('saat günün bölümünden önce', () {
      expectRange('saat gece 10 film', 'film', 22, 0, null);
      expectRange("saat gece 10'da film", 'film', 22, 0, null);
      expectRange('saat akşam 7 ile 9 arası yemek', 'yemek', 19, 0, 120);
    });

    test('aralıkta buçuk ve iki tarafta günün bölümü', () {
      expectRange('10 buçuk ile 11 arası ders', 'ders', 10, 30, 30);
      expectRange("saat 10 buçuktan 12'ye kadar ders", 'ders', 10, 30, 90);
      expectRange("sabah 9'dan öğlen 12'ye kadar kurs", 'kurs', 9, 0, 180);
    });

    test('çeyrek geçe, çeyrek var, dakika kala', () {
      expectRange("saat 10'u çeyrek geçe arama", 'arama', 10, 15, null);
      expectRange("11'e çeyrek var arama", 'arama', 10, 45, null);
      expectRange("akşam 7'ye 10 kala yemek", 'yemek', 18, 50, null);
      expectRange("3'ü 20 geçe toplantı", 'toplantı', 15, 20, null);
    });

    test('gece yarısı', () {
      expectRange('gece yarısı ilaç', 'ilaç', 0, 0, null);
    });

    test('yazıyla saat', () {
      expectRange('saat on bir toplantı', 'toplantı', 11, 0, null);
      expectRange('saat on birde toplantı', 'toplantı', 11, 0, null);
      expectRange('saat beşte çay', 'çay', 17, 0, null);
      expectRange('sabah dokuzda koşu', 'koşu', 9, 0, null);
      expectRange('akşam dokuz buçukta film', 'film', 21, 30, null);
      expect(p('akşam bir şey al').hour, isNull);
      expect(p('akşam bir şey al').title, 'akşam bir şey al');
    });

    test('ve ile gün aralığı', () {
      final r = p('5 ve 10 kasım arasında tatil');
      expect(r.date, DateTime(2026, 11, 5));
      expect(r.endDate, DateTime(2026, 11, 10));
      expect(r.title, 'tatil');
    });
  });

  group('çeyrek, geçe, kala, buçuk', () {
    void expectClock(String text, int h, int m, {String title = 'iş'}) {
      final r = p(text);
      expect([r.hour, r.minute], [h, m], reason: text);
      expect(r.title, title, reason: text);
      expect(r.durationMin, isNull, reason: text);
    }

    void expectNoTime(String text) {
      final r = p(text);
      expect(r.hour, isNull, reason: text);
      expect(r.title, text, reason: text);
    }

    test('çeyrek geçe: rakam ve yazı, ekli ve eksiz', () {
      expectClock("3'ü çeyrek geçe iş", 15, 15);
      expectClock('3ü çeyrek geçe iş', 15, 15);
      expectClock('3 çeyrek geçe iş', 15, 15);
      expectClock('saat 3 çeyrek geçe iş', 15, 15);
      expectClock('üçü çeyrek geçe iş', 15, 15);
      expectClock('ucu ceyrek gece iş', 15, 15);
      expectClock("10'u çeyrek geçe iş", 10, 15);
      expectClock('onu çeyrek geçe iş', 10, 15);
      expectClock('on biri çeyrek geçe iş', 11, 15);
      expectClock('on ikiyi çeyrek geçe iş', 12, 15);
      expectClock('biri çeyrek geçe iş', 13, 15);
      expectClock('saat üç çeyrek geçe iş', 15, 15);
    });

    test('çeyrek kala ve çeyrek var', () {
      expectClock("4'e çeyrek kala iş", 15, 45);
      expectClock('4e çeyrek kala iş', 15, 45);
      expectClock('dörde çeyrek kala iş', 15, 45);
      expectClock('saat 4 çeyrek kala iş', 15, 45);
      expectClock('beşe çeyrek var iş', 16, 45);
      expectClock('on ikiye çeyrek kala iş', 11, 45);
      expectClock('bire çeyrek kala iş', 12, 45);
      expectClock('gece on ikiye çeyrek kala iş', 23, 45);
      expectClock("gece 12'ye 5 kala iş", 23, 55);
    });

    test('dakikalı geçe ve kala', () {
      expectClock("5'i 10 geçe iş", 17, 10);
      expectClock('beşi on geçe iş', 17, 10);
      expectClock("6'ya 15 kala iş", 17, 45);
      expectClock('altıya yirmi kala iş', 17, 40);
      expectClock('on biri yirmi beş geçe iş', 11, 25);
      expectClock('sabah dokuzu çeyrek geçe iş', 9, 15);
      expectClock('akşam sekize on kala iş', 19, 50);
      expectClock('yediyi beş dakika geçe iş', 7, 5);
      expectClock("11'e 10 dakika kala iş", 10, 50);
    });

    test('kala saatten önce', () {
      expectClock('15 kala 6 iş', 17, 45);
      expectClock('yirmi kala altı iş', 17, 40);
      expectClock('çeyrek kala beş iş', 16, 45);
      expectClock('sabah çeyrek kala 9 iş', 8, 45);
    });

    test('buçuk ve yarım', () {
      expectClock('3 buçuk iş', 15, 30);
      expectClock('üç buçuk iş', 15, 30);
      expectClock('üç buçukta iş', 15, 30);
      expectClock('10 buçukta iş', 10, 30);
      expectClock('akşam dokuz buçuk iş', 21, 30);
      expectClock('sabah 8 buçuk iş', 8, 30);
      expectClock('saat yarımda iş', 12, 30);
      expectClock('öğlen yarımda iş', 12, 30);
      expectClock('gece yarımda iş', 0, 30);
    });

    test('saat olmayan ifadeler', () {
      expectNoTime('on iki gece tatil');
      expectNoTime('2 buçuk kilo elma');
      expectNoTime('bir buçuk litre süt');
      expectNoTime('işi yarımda bırakma');
      expectNoTime('ona iki var');
      expect(p('iki buçuk saat ders').hour, isNull);
      expect(p('yarım saat sonra ara').minute, 30);
    });

    test('tarihle birlikte ve aralıklar', () {
      const text = "yarın 3'ü çeyrek geçe dişçi";
      final r = p(text);
      expect(r.date, DateTime(2026, 11, 4));
      expectTime(r, 15, 15);
      expect(r.title, 'dişçi');
      expect(
        [for (final s in r.spans) text.substring(s.start, s.end)],
        ['yarın', "3'ü çeyrek geçe"],
      );
      expect(r.spans.map((s) => s.field), [ParseField.date, ParseField.time]);
    });

    test('kapatılan saat başlıkta kalır', () {
      final r = p("3'ü çeyrek geçe iş", disabled: {ParseField.time});
      expect(r.hour, isNull);
      expect(r.title, "3'ü çeyrek geçe iş");
    });
  });

  group('günden önce ve sonra', () {
    void expectDay(String text, DateTime day, {String title = 'iş'}) {
      final r = p(text);
      expect(r.date, day, reason: text);
      expect(r.title, title, reason: text);
    }

    test('gün adından önce ve sonra', () {
      // Bugün salı 3 kasım; gün adı yalın gün adı gibi çözülür.
      expectDay('pazartesiden önce iş', DateTime(2026, 11, 8));
      expectDay('pazartesiden sonra iş', DateTime(2026, 11, 10));
      expectDay('salıdan sonra iş', DateTime(2026, 11, 11));
      expectDay('salıdan önce iş', DateTime(2026, 11, 9));
      expectDay('çarşambadan önce iş', DateTime(2026, 11, 3));
      expectDay('çarşambadan sonra iş', DateTime(2026, 11, 5));
      expectDay('perşembeden sonra iş', DateTime(2026, 11, 6));
      expectDay('cumadan önce iş', DateTime(2026, 11, 5));
      expectDay('cumartesiden sonra iş', DateTime(2026, 11, 8));
      expectDay('pazardan önce iş', DateTime(2026, 11, 7));
    });

    test('yazım biçimleri', () {
      expectDay("Salı'dan sonra iş", DateTime(2026, 11, 11));
      expectDay('carsambadan once iş', DateTime(2026, 11, 3));
      expectDay('CUMADAN SONRA iş', DateTime(2026, 11, 7));
      expectDay('cuma gününden önce iş', DateTime(2026, 11, 5));
    });

    test('gün sayısıyla', () {
      expectDay('cumadan 2 gün önce iş', DateTime(2026, 11, 4));
      expectDay('cumadan iki gün sonra iş', DateTime(2026, 11, 8));
      expectDay('cumadan bir hafta sonra iş', DateTime(2026, 11, 13));
    });

    test('haftaya', () {
      expectDay('haftaya çarşambadan önce iş', DateTime(2026, 11, 10));
      expectDay('gelecek hafta cumadan sonra iş', DateTime(2026, 11, 14));
    });

    test('bugünden ve yarından sonra', () {
      expectDay('yarından sonra iş', DateTime(2026, 11, 5));
      expectDay('yarindan sonra iş', DateTime(2026, 11, 5));
      expectDay('bugünden sonra iş', DateTime(2026, 11, 4));
      expectDay('yarından 2 gün sonra iş', DateTime(2026, 11, 6));
    });

    test('yazıyla N gün sonra', () {
      expectDay('üç gün sonra iş', DateTime(2026, 11, 6));
      expectDay('on gün sonra iş', DateTime(2026, 11, 13));
      expectDay('3 gün sonra iş', DateTime(2026, 11, 6));
    });

    test('saatle birlikte', () {
      const text = 'salıdan sonra beşe çeyrek kala toplantı';
      final r = p(text);
      expect(r.date, DateTime(2026, 11, 11));
      expectTime(r, 16, 45);
      expect(r.title, 'toplantı');
      expect(
        [for (final s in r.spans) text.substring(s.start, s.end)],
        ['salıdan sonra', 'beşe çeyrek kala'],
      );
    });

    test('mevcut ifadeler bozulmaz', () {
      expect(p('salıdan cumaya kadar kurs').endDate, DateTime(2026, 11, 6));
      expect(
        p('pazartesiden itibaren her gün koşu').resolveDay(now, now),
        DateTime(2026, 11, 9),
      );
      final r = p('salıdan sonra ara', disabled: {ParseField.date});
      expect(r.date, isNull);
      expect(r.title, 'salıdan sonra ara');
    });
  });

  group('ayrık ekler ve çeyrekte', () {
    test('ek ayrı yazılınca da saat anlaşılır', () {
      final r = p('Saat 2 yi çeyrek geçe');
      expectTime(r, 14, 15);
      expect(r.title, '');
      expectTime(p('4 e çeyrek kala ara'), 15, 45);
      expectTime(p('5 i 10 geçe ara'), 17, 10);
    });

    test('çeyrekte / çeyrekde', () {
      for (final t in ['Saat 2 çeyrekde', 'saat 2 çeyrekte', "2'yi çeyrekte"]) {
        final r = p(t);
        expectTime(r, 14, 15);
        expect(r.title, '', reason: t);
      }
      expectTime(p('akşam yediyi çeyrekte yemek'), 19, 15);
      expectTime(p('2 çeyrekte bitir'), 14, 15);
    });
  });

  group('yazım hataları', () {
    test('bir harf eksik/fazla/yanlış gün ve ay adları', () {
      expect(p('saı toplantı').date, DateTime(2026, 11, 10));
      expect(p('saı toplantı').title, 'toplantı');
      expect(p('çarşmba rapor').date, DateTime(2026, 11, 4));
      expect(p('perşebe spor').date, DateTime(2026, 11, 5));
      expect(p('cumrtesi kahvaltı').date, DateTime(2026, 11, 7));
      expect(p('yarn dişçi').date, DateTime(2026, 11, 4));
      expect(p('yrain dişçi').date, DateTime(2026, 11, 4));
      expect(p('15 aralk doğum günü').date, DateTime(2026, 12, 15));
    });

    test('ekli yanlış yazım ve aralık konumu', () {
      final r = p('saıdan sonra ara');
      expect(r.date, DateTime(2026, 11, 11));
      expect(r.title, 'ara');
      final s = r.spans.single;
      expect('saıdan sonra ara'.substring(s.start, s.end), 'saıdan sonra');
    });

    test('gerçek sözcükler düzeltilmez', () {
      expect(p('Ali ile kahve').date, isNull);
      expect(p('Ali ile kahve').title, 'Ali ile kahve');
      expect(p('salt okunur dosya').title, 'salt okunur dosya');
      expect(p('ekip toplantısı').title, 'ekip toplantısı');
      expect(p('kim arayacak').title, 'kim arayacak');
      expect(p('insan kaynakları').title, 'insan kaynakları');
      expect(p('yarım saat yürüyüş').date, isNull);
    });
  });
}
