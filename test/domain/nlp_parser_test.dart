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
}
