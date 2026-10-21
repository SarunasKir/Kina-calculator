import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kina_app/src/rates/rate_sync.dart';

FrankfurterClient clientReplying(
  int status,
  String body, {
  void Function(http.Request)? onRequest,
}) => FrankfurterClient(
  client: MockClient((request) async {
    onRequest?.call(request);
    return http.Response(body, status);
  }),
);

const codes = ['EUR', 'USD', 'GBP'];

void main() {
  test('reads rates and date, asking only for non-EUR codes', () async {
    late Uri asked;
    final rates = await clientReplying(
      200,
      '{"date":"2026-10-20","rates":{"USD":1.0823,"GBP":0.8412,"JPY":160}}',
      onRequest: (r) => asked = r.url,
    ).latest(codes);
    expect(asked.queryParameters, {'base': 'EUR', 'symbols': 'USD,GBP'});
    expect(asked.host, 'api.frankfurter.dev');
    expect(rates.date, '2026-10-20');
    expect(rates.perEur, {
      'USD': Decimal.parse('1.0823'),
      'GBP': Decimal.parse('0.8412'),
    });
  });

  Future<void> expectFailure(FrankfurterClient client, String message) =>
      expectLater(
        client.latest(codes),
        throwsA(
          isA<RateSyncException>().having(
            (e) => e.toString(),
            'message',
            contains(message),
          ),
        ),
      );

  test('HTTP errors', () => expectFailure(clientReplying(503, ''), 'HTTP 503'));

  test(
    'unreadable body',
    () => expectFailure(clientReplying(200, '<html>'), 'Unreadable'),
  );

  test(
    'unexpected shape',
    () => expectFailure(clientReplying(200, '{"rates":{}}'), 'Unexpected'),
  );

  test('missing or bad rate', () async {
    await expectFailure(
      clientReplying(200, '{"date":"d","rates":{"USD":1.1}}'),
      'Missing GBP',
    );
    await expectFailure(
      clientReplying(200, '{"date":"d","rates":{"USD":1.1,"GBP":0}}'),
      'Missing GBP',
    );
  });

  test('network failure', () async {
    final client = FrankfurterClient(
      client: MockClient((_) => throw const SocketException('offline')),
    );
    await expectFailure(client, 'Could not connect');
  });

  test('default client can be created', () {
    expect(FrankfurterClient(), isA<FrankfurterClient>());
  });
}
