import 'package:decimal/decimal.dart';
import 'package:kina_core/kina_core.dart';
import 'package:test/test.dart';

Decimal d(String s) => Decimal.parse(s);

/// The v55 default Quna shop setup: 4000 Quna for 51, 600 Quna per 2M chest.
PurchaseInput input({
  String millions = '100',
  String rate = '1.5',
  String vat = '0',
  String feePct = '0',
  String fixed = '0',
  String qunaPack = '4000',
  String packPrice = '51',
  String qunaChest = '600',
  String millionsChest = '2',
}) => PurchaseInput(
  millions: d(millions),
  ratePerMillion: d(rate),
  vatPercent: d(vat),
  feePercent: d(feePct),
  fixedFee: d(fixed),
  qunaPerPack: d(qunaPack),
  packPrice: d(packPrice),
  qunaPerChest: d(qunaChest),
  millionsPerChest: d(millionsChest),
);

void main() {
  group('v55 parity', () {
    test('baseline: 100M at 1.50 with 21% VAT', () {
      final r = evaluatePurchase(input(vat: '21'));
      expect(r.rmt.subtotal, d('150'));
      expect(r.rmt.vat, d('31.5'));
      expect(r.rmt.fee, d('0'));
      expect(r.rmt.total, d('181.5'));
      expect(r.qunaRequired, d('30000'));
      expect(r.officialCost, d('382.5'));
      expect(r.savings, d('201'));
      expect(r.officialValid, isTrue);
      // v55: 382.5 / (100 * 1.21)
      expect(r.breakEvenRate, d('3.161157'));
    });

    test('fees are charged on subtotal plus VAT', () {
      final r = evaluatePurchase(
        input(rate: '1', vat: '21', feePct: '3.9', fixed: '0.99'),
      );
      expect(r.rmt.fee, d('5.71'));
      expect(r.rmt.total, d('126.71'));
    });

    test('missing chest size makes the official route invalid', () {
      final r = evaluatePurchase(
        input(rate: '2', millionsChest: '0', packPrice: '0'),
      );
      expect(r.officialValid, isFalse);
      expect(r.breakEvenRate, Decimal.zero);
      expect(r.officialCost, Decimal.zero);
      expect(r.savings, Decimal.zero);
      expect(r.qunaRequired, Decimal.zero);
    });

    test('negative inputs count as zero', () {
      final r = evaluatePurchase(
        PurchaseInput(millions: d('-5'), ratePerMillion: d('-1')),
      );
      expect(r.rmt.total, Decimal.zero);
      expect(r.effectiveRate, Decimal.zero);
    });

    test('zero VAT and fees; RMT more expensive gives negative savings', () {
      final r = evaluatePurchase(
        input(
          millions: '2',
          rate: '10',
          qunaPack: '100',
          packPrice: '5',
          qunaChest: '100',
          millionsChest: '1',
        ),
      );
      expect(r.rmt.total, d('20'));
      expect(r.officialCost, d('10'));
      expect(r.savings, d('-10'));
      expect(r.savingsPercent, d('-100'));
    });

    test('break-even price makes RMT match official within 5 cents', () {
      final base = input(
        millions: '200',
        rate: '0',
        vat: '19',
        feePct: '3.9',
        fixed: '1.5',
        packPrice: '70',
      );
      final r = evaluatePurchase(base);
      final at = evaluatePurchase(base.withRate(r.breakEvenRate));
      expect(
        (at.rmt.total - at.officialCost).abs(),
        lessThanOrEqualTo(d('0.05')),
      );
    });

    test('zero pack price is invalid', () {
      final r = evaluatePurchase(
        input(millions: '50', rate: '2', packPrice: '0'),
      );
      expect(r.officialValid, isFalse);
    });

    test('cheaper seller costs less and saves more', () {
      final base = input(vat: '21', feePct: '3.9', fixed: '0.99');
      final a = evaluatePurchase(base);
      final b = evaluatePurchase(base.withRate(d('1')));
      expect(b.rmt.total, lessThan(a.rmt.total));
      expect(b.savings, greaterThan(a.savings));
    });

    test('each step rounds to cents', () {
      final r = evaluatePurchase(
        input(
          millions: '3',
          rate: '0.335',
          vat: '21',
          feePct: '2.5',
          fixed: '0.25',
        ),
      );
      expect(r.rmt.subtotal, d('1.01'));
      expect(r.rmt.vat, d('0.21'));
      expect(r.rmt.fee, d('0.28'));
      expect(r.rmt.total, d('1.5'));
    });
  });

  group('comparison figures', () {
    test('savings percent and effective rate', () {
      final r = evaluatePurchase(input(vat: '21'));
      // 201 / 382.5 * 100
      expect(r.savingsPercent, d('52.549'));
      expect(r.effectiveRate, d('1.815'));
    });

    test('break-even is never negative', () {
      final r = evaluatePurchase(input(fixed: '1000'));
      expect(r.breakEvenRate, Decimal.zero);
    });

    test('zero Kina gives no break-even or effective rate', () {
      final r = evaluatePurchase(input(millions: '0'));
      expect(r.breakEvenRate, Decimal.zero);
      expect(r.effectiveRate, Decimal.zero);
    });

    test('half a cent rounds away from zero', () {
      expect(roundCents(d('0.005').toRational()), d('0.01'));
      expect(roundCents(d('-0.005').toRational()), d('-0.01'));
      expect(roundCents(d('2.675').toRational()), d('2.68'));
    });
  });
}
