import '../entities/namespace_entity.dart';
import '../entities/workload_entity.dart';

abstract class WorkloadRepository {
  Future<List<NamespaceEntity>> getNamespaces(String clusterId);
  Future<List<WorkloadEntity>> getWorkloads(String clusterId, String namespace);
  Future<List<WorkloadEntity>> getPods(String clusterId, String namespace);
}
