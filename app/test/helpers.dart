import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/app.dart';
import 'package:kina_app/src/files/file_access.dart';
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
  FakeFileAccess? files,
  List<Uri>? openedLinks,
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
        fileAccessProvider.overrideWithValue(files ?? FakeFileAccess()),
        linkOpenerProvider.overrideWithValue((uri) async {
          openedLinks?.add(uri);
          return true;
        }),
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

/// Records saved files and returns canned picks instead of opening dialogs.
class FakeFileAccess implements FileAccess {
  /// Files "saved", by name.
  final Map<String, String> saved = {};

  /// What the next pick returns.
  List<PickedFile> picks = const [];

  /// Whether saving should fail.
  bool failSave = false;

  @override
  Future<String?> saveText(String fileName, String content) async {
    if (failSave) {
      throw const FileSystemException('disk full');
    }
    saved[fileName] = content;
    return '/exports/$fileName';
  }

  @override
  Future<List<PickedFile>> pickJsonFiles() async => picks;
}

/// Goes to the page labelled [label] in the navigation.
Future<void> goTo(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await settle(tester);
}

/// The text shown by the widget with [key], or by its Text descendants.
String textOf(WidgetTester tester, Key key) {
  final widget = tester.widget(find.byKey(key));
  if (widget is Text) {
    return widget.data!;
  }
  return tester
      .widgetList<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)),
      )
      .map((t) => t.data)
      .join(' ');
}

/// Checks a snack bar shows [text], then dismisses it so the next one can
/// show.
Future<void> expectSnack(WidgetTester tester, String text) async {
  expect(find.text(text), findsOneWidget);
  ScaffoldMessenger.of(tester.element(find.text(text))).removeCurrentSnackBar();
  await tester.pumpAndSettle();
}
