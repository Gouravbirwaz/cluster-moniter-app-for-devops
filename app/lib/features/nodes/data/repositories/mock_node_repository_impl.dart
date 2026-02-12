import '../../domain/entities/node_entity.dart';
import '../../domain/repositories/node_repository.dart';

class MockNodeRepositoryImpl implements NodeRepository {
  @override
  Future<List<NodeEntity>> getNodes(String clusterId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return List.generate(5, (index) {
      return NodeEntity(
        id: 'node-$clusterId-$index',
        name: 'ip-10-0-1-$index.ec2.internal',
        clusterId: clusterId,
        status: index == 3 ? NodeStatus.notReady : NodeStatus.ready,
        role: index == 0 ? 'master' : 'worker',
        version: 'v1.28.2',
        cpuUsage: 15.0 + (index * 12),
        memoryUsage: 40.0 + (index * 8),
        diskPressure: 10.0 + (index * 2),
        networkIo: 250.0 + (index * 50),
      );
    });
  }

  @override
  Future<NodeEntity> getNodeDetails(String clusterId, String nodeId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return NodeEntity(
      id: nodeId,
      name: 'ip-10-0-1-${nodeId.split('-').last}.ec2.internal',
      clusterId: 'unknown',
      status: NodeStatus.ready,
      role: 'worker',
      version: 'v1.28.2',
      cpuUsage: 45.0,
      memoryUsage: 62.0,
      diskPressure: 12.0,
      networkIo: 450.0,
    );
  }
}
