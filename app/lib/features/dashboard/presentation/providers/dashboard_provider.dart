import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  Timer? _pollingTimer;
  StreamSubscription? _subscription;

  final List<double> _cpuHistory = [];
  final List<double> _memoryHistory = [];
  final List<FlSpot> _cpuSpots = [];
  final List<FlSpot> _memorySpots = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _topPods = [];
  static const int _maxHistoryLength = 20;

  DashboardProvider({required this.apiClient, this.webSocketService}) {
    _initWebSocket();
    // Ensure connection is active - using the monitor endpoint for in-memory updates
    webSocketService?.connect('/api/v1/ws/monitor');
    _startPolling();
  }

  Map<String, dynamic>? get overview => _overview;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isWebSocketConnected => webSocketService?.isConnected ?? false;
  List<double> get cpuHistory => List.unmodifiable(_cpuHistory);
  List<double> get memoryHistory => List.unmodifiable(_memoryHistory);
  List<FlSpot> get cpuSpots => List.unmodifiable(_cpuSpots);
  List<FlSpot> get memorySpots => List.unmodifiable(_memorySpots);
  List<Map<String, dynamic>> get events => List.unmodifiable(_events);
  List<Map<String, dynamic>> get topPods => List.unmodifiable(_topPods);

  void _initWebSocket() {
    _subscription?.cancel();
    _subscription = webSocketService?.stream.listen((event) {
      try {
        final String type = (event['type'] ?? '').toString().toLowerCase();
        
        if (type == 'metric_event') {
          final data = event['data'];
          if (data != null) {
            _overview = Map<String, dynamic>.from(data);
            
            _updateHistory(
              (data['cpu_usage'] as num).toDouble(),
              (data['memory_usage'] as num).toDouble(),
            );
            
            notifyListeners();
          }
        } else if (type == 'pod_failure' || type == 'node_failure' || type == 'github_event' || type == 'cluster_event' || type == 'pod_event' || type == 'node_event') {
          // Add event to local list
          _events.insert(0, Map<String, dynamic>.from(event));
          if (_events.length > 50) _events.removeLast();
          
          _debounceFetch();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error processing dashboard websocket event: $e');
      }
    }, onError: (err) {
      debugPrint('Dashboard WebSocket stream error: $err');
    }, onDone: () {
      debugPrint('Dashboard WebSocket stream closed');
    });
  }


  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isWebSocketConnected) {
        fetchOverview();
      }
    });
  }

  void _updateHistory(double cpu, double memory) {
    _cpuHistory.add(cpu);
    _memoryHistory.add(memory);
    
    if (_cpuHistory.length > _maxHistoryLength) {
      _cpuHistory.removeAt(0);
    }
    if (_memoryHistory.length > _maxHistoryLength) {
      _memoryHistory.removeAt(0);
    }

    _cpuSpots.clear();
    _cpuSpots.addAll(_cpuHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)));
    
    _memorySpots.clear();
    _memorySpots.addAll(_memoryHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)));
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
    _pollingTimer?.cancel();
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
      // Fetch cluster metrics and events in parallel
      final results = await Future.wait([
        apiClient.get('/api/v1/metrics/cluster'),
        apiClient.get('/api/v1/metrics/events').catchError((e) {
          debugPrint('Error fetching events: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      final data = results[0] as Map<String, dynamic>;
      final eventsData = results[1];

      _overview = data;
      
      if (eventsData is List) {
        _events = eventsData
            .where((e) => (e['type'] ?? '').toString().toLowerCase() != 'metric_event')
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      
      _updateHistory(
        (data['cpu_usage'] as num).toDouble(),
        (data['memory_usage'] as num).toDouble(),
      );
      
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
