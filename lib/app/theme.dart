import 'package:flutter/material.dart';

const _accent = Color(0xFF4F7BF7);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _accent,
    brightness: brightness,
  ).copyWith(primary: _accent, onPrimary: Colors.white);

  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: scheme.surface,
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 0.5,
      space: 1,
    ),
  );
}
