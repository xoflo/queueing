import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'globals.dart';

class NodeSocketService {
  static final NodeSocketService _instance = NodeSocketService._internal();
  factory NodeSocketService() => _instance;
  NodeSocketService._internal();

  late WebSocketChannel _channel;
  late Stream _broadcast;
  StreamSubscription? _subscription; // ✅ Add this
  bool _isConnected = false;
  Timer? _reconnectTimer;

  WebSocketChannel get channel => _channel;
  Stream get stream => _broadcast;
  bool get isConnected => _isConnected;

  void connect({BuildContext? context}) {
    // ❌ Don't rely only on `_isConnected`
    if (_subscription != null) {
      print("🛑 Already listening. Skipping connect().");
      return;
    }

    final url = 'ws://${site.toString().split(":")[0]}:3000';
    print("🔌 Connecting to $url");

    _channel = kIsWeb
        ? WebSocketChannel.connect(Uri.parse(url))
        : IOWebSocketChannel.connect(url);

    _broadcast = _channel.stream.asBroadcastStream();

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _subscription = _broadcast.listen(
          (message) {
        _isConnected = true;

        final json = jsonDecode(message);
        final type = json['type'];
        final data = json['data'];

        if (type == 'ping') {
          print("📡 Ping: $data");
          if (context != null) _connected(context);
        }
      },
      onDone: () {
        _handleDisconnect(context, reason: "❌ Disconnected");
      },
      onError: (err) {
        _handleDisconnect(context, reason: "⚠️ Error: $err");
      },
      cancelOnError: true,
    );
  }

  void _handleDisconnect(BuildContext? context, {required String reason}) {
    _isConnected = false;
    print(reason);

    _subscription?.cancel();
    _subscription = null;

    _channel.sink.close();
    _tryReconnect(context);
  }

  void _tryReconnect([BuildContext? context]) {
    if (_reconnectTimer != null) return;

    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (!_isConnected) {
        print("🔁 Trying to reconnect...");
        if (context != null) _reconnecting(context);
        connect(context: context);
      } else {
        print("✅ Reconnected");
        if (context != null) _connected(context);
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
      }
    });
  }

  void sendMessage(String type, dynamic data) {
    if (_isConnected) {
      final msg = jsonEncode({'type': type, 'data': data});
      _channel.sink.add(msg);
    }
  }

  void sendBatch(List<Map<String, dynamic>> data) {
    if (_isConnected) {
      final msg = jsonEncode({'batch': data});
      print(msg);
      _channel.sink.add(msg);
    }
  }

  void _connected(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text("Connected to Server."),
      ),
    );
  }

  void _reconnecting(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orangeAccent,
        content: Text("Connecting to Server..."),
      ),
    );
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _channel.sink.close();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isConnected = false;
  }
}

