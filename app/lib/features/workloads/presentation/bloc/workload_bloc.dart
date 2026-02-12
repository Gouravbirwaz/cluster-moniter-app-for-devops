import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/namespace_entity.dart';
import '../../domain/entities/workload_entity.dart';
import '../../domain/repositories/workload_repository.dart';

// Events
abstract class WorkloadEvent extends Equatable {
  const WorkloadEvent();
  @override
  List<Object> get props => [];
}

class NamespacesLoadStarted extends WorkloadEvent {
  final String clusterId;
  const NamespacesLoadStarted(this.clusterId);
  @override
  List<Object> get props => [clusterId];
}

class WorkloadsLoadStarted extends WorkloadEvent {
  final String clusterId;
  final String namespace;
  const WorkloadsLoadStarted(this.clusterId, this.namespace);
  @override
  List<Object> get props => [clusterId, namespace];
}

// States
abstract class WorkloadState extends Equatable {
  const WorkloadState();
  @override
  List<Object> get props => [];
}

class WorkloadInitial extends WorkloadState {}

class WorkloadLoading extends WorkloadState {}

class NamespacesLoaded extends WorkloadState {
  final List<NamespaceEntity> namespaces;
  const NamespacesLoaded(this.namespaces);
  @override
  List<Object> get props => [namespaces];
}

class WorkloadsLoaded extends WorkloadState {
  final List<WorkloadEntity> workloads;
  const WorkloadsLoaded(this.workloads);
  @override
  List<Object> get props => [workloads];
}

class WorkloadFailure extends WorkloadState {
  final String message;
  const WorkloadFailure(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class WorkloadBloc extends Bloc<WorkloadEvent, WorkloadState> {
  final WorkloadRepository workloadRepository;

  WorkloadBloc({required this.workloadRepository}) : super(WorkloadInitial()) {
    on<NamespacesLoadStarted>(_onNamespacesLoadStarted);
    on<WorkloadsLoadStarted>(_onWorkloadsLoadStarted);
  }

  Future<void> _onNamespacesLoadStarted(
    NamespacesLoadStarted event,
    Emitter<WorkloadState> emit,
  ) async {
    emit(WorkloadLoading());
    try {
      final namespaces = await workloadRepository.getNamespaces(event.clusterId);
      emit(NamespacesLoaded(namespaces));
    } catch (e) {
      emit(WorkloadFailure(e.toString()));
    }
  }

  Future<void> _onWorkloadsLoadStarted(
    WorkloadsLoadStarted event,
    Emitter<WorkloadState> emit,
  ) async {
    emit(WorkloadLoading());
    try {
      final workloads = await workloadRepository.getWorkloads(
        event.clusterId,
        event.namespace,
      );
      emit(WorkloadsLoaded(workloads));
    } catch (e) {
      emit(WorkloadFailure(e.toString()));
    }
  }
}
