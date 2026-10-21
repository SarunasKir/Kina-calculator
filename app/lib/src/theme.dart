import 'package:flutter/material.dart';

// The look is kept in this one file so it can be swapped (for example to the
// dark Aion style of v55) without touching any screen.
const _seed = Color(0xFF7B4FD6);

/// The light theme.
final ThemeData lightTheme = _theme(Brightness.light);

/// The dark theme.
final ThemeData darkTheme = _theme(Brightness.dark);

ThemeData _theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
