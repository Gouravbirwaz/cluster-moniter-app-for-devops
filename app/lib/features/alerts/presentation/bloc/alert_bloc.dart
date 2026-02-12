import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/alert_entity.dart';
import '../../domain/repositories/alert_repository.dart';

// Events
abstract class AlertEvent extends Equatable {
  const AlertEvent();
  @override
  List<Object> get props => [];
}

class AlertLoadStarted extends AlertEvent {}

class AlertRefreshRequested extends AlertEvent {}

// States
abstract class AlertState extends Equatable {
  const AlertState();
  @override
  List<Object> get props => [];
}

class AlertInitial extends AlertState {}

class AlertLoading extends AlertState {}

class AlertLoaded extends AlertState {
  final List<AlertEntity> alerts;
  const AlertLoaded(this.alerts);
  @override
  List<Object> get props => [alerts];
}

class AlertFailure extends AlertState {
  final String message;
  const AlertFailure(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class AlertBloc extends Bloc<AlertEvent, AlertState> {
  final AlertRepository alertRepository;

  AlertBloc({required this.alertRepository}) : super(AlertInitial()) {
    on<AlertLoadStarted>(_onLoadStarted);
    on<AlertRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onLoadStarted(
    AlertLoadStarted event,
    Emitter<AlertState> emit,
  ) async {
    emit(AlertLoading());
    try {
      final alerts = await alertRepository.getActiveAlerts();
      emit(AlertLoaded(alerts));
    } catch (e) {
      emit(AlertFailure(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    AlertRefreshRequested event,
    Emitter<AlertState> emit,
  ) async {
    try {
      final alerts = await alertRepository.getActiveAlerts();
      emit(AlertLoaded(alerts));
    } catch (e) {
      emit(AlertFailure(e.toString()));
    }
  }
}
