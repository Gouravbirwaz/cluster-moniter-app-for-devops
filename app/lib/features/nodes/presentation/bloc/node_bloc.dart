import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/node_entity.dart';
import '../../domain/repositories/node_repository.dart';

// Events
abstract class NodeEvent extends Equatable {
  const NodeEvent();
  @override
  List<Object> get props => [];
}

class NodeLoadStarted extends NodeEvent {
  final String clusterId;
  const NodeLoadStarted(this.clusterId);
  @override
  List<Object> get props => [clusterId];
}

class NodeRefreshRequested extends NodeEvent {
  final String clusterId;
  const NodeRefreshRequested(this.clusterId);
  @override
  List<Object> get props => [clusterId];
}

// States
abstract class NodeState extends Equatable {
  const NodeState();
  @override
  List<Object> get props => [];
}

class NodeInitial extends NodeState {}

class NodeLoading extends NodeState {}

class NodeLoaded extends NodeState {
  final List<NodeEntity> nodes;
  const NodeLoaded(this.nodes);
  @override
  List<Object> get props => [nodes];
}

class NodeFailure extends NodeState {
  final String message;
  const NodeFailure(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class NodeBloc extends Bloc<NodeEvent, NodeState> {
  final NodeRepository nodeRepository;

  NodeBloc({required this.nodeRepository}) : super(NodeInitial()) {
    on<NodeLoadStarted>(_onLoadStarted);
    on<NodeRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadStarted(
    NodeLoadStarted event,
    Emitter<NodeState> emit,
  ) async {
    emit(NodeLoading());
    try {
      final nodes = await nodeRepository.getNodes(event.clusterId);
      emit(NodeLoaded(nodes));
    } catch (e) {
      emit(NodeFailure(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    NodeRefreshRequested event,
    Emitter<NodeState> emit,
  ) async {
    try {
      final nodes = await nodeRepository.getNodes(event.clusterId);
      emit(NodeLoaded(nodes));
    } catch (e) {
      emit(NodeFailure(e.toString()));
    }
  }
}
