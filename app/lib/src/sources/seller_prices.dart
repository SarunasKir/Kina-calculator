import 'package:decimal/decimal.dart';
import 'package:kina_app/src/calculator/calculator_logic.dart';
import 'package:kina_app/src/format.dart';
import 'package:kina_app/src/sources/price_extractor.dart';
import 'package:kina_app/src/sources/source_client.dart';
import 'package:kina_core/kina_core.dart';
import 'package:kina_data/kina_data.dart';

/// Fetches [seller]'s page and returns its lowest price per 1M Kina in the
/// calculator currency, formatted for the price field. Throws
/// [SourceReadException] when the page cannot be read or converted.
Future<String> fetchSellerPrice(
  SourceClient client,
  CalculatorSettings settings,
  Seller seller,
) async {
  final source = seller.source;
  if (source == null || source.url.trim().isEmpty) {
    throw const SourceReadException('No site address set');
  }
  final offers = findOffers(await client.get(source.url), source);
  final rates = ratesOf(settings);
  final fallbackUnit = parseAmount(source.unitMillions);
  final prices = <Decimal>[];
  for (final offer in offers) {
    final unit = offer.unitMillions ?? fallbackUnit;
    final from = offer.currency != null && rates.rate(offer.currency!) != null
        ? offer.currency!
        : source.currency;
    if (unit <= Decimal.zero) {
      throw const SourceReadException('Set how many millions the price is for');
    }
    if (rates.rate(from) == null) {
      throw SourceReadException(
        'No exchange rate for $from; sync online rates',
      );
    }
    final perMillion = toScale(
      offer.amount.toRational() / unit.toRational(),
      8,
    );
    prices.add(rates.convert(perMillion, from, settings.currency, scale: 4));
  }
  prices.sort();
  return formatInput(prices.first);
}
