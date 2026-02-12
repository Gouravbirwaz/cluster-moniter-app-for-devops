import 'package:equatable/equatable.dart';

enum AlertSeverity { info, warning, critical }

class AlertEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final String clusterId;
  final String resource; // e.g., pod name, node name
  final DateTime timestamp;

  const AlertEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.clusterId,
    required this.resource,
    required this.timestamp,
  });

  @override
  List<Object> get props => [
        id,
        title,
        message,
        severity,
        clusterId,
        resource,
        timestamp,
      ];
}
