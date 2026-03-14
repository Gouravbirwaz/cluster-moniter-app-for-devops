import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/node_repository.dart';
import '../bloc/node_bloc.dart';
import '../widgets/node_card.dart';
import 'node_details_page.dart';

class NodesPage extends StatelessWidget {
  final String clusterId;
  final String clusterName;
  final bool isEmbedded;

  const NodesPage({
    super.key,
    required this.clusterId,
    required this.clusterName,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NodeBloc(
        nodeRepository: context.read<NodeRepository>(),
      )..add(NodeLoadStarted(clusterId)),
      child: _NodesView(
        clusterId: clusterId,
        clusterName: clusterName,
        isEmbedded: isEmbedded,
      ),
    );
  }
}

class _NodesView extends StatelessWidget {
  final String clusterId;
  final String clusterName;
  final bool isEmbedded;

  const _NodesView({
    required this.clusterId,
    required this.clusterName,
    required this.isEmbedded,
  });

  @override
  Widget build(BuildContext context) {
    if (isEmbedded) {
      return BlocBuilder<NodeBloc, NodeState>(
        builder: (context, state) {
          if (state is NodeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NodeFailure) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is NodeLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NodeBloc>().add(NodeLoadStarted(clusterId));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.nodes.length,
                itemBuilder: (context, index) {
                  return NodeCard(
                    node: state.nodes[index],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NodeDetailsPage(
                            node: state.nodes[index],
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Nodes: $clusterName'),
      ),
      body: BlocBuilder<NodeBloc, NodeState>(
        builder: (context, state) {
          if (state is NodeLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is NodeFailure) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is NodeLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<NodeBloc>().add(NodeLoadStarted(clusterId));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.nodes.length,
                itemBuilder: (context, index) {
                  return NodeCard(
                    node: state.nodes[index],
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NodeDetailsPage(
                            node: state.nodes[index],
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
      ),
    );
  }
}
