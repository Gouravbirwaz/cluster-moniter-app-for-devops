import '../../domain/entities/cluster_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

class MockDashboardRepositoryImpl implements DashboardRepository {
  @override
  Future<List<ClusterEntity>> getClusters() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate latency
    return [
      const ClusterEntity(
        id: 'c1',
        name: 'prod-us-east-1',
        region: 'us-east-1',
        status: ClusterStatus.healthy,
        totalNodes: 50,
        activeAlerts: 0,
        cpuUsage: 45.5,
        memoryUsage: 60.2,
      ),
      const ClusterEntity(
        id: 'c2',
        name: 'prod-eu-west-1',
        region: 'eu-west-1',
        status: ClusterStatus.degraded,
        totalNodes: 35,
        activeAlerts: 3,
        cpuUsage: 78.0,
        memoryUsage: 82.5,
      ),
      const ClusterEntity(
        id: 'c3',
        name: 'staging-us-west-2',
        region: 'us-west-2',
        status: ClusterStatus.critical,
        totalNodes: 12,
        activeAlerts: 8,
        cpuUsage: 92.1,
        memoryUsage: 88.0,
      ),
    ];
  }
}
