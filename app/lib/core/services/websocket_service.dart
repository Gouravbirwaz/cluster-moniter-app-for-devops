import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectDelay = 5;
  Timer? _reconnectTimer;
  String? _currentPath;

  WebSocketService({required this.url});

  Stream<Map<String, dynamic>> get stream {
    _controller ??= StreamController<Map<String, dynamic>>.broadcast();
    return _controller!.stream;
  }
  
  bool get isConnected => _isConnected;

  Future<void> connect(String path) async {
    if (_isConnected && _currentPath == path) return;
    if (_isConnecting) return;
    
    // If path changed, disconnect first
    if (_isConnected && _currentPath != path) {
      await _channel?.sink.close();
      _isConnected = false;
    }
    
    _currentPath = path;
    _isConnecting = true;
    _reconnectTimer?.cancel();
    
    try {
      final wsUri = _buildUri(path);
      final cleanUrl = wsUri.toString().split('#')[0];
      debugPrint('Connecting to WebSocket (Main): $cleanUrl');
      
      final webSocket = await _establishConnection(cleanUrl);
      _channel = IOWebSocketChannel(webSocket);
      
      _isConnecting = false;
      _isConnected = true;
      _reconnectDelay = 5;
      
      _channel?.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            _controller?.add(decoded);
          } catch (e) {
            debugPrint('Error decoding websocket message: $e');
          }
        },
        onDone: () {
          debugPrint('Main WebSocket connection closed: $cleanUrl');
          _isConnected = false;
          _isConnecting = false;
          _scheduleReconnect(path);
        },
        onError: (error) {
          _isConnected = false;
          _isConnecting = false;
          debugPrint('Main WebSocket error: $error');
          _scheduleReconnect(path);
        },
      );
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      debugPrint('Main WebSocket handshake failed: $e');
      _scheduleReconnect(path);
    }
  }

  /// Creates a dedicated, non-managed stream for high-volume logs or specific features.
  /// Caller is responsible for closing the StreamSubscription.
  Future<Stream<Map<String, dynamic>>> createStandaloneStream(String path) async {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    
    try {
      final wsUri = _buildUri(path);
      final cleanUrl = wsUri.toString().split('#')[0];
      debugPrint('Connecting to Standalone WebSocket: $cleanUrl');
      
      final webSocket = await _establishConnection(cleanUrl);
      final channel = IOWebSocketChannel(webSocket);
      
      channel.stream.listen(
        (data) {
          try {
            controller.add(jsonDecode(data as String));
          } catch (_) {}
        },
        onDone: () => controller.close(),
        onError: (_) => controller.close(),
      );
      
      return controller.stream;
    } catch (e) {
      debugPrint('Standalone WebSocket failure: $e');
      controller.addError(e);
      await controller.close();
      rethrow;
    }
  }

  Uri _buildUri(String path) {
    String sanitizedBase = url.trim().split('#')[0];
    if (sanitizedBase.endsWith('/')) {
      sanitizedBase = sanitizedBase.substring(0, sanitizedBase.length - 1);
    }

    final uri = Uri.parse(sanitizedBase);
    final wsScheme = uri.isScheme('https') ? 'wss' : 'ws';
    
    return Uri(
      scheme: wsScheme,
      host: uri.host,
      port: (uri.port == 443 || uri.port == 80 || uri.port == 0) ? null : uri.port,
      path: path.split('#')[0].startsWith('/') ? path.split('#')[0] : '/${path.split('#')[0]}',
    );
  }

  Future<WebSocket> _establishConnection(String cleanUrl) async {
    final webSocket = await WebSocket.connect(
      cleanUrl,
      headers: {
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'Flutter-K8s-Monitor-Client',
      },
    ).timeout(const Duration(seconds: 15));
    
    webSocket.pingInterval = const Duration(seconds: 20);
    return webSocket;
  }

  // Helper to notify listeners of connection status changes if needed
  void notifyListeners() {
    // In a real app, you might want to wrap this service in a ChangeNotifier 
    // or use a callback mechanism to update the UI "LIVE" indicator instantly.
  }

  void _scheduleReconnect(String path) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelay), () {
      debugPrint('Attempting to reconnect WebSocket to $path... (Delay: $_reconnectDelay s)');
      
      // Exponential backoff
      _reconnectDelay = (_reconnectDelay * 2).clamp(5, 60);
      
      connect(path);
    });
  }

  void send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _controller?.close();
  }
}
