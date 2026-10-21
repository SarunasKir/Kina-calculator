import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/app.dart';
import 'package:kina_app/src/providers.dart';
import 'package:kina_app/src/rates/rate_sync.dart';
import 'package:kina_data/kina_data.dart';

/// A fresh in-memory database.
KinaDatabase memoryDatabase() => KinaDatabase(NativeDatabase.memory());

/// Pumps the whole app on [db] at [size] logical pixels and waits for the
/// settings to load.
Future<void> pumpApp(
  WidgetTester tester,
  KinaDatabase db, {
  Size size = const Size(1440, 1180),
  FrankfurterClient? rateClient,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (rateClient != null)
          rateClientProvider.overrideWithValue(rateClient),
      ],
      child: const KinaApp(),
    ),
  );
  await settle(tester);
}

/// Lets database work finish, then settles the frame.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

/// Loads Roboto and the Material icons so goldens show real text.
Future<void> loadAppFonts() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(
        Platform.resolvedExecutable,
      ).parent.parent.parent.parent.parent.parent.path;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  ByteData bytes(String name) =>
      ByteData.sublistView(File('$dir/$name').readAsBytesSync());
  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(Future.value(bytes('Roboto-$weight.ttf')));
  }
  await roboto.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(bytes('MaterialIcons-Regular.otf')))).load();
}
