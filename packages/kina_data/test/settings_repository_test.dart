import 'package:clock/clock.dart';
import 'package:decimal/decimal.dart';
import 'package:kina_data/kina_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late KinaDatabase db;
  late SettingsRepository repo;

  setUp(() {
    db = openTestDatabase();
    repo = SettingsRepository(db);
  });
  tearDown(() => db.close());

  test('returns v55 defaults when nothing is saved', () async {
    final s = await repo.load();
    expect(s.amountMillions, '300');
    expect(s.vatPercent, '23.4567');
    expect(s.paymentMethods, hasLength(8));
    expect(s.paymentMethods[3].feePercent, '5.9');
    expect(s.sellers.map((e) => e.name), ['Seller A', 'Seller B', 'Seller C']);
    expect(s.ratesPerEur['USD'], Decimal.parse('1.10'));
    expect(s.rateSource, RateSource.saved);
  });

  test('saves and reloads every field', () async {
    final changed = CalculatorSettings.fromJson({
      ...CalculatorSettings.defaults.toJson(),
      'amountMillions': '42',
      'selectedPayment': 2,
      'paymentMethods': [
        CalculatorSettings.defaults.paymentMethods.first
            .copyWith(feePercent: '1.5', fixedFee: '0.10')
            .toJson(),
      ],
      'sellers': [const Seller(name: 'Only', pricePerMillion: '0.80').toJson()],
      'currency': 'GBP',
      'rateSource': 'ecb',
      'rateDate': '2026-10-17',
    });
    await repo.save(changed);
    final loaded = await repo.load();
    expect(loaded.toJson(), changed.toJson());
    expect(loaded.paymentMethods.single.feePercent, '1.5');
    expect(loaded.sellers.single, changed.sellers.single);
    expect(loaded.rateSource, RateSource.ecb);
  });

  test('records the change time', () async {
    final at = DateTime.utc(2026, 10, 21, 12);
    await withClock(
      Clock.fixed(at),
      () => repo.save(CalculatorSettings.defaults),
    );
    final row = await db.select(db.settingsTable).getSingle();
    expect(row.updatedAt.toUtc(), at);
  });

  test('reset restores defaults', () async {
    await repo.save(CalculatorSettings.fromJson(const {'amountMillions': '1'}));
    await repo.reset();
    expect((await repo.load()).amountMillions, '300');
  });

  test('watch emits after a change', () async {
    final values = repo.watch().map((s) => s.amountMillions);
    final expectation = expectLater(values, emitsInOrder(['300', '7']));
    await Future<void>.delayed(Duration.zero);
    await repo.save(CalculatorSettings.fromJson(const {'amountMillions': '7'}));
    await expectation;
  });

  test('unknown fields in JSON fall back to defaults', () {
    final s = CalculatorSettings.fromJson(const {'rateSource': 'nonsense'});
    expect(s.rateSource, RateSource.saved);
    expect(s.currency, 'EUR');
  });

  test('value equality for payment methods and sellers', () {
    const a = PaymentMethod(name: 'X', feePercent: '1', fixedFee: '2');
    expect(a, PaymentMethod.fromJson(a.toJson()));
    expect(a.hashCode, PaymentMethod.fromJson(a.toJson()).hashCode);
    expect(
      a.copyWith(name: 'Y'),
      const PaymentMethod(name: 'Y', feePercent: '1', fixedFee: '2'),
    );
    expect(a == a.copyWith(fixedFee: '3'), isFalse);
    expect(a.copyWith(feePercent: '9').fixedFee, '2');
    const s = Seller(name: 'S', pricePerMillion: '1');
    expect(s.hashCode, Seller.fromJson(s.toJson()).hashCode);
  });

  test('sellers keep their fees and price source through JSON', () {
    const source = PriceSource(
      url: 'https://example.com/kina',
      kind: SourceKind.css,
      rule: '.price',
      unitMillions: '100',
      currency: 'USD',
    );
    const seller = Seller(
      name: 'Site',
      pricePerMillion: '1.5',
      extraFeePercent: '2',
      extraFixedFee: '0.5',
      source: source,
    );
    final back = Seller.fromJson(seller.toJson());
    expect(back, seller);
    expect(back.source, source);
    expect(back.hashCode, seller.hashCode);
    expect(source.hashCode, PriceSource.fromJson(source.toJson()).hashCode);
  });

  test('older sellers and sources read with defaults', () {
    final seller = Seller.fromJson(const {
      'name': 'Old',
      'pricePerMillion': '1',
    });
    expect(seller.extraFeePercent, '0');
    expect(seller.extraFixedFee, '0');
    expect(seller.source, isNull);
    final source = PriceSource.fromJson(const {'kind': 'nonsense'});
    expect(source.url, '');
    expect(source.kind, SourceKind.auto);
    expect(source.unitMillions, '1');
    expect(source.currency, 'EUR');
    expect(const PriceSource(url: 'u').rule, '');
  });

  test('seller and source copyWith replace only the given fields', () {
    const source = PriceSource(url: 'a');
    final changed = source.copyWith(
      url: 'b',
      kind: SourceKind.json,
      rule: 'x.y',
      unitMillions: '10',
      currency: 'GBP',
    );
    expect(changed.url, 'b');
    expect(changed.kind, SourceKind.json);
    expect(changed.rule, 'x.y');
    expect(changed.unitMillions, '10');
    expect(changed.currency, 'GBP');
    expect(changed == source, isFalse);
    expect(source.copyWith(), source);

    const seller = Seller(name: 'S', pricePerMillion: '1', source: source);
    final updated = seller.copyWith(
      name: 'T',
      pricePerMillion: '2',
      extraFeePercent: '3',
      extraFixedFee: '4',
      source: changed,
    );
    expect(updated.name, 'T');
    expect(updated.pricePerMillion, '2');
    expect(updated.extraFeePercent, '3');
    expect(updated.extraFixedFee, '4');
    expect(updated.source, changed);
    expect(seller.copyWith().source, source);
    expect(seller.copyWith(clearSource: true).source, isNull);
    expect(seller == updated, isFalse);
  });

  test('copyWith replaces only the given fields', () {
    final d = CalculatorSettings.defaults;
    final c = d.copyWith(
      amountMillions: '1',
      pricePerMillion: '2',
      vatPercent: '3',
      qunaPerPack: '4',
      packPrice: '5',
      qunaPerChest: '6',
      millionsPerChest: '7',
      paymentMethods: [d.paymentMethods.last],
      selectedPayment: 0,
      sellers: const [],
      currency: 'GBP',
      targetCurrency: 'EUR',
      ratesPerEur: {'EUR': Decimal.one},
      rateSource: RateSource.manual,
      rateDate: '2026-10-21',
    );
    expect(c.toJson(), {
      ...d.toJson(),
      'amountMillions': '1',
      'pricePerMillion': '2',
      'vatPercent': '3',
      'qunaPerPack': '4',
      'packPrice': '5',
      'qunaPerChest': '6',
      'millionsPerChest': '7',
      'paymentMethods': [d.paymentMethods.last.toJson()],
      'selectedPayment': 0,
      'sellers': <Object?>[],
      'currency': 'GBP',
      'targetCurrency': 'EUR',
      'ratesPerEur': {'EUR': '1'},
      'rateSource': 'manual',
      'rateDate': '2026-10-21',
    });
    expect(c.copyWith().toJson(), c.toJson());
    expect(c.copyWith(clearRateDate: true).rateDate, isNull);
  });

  test('payment falls back to the first method for a stale index', () {
    final d = CalculatorSettings.defaults;
    expect(d.copyWith(selectedPayment: 3).payment.name, 'PayPal');
    expect(d.copyWith(selectedPayment: 99).payment.name, 'Visa / Mastercard');
    expect(d.copyWith(selectedPayment: -1).payment.name, 'Visa / Mastercard');
  });
}
