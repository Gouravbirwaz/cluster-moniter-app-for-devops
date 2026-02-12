import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/workload_repository.dart';
import '../bloc/workload_bloc.dart';
import '../widgets/namespace_list_item.dart';
import 'workloads_page.dart';

class NamespacesPage extends StatelessWidget {
  final String clusterId;
  final String clusterName;

  const NamespacesPage({
    super.key,
    required this.clusterId,
    required this.clusterName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WorkloadBloc(
        workloadRepository: context.read<WorkloadRepository>(),
      )..add(NamespacesLoadStarted(clusterId)),
      child: _NamespacesView(clusterId: clusterId, clusterName: clusterName),
    );
  }
}

class _NamespacesView extends StatelessWidget {
  final String clusterId;
  final String clusterName;

  const _NamespacesView({
    required this.clusterId,
    required this.clusterName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkloadBloc, WorkloadState>(
      builder: (context, state) {
        if (state is WorkloadLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is WorkloadFailure) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is NamespacesLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<WorkloadBloc>().add(NamespacesLoadStarted(clusterId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.namespaces.length,
              itemBuilder: (context, index) {
                final namespace = state.namespaces[index];
                return NamespaceListItem(
                  namespace: namespace,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkloadsPage(
                          clusterId: clusterId,
                          namespace: namespace.name,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
