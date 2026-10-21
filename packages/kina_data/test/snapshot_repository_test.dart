import 'package:decimal/decimal.dart';
import 'package:kina_data/kina_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

PriceSnapshot snapshot(int i, {Decimal? official}) => PriceSnapshot(
  id: 'snap-$i',
  takenAt: DateTime.utc(2026).add(Duration(hours: i)),
  currency: 'EUR',
  eurRate: Decimal.one,
  rateSource: 'Saved manual rates',
  millions: Decimal.fromInt(300),
  sellers: [
    SnapshotPrice(name: 'Seller A', eurPerMillion: Decimal.parse('1.2756')),
  ],
  officialEurPerMillion: official,
);

void main() {
  late KinaDatabase db;
  late SnapshotRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = SnapshotRepository(db);
  });
  tearDown(() => db.close());

  test('stores every field and lists oldest first', () async {
    await repo.add(snapshot(2, official: Decimal.parse('3.1875')));
    await repo.add(snapshot(1));
    final all = await repo.list();
    expect(all.map((s) => s.id), ['snap-1', 'snap-2']);
    expect(all.last.officialEurPerMillion, Decimal.parse('3.1875'));
    expect(all.first.officialEurPerMillion, isNull);
    expect(all.first.sellers.single.eurPerMillion, Decimal.parse('1.2756'));
    expect(all.first.millions, Decimal.fromInt(300));
  });

  test('latest limits to the newest snapshots', () async {
    for (var i = 0; i < 5; i++) {
      await repo.add(snapshot(i));
    }
    final latest = await repo.list(latest: 2);
    expect(latest.map((s) => s.id), ['snap-3', 'snap-4']);
  });

  test('keeps only the newest 500', () async {
    for (var i = 0; i < SnapshotRepository.maxSnapshots + 3; i++) {
      await repo.add(snapshot(i));
    }
    final all = await repo.list();
    expect(all, hasLength(500));
    expect(all.first.id, 'snap-3');
  });
}
