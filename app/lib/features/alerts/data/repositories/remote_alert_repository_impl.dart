import '../../domain/entities/alert_entity.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../../../core/network/api_client.dart';

class RemoteAlertRepositoryImpl implements AlertRepository {
  final ApiClient apiClient;

  RemoteAlertRepositoryImpl({required this.apiClient});

  @override
  Future<List<AlertEntity>> getActiveAlerts() async {
    final List<dynamic> data = await apiClient.get('/api/v1/alerts');
    return data.map((json) => AlertEntity(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      severity: _parseSeverity(json['severity']),
      clusterId: json['clusterId'],
      resource: json['resource'],
      timestamp: DateTime.parse(json['timestamp']),
    )).toList();
  }

  AlertSeverity _parseSeverity(String severity) {
    switch (severity) {
      case 'critical': return AlertSeverity.critical;
      case 'warning': return AlertSeverity.warning;
      case 'info': return AlertSeverity.info;
      default: return AlertSeverity.info;
    }
  }
}
