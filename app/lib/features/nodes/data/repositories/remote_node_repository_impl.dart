import '../../domain/entities/node_entity.dart';
import '../../domain/repositories/node_repository.dart';
import '../../../../core/network/api_client.dart';

class RemoteNodeRepositoryImpl implements NodeRepository {
  final ApiClient apiClient;

  RemoteNodeRepositoryImpl({required this.apiClient});

  @override
  Future<List<NodeEntity>> getNodes(String clusterId) async {
    final List<dynamic> data = await apiClient.get('/api/v1/nodes');
    return data.map((json) => NodeEntity(
      id: json['id'],
      name: json['name'],
      clusterId: clusterId, // Backend might not return it, so we use passed one
      status: _parseStatus(json['status'] ?? 'unknown'),
      role: json['role'] ?? 'worker',
      version: json['version'] ?? 'unknown',
      cpuUsage: (json['cpu_usage_pct'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (json['memory_usage_pct'] as num?)?.toDouble() ?? 0.0,
      diskPressure: json['disk_pressure'] == true,
      networkIo: (json['network_io'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }

  @override
  Future<NodeEntity> getNodeDetails(String clusterId, String nodeId) async {
    final nodes = await getNodes(clusterId);
    return nodes.firstWhere((n) => n.id == nodeId);
  }

  NodeStatus _parseStatus(String status) {
    switch (status) {
      case 'ready': return NodeStatus.ready;
      case 'notReady': return NodeStatus.notReady;
      case 'unknown': return NodeStatus.unknown;
      default: return NodeStatus.unknown;
    }
  }
}
