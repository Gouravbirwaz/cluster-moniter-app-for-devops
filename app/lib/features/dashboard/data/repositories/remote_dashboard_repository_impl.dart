import '../../domain/entities/cluster_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/network/api_client.dart';

class RemoteDashboardRepositoryImpl implements DashboardRepository {
  final ApiClient apiClient;

  RemoteDashboardRepositoryImpl({required this.apiClient});

  @override
  Future<List<ClusterEntity>> getClusters() async {
    final List<dynamic> data = await apiClient.get('/clusters');
    return data.map((json) => ClusterEntity(
      id: json['id'],
      name: json['name'],
      region: json['region'],
      status: _parseStatus(json['status']),
      totalNodes: json['totalNodes'],
      activeAlerts: json['activeAlerts'],
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
    )).toList();
  }

  ClusterStatus _parseStatus(String status) {
    switch (status) {
      case 'healthy': return ClusterStatus.healthy;
      case 'degraded': return ClusterStatus.degraded;
      case 'critical': return ClusterStatus.critical;
      default: return ClusterStatus.healthy;
    }
  }
}
