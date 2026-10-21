import 'dart:math';

import 'package:kina_sync/kina_sync.dart';
import 'package:kina_sync/src/cipher.dart' show randomBytes;
import 'package:test/test.dart';

void main() {
  test('seals and opens a message', () async {
    final cipher = SyncCipher.random();
    final sealed = await cipher.seal({'a': 1, 'b': 'x'}, 'ctx');
    expect(sealed, isNot(contains('"a"')));
    expect(await cipher.open(sealed, 'ctx'), {'a': 1, 'b': 'x'});
  });

  test('the same message seals differently each time', () async {
    final cipher = SyncCipher.random();
    expect(
      await cipher.seal({'a': 1}, 'ctx'),
      isNot(await cipher.seal({'a': 1}, 'ctx')),
    );
  });

  test('rejects another key, another context and tampering', () async {
    final cipher = SyncCipher.random();
    final sealed = await cipher.seal({'a': 1}, 'ctx');
    await expectLater(
      SyncCipher.random().open(sealed, 'ctx'),
      throwsA(isA<CipherException>()),
    );
    await expectLater(
      cipher.open(sealed, 'other'),
      throwsA(isA<CipherException>()),
    );
    final flipped = sealed.startsWith('A')
        ? 'B${sealed.substring(1)}'
        : 'A${sealed.substring(1)}';
    await expectLater(
      cipher.open(flipped, 'ctx'),
      throwsA(isA<CipherException>()),
    );
    await expectLater(
      cipher.open('not base64!', 'ctx'),
      throwsA(isA<CipherException>()),
    );
    expect(const CipherException().toString(), contains('decrypted'));
  });

  test('keys round-trip through base64', () async {
    final cipher = SyncCipher.random();
    final copy = SyncCipher.fromBase64(cipher.keyBase64);
    expect(copy.key, cipher.key);
    expect(cipher.key, hasLength(32));
    expect(await copy.open(await cipher.seal({'a': 1}, 'c'), 'c'), {'a': 1});
  });

  test('randomBytes uses the given source', () {
    expect(
      randomBytes(4, random: Random(1)),
      randomBytes(4, random: Random(1)),
    );
    expect(randomBytes(16), hasLength(16));
  });
}
