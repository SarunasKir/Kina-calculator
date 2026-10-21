import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The UDP port hubs listen on for "where are you" calls.
const discoveryPort = 47822;

const _question = 'KINA?';

/// Answers "where are you" calls on the local network, so phones can find
/// the hub again after its address changes.
class DiscoveryResponder {
  /// Creates a responder that tells callers the hub's [hubId] and [hubPort].
  DiscoveryResponder({
    required this.hubId,
    required this.hubPort,
    this.port = discoveryPort,
  });

  /// The hub's id.
  final String hubId;

  /// The port the sync server listens on.
  final int hubPort;

  /// The UDP port to listen on.
  final int port;

  RawDatagramSocket? _socket;

  /// The port actually listened on, once started.
  int? get boundPort => _socket?.port;

  /// Starts listening.
  Future<void> start() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket = socket;
    socket.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }
      final packet = socket.receive();
      if (packet != null &&
          utf8.decode(packet.data, allowMalformed: true) == _question) {
        socket.send(
          utf8.encode(jsonEncode({'hub': hubId, 'port': hubPort})),
          packet.address,
          packet.port,
        );
      }
    });
  }

  /// Stops listening.
  void stop() {
    _socket?.close();
    _socket = null;
  }
}

/// Where a hub answered from.
typedef FoundHub = ({String address, int port});

/// Asks the local network for the hub with [hubId] and returns where it
/// answered from, or null if nothing answered within [timeout].
///
/// [target] is where to send the question: the broadcast address by default.
Future<FoundHub?> discoverHub(
  String hubId, {
  Duration timeout = const Duration(seconds: 2),
  InternetAddress? target,
  int port = discoveryPort,
}) async {
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  final found = Completer<FoundHub?>();
  socket.broadcastEnabled = true;
  final sub = socket.listen((event) {
    if (event != RawSocketEvent.read || found.isCompleted) {
      return;
    }
    final packet = socket.receive();
    if (packet == null) {
      return;
    }
    try {
      final json = jsonDecode(utf8.decode(packet.data)) as Map<String, Object?>;
      if (json['hub'] == hubId) {
        found.complete((
          address: packet.address.address,
          port: json['port']! as int,
        ));
      }
    } on Object {
      // Not a hub answer; keep waiting.
    }
  });
  socket.send(
    utf8.encode(_question),
    target ?? InternetAddress('255.255.255.255'),
    port,
  );
  final result = await found.future.timeout(timeout, onTimeout: () => null);
  await sub.cancel();
  socket.close();
  return result;
}
