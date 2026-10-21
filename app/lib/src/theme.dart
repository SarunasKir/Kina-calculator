import 'package:flutter/material.dart';

// The look is kept in this one file so it can be swapped without touching any
// screen. The palette is taken from the dark Aion style of v55: a near-black
// plum background with warm gold accents.
const _background = Color(0xFF120D12);
const _panel = Color(0xFF241A24);
const _text = Color(0xFFF5E4E9);
const _mutedText = Color(0xFFCFB4A3);
const _gold = Color(0xFFDDA86A);
const _rose = Color(0xFF9A635B);
const _line = Color(0xFF3D2B3A);
const _red = Color(0xFFE84F4F);

const _scheme = ColorScheme(
  brightness: Brightness.dark,
  primary: _gold,
  onPrimary: Color(0xFF2B1A12),
  primaryContainer: Color(0xFF4A3322),
  onPrimaryContainer: Color(0xFFFFDBA4),
  secondary: _rose,
  onSecondary: _text,
  secondaryContainer: Color(0xFF3A2630),
  onSecondaryContainer: _text,
  tertiary: Color(0xFFF5C577),
  onTertiary: Color(0xFF2B1A12),
  error: _red,
  onError: Color(0xFF2B0A0A),
  errorContainer: Color(0xFF5A2024),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: _background,
  onSurface: _text,
  onSurfaceVariant: _mutedText,
  surfaceContainerLowest: Color(0xFF0D090E),
  surfaceContainerLow: Color(0xFF1A121A),
  surfaceContainer: _panel,
  surfaceContainerHigh: Color(0xFF2E222D),
  surfaceContainerHighest: Color(0xFF382B37),
  outline: _rose,
  outlineVariant: _line,
);

/// The app theme: dark Aion style.
final ThemeData aionTheme = ThemeData(
  colorScheme: _scheme,
  scaffoldBackgroundColor: _background,
  visualDensity: VisualDensity.standard,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    isDense: true,
  ),
  cardTheme: CardThemeData(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: _scheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: _line),
    ),
  ),
);
