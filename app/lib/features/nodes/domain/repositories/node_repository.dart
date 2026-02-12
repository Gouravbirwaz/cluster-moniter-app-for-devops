import '../entities/node_entity.dart';

abstract class NodeRepository {
  Future<List<NodeEntity>> getNodes(String clusterId);
  Future<NodeEntity> getNodeDetails(String clusterId, String nodeId);
}
