import 'dart:math' as math;

import 'settings.dart';

/// Bir temanın tek parlaklıktaki renkleri, 0xAARRGGBB.
class PaletteColors {
  const PaletteColors({
    required this.surface,
    required this.low,
    required this.container,
    required this.high,
    required this.hairline,
    required this.muted,
    required this.text,
    required this.textSoft,
    required this.accent,
    required this.accentSoft,
    required this.accentText,
    required this.onAccent,
    required this.danger,
  });

  final int surface;
  final int low;
  final int container;
  final int high;
  final int hairline;
  final int muted;
  final int text;
  final int textSoft;
  final int accent;
  final int accentSoft;
  final int accentText;
  final int onAccent;
  final int danger;

  /// Widget'ların kullandığı renkler; widget yeni temalarda kod değişmeden uyar.
  Map<String, String> toWidgetJson() => {
    'surface': _hex(surface),
    'container': _hex(container),
    'text': _hex(text),
    'soft': _hex(textSoft),
    'muted': _hex(muted),
    'accent': _hex(accent),
    'accentSoft': _hex(accentSoft),
    'accentText': _hex(accentText),
    'onAccent': _hex(onAccent),
    'danger': _hex(danger),
  };

  static String _hex(int color) =>
      '#${color.toRadixString(16).padLeft(8, '0').toUpperCase()}';

  /// Yüksek kontrast sürümü: zemin saf siyah/beyaz, yazılar saf beyaz/siyah,
  /// ikincil yazılar ana yazıya çok yakın, kartlar ve kenarlıklar net ayrışır.
  /// Vurgu rengi kimliği korur ama zemin üstünde okunur hale gelir.
  PaletteColors withHighContrast({required bool dark}) {
    final pure = dark ? 0xFFFFFFFF : 0xFF000000;
    final paper = dark ? 0xFF000000 : 0xFFFFFFFF;
    final bg = paper;
    // Kartlar zeminden açıkça ayrışan nötr katmanlar.
    final lowHc = mixColors(paper, pure, dark ? 0.10 : 0.05);
    final containerHc = mixColors(paper, pure, dark ? 0.16 : 0.09);
    final highHc = mixColors(paper, pure, dark ? 0.24 : 0.14);
    final grounds = [bg, lowHc, containerHc];

    final textHc = pure;
    final accentHc = ensureContrast(accent, [bg], 4.5, toward: pure);
    return PaletteColors(
      surface: bg,
      low: lowHc,
      container: containerHc,
      high: highHc,
      // Kenarlıklar her katmanda yazı gibi seçilir.
      hairline: ensureContrast(
        mixColors(bg, textHc, 0.55),
        grounds,
        4.5,
        toward: textHc,
      ),
      muted: ensureContrast(
        mixColors(textHc, muted, 0.35),
        grounds,
        10,
        toward: pure,
      ),
      text: textHc,
      textSoft: ensureContrast(
        mixColors(textHc, textSoft, 0.15),
        grounds,
        15,
        toward: pure,
      ),
      accent: accentHc,
      accentSoft: mixColors(bg, accentHc, dark ? 0.35 : 0.22),
      accentText: ensureContrast(accentText, grounds, 9, toward: pure),
      onAccent: contrastRatio(paper, accentHc) >= contrastRatio(pure, accentHc)
          ? paper
          : pure,
      danger: ensureContrast(danger, grounds, 7, toward: pure),
    );
  }
}

