import 'package:flutter/material.dart';
import '../../domain/entities/namespace_entity.dart';

class NamespaceListItem extends StatelessWidget {
  final NamespaceEntity namespace;
  final VoidCallback? onTap;

  const NamespaceListItem({
    super.key,
    required this.namespace,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.layers, color: Colors.blueGrey),
                  const SizedBox(width: 12),
                  Text(
                    namespace.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  _StatusChip(
                    label: '${namespace.runningPods}',
                    color: Colors.green,
                    tooltip: 'Running Pods',
                  ),
                  const SizedBox(width: 4),
                  if (namespace.failedPods > 0)
                    _StatusChip(
                      label: '${namespace.failedPods}',
                      color: Colors.red,
                      tooltip: 'Failed Pods',
                    ),
                  const SizedBox(width: 4),
                  Text(
                    '/${namespace.totalPods}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final String tooltip;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
