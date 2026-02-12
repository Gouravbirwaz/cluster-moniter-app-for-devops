import '../entities/alert_entity.dart';

abstract class AlertRepository {
  Future<List<AlertEntity>> getActiveAlerts();
}
