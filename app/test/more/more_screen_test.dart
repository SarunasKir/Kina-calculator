import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/help/help.dart';
import 'package:kina_data/kina_data.dart';

import '../helpers.dart';

void main() {
  late KinaDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  testWidgets('opens each help guide', (tester) async {
    final links = <Uri>[];
    await pumpApp(tester, db, openedLinks: links);
    await goTo(tester, 'More');

    for (final topic in HelpTopic.values) {
      await tester.tap(find.byKey(Key('help-${topic.name}')));
      await tester.pumpAndSettle();
      expect(find.byType(HelpDialog), findsOneWidget);
      for (final section in helpText[topic]!) {
        expect(find.text(section.heading), findsOneWidget);
      }
      if (topic == HelpTopic.risks) {
        await tester.tap(find.byKey(const Key('openPolicy')));
        await tester.pump();
        expect(links, [ncsoftPolicyUrl]);
      } else {
        expect(find.byKey(const Key('openPolicy')), findsNothing);
      }
      await tester.tap(find.byKey(const Key('closeHelp')));
      await tester.pumpAndSettle();
      expect(find.byType(HelpDialog), findsNothing);
    }
  });

  testWidgets('imports v55 files and refreshes the screens', (tester) async {
    final files = FakeFileAccess();
    await pumpApp(tester, db, files: files);
    await goTo(tester, 'More');

    // Cancelling the picker does nothing.
    await tester.tap(find.byKey(const Key('importV55')));
    await settle(tester);
    expect(find.byType(SnackBar), findsNothing);

    files.picks = [
      (name: 'settings.json', content: jsonEncode({'Amount': '50'})),
      (
        name: 'marketplace_purchases.json',
        content: jsonEncode([
          {'date': '2026-10-01T10:00:00Z', 'item': 'Sword', 'kina': 25000000},
        ]),
      ),
    ];
    await tester.tap(find.byKey(const Key('importV55')));
    await settle(tester);
    expect(
      find.text(
        'Imported calculator settings, 0 profiles, 0 snapshots, '
        '1 journal entries',
      ),
      findsOneWidget,
    );

    await goTo(tester, 'Calculator');
    expect(find.widgetWithText(TextField, '50'), findsOneWidget);
    await goTo(tester, 'Marketplace');
    expect(find.text('Sword'), findsOneWidget);
  });

  testWidgets('explains when no v55 file was picked', (tester) async {
    final files = FakeFileAccess()
      ..picks = [(name: 'notes.json', content: '{}')];
    await pumpApp(tester, db, files: files);
    await goTo(tester, 'More');
    await tester.tap(find.byKey(const Key('importV55')));
    await settle(tester);
    expect(find.textContaining('No v55 files found'), findsOneWidget);
  });

  testWidgets('reports a broken file', (tester) async {
    final files = FakeFileAccess()
      ..picks = [(name: 'profiles.json', content: '[{')];
    await pumpApp(tester, db, files: files);
    await goTo(tester, 'More');
    await tester.tap(find.byKey(const Key('importV55')));
    await settle(tester);
    expect(find.textContaining('Import failed'), findsOneWidget);
  });
}
