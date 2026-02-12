import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/alert_repository.dart';
import '../bloc/alert_bloc.dart';
import '../widgets/alert_card.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AlertBloc(
        alertRepository: context.read<AlertRepository>(),
      )..add(AlertLoadStarted()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active Alerts'),
        ),
        body: BlocBuilder<AlertBloc, AlertState>(
          builder: (context, state) {
            if (state is AlertLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is AlertFailure) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is AlertLoaded) {
              if (state.alerts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('No Active Alerts'),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<AlertBloc>().add(AlertRefreshRequested());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.alerts.length,
                  itemBuilder: (context, index) {
                    return AlertCard(alert: state.alerts[index]);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
