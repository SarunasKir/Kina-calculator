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
    expect(a == a.copyWith(fixedFee: '3'), isFalse);
    expect(a.copyWith(feePercent: '9').fixedFee, '2');
    const s = Seller(name: 'S', pricePerMillion: '1');
    expect(s.hashCode, Seller.fromJson(s.toJson()).hashCode);
  });
}
