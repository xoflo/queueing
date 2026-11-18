import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'globals.dart';

class NodeSocketService {
  static final NodeSocketService _instance = NodeSocketService._internal();
  factory NodeSocketService() => _instance;
  NodeSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  DateTime? _lastMessageTime;
  bool _isConnected = false;

  // The server sends a {"type":"hb"} message every 10s. The stale-connection
  // watchdog only runs once this connection has actually received one, so it
  // can never drop a healthy-but-quiet connection, and it stays harmless
  // against an older server.js that does not send heartbeats yet.
  bool _serverHasHeartbeat = false;

  // How long without any message before we assume the connection is dead
  static const Duration _staleTimeout = Duration(seconds: 30);

  // 🔑 Persistent broadcast controller
  final StreamController<String> _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;
  bool get isConnected => _isConnected;

  void connect({BuildContext? context}) {
    _subscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}

    _isConnected = false;
    _serverHasHeartbeat = false;

    final url = 'ws://${site.toString().split(":")[0]}:3000';
    print("Connecting to $url");

    _channel = kIsWeb
        ? WebSocketChannel.connect(Uri.parse(url))
        : IOWebSocketChannel.connect(
      url,
      pingInterval: const Duration(seconds: 10),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _lastMessageTime = DateTime.now();
    _startWatchdog(context);

    _subscription = _channel!.stream.listen(
          (message) {
        final wasConnected = _isConnected;
        _isConnected = true;
        _lastMessageTime = DateTime.now();

        try {
          final json = jsonDecode(message);

          // Heartbeat: proves the connection is alive. Not passed to screens.
          if (json['type'] == 'hb') {
            _serverHasHeartbeat = true;
            return;
          }

          _controller.add(message); // ✅ push into broadcast

          if (json['type'] == 'ping') {
            print("📡 Ping: ${json['data']}");
            if (!wasConnected) {
              _connected(); // only announce on reconnect
              // Tell every screen to re-sync its state with the server.
              _controller.add(jsonEncode({'type': 'reconnected', 'data': null}));
            }
          }
        } catch (e) {
          print("JSON parse error: $e");
        }
      },
      onDone: () {
        _handleDisconnect(context, reason: "Disconnected");
      },
      onError: (err) {
        _handleDisconnect(context, reason: "Error: $err");
      },
      cancelOnError: true,
    );
  }

  // Force a reconnect if the server's heartbeat stops arriving.
  // Catches silently-dead sockets that never fire onDone/onError.
  void _startWatchdog(BuildContext? context) {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_lastMessageTime == null) return;
      if (!_serverHasHeartbeat) return;
      final silentFor = DateTime.now().difference(_lastMessageTime!);
      if (silentFor > _staleTimeout) {
        print("⚠️ No messages for ${silentFor.inSeconds}s, assuming dead connection");
        _watchdogTimer?.cancel();
        _watchdogTimer = null;
        _handleDisconnect(context, reason: "Stale connection (watchdog)");
      }
    });
  }

  void _handleDisconnect(BuildContext? context, {required String reason}) {
    _isConnected = false;
    print(reason);

    _watchdogTimer?.cancel();
    _watchdogTimer = null;

    _subscription?.cancel();
    _subscription = null;

    try {
      _channel?.sink.close();
    } catch (_) {}

    _tryReconnect(context);
  }

  void _tryReconnect([BuildContext? context]) {
    if (_reconnectTimer != null) return;

    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isConnected) {
        _reconnecting();
        connect(context: context);
      } else {
        _connected();
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      }
    });
  }

  // Returns true if the message was sent. When offline the message is NOT
  // sent (it would be stale by the time we reconnect), so the person is told.
  bool sendMessage(String type, dynamic data) {
    if (_isConnected && _channel != null) {
      final msg = jsonEncode({'type': type, 'data': data});
      _channel!.sink.add(msg);
      return true;
    }
    return false;
  }

  bool sendBatch(List<Map<String, dynamic>> data) {
    if (_isConnected && _channel != null) {
      final msg = jsonEncode({'batch': data});
      _channel!.sink.add(msg);
      return true;
    }
    _notSent();
    return false;
  }

  void _notSent() {
    Fluttertoast.showToast(
      msg: "Offline - that action was NOT sent. Wait for 'Connected' and try again.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 18.0,
    );
  }

  void _connected() {
    sendMessage('refresh', {});
    Fluttertoast.showToast(
      msg: "Connected to Server.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _reconnecting() {
    Fluttertoast.showToast(
      msg: "Reconnecting to Server...",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _isConnected = false;
  }
}