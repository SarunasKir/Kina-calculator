import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:kina_data/kina_data.dart';
import 'package:meta/meta.dart';

/// One price found on a page.
@immutable
class PriceOffer {
  /// Creates an offer.
  const PriceOffer({
    required this.amount,
    required this.where,
    this.currency,
    this.unitMillions,
  });

  /// The price as written on the page.
  final Decimal amount;

  /// Where on the page it was found, for messages.
  final String where;

  /// The currency the page states, if it states one.
  final String? currency;

  /// How many millions of Kina the price is for, if the page states it.
  final Decimal? unitMillions;
}

/// Thrown when a page cannot be read or holds no price.
class SourceReadException implements Exception {
  /// Creates the exception with a short [message].
  const SourceReadException(this.message);

  /// What went wrong, for showing to the user.
  final String message;

  @override
  String toString() => message;
}

/// Reads a price from [text] such as `1,234.50`, `1.234,50` or `1.25`.
/// With both separators the last one is the decimal point; a lone separator
/// is a decimal point; a repeated one groups thousands.
Decimal? parsePriceNumber(String text) {
  final match = RegExp(r'\d[\d.,\s]*').firstMatch(text);
  if (match == null) {
    return null;
  }
  var digits = match.group(0)!.replaceAll(RegExp(r'\s'), '');
  digits = digits.replaceAll(RegExp(r'[.,]+$'), '');
  final lastDot = digits.lastIndexOf('.');
  final lastComma = digits.lastIndexOf(',');
  final decimalAt = lastDot > lastComma ? lastDot : lastComma;
  if (decimalAt < 0) {
    return Decimal.tryParse(digits);
  }
  final separator = digits[decimalAt];
  final other = separator == '.' ? ',' : '.';
  final repeated = separator.allMatches(digits).length > 1;
  final grouped = digits.replaceAll(other, '');
  if (repeated) {
    return Decimal.tryParse(grouped.replaceAll(separator, ''));
  }
  return Decimal.tryParse(grouped.replaceAll(separator, '.'));
}

const _currencySymbols = {'€': 'EUR', r'$': 'USD', '£': 'GBP'};

final _priceKeys = RegExp(
  r'^(price|lowprice|rate|cost|priceperm|pricepermillion)$',
  caseSensitive: false,
);

/// Finds the prices a page offers for Kina, using the way [source] says to
/// read it. Throws [SourceReadException] when nothing usable is found.
List<PriceOffer> findOffers(String body, PriceSource source) {
  final offers = switch (source.kind) {
    SourceKind.json => _fromJsonPath(body, source.rule),
    SourceKind.css => _fromSelector(body, source.rule),
    SourceKind.auto => _guess(body),
  };
  final usable = offers.where((o) => o.amount > Decimal.zero).toList();
  if (usable.isEmpty) {
    throw SourceReadException(
      source.kind == SourceKind.auto
          ? 'No price found on that page. Try a selector or a JSON address.'
          : 'Nothing matched "${source.rule}"',
    );
  }
  return usable;
}

Object? _decode(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    throw const SourceReadException('That address does not return JSON');
  }
}

List<PriceOffer> _fromJsonPath(String body, String rule) {
  var node = _decode(body);
  for (final step in RegExp(r'[^.\[\]]+|\[\d+\]').allMatches(rule)) {
    final token = step.group(0)!;
    if (token.startsWith('[')) {
      final i = int.parse(token.substring(1, token.length - 1));
      node = node is List<Object?> && i < node.length ? node[i] : null;
    } else {
      node = node is Map<String, Object?> ? node[token] : null;
    }
  }
  final amount = _number(node);
  return [if (amount != null) PriceOffer(amount: amount, where: rule)];
}

List<PriceOffer> _fromSelector(String body, String rule) {
  final Iterable<Element> found;
  try {
    found = html.parse(body).querySelectorAll(rule);
  } on FormatException {
    throw SourceReadException('"$rule" is not a valid selector');
  }
  return [
    for (final e in found)
      if (parsePriceNumber(e.attributes['content'] ?? e.text)
          case final amount?)
        PriceOffer(amount: amount, where: rule),
  ];
}

