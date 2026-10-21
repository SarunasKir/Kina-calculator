import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:meta/meta.dart';

/// Thrown when a message cannot be decrypted: wrong key, tampering or a
/// malformed message.
class CipherException implements Exception {
  /// Creates the exception.
  const CipherException();

  @override
  String toString() => 'Message could not be decrypted';
}

/// Random bytes from the operating system's secure generator.
List<int> randomBytes(int length, {Random? random}) {
  final source = random ?? Random.secure();
  return List<int>.generate(length, (_) => source.nextInt(256));
}

/// Encrypts and authenticates JSON messages with AES-256-GCM.
///
/// Every message is bound to a context string (who it is for and what it is
/// for), so a message cannot be replayed into another conversation.
@immutable
class SyncCipher {
  /// Creates a cipher from a 32-byte [key].
  const SyncCipher(this.key);

  /// Creates a cipher from a base64 key.
  factory SyncCipher.fromBase64(String key) => SyncCipher(base64Decode(key));

  /// A fresh random key.
  factory SyncCipher.random() => SyncCipher(randomBytes(32));

  /// The raw key.
  final List<int> key;

  /// The key as base64, for storing.
  String get keyBase64 => base64Encode(key);

  static final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypts [message] for [context]. Returns base64 text.
  Future<String> seal(Map<String, Object?> message, String context) async {
    final box = await _algorithm.encrypt(
      utf8.encode(jsonEncode(message)),
      secretKey: SecretKey(key),
      aad: utf8.encode(context),
    );
    return base64Encode(box.concatenation());
  }

  /// Decrypts [sealed] for [context]. Throws [CipherException] if it was not
  /// made with this key and context.
  Future<Map<String, Object?>> open(String sealed, String context) async {
    try {
      final box = SecretBox.fromConcatenation(
        base64Decode(sealed),
        nonceLength: _algorithm.nonceLength,
        macLength: _algorithm.macAlgorithm.macLength,
      );
      final clear = await _algorithm.decrypt(
        box,
        secretKey: SecretKey(key),
        aad: utf8.encode(context),
      );
      return jsonDecode(utf8.decode(clear)) as Map<String, Object?>;
    } on Object {
      throw const CipherException();
    }
  }
}
