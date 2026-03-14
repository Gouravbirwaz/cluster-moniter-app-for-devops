import '../../domain/entities/namespace_entity.dart';
import '../../domain/entities/workload_entity.dart';
import '../../domain/repositories/workload_repository.dart';
import '../../../../core/network/api_client.dart';

class RemoteWorkloadRepositoryImpl implements WorkloadRepository {
  final ApiClient apiClient;

  RemoteWorkloadRepositoryImpl({required this.apiClient});

  @override
  Future<List<NamespaceEntity>> getNamespaces(String clusterId) async {
    final List<dynamic> data = await apiClient.get('/api/v1/workloads/namespaces');
    return data.map((json) => NamespaceEntity(
      name: json['name'],
      status: json['status'],
      totalPods: json['total_pods'] ?? 0,
      runningPods: json['running_pods'] ?? 0,
      failedPods: json['failed_pods'] ?? 0,
    )).toList();
  }

  @override
  Future<List<WorkloadEntity>> getWorkloads(String clusterId, String namespace) async {
    final List<dynamic> data = await apiClient.get('/api/v1/workloads?namespace=$namespace');
    return data.map((json) => WorkloadEntity(
      id: json['id'],
      name: json['name'],
      type: _parseType(json['type']),
      namespace: json['namespace'],
      replicas: json['replicas'],
      availableReplicas: json['available_replicas'],
      image: json['image'],
      lastUpdate: DateTime.parse(json['creation_timestamp']),
      status: json['status'],
    )).toList();
  }

  @override
  Future<List<WorkloadEntity>> getPods(String clusterId, String namespace) async {
    final List<dynamic> data = await apiClient.get('/api/v1/pods?namespace=$namespace');
    return data.map((json) => WorkloadEntity(
      id: json['id'],
      name: json['name'],
      type: WorkloadType.pod,
      namespace: json['namespace'],
      replicas: 1,
      availableReplicas: 1,
      image: json['image'],
      lastUpdate: json['start_time'] != null ? DateTime.parse(json['start_time']) : DateTime.now(),
      status: json['status'],
    )).toList();
  }

  WorkloadType _parseType(String type) {
    if (type.toLowerCase() == 'deployment') return WorkloadType.deployment;
    if (type.toLowerCase() == 'statefulset') return WorkloadType.statefulSet;
    if (type.toLowerCase() == 'daemonset') return WorkloadType.daemonSet;
    return WorkloadType.pod; 
  }
}