Decimal? _number(Object? value) => switch (value) {
  num() => Decimal.tryParse(value.toString()),
  String() => parsePriceNumber(value),
  _ => null,
};

List<PriceOffer> _guess(String body) {
  final head = body.trimLeft();
  if (head.startsWith('{') || head.startsWith('[')) {
    try {
      return _walk(jsonDecode(head), r'$');
    } on FormatException {
      // Not JSON after all; read it as a page.
    }
  }
  final document = html.parse(body);
  final text = document.body?.text ?? '';
  final stated = _statedUnitPrices(text);
  if (stated.isNotEmpty) {
    return stated;
  }
  final offers = <PriceOffer>[];
  for (final script in document.querySelectorAll(
    'script[type="application/ld+json"]',
  )) {
    try {
      offers.addAll(_walk(jsonDecode(script.text), 'JSON-LD'));
    } on FormatException {
      continue;
    }
  }
  for (final e in document.querySelectorAll('[itemprop=price]')) {
    final amount = _number(e.attributes['content'] ?? e.text);
    if (amount != null) {
      final currency = document
          .querySelector('[itemprop=priceCurrency]')
          ?.attributes['content'];
      offers.add(
        PriceOffer(amount: amount, where: 'itemprop', currency: currency),
      );
    }
  }
  for (final e in document.querySelectorAll(
    'meta[property="product:price:amount"]',
  )) {
    final amount = _number(e.attributes['content']);
    if (amount != null) {
      offers.add(
        PriceOffer(
          amount: amount,
          where: 'meta',
          currency: document
              .querySelector('meta[property="product:price:currency"]')
              ?.attributes['content'],
        ),
      );
    }
  }
  return offers;
}

List<PriceOffer> _walk(Object? node, String path) {
  final offers = <PriceOffer>[];
  if (node is Map<String, Object?>) {
    final currency = (node['priceCurrency'] ?? node['currency']) is String
        ? (node['priceCurrency'] ?? node['currency'])! as String
        : null;
    for (final entry in node.entries) {
      final value = entry.value;
      if (_priceKeys.hasMatch(entry.key) && value is! Map && value is! List) {
        final amount = _number(value);
        if (amount != null) {
          offers.add(
            PriceOffer(
              amount: amount,
              where: '$path.${entry.key}',
              currency: currency,
            ),
          );
        }
      } else {
        offers.addAll(_walk(value, '$path.${entry.key}'));
      }
    }
  } else if (node is List<Object?>) {
    for (var i = 0; i < node.length; i++) {
      offers.addAll(_walk(node[i], '$path[$i]'));
    }
  }
  return offers;
}

final _statedUnit = RegExp(
  r'(€|\$|£|EUR|USD|GBP)?\s?(\d[\d.,]*)\s?(€|\$|£|EUR|USD|GBP)?'
  r'\s?(?:/|per|for)\s?(\d+)?\s?([MB])\b',
  caseSensitive: false,
);

/// Prices written with their unit, such as "€1.25 / 1M" or "$9 per 10M".
List<PriceOffer> _statedUnitPrices(String text) {
  final offers = <PriceOffer>[];
  for (final m in _statedUnit.allMatches(text)) {
    final amount = parsePriceNumber(m.group(2)!);
    if (amount == null) {
      continue;
    }
    final symbol = (m.group(1) ?? m.group(3))?.toUpperCase();
    final count = Decimal.parse(m.group(4) ?? '1');
    final unit = m.group(5)!.toUpperCase() == 'B'
        ? count * Decimal.fromInt(1000)
        : count;
    offers.add(
      PriceOffer(
        amount: amount,
        where: m.group(0)!.trim(),
        currency: _currencySymbols[symbol] ?? symbol,
        unitMillions: unit,
      ),
    );
  }
  return offers;
}
