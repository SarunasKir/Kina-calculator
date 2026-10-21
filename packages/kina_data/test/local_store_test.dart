import 'package:drift/native.dart';
import 'package:kina_data/kina_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late KinaDatabase db;
  late LocalStore store;

  setUp(() {
    db = openTestDatabase();
    store = LocalStore(db);
  });
  tearDown(() => db.close());

  test('reads null for an unknown key', () async {
    expect(await store.read('missing'), isNull);
  });

  test('writes, replaces and removes values', () async {
    await store.write('a', '1');
    await store.write('b', '2');
    await store.write('a', '3');
    expect(await store.read('a'), '3');
    expect(await store.read('b'), '2');
    await store.remove('a');
    expect(await store.read('a'), isNull);
    expect(await store.read('b'), '2');
  });

  test('upgrading from schema 1 adds the local values table', () async {
    final old = KinaDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 1'),
      ),
    );
    addTearDown(old.close);
    final upgraded = LocalStore(old);
    await upgraded.write('k', 'v');
    expect(await upgraded.read('k'), 'v');
  });
}
