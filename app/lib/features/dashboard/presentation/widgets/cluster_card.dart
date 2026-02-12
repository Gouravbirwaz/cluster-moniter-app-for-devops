import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/cluster_entity.dart';
import 'mini_metric_chart.dart';

class ClusterCard extends StatelessWidget {
  final ClusterEntity cluster;
  final VoidCallback? onTap;

  const ClusterCard({
    super.key,
    required this.cluster,
    this.onTap,
  });

  Color _getStatusColor(ClusterStatus status) {
    switch (status) {
      case ClusterStatus.healthy:
        return const Color(0xFF238636); // Github Green
      case ClusterStatus.degraded:
        return const Color(0xFFD29922); // Github Orange
      case ClusterStatus.critical:
        return const Color(0xFFDA3633); // Github Red
    }
  }

  // Generate deterministic mock history based on current value
  List<FlSpot> _generateMockHistory(double current) {
    return List.generate(20, (index) {
      double val = current + (index % 5 - 2) * 5;
      if (val < 0) val = 0;
      if (val > 100) val = 100;
      return FlSpot(index.toDouble(), val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(cluster.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B1F),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF202226)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: Column(
          children: [
            // Panel Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF202226))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cluster.name,
                      style: const TextStyle(
                        color: Color(0xFFF7F8FA),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _RegionBadge(region: cluster.region),
                ],
              ),
            ),
            
            // Panel Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricPanel(
                          label: 'CPU Usage',
                          value: '${cluster.cpuUsage.toStringAsFixed(1)}%',
                          data: _generateMockHistory(cluster.cpuUsage),
                          color: const Color(0xFF73BF69), // Grafana Greenish
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricPanel(
                          label: 'Memory',
                          value: '${cluster.memoryUsage.toStringAsFixed(1)}%',
                          data: _generateMockHistory(cluster.memoryUsage),
                          color: const Color(0xFFF2CC0C), // Grafana Yellow
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Row(
                        children: [
                          const Icon(Icons.dns, size: 14, color: Color(0xFFCCCCDC)),
                          const SizedBox(width: 4),
                           Text(
                            '${cluster.totalNodes} Nodes',
                            style: const TextStyle(color: Color(0xFFCCCCDC), fontSize: 12),
                          ),
                        ],
                       ),
                       if (cluster.activeAlerts > 0)
                        Row(
                          children: [
                            const Icon(Icons.warning, size: 14, color: Color(0xFFE02F44)),
                            const SizedBox(width: 4),
                            Text(
                              '${cluster.activeAlerts} Alerts',
                              style: const TextStyle(
                                color: Color(0xFFE02F44),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionBadge extends StatelessWidget {
  final String region;
  const _RegionBadge({required this.region});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        region.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  final String label;
  final String value;
  final List<FlSpot> data;
  final Color color;

  const _MetricPanel({
    required this.label,
    required this.value,
    required this.data,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFCCCCDC), fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                color: const Color(0xFFF7F8FA),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [
                  Shadow(color: color.withOpacity(0.4), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MiniMetricChart(
              data: data,
              color: color,
            ),
          ],
        ),
      ],
    );
  }
}
