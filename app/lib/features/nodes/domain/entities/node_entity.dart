import 'package:equatable/equatable.dart';

enum NodeStatus { ready, notReady, unknown }

class NodeEntity extends Equatable {
  final String id;
  final String name;
  final String clusterId;
  final NodeStatus status;
  final String role; // master, worker
  final String version;
  final double cpuUsage; // %
  final double memoryUsage; // %
  final double diskPressure; // %
  final double networkIo; // Mbps

  const NodeEntity({
    required this.id,
    required this.name,
    required this.clusterId,
    required this.status,
    required this.role,
    required this.version,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskPressure,
    required this.networkIo,
  });

  @override
  List<Object> get props => [
        id,
        name,
        clusterId,
        status,
        role,
        version,
        cpuUsage,
        memoryUsage,
        diskPressure,
        networkIo,
      ];
}
