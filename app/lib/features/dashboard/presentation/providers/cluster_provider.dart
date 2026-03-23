import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';

class ClusterConfig {
  final String id;
  final String name;
  final String? prometheusUrl;
  final String? description;

  ClusterConfig({
    required this.id,
    required this.name,
    this.prometheusUrl,
    this.description,
  });

  factory ClusterConfig.fromJson(Map<String, dynamic> json) {
    return ClusterConfig(
      id: json['id'],
      name: json['name'],
      prometheusUrl: json['prometheus_url'],
      description: json['description'],
    );
  }
}

class ClusterProvider with ChangeNotifier {
  final ApiClient apiClient;
  
  List<ClusterConfig> _clusters = [];
  ClusterConfig? _selectedCluster;
  bool _isLoading = false;
  String? _error;

  ClusterProvider({required this.apiClient}) {
    fetchClusters();
  }

  List<ClusterConfig> get clusters => _clusters;
  ClusterConfig? get selectedCluster => _selectedCluster;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasClusters => _clusters.isNotEmpty;

  Future<void> fetchClusters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<dynamic> data = await apiClient.get('/api/v1/clusters');
      _clusters = data.map((json) => ClusterConfig.fromJson(json)).toList();
      
      if (_clusters.isNotEmpty && _selectedCluster == null) {
        _selectedCluster = _clusters.first;
      }
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> addCluster({
    required String name,
    required String kubeconfig,
    String? prometheusUrl,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.post('/api/v1/clusters', data: {
        'name': name,
        'kubeconfig': kubeconfig,
        'prometheus_url': prometheusUrl,
        'description': description,
      });
      await fetchClusters();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> selectCluster(ClusterConfig cluster) async {
    _isLoading = true;
    notifyListeners();

    try {
      await apiClient.post('/api/v1/clusters/${cluster.name}/activate');
      _selectedCluster = cluster;
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
