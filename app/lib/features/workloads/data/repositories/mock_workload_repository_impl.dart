import '../../domain/entities/namespace_entity.dart';
import '../../domain/entities/workload_entity.dart';
import '../../domain/repositories/workload_repository.dart';

class MockWorkloadRepositoryImpl implements WorkloadRepository {
  @override
  Future<List<NamespaceEntity>> getNamespaces(String clusterId) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const NamespaceEntity(
        name: 'default',
        status: 'Active',
        totalPods: 15,
        runningPods: 12,
        failedPods: 3,
      ),
      const NamespaceEntity(
        name: 'kube-system',
        status: 'Active',
        totalPods: 25,
        runningPods: 25,
        failedPods: 0,
      ),
      const NamespaceEntity(
        name: 'ingress-nginx',
        status: 'Active',
        totalPods: 5,
        runningPods: 4,
        failedPods: 1,
      ),
      const NamespaceEntity(
        name: 'monitoring',
        status: 'Active',
        totalPods: 10,
        runningPods: 10,
        failedPods: 0,
      ),
    ];
  }

  @override
  Future<List<WorkloadEntity>> getWorkloads(
      String clusterId, String namespace) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();

    if (namespace == 'default') {
      return [
        WorkloadEntity(
          id: 'deploy-1',
          name: 'frontend-service',
          namespace: namespace,
          type: WorkloadType.deployment,
          replicas: 3,
          availableReplicas: 3,
          image: 'registry.com/frontend:v1.2.0',
          status: 'Running',
          lastUpdate: now.subtract(const Duration(minutes: 5)),
        ),
        WorkloadEntity(
          id: 'deploy-2',
          name: 'backend-api',
          namespace: namespace,
          type: WorkloadType.deployment,
          replicas: 5,
          availableReplicas: 3,
          image: 'registry.com/backend:v2.0.1',
          status: 'Degraded',
          lastUpdate: now.subtract(const Duration(hours: 1)),
        ),
      ];
    } else if (namespace == 'kube-system') {
      return [
        WorkloadEntity(
          id: 'ds-1',
          name: 'kube-proxy',
          namespace: namespace,
          type: WorkloadType.daemonSet,
          replicas: 10,
          availableReplicas: 10,
          image: 'k8s.gcr.io/kube-proxy:v1.28.2',
          status: 'Running',
          lastUpdate: now.subtract(const Duration(days: 10)),
        ),
        WorkloadEntity(
          id: 'deploy-3',
          name: 'coredns',
          namespace: namespace,
          type: WorkloadType.deployment,
          replicas: 2,
          availableReplicas: 2,
          image: 'k8s.gcr.io/coredns:v1.10.1',
          status: 'Running',
          lastUpdate: now.subtract(const Duration(days: 15)),
        ),
      ];
    }
    return [];
  }
}
