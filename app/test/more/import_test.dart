import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/more/more_screen.dart';
import 'package:kina_data/kina_data.dart';

import '../helpers.dart';

void main() {
  late KinaDatabase db;

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  test('imports the v55 files it recognises, by name', () async {
    final summary = await importV55Files(db, [
      (name: 'Settings.json', content: jsonEncode({'Amount': '50'})),
      (
        name: 'profiles.json',
        content: jsonEncode([
          {'Name': 'Cheap', 'Data': <String, Object?>{}},
        ]),
      ),
      (
        name: 'price_history.json',
        content: jsonEncode([
          {
            'timestamp': '2026-10-01T10:00:00Z',
            'names': ['A'],
            'all_in_eur': [1.2, 3.8],
          },
        ]),
      ),
      (
        name: 'marketplace_purchases.json',
        content: jsonEncode([
          {'date': '2026-10-01T10:00:00Z', 'item': 'Sword', 'kina': 25000000},
        ]),
      ),
      (name: 'notes.json', content: 'not even json'),
    ]);
    expect(summary, isNotNull);
    expect(
      describeImport(summary!),
      'calculator settings, 1 profiles, 1 snapshots, 1 journal entries',
    );
    expect((await SettingsRepository(db).load()).amountMillions, '50');
    expect(await JournalRepository(db).list(), hasLength(1));
  });

  test('returns null when no v55 file is picked', () async {
    expect(
      await importV55Files(db, [(name: 'other.json', content: '{}')]),
      isNull,
    );
  });

  test('describes an import without settings', () {
    expect(
      describeImport(
        const ImportSummary(
          settings: false,
          profiles: 0,
          snapshots: 2,
          journalEntries: 0,
        ),
      ),
      '0 profiles, 2 snapshots, 0 journal entries',
    );
  });
}
