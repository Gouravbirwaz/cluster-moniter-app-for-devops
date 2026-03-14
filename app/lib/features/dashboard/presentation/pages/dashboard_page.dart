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

        final data = provider.overview ?? {};

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cluster Dashboard',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.isWebSocketConnected 
                          ? AppColors.healthy.withOpacity(0.1) 
                          : AppColors.critical.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: provider.isWebSocketConnected 
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
                            color: provider.isWebSocketConnected ? AppColors.healthy : AppColors.critical,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (provider.isWebSocketConnected)
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
                          provider.isWebSocketConnected ? 'LIVE' : 'DISCONNECTED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: provider.isWebSocketConnected ? AppColors.healthy : AppColors.critical,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildMetricGrid(data),
              const SizedBox(height: AppSizes.paddingM),
              _buildCharts(),
              const SizedBox(height: AppSizes.paddingM),
              _buildBottomSection(),
            ],
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
      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2 : 1.4,
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

  Widget _buildCharts() {
    return SizedBox(
      height: 300,
      child: Row(
        children: [
          Expanded(
            child: MetricsChart(
              title: 'Cluster CPU Over Time',
              color: AppColors.cpu,
              spots: const [
                FlSpot(0, 30), FlSpot(1, 35), FlSpot(2, 45), FlSpot(3, 40),
                FlSpot(4, 50), FlSpot(5, 55), FlSpot(6, 48), FlSpot(7, 52),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.paddingM),
          Expanded(
            child: MetricsChart(
              title: 'Cluster Memory Over Time',
              color: AppColors.memory,
              spots: const [
                FlSpot(0, 60), FlSpot(1, 62), FlSpot(2, 65), FlSpot(3, 63),
                FlSpot(4, 68), FlSpot(5, 70), FlSpot(6, 72), FlSpot(7, 71),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Cluster Events',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textHighlight,
              ),
            ),
            const SizedBox(height: AppSizes.paddingM),
            _buildEventItem('Pod "backend-v1" restarted in namespace "prod"', '2m ago', AppColors.warning),
            _buildEventItem('New node "worker-3" joined the cluster', '15m ago', AppColors.healthy),
            _buildEventItem('Image pull failure on pod "redis-0"', '45m ago', AppColors.critical),
          ],
        ),
      ),
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
