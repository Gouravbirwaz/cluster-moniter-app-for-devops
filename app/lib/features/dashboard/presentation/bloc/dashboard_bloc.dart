import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/cluster_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object> get props => [];
}

class DashboardLoadStarted extends DashboardEvent {}

class DashboardRefreshRequested extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<ClusterEntity> clusters;
  const DashboardLoaded(this.clusters);
  @override
  List<Object> get props => [clusters];
}

class DashboardFailure extends DashboardState {
  final String message;
  const DashboardFailure(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository dashboardRepository;

  DashboardBloc({required this.dashboardRepository}) : super(DashboardInitial()) {
    on<DashboardLoadStarted>(_onLoadStarted);
    on<DashboardRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadStarted(
    DashboardLoadStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final clusters = await dashboardRepository.getClusters();
      emit(DashboardLoaded(clusters));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep showing current data while refreshing if possible, or emit loading
    // For now, simple loading state
    try {
      final clusters = await dashboardRepository.getClusters();
      emit(DashboardLoaded(clusters));
    } catch (e) {
      emit(DashboardFailure(e.toString()));
    }
  }
}
