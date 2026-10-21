@Tags(['golden'])
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/app.dart';
import 'package:kina_data/kina_data.dart';

import '../helpers.dart';

Future<void> golden(
  WidgetTester tester, {
  required Size size,
  required double pixelRatio,
  required Brightness brightness,
  required String name,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final db = memoryDatabase();
  addTearDown(() => tester.runAsync(db.close));
  await tester.runAsync(
    () => SettingsRepository(
      db,
    ).save(CalculatorSettings.defaults.copyWith(vatPercent: '21')),
  );
  await pumpApp(tester, db, size: size * pixelRatio);
  tester.view.devicePixelRatio = pixelRatio;
  await tester.pumpAndSettle();
  await expectLater(find.byType(KinaApp), matchesGoldenFile('$name.png'));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets(
    'Windows, light',
    (t) => golden(
      t,
      size: const Size(1440, 1180),
      pixelRatio: 1,
      brightness: Brightness.light,
      name: 'windows_light',
    ),
  );
  testWidgets(
    'Windows, dark',
    (t) => golden(
      t,
      size: const Size(1440, 1180),
      pixelRatio: 1,
      brightness: Brightness.dark,
      name: 'windows_dark',
    ),
  );
  testWidgets(
    'phone, light',
    (t) => golden(
      t,
      size: const Size(412, 915),
      pixelRatio: 2,
      brightness: Brightness.light,
      name: 'phone_light',
    ),
  );
  testWidgets(
    'phone, dark',
    (t) => golden(
      t,
      size: const Size(412, 915),
      pixelRatio: 2,
      brightness: Brightness.dark,
      name: 'phone_dark',
    ),
  );
}
