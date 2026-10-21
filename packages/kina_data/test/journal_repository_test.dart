import 'package:decimal/decimal.dart';
import 'package:kina_data/kina_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

JournalEntry entry(int i, {String item = 'Sword'}) => JournalEntry(
  id: 'entry-$i',
  date: DateTime.utc(2026).add(Duration(minutes: i)),
  item: item,
  kina: Decimal.fromInt(25000000),
  qunaEquivalent: Decimal.fromInt(7500),
  officialEur: Decimal.parse('95.63'),
  rmtEur: Decimal.parse('37.50'),
  currency: 'EUR',
  fxRatePerEur: Decimal.one,
);

void main() {
  late KinaDatabase db;
  late JournalRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = JournalRepository(db);
  });
  tearDown(() => db.close());

  test('lists newest first with totals', () async {
    await repo.add(entry(1));
    await repo.add(entry(2));
    expect((await repo.list()).map((e) => e.id), ['entry-2', 'entry-1']);
    final totals = await repo.totals();
    expect(totals.count, 2);
    expect(totals.officialEur, Decimal.parse('191.26'));
    expect(totals.rmtEur, Decimal.fromInt(75));
  });

  test('cleans item names', () async {
    await repo.add(entry(1, item: '   '));
    await repo.add(entry(2, item: 'é' * 90));
    final names = (await repo.list()).map((e) => e.item).toList();
    expect(names.last, JournalRepository.unnamedItem);
    expect(names.first.runes, hasLength(80));
    expect(JournalRepository.cleanItemName(' Bow '), 'Bow');
  });

  test('delete removes one entry', () async {
    await repo.add(entry(1));
    await repo.add(entry(2));
    await repo.delete('entry-1');
    expect((await repo.list()).single.id, 'entry-2');
  });

  test('keeps only the newest 3000', () async {
    await db.transaction(() async {
      for (var i = 0; i < JournalRepository.maxEntries + 2; i++) {
        await repo.add(entry(i));
      }
    });
    final all = await repo.list();
    expect(all, hasLength(3000));
    expect(all.last.id, 'entry-2');
  });
}
