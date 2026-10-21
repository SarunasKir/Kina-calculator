import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kina_app/src/sources/price_extractor.dart';
import 'package:kina_data/kina_data.dart';

Decimal d(String s) => Decimal.parse(s);

PriceSource auto() => const PriceSource(url: 'https://x.test');

PriceSource json(String rule) =>
    PriceSource(url: 'https://x.test', kind: SourceKind.json, rule: rule);

PriceSource css(String rule) =>
    PriceSource(url: 'https://x.test', kind: SourceKind.css, rule: rule);

void main() {
  group('parsePriceNumber', () {
    test('reads the usual spellings', () {
      expect(parsePriceNumber('1.25'), d('1.25'));
      expect(parsePriceNumber('1,25'), d('1.25'));
      expect(parsePriceNumber('1,234.50'), d('1234.50'));
      expect(parsePriceNumber('1.234,50'), d('1234.50'));
      expect(parsePriceNumber('1,234,567'), d('1234567'));
      expect(parsePriceNumber('1 234'), d('1234'));
      expect(parsePriceNumber('€ 3.'), d('3'));
      expect(parsePriceNumber('7'), d('7'));
    });

    test('returns null without digits', () {
      expect(parsePriceNumber('free'), isNull);
    });
  });

  group('json kind', () {
    const body = '{"data":{"items":[{"price":"1.30"},{"price":2}]}}';

    test('follows a dot path with indexes', () {
      expect(
        findOffers(body, json('data.items[1].price')).single.amount,
        d('2'),
      );
      expect(
        findOffers(body, json('data.items[0].price')).single.amount,
        d('1.30'),
      );
    });

    test('a path that leads nowhere is an error', () {
      for (final rule in ['data.nothing', 'data.items[9].price', 'data[0]']) {
        expect(
          () => findOffers(body, json(rule)),
          throwsA(
            isA<SourceReadException>().having(
              (e) => e.message,
              'message',
              'Nothing matched "$rule"',
            ),
          ),
        );
      }
    });

    test('a page that is not JSON is an error', () {
      expect(
        () => findOffers('<html>', json('a')),
        throwsA(isA<SourceReadException>()),
      );
    });
  });

  group('css kind', () {
    const page =
        '<p class="p" content="9">x</p><span class="price">€ 1,25</span> '
        '<span class="price">free</span><b data-p>2</b>';

    test('reads text and content attributes', () {
      final offers = findOffers(page, css('.price'));
      expect(offers.single.amount, d('1.25'));
      expect(findOffers(page, css('.p')).single.amount, d('9'));
    });

    test('no match or a bad selector is an error', () {
      expect(
        () => findOffers(page, css('.missing')),
        throwsA(isA<SourceReadException>()),
      );
      expect(
        () => findOffers(page, css('[')),
        throwsA(
          isA<SourceReadException>().having(
            (e) => e.message,
            'message',
            contains('not a valid selector'),
          ),
        ),
      );
    });
  });

  group('automatic', () {
    test('reads a JSON feed with price keys and a currency', () {
      const body =
          '{"offers":[{"price":"1.10","currency":"USD"},'
          '{"rate":0.9},{"price":0},{"name":"x","price":{"a":1}}],"n":[1]}';
      final offers = findOffers(body, auto());
      expect(offers.map((o) => o.amount), [d('1.10'), d('0.9')]);
      expect(offers.first.currency, 'USD');
      expect(offers.last.currency, isNull);
    });

    test('reads prices stated with their unit', () {
      const page =
          '<body><p>Kina €1.25 / 1M</p>\n<p>Bulk: 9,50 USD per 10M</p>\n'
          '<p>£1.5 for B</p>\n<p>0 / M</p></body>';
      final offers = findOffers(page, auto());
      expect(offers.map((o) => o.amount), [d('1.25'), d('9.5'), d('1.5')]);
      expect(offers.map((o) => o.currency), ['EUR', 'USD', 'GBP']);
      expect(offers.map((o) => o.unitMillions), [d('1'), d('10'), d('1000')]);
    });

    test('falls back to structured page data', () {
      const page = '''
<html><head>
<script type="application/ld+json">{"offers":{"price":"2.10","priceCurrency":"EUR"}}</script>
<script type="application/ld+json">not json</script>
<meta property="product:price:amount" content="3.30">
<meta property="product:price:currency" content="GBP">
<meta property="product:price:amount" content="oops">
</head><body>
<span itemprop="price" content="4.40"></span>
<span itemprop="priceCurrency" content="USD"></span>
<span itemprop="price">none</span>
</body></html>''';
      final offers = findOffers(page, auto());
      expect(offers.map((o) => o.amount), [d('2.10'), d('4.40'), d('3.30')]);
      expect(offers.map((o) => o.currency), ['EUR', 'USD', 'GBP']);
    });

    test('a page that only looks like JSON is read as a page', () {
      expect(
        () => findOffers('{ not json </p>', auto()),
        throwsA(
          isA<SourceReadException>().having(
            (e) => e.message,
            'message',
            startsWith('No price found'),
          ),
        ),
      );
    });

    test('a page without prices is an error', () {
      expect(
        () => findOffers('<p>hello</p>', auto()),
        throwsA(isA<SourceReadException>()),
      );
      expect(const SourceReadException('x').toString(), 'x');
    });
  });
}
