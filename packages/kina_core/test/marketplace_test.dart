import 'package:decimal/decimal.dart';
import 'package:kina_core/kina_core.dart';
import 'package:test/test.dart';

Decimal d(String s) => Decimal.parse(s);

MarketQuote quote({
  String kina = '25000000',
  String qunaChest = '600',
  String kinaChest = '2000000',
  String qunaPack = '4000',
  String packPrice = '51',
  String seller = '1.5',
  String vat = '0',
  String feePct = '0',
  String fixed = '0',
}) => MarketQuote(
  kina: d(kina),
  qunaPerChest: d(qunaChest),
  kinaPerChest: d(kinaChest),
  qunaPerPack: d(qunaPack),
  packPrice: d(packPrice),
  sellerPerMillion: d(seller),
  vatPercent: d(vat),
  feePercent: d(feePct),
  fixedFee: d(fixed),
);

void main() {
  group('v55 parity', () {
    test('25m item: exact and whole-chest values', () {
      final r = evaluateMarket(quote());
      expect(r.validOfficial, isTrue);
      expect(r.qunaExact, d('7500'));
      expect(r.chestCount, 13);
      expect(r.qunaWholeChests, d('7800'));
      expect(r.officialExact, d('95.63'));
      expect(r.officialWholeChests, d('99.45'));
      expect(r.rmt.total, d('37.5'));
      expect(r.difference, d('58.13'));
    });

    test('a fraction of a chest rounds the chest count up', () {
      final r = evaluateMarket(quote(kina: '2500000', seller: '0'));
      expect(r.qunaExact, d('750'));
      expect(r.qunaWholeChests, d('1200'));
    });

    test('RMT fees apply after VAT', () {
      final r = evaluateMarket(
        quote(
          kina: '100000000',
          seller: '1',
          vat: '21',
          feePct: '3.9',
          fixed: '0.99',
          qunaChest: '0',
        ),
      );
      expect(r.validOfficial, isFalse);
      expect(r.rmt.subtotal, d('100'));
      expect(r.rmt.vat, d('21'));
      expect(r.rmt.fee, d('5.71'));
      expect(r.rmt.total, d('126.71'));
    });

    test('negative values are rejected', () {
      expect(
        () => evaluateMarket(quote(kina: '-1')),
        throwsA(isA<InvalidQuoteException>()),
      );
      expect(InvalidQuoteException().toString(), contains('invalid'));
    });

    test('missing Quna setup is not valid official', () {
      final r = evaluateMarket(quote(kina: '1000000', packPrice: '0'));
      expect(r.validOfficial, isFalse);
      expect(r.chestCount, 0);
      expect(r.officialExact, Decimal.zero);
    });
  });
}
