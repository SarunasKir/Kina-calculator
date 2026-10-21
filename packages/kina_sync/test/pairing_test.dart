import 'package:kina_sync/kina_sync.dart';
import 'package:test/test.dart';

void main() {
  test('a code round-trips', () {
    final offer = PairingOffer.create(
      hubId: 'hub-1',
      addresses: const ['192.168.1.20', '10.0.0.4'],
      port: 47821,
    );
    expect(offer.code, startsWith(pairingPrefix));
    final parsed = PairingOffer.parse('  ${offer.code}\n');
    expect(parsed.hubId, 'hub-1');
    expect(parsed.addresses, ['192.168.1.20', '10.0.0.4']);
    expect(parsed.port, 47821);
    expect(parsed.secret, offer.secret);
    expect(parsed.secret, hasLength(32));
  });

  test('two offers have different secrets', () {
    PairingOffer make() =>
        PairingOffer.create(hubId: 'h', addresses: const [], port: 1);
    expect(make().secret, isNot(make().secret));
  });

  test('rejects text that is not a code', () {
    expect(
      () => PairingOffer.parse('hello'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'This is not a Kina pairing code',
        ),
      ),
    );
  });

  test('rejects a damaged code', () {
    expect(
      () => PairingOffer.parse('${pairingPrefix}e30'),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'This pairing code is damaged',
        ),
      ),
    );
    expect(
      () => PairingOffer.parse('$pairingPrefix%%%'),
      throwsA(isA<FormatException>()),
    );
  });
}
