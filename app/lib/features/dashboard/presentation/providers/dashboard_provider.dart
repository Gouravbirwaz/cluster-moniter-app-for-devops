import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/websocket_service.dart';

class DashboardProvider with ChangeNotifier {
  final ApiClient apiClient;
  final WebSocketService? webSocketService;
  
  Map<String, dynamic>? _overview;
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;
  Timer? _debounceTimer;
  StreamSubscription? _subscription;

  DashboardProvider({required this.apiClient, this.webSocketService}) {
    _initWebSocket();
  }

  Map<String, dynamic>? get overview => _overview;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isWebSocketConnected => webSocketService?.isConnected ?? false;

  void _initWebSocket() {
    _subscription = webSocketService?.stream.listen((event) {
      if (event['type'] == 'METRIC_EVENT') {
        final data = event['data'];
        if (_overview != null && data != null) {
          // Merge metrics directly into local state for instant update
          _overview!['cpu_usage'] = data['cpu_usage'];
          _overview!['memory_usage'] = data['memory_usage'];
          _overview!['running_pods'] = data['running_pods'];
          _overview!['failed_pods'] = data['failed_pods'];
          notifyListeners();
        }
      } else if (event['type'] == 'NODE_EVENT' || 
                 event['type'] == 'POD_EVENT' || 
                 event['type'] == 'CLUSTER_EVENT') {
        _debounceFetch();
      }
    });
  }

  void _debounceFetch() {
    if (_debounceTimer?.isActive ?? false) return;
    
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      fetchOverview();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOverview() async {
    if (_isFetching) return;
    _isFetching = true;

    // Only show full loading if we have no data yet
    if (_overview == null) {
      _isLoading = true;
      notifyListeners();
    }
    
    _error = null;

    try {
      final data = await apiClient.get('/api/v1/cluster/overview');
      _overview = data;
      _isLoading = false;
      _error = null;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }
}
