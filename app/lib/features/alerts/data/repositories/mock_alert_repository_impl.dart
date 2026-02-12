import '../../domain/entities/alert_entity.dart';
import '../../domain/repositories/alert_repository.dart';

class MockAlertRepositoryImpl implements AlertRepository {
  @override
  Future<List<AlertEntity>> getActiveAlerts() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();

    return [
      AlertEntity(
        id: 'a1',
        title: 'High CPU Usage',
        message: 'Node ip-10-0-1-5 CPU usage is above 90%',
        severity: AlertSeverity.critical,
        clusterId: 'c1',
        resource: 'node/ip-10-0-1-5',
        timestamp: now.subtract(const Duration(minutes: 10)),
      ),
      AlertEntity(
        id: 'a2',
        title: 'Pod CrashLoopBackOff',
        message: 'Pod frontend-service-xyz restarting frequently',
        severity: AlertSeverity.warning,
        clusterId: 'c1',
        resource: 'pod/frontend-service-xyz',
        timestamp: now.subtract(const Duration(minutes: 45)),
      ),
      AlertEntity(
        id: 'a3',
        title: 'Disk Pressure',
        message: 'Node ip-10-0-1-2 disk usage > 85%',
        severity: AlertSeverity.warning,
        clusterId: 'c2',
        resource: 'node/ip-10-0-1-2',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      AlertEntity(
        id: 'a4',
        title: 'Deployment Scaled',
        message: 'Deployment backend-api scaled to 5 replicas',
        severity: AlertSeverity.info,
        clusterId: 'c1',
        resource: 'deployment/backend-api',
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
