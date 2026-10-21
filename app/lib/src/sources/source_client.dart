import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kina_app/src/sources/price_extractor.dart';

/// Downloads a seller's page or data feed. Only runs when the user asks for
/// a price, never in the background.
class SourceClient {
  /// Creates a client. Pass [client] in tests.
  SourceClient({http.Client? client}) : _client = client ?? http.Client();

  /// The largest page that is read.
  static const int maxBytes = 2 * 1024 * 1024;

  final http.Client _client;

  /// Returns the text at [address]. Throws [SourceReadException] for a bad
  /// address, a network error, a non-200 reply or an oversized page.
  Future<String> get(String address) async {
    final uri = Uri.tryParse(address.trim());
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        uri.host.isEmpty) {
      throw const SourceReadException(
        'Enter a web address starting with https://',
      );
    }
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: {'User-Agent': 'KinaCalculator'})
          .timeout(const Duration(seconds: 12));
    } on Exception catch (e) {
      throw SourceReadException('Could not connect: $e');
    }
    if (response.statusCode != 200) {
      throw SourceReadException('HTTP ${response.statusCode}');
    }
    if (response.bodyBytes.length > maxBytes) {
      throw const SourceReadException('That page is too large to read');
    }
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }
}
