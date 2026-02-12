import 'package:equatable/equatable.dart';

class NamespaceEntity extends Equatable {
  final String name;
  final String status;
  final int totalPods;
  final int runningPods;
  final int failedPods;

  const NamespaceEntity({
    required this.name,
    required this.status,
    required this.totalPods,
    required this.runningPods,
    required this.failedPods,
  });

  @override
  List<Object> get props => [name, status, totalPods, runningPods, failedPods];
}
