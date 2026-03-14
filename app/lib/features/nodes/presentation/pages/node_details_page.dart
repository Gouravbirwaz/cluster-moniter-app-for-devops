import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../features/nodes/domain/entities/node_entity.dart';
import '../../../dashboard/presentation/widgets/metric_chart.dart';

class NodeDetailsPage extends StatelessWidget {
  final NodeEntity node;

  const NodeDetailsPage({super.key, required this.node});

  // Mock data generator
  List<FlSpot> _generateMockData(double baseValue) {
    return List.generate(24, (index) {
      // Add some random fluctuation
      double val = baseValue + (index % 5) - 2;
      if (val < 0) val = 0;
      if (val > 100) val = 100;
      return FlSpot(index.toDouble(), val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(node.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoSection(node: node),
            const Divider(height: 32),
            MetricChart(
              title: 'CPU Usage (Last 24h)',
              data: _generateMockData(node.cpuUsage),
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            MetricChart(
              title: 'Memory Usage (Last 24h)',
              data: _generateMockData(node.memoryUsage),
              color: Colors.purple,
            ),
            const SizedBox(height: 24),
            MetricChart(
              title: 'Disk Pressure (Last 24h)',
              data: _generateMockData(node.diskPressure ? 100.0 : 0.0),
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final NodeEntity node;

  const _InfoSection({required this.node});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Node Information', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        _buildRow('Status', node.status.name.toUpperCase()),
        _buildRow('Role', node.role.toUpperCase()),
        _buildRow('Version', node.version),
        _buildRow('Cluster ID', node.clusterId),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
