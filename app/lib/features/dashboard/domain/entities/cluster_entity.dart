import 'package:equatable/equatable.dart';

enum ClusterStatus { healthy, degraded, critical }

class ClusterEntity extends Equatable {
  final String id;
  final String name;
  final String region;
  final ClusterStatus status;
  final int totalNodes;
  final int activeAlerts;
  final double cpuUsage; // Percentage 0-100
  final double memoryUsage; // Percentage 0-100

  const ClusterEntity({
    required this.id,
    required this.name,
    required this.region,
    required this.status,
    required this.totalNodes,
    required this.activeAlerts,
    required this.cpuUsage,
    required this.memoryUsage,
  });

  @override
  List<Object> get props => [
        id,
        name,
        region,
        status,
        totalNodes,
        activeAlerts,
        cpuUsage,
        memoryUsage,
      ];
}
