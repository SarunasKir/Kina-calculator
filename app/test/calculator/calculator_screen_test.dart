import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kina_app/src/calculator/calculator_view.dart';
import 'package:kina_app/src/rates/rate_sync.dart';
import 'package:kina_data/kina_data.dart';

import '../helpers.dart';

Future<void> enter(WidgetTester tester, Key key, String text) async {
  await tester.enterText(
    find.descendant(of: find.byKey(key), matching: find.byType(TextField)),
    text,
  );
  await settle(tester);
}

Future<void> choose(WidgetTester tester, Key key, String item) async {
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await settle(tester);
}

void main() {
  late KinaDatabase db;

  setUp(() async {
    db = memoryDatabase();
  });
  tearDown(() => db.close());

  Future<CalculatorSettings> saved(WidgetTester tester) async =>
      (await tester.runAsync(() => SettingsRepository(db).load()))!;

  testWidgets('shows v55 defaults and results side by side on desktop', (
    tester,
  ) async {
    await pumpApp(tester, db);
    expect(find.byKey(const Key('summaryBar')), findsNothing);
    expect(textOf(tester, const Key('rmtTotal')), contains('€ 385.80'));
    expect(textOf(tester, const Key('quna')), contains('90000 Quna'));
    expect(textOf(tester, const Key('official')), contains('€ 1147.50'));
    expect(
      textOf(tester, const Key('savings')),
      startsWith('You save € 761.70'),
    );
    expect(textOf(tester, const Key('effective')), contains('per 1M Kina'));
    expect(textOf(tester, const Key('breakEven')), contains('Break-even'));
    expect(textOf(tester, const Key('rateStatus')), startsWith('Saved rates'));
  });

  testWidgets('phone layout shows a summary bar', (tester) async {
    await pumpApp(tester, db, size: const Size(412, 915));
    expect(find.byKey(const Key('summaryBar')), findsOneWidget);
  });

  testWidgets('typing updates results and saves', (tester) async {
    await pumpApp(tester, db);
    await enter(tester, const Key('vat'), '21');
    await enter(tester, const Key('amount'), '100');
    await enter(tester, const Key('price'), '1,5');
    expect(textOf(tester, const Key('rmtTotal')), contains('€ 189.57'));
    final s = await saved(tester);
    expect(s.amountMillions, '100');
    expect(s.pricePerMillion, '1,5');

    await enter(tester, const Key('qunaPerPack'), '0');
    expect(textOf(tester, const Key('official')), contains('Enter a valid'));
    expect(textOf(tester, const Key('quna')), contains('--'));
    expect(textOf(tester, const Key('breakEven')), endsWith('--'));
    await enter(tester, const Key('packPrice'), '60');
    await enter(tester, const Key('qunaPerChest'), '500');
    await enter(tester, const Key('millionsPerChest'), '3');
    await enter(tester, const Key('amount'), '');
    expect(textOf(tester, const Key('effective')), endsWith('--'));
    final after = await saved(tester);
    expect(after.packPrice, '60');
    expect(after.qunaPerChest, '500');
    expect(after.millionsPerChest, '3');
  });

  testWidgets('fees belong to the selected payment method', (tester) async {
    await pumpApp(tester, db);
    await choose(tester, const Key('payment'), 'PayPal');
    expect((await saved(tester)).selectedPayment, 3);
    await enter(tester, const Key('feePercent'), '4.4');
    await enter(tester, const Key('fixedFee'), '0.35');
    var s = await saved(tester);
    expect(s.paymentMethods[3].feePercent, '4.4');
    expect(s.paymentMethods[3].fixedFee, '0.35');
    expect(s.paymentMethods[0].feePercent, '3.9');

    await choose(tester, const Key('payment'), 'Visa / Mastercard');
    s = await saved(tester);
    expect(s.payment.fixedFee, '0.99');
  });

  testWidgets('seller rows update their own line', (tester) async {
    await pumpApp(tester, db);
    await enter(tester, const Key('sellerName1'), 'Bob');
    await enter(tester, const Key('sellerPrice1'), '9');
    expect(textOf(tester, const Key('sellerResult1')), contains('Extra'));
    final s = await saved(tester);
    expect(s.sellers[1], const Seller(name: 'Bob', pricePerMillion: '9'));
  });

  testWidgets('currency switch revalues money fields', (tester) async {
    await pumpApp(tester, db);
    await choose(tester, const Key('currency'), 'USD US Dollar');
    final s = await saved(tester);
    expect(s.currency, 'USD');
    expect(s.packPrice, '56.1');
    expect(find.text('56.1'), findsOneWidget);
    expect(textOf(tester, const Key('rmtTotal')), contains(r'$'));

    await choose(tester, const Key('targetCurrency'), 'GBP');
    expect((await saved(tester)).targetCurrency, 'GBP');
  });

  testWidgets('typing a rate sets a manual rate when done', (tester) async {
    await pumpApp(tester, db);
    await enter(tester, const Key('rate'), '1.25');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    final s = await saved(tester);
    expect(s.rateSource, RateSource.manual);
    expect(textOf(tester, const Key('rateStatus')), 'Manual rate');
  });

  testWidgets('sync success updates rates and shows the date', (tester) async {
    final client = FrankfurterClient(
      client: MockClient(
        (_) async => http.Response(
          '{"date":"2026-10-20",'
          '"rates":{"USD":1.2,"GBP":0.9,"CAD":1.5,"AUD":1.6}}',
          200,
        ),
      ),
    );
    await pumpApp(tester, db, rateClient: client);
    await tester.tap(find.byKey(const Key('syncRates')));
    await settle(tester);
    expect(
      find.textContaining('Rates updated (ECB, 2026-10-20)'),
      findsOneWidget,
    );
    expect(textOf(tester, const Key('rateStatus')), contains('2026-10-20'));
    expect(
      rateStatus((await saved(tester)).copyWith(rateSource: RateSource.manual)),
      'Manual rate · last sync 2026-10-20',
    );
  });

  testWidgets('sync brings in every currency the ECB publishes', (
    tester,
  ) async {
    final client = FrankfurterClient(
      client: MockClient(
        (_) async => http.Response(
          '{"date":"2026-10-20",'
          '"rates":{"USD":1.2,"GBP":0.9,"CAD":1.5,"AUD":1.6,"JPY":160}}',
          200,
        ),
      ),
    );
    await pumpApp(tester, db, rateClient: client);
    await tester.tap(find.byKey(const Key('syncRates')));
    await settle(tester);
    final rates = (await saved(tester)).ratesPerEur;
    expect(rates.keys, containsAll(['EUR', 'USD', 'JPY']));
    await tester.tap(find.byKey(const Key('currency')));
    await tester.pumpAndSettle();
    expect(find.text('JPY Japanese Yen'), findsOneWidget);
  });

  testWidgets('sync failure keeps rates', (tester) async {
    final client = FrankfurterClient(
      client: MockClient((_) async => http.Response('', 500)),
    );
    await pumpApp(tester, db, rateClient: client);
    await tester.tap(find.byKey(const Key('syncRates')));
    await settle(tester);
    expect(find.textContaining('Sync failed: HTTP 500'), findsOneWidget);
    expect((await saved(tester)).rateSource, RateSource.saved);
  });

  testWidgets('reset asks first, then restores defaults', (tester) async {
    await pumpApp(tester, db);
    await enter(tester, const Key('amount'), '5');
    await tester.tap(find.byKey(const Key('reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect((await saved(tester)).amountMillions, '5');

    await tester.tap(find.byKey(const Key('reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirmReset')));
    await settle(tester);
    expect((await saved(tester)).amountMillions, '300');
    expect(find.text('300'), findsOneWidget);
  });

  test('rate status for an ECB rate without a date', () {
    expect(
      rateStatus(
        CalculatorSettings.defaults.copyWith(rateSource: RateSource.ecb),
      ),
      'ECB via Frankfurter · published ?',
    );
  });

  testWidgets('VAT and fee fields open their help guides', (tester) async {
    await pumpApp(tester, db);
    await tester.tap(find.byTooltip('About VAT'));
    await tester.pumpAndSettle();
    expect(find.text('Understanding VAT'), findsOneWidget);
    await tester.tap(find.byKey(const Key('closeHelp')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('About Payment fee'));
    await tester.pumpAndSettle();
    expect(find.text('Payment processing fees'), findsOneWidget);
  });

  testWidgets('exports the calculation to CSV', (tester) async {
    final files = FakeFileAccess();
    await pumpApp(tester, db, files: files);
    await tester.tap(find.byKey(const Key('exportCalculation')));
    await settle(tester);
    expect(files.saved.keys.single, startsWith('kina_comparison_'));
    expect(files.saved.values.single, contains('RMT total,385.80'));
    expect(find.textContaining('CSV saved'), findsOneWidget);
  });

  testWidgets('marks unreadable numbers and counts them as zero', (
    tester,
  ) async {
    await pumpApp(tester, db);
    await enter(tester, const Key('price'), '1.2.3');
    expect(find.text('Enter a number such as 12.5'), findsOneWidget);
    expect(find.textContaining('RMT total'), findsWidgets);
    await enter(tester, const Key('price'), '1.5');
    expect(find.text('Enter a number such as 12.5'), findsNothing);
  });

  testWidgets('the Kina amount accepts compact notation', (tester) async {
    await pumpApp(tester, db);
    await enter(tester, const Key('amount'), '1.5b');
    expect(find.text('Enter a number such as 12.5'), findsNothing);
    expect(find.text('Use a number such as 300 or 1.5b'), findsNothing);
    expect(find.textContaining('90000'), findsNothing);
    expect(find.textContaining('450000'), findsWidgets);
    await enter(tester, const Key('amount'), '1.2.3m');
    expect(find.text('Use a number such as 300 or 1.5b'), findsOneWidget);
  });

  testWidgets('sellers can be added and removed between 1 and 10', (
    tester,
  ) async {
    await pumpApp(tester, db, size: const Size(1440, 2400));
    final add = find.byKey(const Key('addSeller'));
    await tester.tap(add);
    await settle(tester);
    expect((await saved(tester)).sellers.map((s) => s.name), [
      'Seller A',
      'Seller B',
      'Seller C',
      'Seller 4',
    ]);
    expect(find.byKey(const Key('sellerName3')), findsOneWidget);

    for (var i = 0; i < 6; i++) {
      await tester.tap(add);
      await settle(tester);
    }
    expect((await saved(tester)).sellers, hasLength(10));
    expect(tester.widget<OutlinedButton>(add).onPressed, isNull);

    for (var i = 9; i > 0; i--) {
      await tester.tap(find.byKey(Key('removeSeller$i')));
      await settle(tester);
    }
    expect((await saved(tester)).sellers.map((s) => s.name), ['Seller A']);
    final last = tester.widget<IconButton>(
      find.byKey(const Key('removeSeller0')),
    );
    expect(last.onPressed, isNull);
  });

  testWidgets('payment methods can be added, renamed and removed', (
    tester,
  ) async {
    await pumpApp(tester, db, size: const Size(1440, 1400));
    Future<void> name(String text) async {
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('paymentName')), text);
      await tester.tap(find.byKey(const Key('savePaymentName')));
      await settle(tester);
    }

    await tester.tap(find.byKey(const Key('addPayment')));
    await name('Bank transfer');
    var settings = await saved(tester);
    expect(settings.paymentMethods, hasLength(9));
    expect(settings.payment.name, 'Bank transfer');
    expect(settings.payment.feePercent, '0');

    await enter(tester, const Key('feePercent'), '1.5');
    await tester.tap(find.byKey(const Key('renamePayment')));
    await name('  Wire  ');
    settings = await saved(tester);
    expect(settings.payment.name, 'Wire');
    expect(settings.payment.feePercent, '1.5');

    await tester.tap(find.byKey(const Key('addPayment')));
    await name('   ');
    expect((await saved(tester)).paymentMethods, hasLength(9));

    await tester.tap(find.byKey(const Key('addPayment')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect((await saved(tester)).paymentMethods, hasLength(9));

    await tester.tap(find.byKey(const Key('removePayment')));
    await settle(tester);
    settings = await saved(tester);
    expect(settings.paymentMethods, hasLength(8));
    expect(settings.payment.name, 'Visa / Mastercard');
  });

  testWidgets('the last payment method cannot be removed', (tester) async {
    await tester.runAsync(
      () => SettingsRepository(db).save(
        CalculatorSettings.defaults.copyWith(
          paymentMethods: [CalculatorSettings.defaults.paymentMethods.first],
        ),
      ),
    );
    await pumpApp(tester, db);
    final remove = tester.widget<TextButton>(
      find.byKey(const Key('removePayment')),
    );
    expect(remove.onPressed, isNull);
  });
}
