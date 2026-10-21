import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kina_app/src/sources/price_extractor.dart';
import 'package:kina_app/src/sources/seller_prices.dart';
import 'package:kina_app/src/sources/source_client.dart';
import 'package:kina_data/kina_data.dart';

SourceClient serving(String body, {int status = 200}) => SourceClient(
  client: MockClient(
    (_) async => http.Response.bytes(utf8.encode(body), status),
  ),
);

Seller seller(PriceSource? source) =>
    Seller(name: 'S', pricePerMillion: '1', source: source);

void main() {
  final settings = CalculatorSettings.defaults;

  group('SourceClient', () {
    test('returns the body', () async {
      expect(await serving('héllo').get(' https://x.test/a '), 'héllo');
    });

    test('rejects bad addresses', () async {
      for (final bad in ['', 'ftp://x.test', 'https://', 'not a url']) {
        await expectLater(
          serving('').get(bad),
          throwsA(isA<SourceReadException>()),
        );
      }
    });

    test('reports HTTP status, network failure and oversize pages', () async {
      await expectLater(
        serving('', status: 404).get('https://x.test'),
        throwsA(
          isA<SourceReadException>().having((e) => e.message, 'm', 'HTTP 404'),
        ),
      );
      final offline = SourceClient(
        client: MockClient((_) => throw http.ClientException('offline')),
      );
      await expectLater(
        offline.get('https://x.test'),
        throwsA(
          isA<SourceReadException>().having(
            (e) => e.message,
            'm',
            startsWith('Could not connect'),
          ),
        ),
      );
      await expectLater(
        serving('x' * (SourceClient.maxBytes + 1)).get('https://x.test'),
        throwsA(isA<SourceReadException>()),
      );
    });

    test('builds a client of its own', () {
      expect(SourceClient(), isNotNull);
    });
  });

  group('fetchSellerPrice', () {
    test('picks the lowest offer and divides by the unit', () async {
      const source = PriceSource(url: 'https://x.test', unitMillions: '10');
      final price = await fetchSellerPrice(
        serving('{"price":"12","other":{"rate":"15"}}'),
        settings,
        seller(source),
      );
      expect(price, '1.2');
    });

    test('converts from the site currency', () async {
      const source = PriceSource(url: 'https://x.test', currency: 'USD');
      final price = await fetchSellerPrice(
        serving('{"price":"1.10"}'),
        settings,
        seller(source),
      );
      expect(price, '1');
    });

    test('uses a currency and unit stated on the page', () async {
      const source = PriceSource(url: 'https://x.test');
      final price = await fetchSellerPrice(
        serving('<body>1.10 USD / 1M</body>'),
        settings,
        seller(source),
      );
      expect(price, '1');
    });

    test('needs an address, a unit and a known currency', () async {
      await expectLater(
        fetchSellerPrice(serving(''), settings, seller(null)),
        throwsA(isA<SourceReadException>()),
      );
      await expectLater(
        fetchSellerPrice(
          serving(''),
          settings,
          seller(const PriceSource(url: ' ')),
        ),
        throwsA(isA<SourceReadException>()),
      );
      await expectLater(
        fetchSellerPrice(
          serving('{"price":1}'),
          settings,
          seller(const PriceSource(url: 'https://x.test', unitMillions: '0')),
        ),
        throwsA(isA<SourceReadException>()),
      );
      await expectLater(
        fetchSellerPrice(
          serving('{"price":1}'),
          settings,
          seller(const PriceSource(url: 'https://x.test', currency: 'JPY')),
        ),
        throwsA(
          isA<SourceReadException>().having(
            (e) => e.message,
            'm',
            'No exchange rate for JPY; sync online rates',
          ),
        ),
      );
    });
  });
}
