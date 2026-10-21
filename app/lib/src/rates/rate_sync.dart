import 'dart:convert';

import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Rates published by the ECB on one day.
@immutable
class PublishedRates {
  /// Creates published rates.
  const PublishedRates({required this.date, required this.perEur});

  /// Publication date, `YYYY-MM-DD`.
  final String date;

  /// Units of each currency per 1 EUR.
  final Map<String, Decimal> perEur;
}

/// Thrown when rates cannot be fetched or read.
class RateSyncException implements Exception {
  /// Creates the exception with a short [message].
  const RateSyncException(this.message);

  /// What went wrong, for showing to the user.
  final String message;

  @override
  String toString() => message;
}

/// Fetches the latest ECB rates from Frankfurter (requirement FR-11). This
/// is the only place the app goes online for rates.
class FrankfurterClient {
  /// Creates a client. Pass [client] in tests.
  FrankfurterClient({http.Client? client}) : _client = client ?? http.Client();

  /// The API endpoint, as used by v55.
  static final Uri endpoint = Uri.parse(
    'https://api.frankfurter.dev/v1/latest',
  );

  final http.Client _client;

  /// Returns the latest rates for [codes] against EUR.
  ///
  /// Throws [RateSyncException] on a network error, a non-200 reply, or a
  /// reply that is missing a rate or the date.
  Future<PublishedRates> latest(List<String> codes) async {
    final wanted = codes.where((c) => c != 'EUR').toList();
    final uri = endpoint.replace(
      queryParameters: {'base': 'EUR', 'symbols': wanted.join(',')},
    );
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'User-Agent': 'KinaCalculator'})
          .timeout(const Duration(seconds: 12));
    } on Exception catch (e) {
      throw RateSyncException('Could not connect: $e');
    }
    if (response.statusCode != 200) {
      throw RateSyncException('HTTP ${response.statusCode}');
    }
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw const RateSyncException('Unreadable reply');
    }
    if (body is! Map<String, Object?> ||
        body['date'] is! String ||
        body['rates'] is! Map<String, Object?>) {
      throw const RateSyncException('Unexpected reply');
    }
    final rates = body['rates']! as Map<String, Object?>;
    final perEur = <String, Decimal>{};
    for (final code in wanted) {
      final value = rates[code];
      final rate = value is num ? Decimal.tryParse(value.toString()) : null;
      if (rate == null || rate <= Decimal.zero) {
        throw RateSyncException('Missing $code rate');
      }
      perEur[code] = rate;
    }
    return PublishedRates(date: body['date']! as String, perEur: perEur);
  }
}
