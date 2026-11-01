import 'package:flutter/material.dart';

/// Stitch “Nocturne Agenda” tasarım sisteminin renkleri. Açık tema aynı
/// tonlardan, kâğıt hissi verecek şekilde türetilmiştir.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface,
    required this.low,
    required this.container,
    required this.high,
    required this.hairline,
    required this.muted,
    required this.text,
    required this.textSoft,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.danger,
  });

  static const dark = AppColors(
    surface: Color(0xFF121316),
    low: Color(0xFF1B1B1F),
    container: Color(0xFF1F1F23),
    high: Color(0xFF292A2D),
    hairline: Color(0xFF2F323A),
    muted: Color(0xFF8D919A),
    text: Color(0xFFE3E2E6),
    textSoft: Color(0xFFC3C6D1),
    accent: Color(0xFF4A6FA5),
    accentText: Color(0xFFA7C8FF),
    onAccent: Color(0xFFEDF1FF),
    danger: Color(0xFFFFB4AB),
  );

  static const light = AppColors(
    surface: Color(0xFFF6F5F1),
    low: Color(0xFFFFFFFF),
    container: Color(0xFFEDECE7),
    high: Color(0xFFE3E2DC),
    hairline: Color(0xFFDAD9D2),
    muted: Color(0xFF6E727B),
    text: Color(0xFF1B1C1F),
    textSoft: Color(0xFF43474F),
    accent: Color(0xFF4A6FA5),
    accentText: Color(0xFF395F94),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB3261E),
  );

  final Color surface;
  final Color low;
  final Color container;
  final Color high;
  final Color hairline;
  final Color muted;
  final Color text;
  final Color textSoft;
  final Color accent;
  final Color accentText;
  final Color onAccent;
  final Color danger;

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
const _mono = 'JetBrainsMono';

TextTheme _textTheme(AppColors c) {
  TextStyle serif(double size, double height, FontWeight weight) => TextStyle(
    fontFamily: _serif,
    fontSize: size,
    height: height / size,
    fontWeight: weight,
    color: c.text,
  );
  TextStyle mono(double size, double height, double tracking, FontWeight w) =>
      TextStyle(
        fontFamily: _mono,
        fontSize: size,
        height: height / size,
        letterSpacing: size * tracking,
        fontWeight: w,
        color: c.textSoft,
      );
  TextStyle sans(double size, double height) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    height: height / size,
    color: c.text,
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
    labelLarge: mono(13, 18, 0.02, FontWeight.w500),
    labelMedium: mono(11, 16, 0.04, FontWeight.w500),
    labelSmall: mono(10, 14, 0.05, FontWeight.w400),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
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
    fontFamily: 'Inter',
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
