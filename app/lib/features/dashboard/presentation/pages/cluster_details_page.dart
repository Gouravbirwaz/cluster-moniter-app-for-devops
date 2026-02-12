import 'package:flutter/material.dart';
import '../../../../features/nodes/presentation/pages/nodes_page.dart';
import '../../../../features/workloads/presentation/pages/namespaces_page.dart';

class ClusterDetailsPage extends StatefulWidget {
  final String clusterId;
  final String clusterName;

  const ClusterDetailsPage({
    super.key,
    required this.clusterId,
    required this.clusterName,
  });

  @override
  State<ClusterDetailsPage> createState() => _ClusterDetailsPageState();
}

class _ClusterDetailsPageState extends State<ClusterDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clusterName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nodes', icon: Icon(Icons.dns)),
            Tab(text: 'Namespaces', icon: Icon(Icons.layers)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NodesPage(
            clusterId: widget.clusterId,
            clusterName: widget.clusterName,
            isEmbedded: true, // New flag to hide AppBar
          ),
          NamespacesPage(
            clusterId: widget.clusterId,
            clusterName: widget.clusterName,
          ),
        ],
      ),
    );
  }
}
