import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:fluttertoast/fluttertoast.dart'; // ✅ Add this

import 'globals.dart';

class NodeSocketService {
  static final NodeSocketService _instance = NodeSocketService._internal();
  factory NodeSocketService() => _instance;
  NodeSocketService._internal();

  late WebSocketChannel _channel;
  late Stream _broadcast;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  WebSocketChannel get channel => _channel;
  Stream get stream => _broadcast;
  bool get isConnected => _isConnected;

  void connect({BuildContext? context}) {
    if (_subscription != null) {
      print("🛑 Already listening. Skipping connect().");
      return;
    }

    final url = 'ws://${site.toString().split(":")[0]}:3000';
    print("🔌 Connecting to $url");

    _channel = kIsWeb
        ? WebSocketChannel.connect(Uri.parse(url))
        : IOWebSocketChannel.connect(url, pingInterval: Duration(seconds: 10));

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
          _connected(); // 🔄 context no longer needed for this
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

    _reconnectTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (!_isConnected) {
        print("🔁 Trying to reconnect...");
        await clearCache();
        _reconnecting(); // 🔄 no context needed
        connect(context: context);
      } else {
        print("✅ Reconnected");
        _connected();
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

  void _connected() {
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
    _channel.sink.close();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isConnected = false;
  }
}
