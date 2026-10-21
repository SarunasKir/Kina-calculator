import 'package:flutter/material.dart';
import 'package:kina_app/src/calculator/calculator_screen.dart';
import 'package:kina_app/src/theme.dart';

/// The app root.
class KinaApp extends StatelessWidget {
  /// Creates the app.
  const KinaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kina Calculator',
    debugShowCheckedModeBanner: false,
    theme: lightTheme,
    darkTheme: darkTheme,
    home: Scaffold(
      appBar: AppBar(title: const Text('Kina Calculator')),
      body: const SafeArea(child: CalculatorScreen()),
    ),
  );
}
