import 'package:ajandam/domain/nlp_parser.dart';
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
}
