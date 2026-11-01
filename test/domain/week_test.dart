import 'package:ajandam/domain/week.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('weekDays', () {
    test('pazartesiden başlayan haftayı döndürür', () {
      final days = weekDays(DateTime(2026, 11, 3));

      expect(days.first, DateTime(2026, 11, 2));
      expect(days.last, DateTime(2026, 11, 8));
      expect(days, hasLength(7));
    });

    test('odak günü pazar ise aynı haftada kalır', () {
      final days = weekDays(DateTime(2026, 11, 1));

      expect(days.first, DateTime(2026, 10, 26));
      expect(days.last, DateTime(2026, 11, 1));
    });

    test('hafta başlangıcı pazar olabilir', () {
      final days = weekDays(
        DateTime(2026, 11, 3),
        firstWeekday: DateTime.sunday,
      );

      expect(days.first, DateTime(2026, 11, 1));
      expect(days.last, DateTime(2026, 11, 7));
    });

    test('monthGrid ayı tam haftalara tamamlar', () {
      final days = monthGrid(DateTime(2026, 11));

      expect(days.first, DateTime(2026, 10, 26));
      expect(days.last, DateTime(2026, 12, 6));
      expect(days, hasLength(42));
    });

    test('monthGrid gereksiz satır eklemez', () {
      expect(monthGrid(DateTime(2027, 2)), hasLength(28));
      expect(monthGrid(DateTime(2026, 10)), hasLength(35));
    });

    test('ISO hafta numarası', () {
      expect(isoWeekNumber(DateTime(2024, 10, 16)), 42);
      expect(isoWeekNumber(DateTime(2026, 1, 1)), 1);
      expect(isoWeekNumber(DateTime(2027, 1, 1)), 53);
    });

    test('yaz saati geçişinde günler tekrar etmez', () {
      final days = weekDays(DateTime(2026, 3, 30));

      expect({for (final d in days) d.day}, hasLength(7));
    });
  });
}
