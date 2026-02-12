import 'package:equatable/equatable.dart';

enum WorkloadType { deployment, statefulSet, daemonSet, pod }

class WorkloadEntity extends Equatable {
  final String id;
  final String name;
  final String namespace;
  final WorkloadType type;
  final int replicas;
  final int availableReplicas;
  final String image;
  final String status; // Running, Pending, etc.
  final DateTime lastUpdate;

  const WorkloadEntity({
    required this.id,
    required this.name,
    required this.namespace,
    required this.type,
    required this.replicas,
    required this.availableReplicas,
    required this.image,
    required this.status,
    required this.lastUpdate,
  });

  @override
  List<Object> get props => [
        id,
        name,
        namespace,
        type,
        replicas,
        availableReplicas,
        image,
        status,
        lastUpdate,
      ];
}
