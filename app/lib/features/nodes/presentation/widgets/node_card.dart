import 'package:flutter/material.dart';
import '../../domain/entities/node_entity.dart';

class NodeCard extends StatelessWidget {
  final NodeEntity node;
  final VoidCallback? onTap;

  const NodeCard({
    super.key,
    required this.node,
    this.onTap,
  });

  Color _getStatusColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.ready:
        return Colors.green;
      case NodeStatus.notReady:
        return Colors.red;
      case NodeStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(node.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            node.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: node.role == 'master'
                          ? Colors.purple.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      node.role.toUpperCase(),
                      style: TextStyle(
                        color: node.role == 'master'
                            ? Colors.purpleAccent
                            : Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NodeMetric(
                    label: 'CPU',
                    value: '${node.cpuUsage.toStringAsFixed(1)}%',
                    color: node.cpuUsage > 80 ? Colors.orange : null,
                  ),
                  _NodeMetric(
                    label: 'MEM',
                    value: '${node.memoryUsage.toStringAsFixed(1)}%',
                    color: node.memoryUsage > 80 ? Colors.orange : null,
                  ),
                   _NodeMetric(
                    label: 'DISK',
                    value: node.diskPressure ? 'YES' : 'NO',
                    color: node.diskPressure ? Colors.red : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _NodeMetric({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
