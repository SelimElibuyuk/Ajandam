import 'package:flutter/material.dart';

import '../domain/palettes.dart';

/// Kartlar ve üst bant temanın vurgu rengine hafifçe bürünür.
/// Yüksek kontrastta süs tonları yarıya iner, yazının zemini sade kalır.
const _cardTint = 0.04;
const _headerTint = 0.07;
const _contrastTintScale = 0.0;

Color _tinted(Color base, Color accent, double amount) =>
    Color.alphaBlend(accent.withValues(alpha: amount), base);

/// Çiplerin renk aileleri; temadan bağımsız, açık ve koyu kipte okunur.
/// null, temanın kendi vurgu rengidir.
enum ChipHue {
  accent(null),
  time(0xFF4FA3A8),
  repeat(0xFFB477C4),
  duration(0xFFD39A4E),
  reminder(0xFFD3706B);

  const ChipHue(this.value);

  final int? value;
}

/// Renkli bir öğenin hafif zemini ve üstündeki yazı rengi.
typedef Tone = ({Color background, Color foreground});

/// Seçili renk temasının uygulamadaki renkleri, bkz. palettes.dart.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.dark,
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
    required this.header,
    this.highContrast = false,
  });

  /// [p] yüksek kontrastta zaten dönüştürülmüş renklerdir, bkz.
  /// [ColorPalette.colors].
  AppColors.from(
    PaletteColors p, {
    required this.dark,
    this.highContrast = false,
  }) : surface = Color(p.surface),
       low = _tinted(
         Color(p.low),
         Color(p.accent),
         _cardTint * (highContrast ? _contrastTintScale : 1),
       ),
       container = _tinted(
         Color(p.container),
         Color(p.accent),
         _cardTint * (highContrast ? _contrastTintScale : 1),
       ),
       high = Color(p.high),
       hairline = Color(p.hairline),
       muted = Color(p.muted),
       text = Color(p.text),
       textSoft = Color(p.textSoft),
       accent = Color(p.accent),
       accentSoft = Color(p.accentSoft),
       accentText = Color(p.accentText),
       onAccent = Color(p.onAccent),
       danger = Color(p.danger),
       header = _tinted(
         Color(p.surface),
         Color(p.accent),
         _headerTint * (highContrast ? _contrastTintScale : 1),
       );

  final bool dark;
  final bool highContrast;
  final Color surface;
  final Color low;
  final Color container;
  final Color high;
  final Color hairline;
  final Color muted;
  final Color text;
  final Color textSoft;
  final Color accent;
  final Color accentSoft;
  final Color accentText;
  final Color onAccent;
  final Color danger;

  /// Üst bant ve alt menü zemini.
  final Color header;

  /// Hafif renkli zemin ve okunur yazı: etkinlik kartları, çipler.
  Tone tone([ChipHue hue = ChipHue.accent]) {
    final base = hue.value == null ? accent : Color(hue.value!);
    return (
      background: Color.alphaBlend(
        base.withValues(alpha: (dark ? 0.2 : 0.14) + (highContrast ? 0.12 : 0)),
        surface,
      ),
      foreground: hue.value == null
          ? accentText
          : Color.lerp(
              base,
              dark ? Colors.white : Colors.black,
              highContrast ? 0.75 : 0.4,
            )!,
    );
  }

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      t < 0.5 || other is! AppColors ? this : other;
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get type => Theme.of(this).textTheme;
}

const _serif = 'Newsreader';
const _sans = 'PlusJakartaSans';

/// Saatlerde rakamlar aynı genişlikte durur, sütunlar kaymaz.
const _tabular = [FontFeature.tabularFigures()];

TextTheme _textTheme(AppColors c) {
  // Yüksek kontrastta yazılar bir kademe kalınlaşır.
  FontWeight w(FontWeight base) => c.highContrast
      ? FontWeight.values[(FontWeight.values.indexOf(base) + 1).clamp(
          0,
          FontWeight.values.length - 1,
        )]
      : base;
  TextStyle serif(double size, double height, FontWeight weight) => TextStyle(
    fontFamily: _serif,
    fontSize: size,
    height: height / size,
    fontWeight: w(weight),
    color: c.text,
  );
  TextStyle sans(double size, double height) => TextStyle(
    fontFamily: _sans,
    fontSize: size,
    height: height / size,
    fontWeight: w(FontWeight.w400),
    color: c.text,
  );
  // Etiketler, saatler ve çipler: aynı yazı tipi, hafif aralıklı.
  TextStyle label(
    double size,
    double height,
    double tracking,
    FontWeight weight,
  ) => TextStyle(
    fontFamily: _sans,
    fontSize: size,
    height: height / size,
    letterSpacing: size * tracking,
    fontWeight: w(weight),
    fontFeatures: _tabular,
    color: c.textSoft,
  );

  return TextTheme(
    headlineLarge: serif(28, 36, FontWeight.w400),
    headlineMedium: serif(22, 30, FontWeight.w500),
    headlineSmall: serif(18, 26, FontWeight.w500),
    titleLarge: serif(22, 30, FontWeight.w500),
    titleMedium: sans(16, 24),
    titleSmall: sans(14, 20),
    bodyLarge: sans(16, 24),
    bodyMedium: sans(14, 20),
    bodySmall: sans(12, 18),
    labelLarge: label(13, 18, 0.01, FontWeight.w600),
    labelMedium: label(12, 16, 0.02, FontWeight.w600),
    labelSmall: label(11, 14, 0.03, FontWeight.w500),
  );
}

ThemeData buildTheme(
  Brightness brightness, {
  ColorPalette palette = nocturne,
  bool highContrast = false,
}) {
  final dark = brightness == Brightness.dark;
  final c = AppColors.from(
    palette.colors(dark: dark, highContrast: highContrast),
    dark: dark,
    highContrast: highContrast,
  );
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: c.surface,
    surface: c.surface,
    onSurface: c.text,
    onSurfaceVariant: c.textSoft,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.low,
    surfaceContainer: c.container,
    surfaceContainerHigh: c.low,
    surfaceContainerHighest: c.high,
    primaryContainer: c.accent,
    onPrimaryContainer: c.onAccent,
    outline: c.muted,
    outlineVariant: c.hairline,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));

  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: _sans,
    textTheme: _textTheme(c),
    scaffoldBackgroundColor: c.surface,
    extensions: [c],
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _textTheme(c).headlineSmall,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.low,
      elevation: 0,
      shape: shape.copyWith(side: BorderSide(color: c.hairline)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: c.low,
      elevation: 0,
      headerBackgroundColor: c.container,
      headerForegroundColor: c.text,
      shape: shape,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: c.low,
      elevation: 0,
      shape: shape,
    ),
    popupMenuTheme: PopupMenuThemeData(color: c.low, elevation: 0),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.high,
      contentTextStyle: TextStyle(color: c.text),
      actionTextColor: c.accentText,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: shape,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.container,
      side: BorderSide(color: c.hairline),
      shape: shape,
      labelStyle: _textTheme(c).labelMedium,
      deleteIconColor: c.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        shape: shape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.accentText),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? c.onAccent : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? c.accent : c.high,
      ),
    ),
    dividerTheme: DividerThemeData(color: c.hairline, thickness: 1, space: 1),
  );
}
