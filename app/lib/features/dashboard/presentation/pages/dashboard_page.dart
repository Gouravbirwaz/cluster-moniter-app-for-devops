import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/widgets/status_card.dart';
import '../../../../core/widgets/metrics_chart.dart';
import '../providers/dashboard_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.overview == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null && provider.overview == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.critical),
                const SizedBox(height: 16),
                Text('Connection Error', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(provider.error!, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => provider.fetchOverview(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMetricGridSection(),
              const SizedBox(height: AppSizes.paddingM),
              _buildChartsSection(),
              const SizedBox(height: AppSizes.paddingM),
              _buildNodeHealthSectionFiltered(),
              const SizedBox(height: AppSizes.paddingM),
              _buildTopPodsSectionFiltered(),
              const SizedBox(height: AppSizes.paddingM),
              _buildRecentEventsSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Selector<DashboardProvider, bool>(
      selector: (_, p) => p.isWebSocketConnected,
      builder: (context, isConnected, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cluster Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textHighlight,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isConnected 
                    ? AppColors.healthy.withOpacity(0.1) 
                    : AppColors.critical.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnected 
                      ? AppColors.healthy.withOpacity(0.5) 
                      : AppColors.critical.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.healthy : AppColors.critical,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (isConnected)
                          BoxShadow(
                            color: AppColors.healthy.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'LIVE' : 'DISCONNECTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? AppColors.healthy : AppColors.critical,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricGridSection() {
    return Selector<DashboardProvider, Map<String, dynamic>>(
      selector: (_, p) => p.overview ?? {},
      builder: (context, data, child) {
        return _buildMetricGrid(data);
      },
    );
  }

  Widget _buildChartsSection() {
    return Selector<DashboardProvider, List<List<FlSpot>>>(
      selector: (_, p) => [p.cpuSpots, p.memorySpots],
      builder: (context, spots, child) {
        return SizedBox(
          height: 300,
          child: Row(
            children: [
              Expanded(
                child: MetricsChart(
                  title: 'Cluster CPU Over Time',
                  color: AppColors.cpu,
                  spots: spots[0],
                ),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: MetricsChart(
                  title: 'Cluster Memory Over Time',
                  color: AppColors.memory,
                  spots: spots[1],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeHealthSectionFiltered() {
    return Selector<DashboardProvider, List<dynamic>>(
      selector: (_, p) => p.overview?['nodes'] ?? [],
      builder: (context, nodes, child) {
        if (nodes.isEmpty) return const SizedBox.shrink();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Node Health',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHighlight),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  final node = nodes[index];
                  final bool isReady = node['ready'] ?? false;
                  final String nodeName = node['name'] ?? 'unknown';

                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.dns, size: 16, color: isReady ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(nodeName, 
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
                              Text(isReady ? 'Ready' : 'NotReady', 
                                style: TextStyle(fontSize: 10, color: isReady ? Colors.green : Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopPodsSectionFiltered() {
    return Selector<DashboardProvider, List<Map<String, dynamic>>>(
      selector: (_, p) => p.topPods,
      builder: (context, topPods, child) {
        if (topPods.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Resource Consumers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHighlight),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topPods.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final pod = topPods[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.widgets_outlined, size: 18, color: AppColors.primary),
                    title: Text(pod['name'] ?? 'Unknown', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTag(pod['cpu'] ?? '0m', Colors.blue),
                        const SizedBox(width: 8),
                        _buildTag(pod['mem'] ?? '0Mi', Colors.purple),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentEventsSection() {
    return Selector<DashboardProvider, List<Map<String, dynamic>>>(
      selector: (_, p) => p.events,
      builder: (context, events, child) {
        final top3Events = events.take(3).toList();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Cluster Events',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHighlight,
                      ),
                    ),
                    if (events.length > 3)
                      Text(
                        'Showing 3 of ${events.length}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                      ),
                  ],
                ),
                const SizedBox(height: AppSizes.paddingM),
                if (top3Events.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No recent events', style: TextStyle(color: AppColors.textDim)),
                  ))
                else
                  ...top3Events.map((event) {
                    final type = event['type'] ?? 'info';
                    final color = type.contains('failure') ? AppColors.critical : (type.contains('warning') ? AppColors.warning : AppColors.healthy);
                    return _buildEventItem(
                      event['message'] ?? event['data']?['message'] ?? 'Unknown event',
                      'Just now', 
                      color,
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricGrid(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
      crossAxisSpacing: AppSizes.paddingM,
      mainAxisSpacing: AppSizes.paddingM,
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.8 : 1.1,
      children: [
        StatusCard(
          title: 'TOTAL NODES',
          value: '${data['total_nodes'] ?? 0}',
          subtitle: 'Active: ${data['ready_nodes'] ?? 0}',
          icon: Icons.dns,
          color: AppColors.primary,
        ),
        StatusCard(
          title: 'TOTAL PODS',
          value: '${data['total_pods'] ?? 0}',
          subtitle: 'Running: ${data['running_pods'] ?? 0}',
          icon: Icons.widgets,
          color: AppColors.secondary,
        ),
        StatusCard(
          title: 'CPU USAGE',
          value: '${(data['cpu_usage'] ?? 0).toStringAsFixed(1)}%',
          subtitle: 'Cluster Total',
          icon: Icons.memory,
          color: AppColors.cpu,
          trend: 2.4,
        ),
        StatusCard(
          title: 'MEMORY USAGE',
          value: '${(data['memory_usage'] ?? 0).toStringAsFixed(1)}%',
          subtitle: 'Cluster Total',
          icon: Icons.storage,
          color: AppColors.memory,
          trend: -0.8,
        ),
      ],
    );
  }


  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEventItem(String message, String time, Color color) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.textMain),
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
