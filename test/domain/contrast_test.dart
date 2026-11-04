import 'package:ajandam/domain/palettes.dart';
import 'package:ajandam/domain/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('yüksek kontrast', () {
    test('beyaz/siyah oranı 21:1', () {
      expect(contrastRatio(0xFFFFFFFF, 0xFF000000), closeTo(21, 0.01));
    });

    for (final palette in palettes) {
      for (final dark in [true, false]) {
        final mode = dark ? 'koyu' : 'açık';
        test('${palette.name} $mode WCAG eşiklerini sağlar', () {
          final c = palette.colors(dark: dark, highContrast: true);
          for (final ground in [c.surface, c.low, c.container]) {
            expect(contrastRatio(c.text, ground), greaterThanOrEqualTo(7));
            expect(contrastRatio(c.textSoft, ground), greaterThanOrEqualTo(7));
            expect(contrastRatio(c.muted, ground), greaterThanOrEqualTo(4.5));
            expect(
              contrastRatio(c.accentText, ground),
              greaterThanOrEqualTo(4.5),
            );
          }
          // Kenarlık zeminden seçilir.
          expect(contrastRatio(c.hairline, c.surface), greaterThanOrEqualTo(3));
          // Her ayar normal kipten en az onun kadar belirgin.
          final n = dark ? palette.dark : palette.light;
          expect(
            contrastRatio(c.muted, c.surface),
            greaterThan(contrastRatio(n.muted, n.surface)),
          );
          expect(
            contrastRatio(c.hairline, c.surface),
            greaterThan(contrastRatio(n.hairline, n.surface)),
          );
        });

        test('${palette.name} $mode normal kipte metin ≥ 7, değişmez', () {
          final n = palette.colors(dark: dark);
          expect(identical(n, dark ? palette.dark : palette.light), isTrue);
          expect(contrastRatio(n.text, n.surface), greaterThanOrEqualTo(7));
        });
      }
    }

    test('widget görünümü kontrastlı renkleri ve bayrağı taşır', () {
      final normal = widgetAppearance(const AppSettings());
      final high = widgetAppearance(const AppSettings(highContrast: true));
      expect((normal['widgetStyle'] as Map)['highContrast'], isFalse);
      expect((high['widgetStyle'] as Map)['highContrast'], isTrue);
      expect((normal['colors'] as Map)['dark'], nocturne.dark.toWidgetJson());
      expect(
        (high['colors'] as Map)['dark'],
        nocturne.dark.withHighContrast(dark: true).toWidgetJson(),
      );
      expect(
        (high['colors'] as Map)['light'],
        isNot(nocturne.light.toWidgetJson()),
      );
    });

    test('ölçülen en düşük oranlar', () {
      double minOf(int Function(PaletteColors) pick, {bool high = true}) {
        var m = 99.0;
        for (final p in palettes) {
          for (final dark in [true, false]) {
            final c = p.colors(dark: dark, highContrast: high);
            for (final g in [c.surface, c.low, c.container]) {
              final r = contrastRatio(pick(c), g);
              if (r < m) m = r;
            }
          }
        }
        return m;
      }

      // ignore: avoid_print
      print(
        'HC min — text ${minOf((c) => c.text).toStringAsFixed(2)}, '
        'soft ${minOf((c) => c.textSoft).toStringAsFixed(2)}, '
        'muted ${minOf((c) => c.muted).toStringAsFixed(2)}, '
        'accentText ${minOf((c) => c.accentText).toStringAsFixed(2)}, '
        'hairline/surface ${minOf((c) => c.hairline).toStringAsFixed(2)} | '
        'normal muted ${minOf((c) => c.muted, high: false).toStringAsFixed(2)}, '
        'normal soft ${minOf((c) => c.textSoft, high: false).toStringAsFixed(2)}',
      );
    });
  });
}
