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

/// Yeni renk temaları buraya eklenir; ayarlar ve widget'lar listeyi okur.
const palettes = [nocturne];

ColorPalette paletteById(String id) =>
    palettes.firstWhere((p) => p.id == id, orElse: () => nocturne);

/// İki widget'ın anlık görüntüsüne yazılan görünüm: tema kipi, seçili temanın
/// renkleri ve widget ayarları.
Map<String, dynamic> widgetAppearance(AppSettings settings) {
  final palette = paletteById(settings.palette);
  return {
    'theme': settings.theme,
    'palette': palette.id,
    'colors': {
      'dark': palette.dark.toWidgetJson(),
      'light': palette.light.toWidgetJson(),
    },
    'widgetStyle': {
      'opacity': settings.widgetOpacity,
      'radius': settings.widgetRadius,
    },
  };
}