/// İki rengi sRGB kanallarında karıştırır; t=0 [a], t=1 [b].
int mixColors(int a, int b, double t) {
  int ch(int shift) {
    final x = (a >> shift) & 0xFF;
    final y = (b >> shift) & 0xFF;
    return (x + (y - x) * t).round().clamp(0, 255);
  }

  return (ch(24) << 24) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

/// WCAG göreli parlaklığı (alfa yok sayılır).
double relativeLuminance(int color) {
  double lin(int shift) {
    final c = ((color >> shift) & 0xFF) / 255;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * lin(16) + 0.7152 * lin(8) + 0.0722 * lin(0);
}

/// WCAG kontrast oranı, 1–21.
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// [color], tüm [grounds] üzerinde en az [target] kontrasta ulaşana dek
/// [toward] rengine adım adım yaklaştırılır.
int ensureContrast(
  int color,
  List<int> grounds,
  double target, {
  required int toward,
}) {
  bool ok(int c) => grounds.every((g) => contrastRatio(c, g) >= target);
  for (var i = 0; i <= 40; i++) {
    final c = mixColors(color, toward, i / 40);
    if (ok(c)) return c;
  }
  return toward;
}

/// Seçilebilir renk teması; açık ve koyu sürümüyle.
class ColorPalette {
  const ColorPalette({
    required this.id,
    required this.name,
    required this.dark,
    required this.light,
  });

  final String id;
  final String name;
  final PaletteColors dark;
  final PaletteColors light;

  /// Kontrast ayarına göre kullanılacak renkler.
  PaletteColors colors({required bool dark, bool highContrast = false}) {
    final base = dark ? this.dark : light;
    return highContrast ? base.withHighContrast(dark: dark) : base;
  }
}

/// Stitch “Nocturne Agenda”. Açık sürüm aynı tonlardan, kâğıt hissiyle
/// türetilmiştir.
const nocturne = ColorPalette(
  id: 'nocturne',
  name: 'Nocturne',
  dark: PaletteColors(
    surface: 0xFF121316,
    low: 0xFF1B1B1F,
    container: 0xFF1F1F23,
    high: 0xFF292A2D,
    hairline: 0xFF2F323A,
    muted: 0xFF8D919A,
    text: 0xFFE3E2E6,
    textSoft: 0xFFC3C6D1,
    accent: 0xFF4A6FA5,
    accentSoft: 0xFF243247,
    accentText: 0xFFA7C8FF,
    onAccent: 0xFFEDF1FF,
    danger: 0xFFFFB4AB,
  ),
  light: PaletteColors(
    surface: 0xFFF6F5F1,
    low: 0xFFFFFFFF,
    container: 0xFFEDECE7,
    high: 0xFFE3E2DC,
    hairline: 0xFFDAD9D2,
    muted: 0xFF6E727B,
    text: 0xFF1B1C1F,
    textSoft: 0xFF43474F,
    accent: 0xFF4A6FA5,
    accentSoft: 0xFFDCE4F2,
    accentText: 0xFF395F94,
    onAccent: 0xFFFFFFFF,
    danger: 0xFFB3261E,
  ),
);

/// Doğal, sakin yeşil.
const orman = ColorPalette(
  id: 'orman',
  name: 'Orman',
  dark: PaletteColors(
    surface: 0xFF111613,
    low: 0xFF171E1B,
    container: 0xFF1B2420,
    high: 0xFF27302C,
    hairline: 0xFF2C3531,
    muted: 0xFF8A968F,
    text: 0xFFE1E6E2,
    textSoft: 0xFFC7CEC9,
    accent: 0xFF4E8A6B,
    accentSoft: 0xFF203329,
    accentText: 0xFF9FD4B5,
    onAccent: 0xFFF3FAF6,
    danger: 0xFFFFB4AB,
  ),
  light: PaletteColors(
    surface: 0xFFF3F5F0,
    low: 0xFFFBFCFA,
    container: 0xFFE6EBE3,
    high: 0xFFDEE3DB,
    hairline: 0xFFD3D9D2,
    muted: 0xFF6A766F,
    text: 0xFF18201B,
    textSoft: 0xFF353E38,
    accent: 0xFF3F7A5C,
    accentSoft: 0xFFDCE7E2,
    accentText: 0xFF2F6649,
    onAccent: 0xFFFFFFFF,
    danger: 0xFFB3261E,
  ),
);

/// Sıcak, kâğıt ve mum ışığı.
const kehribar = ColorPalette(
  id: 'kehribar',
  name: 'Kehribar',
  dark: PaletteColors(
    surface: 0xFF16130F,
    low: 0xFF1E1A14,
    container: 0xFF241F18,
    high: 0xFF302B24,
    hairline: 0xFF363028,
    muted: 0xFF9A8F80,
    text: 0xFFECE4D8,
    textSoft: 0xFFD3CABE,
    accent: 0xFFC08A3E,
    accentSoft: 0xFF40311B,
    accentText: 0xFFF0C48A,
    onAccent: 0xFFFDF8F1,
    danger: 0xFFFFB4AB,
  ),
  light: PaletteColors(
    surface: 0xFFFAF6EE,
    low: 0xFFFEFCFA,
    container: 0xFFF0E8DA,
    high: 0xFFE8E0D2,
    hairline: 0xFFDFD6C8,
    muted: 0xFF7D7263,
    text: 0xFF221C14,
    textSoft: 0xFF423A30,
    accent: 0xFFA8732B,
    accentSoft: 0xFFEFE6D9,
    accentText: 0xFF8A5C1E,
    onAccent: 0xFFFFFFFF,
    danger: 0xFFB3261E,
  ),
);

/// Ajanda defteri kırmızısı.
const bordo = ColorPalette(
  id: 'bordo',
  name: 'Bordo',
  dark: PaletteColors(
    surface: 0xFF161113,
    low: 0xFF1F161A,
    container: 0xFF251A1E,
    high: 0xFF31262A,
    hairline: 0xFF372B2F,
    muted: 0xFF9C8A90,
    text: 0xFFEDE1E4,
    textSoft: 0xFFD5C7CB,
    accent: 0xFF9E4A5E,
    accentSoft: 0xFF381F26,
    accentText: 0xFFF0AEBE,
    onAccent: 0xFFFDF5F7,
    danger: 0xFFFFB4AB,
  ),
  light: PaletteColors(
    surface: 0xFFFAF4F5,
    low: 0xFFFEFCFC,
    container: 0xFFF1E5E8,
    high: 0xFFE9DDE0,
    hairline: 0xFFE0D3D6,
    muted: 0xFF7D6A70,
    text: 0xFF241519,
    textSoft: 0xFF433337,
    accent: 0xFF8E3B4F,
    accentSoft: 0xFFEBDCDF,
    accentText: 0xFF7A2E41,
    onAccent: 0xFFFFFFFF,
    danger: 0xFFB3261E,
  ),
);

/// Yumuşak, odaklı mor.
const lavanta = ColorPalette(
  id: 'lavanta',
  name: 'Lavanta',
  dark: PaletteColors(
    surface: 0xFF131218,
    low: 0xFF1B1923,
    container: 0xFF201E2A,
    high: 0xFF2C2A36,
    hairline: 0xFF312F3C,
    muted: 0xFF918DA0,
    text: 0xFFE6E3EF,
    textSoft: 0xFFCCC9D7,
    accent: 0xFF7A6BB8,
    accentSoft: 0xFF2D2840,
    accentText: 0xFFC6BCF5,
    onAccent: 0xFFF8F7FE,
    danger: 0xFFFFB4AB,
  ),
  light: PaletteColors(
    surface: 0xFFF6F5FA,
    low: 0xFFFCFCFE,
    container: 0xFFECE9F4,
    high: 0xFFE4E1EC,
    hairline: 0xFFDAD6E3,
    muted: 0xFF716C82,
    text: 0xFF1C1A26,
    textSoft: 0xFF3A3746,
    accent: 0xFF6656A8,
    accentSoft: 0xFFE3E1EF,
    accentText: 0xFF54459A,
    onAccent: 0xFFFFFFFF,
    danger: 0xFFB3261E,
  ),
);

/// Serin camgöbeği.
const deniz = ColorPalette(
  id: 'deniz',
  name: 'Deniz',
  dark: PaletteColors(
    surface: 0xFF0F1516,
    low: 0xFF141D1F,
    container: 0xFF182325,
    high: 0xFF242F31,
    hairline: 0xFF283436,
    muted: 0xFF869597,
    text: 0xFFDFE8E8,
    textSoft: 0xFFC4CFD0,
    accent: 0xFF3E8A8F,
    accentSoft: 0xFF1B3234,
    accentText: 0xFF93D3D6,
    onAccent: 0xFFF2FAFA,
    danger: 0xFFFFB4AB,
  ),
  light: PaletteColors(
    surface: 0xFFF2F6F6,
    low: 0xFFFBFCFC,
    container: 0xFFE3ECEC,
    high: 0xFFDBE4E4,
    hairline: 0xFFD0DBDB,
    muted: 0xFF66787A,
    text: 0xFF142022,
    textSoft: 0xFF313F41,
    accent: 0xFF2F7A7F,
    accentSoft: 0xFFDAE7E8,
    accentText: 0xFF23656A,
    onAccent: 0xFFFFFFFF,
    danger: 0xFFB3261E,
  ),
);

/// Yeni renk temaları buraya eklenir; ayarlar ve widget'lar listeyi okur.
const palettes = [nocturne, orman, kehribar, bordo, lavanta, deniz];

ColorPalette paletteById(String id) =>
    palettes.firstWhere((p) => p.id == id, orElse: () => nocturne);

/// İki widget'ın anlık görüntüsüne yazılan görünüm: tema kipi, seçili temanın
/// (kontrast uygulanmış) renkleri ve widget ayarları.
Map<String, dynamic> widgetAppearance(AppSettings settings) {
  final palette = paletteById(settings.palette);
  return {
    'theme': settings.theme,
    'palette': palette.id,
    'colors': {
      'dark': palette
          .colors(dark: true, highContrast: settings.highContrast)
          .toWidgetJson(),
      'light': palette
          .colors(dark: false, highContrast: settings.highContrast)
          .toWidgetJson(),
    },
    'widgetStyle': {
      'opacity': settings.widgetOpacity,
      'radius': settings.widgetRadius,
      'highContrast': settings.highContrast,
    },
  };
}
