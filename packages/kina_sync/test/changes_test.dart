// Records are built from map literals that cannot all be const.
// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:clock/clock.dart';
import 'package:kina_data/kina_data.dart';
import 'package:kina_sync/kina_sync.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late KinaDatabase a;
  late KinaDatabase b;

  setUp(() {
    a = openTestDatabase();
    b = openTestDatabase();
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  Future<List<String>> items(KinaDatabase db) async => [
    for (final e in await JournalRepository(db).list()) e.item,
  ];

  test('exports only what changed after a time', () async {
    final repo = JournalRepository(a);
    await withClock(
      Clock.fixed(DateTime.utc(2026, 10)),
      () => repo.add(entry('1', 'Old')),
    );
    await withClock(
      Clock.fixed(DateTime.utc(2026, 10, 5)),
      () => repo.add(entry('2', 'New')),
    );
    final all = await exportChanges(a);
    expect(all.tables['journal_entries'], hasLength(2));
    expect(all.length, 2);
    final recent = await exportChanges(a, since: DateTime.utc(2026, 10, 3));
    final rows = recent.tables['journal_entries']!;
    expect(rows.single['item'], 'New');
    expect(recent.tables.keys, ['journal_entries']);
    expect(await exportChanges(a, since: DateTime.utc(2027)), isA<ChangeSet>());
    expect((await exportChanges(a, since: DateTime.utc(2027))).length, 0);
  });

  test('applying stores new records on another database', () async {
    await JournalRepository(a).add(entry('1', 'Sword'));
    await ProfileRepository(a).save('Cheap', CalculatorSettings.defaults);
    await SettingsRepository(
      a,
    ).save(CalculatorSettings.defaults.copyWith(amountMillions: '5'));
    final result = await applyChanges(b, await exportChanges(a));
    expect(result.applied, 3);
    expect(result.skipped, 0);
    expect(await items(b), ['Sword']);
    expect((await ProfileRepository(b).list()).single.name, 'Cheap');
    expect((await SettingsRepository(b).load()).amountMillions, '5');
  });

  test('the newest version of a record wins, in both directions', () async {
    final repoA = JournalRepository(a);
    final repoB = JournalRepository(b);
    await withClock(
      Clock.fixed(DateTime.utc(2026, 10)),
      () => repoA.add(entry('1', 'From A')),
    );
    await withClock(
      Clock.fixed(DateTime.utc(2026, 10, 2)),
      () => repoB.add(entry('1', 'From B')),
    );
    final toB = await applyChanges(b, await exportChanges(a));
    expect(toB.skipped, 1);
    expect(await items(b), ['From B']);
    final toA = await applyChanges(a, await exportChanges(b));
    expect(toA.applied, 1);
    expect(await items(a), ['From B']);
    // Applying the same records again changes nothing.
    final again = await applyChanges(a, await exportChanges(b));
    expect((again.applied, again.skipped), (0, 1));
  });

  test('deletions sync too', () async {
    final repoA = JournalRepository(a);
    await withClock(
      Clock.fixed(DateTime.utc(2026, 10)),
      () => repoA.add(entry('1', 'Sword')),
    );
    await applyChanges(b, await exportChanges(a));
    await withClock(
      Clock.fixed(DateTime.utc(2026, 10, 2)),
      () => repoA.delete('1'),
    );
    await applyChanges(b, await exportChanges(a));
    expect(await items(b), isEmpty);
  });

  test('device-only values are never exported', () async {
    await LocalStore(a).write('sync.pairing', 'secret');
    expect((await exportChanges(a)).length, 0);
    expect(syncedTables, isNot(contains('local_values')));
  });

  group('rejects bad records', () {
    Future<void> rejects(Map<String, Object?> json, String message) =>
        expectLater(
          applyChanges(a, ChangeSet.fromJson(json)),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains(message),
            ),
          ),
        );

    test('with columns that do not exist', () async {
      await rejects({
        'journal_entries': [
          {'id': '1', 'updated_at': '2026-10-01T00:00:00Z', 'evil': 'x'},
        ],
      }, 'does not match');
    });

    test('with missing columns', () async {
      await rejects({
        'journal_entries': [
          {'id': '1'},
        ],
      }, 'does not match');
    });

    test('without an id or time', () async {
      await JournalRepository(a).add(entry('x', 'Sword'));
      final row = (await exportChanges(a)).tables['journal_entries']!.single;
      await rejects({
        'journal_entries': [
          {...row, 'id': 5},
        ],
      }, 'no id or time');
    });

    test('for another table', () async {
      expect(
        () => applyChanges(
          a,
          const ChangeSet({
            'sqlite_master': [<String, Object?>{}],
          }),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('a change set ignores unknown tables when read from JSON', () {
    final set = ChangeSet.fromJson({
      'journal_entries': <Object?>[],
      'sqlite_master': [
        {'x': 1},
      ],
    });
    expect(set.tables.keys, ['journal_entries']);
    expect(ChangeSet.empty.length, 0);
  });

  test('a failed apply leaves the database unchanged', () async {
    await JournalRepository(a).add(entry('1', 'Sword'));
    final good = (await exportChanges(a)).tables['journal_entries']!.single;
    final changes = ChangeSet({
      'journal_entries': [
        good,
        {'id': 'bad', 'updated_at': '2026-10-01T00:00:00Z'},
      ],
    });
    await expectLater(
      applyChanges(b, changes),
      throwsA(isA<FormatException>()),
    );
    expect(await items(b), isEmpty);
  });
}
