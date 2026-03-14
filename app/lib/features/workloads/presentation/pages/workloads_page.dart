import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/workload_repository.dart';
import '../bloc/workload_bloc.dart';
import '../widgets/workload_card.dart';

class WorkloadsPage extends StatelessWidget {
  final String clusterId;
  final String namespace;

  const WorkloadsPage({
    super.key,
    required this.clusterId,
    required this.namespace,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WorkloadBloc(
        workloadRepository: context.read<WorkloadRepository>(),
      )..add(WorkloadsLoadStarted(clusterId, namespace)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('$namespace Workloads'),
        ),
        body: BlocBuilder<WorkloadBloc, WorkloadState>(
          builder: (context, state) {
            if (state is WorkloadLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is WorkloadFailure) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is WorkloadsLoaded) {
              if (state.workloads.isEmpty) {
                return const Center(child: Text('No workloads found'));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<WorkloadBloc>().add(WorkloadsLoadStarted(clusterId, namespace));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.workloads.length,
                  itemBuilder: (context, index) {
                    return WorkloadCard(workload: state.workloads[index]);
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
