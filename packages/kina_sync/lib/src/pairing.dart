import 'dart:convert';

import 'package:kina_sync/src/cipher.dart';
import 'package:meta/meta.dart';

/// Prefix of the pairing code shown by the hub.
const pairingPrefix = 'kina1:';

/// What a phone needs to pair with a hub. It is shown as a QR code and as
/// text, and its secret works only once and only for a few minutes.
@immutable
class PairingOffer {
  /// Creates an offer.
  const PairingOffer({
    required this.hubId,
    required this.addresses,
    required this.port,
    required this.secret,
  });

  /// Reads an offer from a pairing code. Throws [FormatException] if [code]
  /// is not a Kina pairing code.
  factory PairingOffer.parse(String code) {
    final trimmed = code.trim();
    if (!trimmed.startsWith(pairingPrefix)) {
      throw const FormatException('This is not a Kina pairing code');
    }
    try {
      final json =
          jsonDecode(
                utf8.decode(
                  base64Url.decode(
                    base64Url.normalize(
                      trimmed.substring(pairingPrefix.length),
                    ),
                  ),
                ),
              )
              as Map<String, Object?>;
      return PairingOffer(
        hubId: json['hub']! as String,
        addresses: [
          for (final a in json['addresses']! as List<Object?>) a! as String,
        ],
        port: json['port']! as int,
        secret: base64Decode(json['secret']! as String),
      );
    } on Object {
      throw const FormatException('This pairing code is damaged');
    }
  }

  /// A fresh offer for [hubId] reachable at [addresses] and [port].
  factory PairingOffer.create({
    required String hubId,
    required List<String> addresses,
    required int port,
  }) => PairingOffer(
    hubId: hubId,
    addresses: addresses,
    port: port,
    secret: randomBytes(32),
  );

  /// The hub's id.
  final String hubId;

  /// Addresses the hub can be reached at on the local network.
  final List<String> addresses;

  /// The hub's port.
  final int port;

  /// The one-time secret.
  final List<int> secret;

  /// The cipher for the pairing conversation.
  SyncCipher get cipher => SyncCipher(secret);

  /// The pairing code: text for the QR code.
  String get code =>
      pairingPrefix +
      base64Url.encode(
        utf8.encode(
          jsonEncode({
            'hub': hubId,
            'addresses': addresses,
            'port': port,
            'secret': base64Encode(secret),
          }),
        ),
      );
}
