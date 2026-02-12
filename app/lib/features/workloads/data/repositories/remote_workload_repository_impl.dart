import '../../domain/entities/namespace_entity.dart';
import '../../domain/entities/workload_entity.dart';
import '../../domain/repositories/workload_repository.dart';
import '../../../../core/network/api_client.dart';

class RemoteWorkloadRepositoryImpl implements WorkloadRepository {
  final ApiClient apiClient;

  RemoteWorkloadRepositoryImpl({required this.apiClient});

  @override
  Future<List<NamespaceEntity>> getNamespaces(String clusterId) async {
    final List<dynamic> data = await apiClient.get('/clusters/$clusterId/namespaces');
    return data.map((json) => NamespaceEntity(
      name: json['name'],
      status: json['status'],
      totalPods: json['totalPods'],
      runningPods: json['runningPods'],
      failedPods: json['failedPods'],
    )).toList();
  }

  @override
  Future<List<WorkloadEntity>> getWorkloads(String clusterId, String namespace) async {
    final List<dynamic> data = await apiClient.get('/clusters/$clusterId/namespaces/$namespace/workloads');
    return data.map((json) => WorkloadEntity(
      id: json['id'],
      name: json['name'],
      type: _parseType(json['type']),
      namespace: json['namespace'],
      replicas: json['replicas'],
      availableReplicas: json['availableReplicas'],
      image: json['image'],
      lastUpdate: DateTime.parse(json['lastUpdate']),
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
