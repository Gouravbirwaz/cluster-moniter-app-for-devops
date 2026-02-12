import '../../domain/entities/node_entity.dart';
import '../../domain/repositories/node_repository.dart';
import '../../../../core/network/api_client.dart';

class RemoteNodeRepositoryImpl implements NodeRepository {
  final ApiClient apiClient;

  RemoteNodeRepositoryImpl({required this.apiClient});

  @override
  Future<List<NodeEntity>> getNodes(String clusterId) async {
    final List<dynamic> data = await apiClient.get('/clusters/$clusterId/nodes');
    return data.map((json) => NodeEntity(
      id: json['id'],
      name: json['name'],
      clusterId: json['clusterId'],
      status: _parseStatus(json['status']),
      role: json['role'],
      version: json['version'],
      cpuUsage: (json['cpuUsage'] as num).toDouble(),
      memoryUsage: (json['memoryUsage'] as num).toDouble(),
      diskPressure: (json['diskPressure'] as num).toDouble(),
      networkIo: (json['networkIo'] as num).toDouble(),
    )).toList();
  }

  @override
  Future<NodeEntity> getNodeDetails(String clusterId, String nodeId) async {
    // For now, re-using getNodes and filtering, or we could add a specific endpoint
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
