import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/app.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_data/kina_data.dart';

void main() {
  final database = KinaDatabase(driftDatabase(name: 'kina_calculator'));
  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const KinaApp(),
    ),
  );
}
