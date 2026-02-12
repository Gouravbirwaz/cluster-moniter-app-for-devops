import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/cluster_card.dart';
import 'cluster_details_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        dashboardRepository: context.read<DashboardRepository>(),
      )..add(DashboardLoadStarted()),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Mission Control'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0D1117),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(DashboardRefreshRequested());
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AlertsPage()),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DashboardFailure) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is DashboardLoaded) {
            final clusters = state.clusters;
            
            // Calc totals
            final totalNodes = clusters.fold(0, (sum, c) => sum + c.totalNodes);
            final totalAlerts = clusters.fold(0, (sum, c) => sum + c.activeAlerts);
            final avgCpu = clusters.isEmpty ? 0.0 : clusters.fold(0.0, (sum, c) => sum + c.cpuUsage) / clusters.length;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(DashboardRefreshRequested());
              },
              child: CustomScrollView(
                slivers: [
                  // Global Stats Grid
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildListDelegate([
                        _StatPanel(
                          title: 'Total Clusters',
                          value: '${clusters.length}',
                          color: Colors.blue,
                          icon: Icons.hub,
                        ),
                        _StatPanel(
                          title: 'Active Alerts',
                          value: '$totalAlerts',
                          color: totalAlerts > 0 ? Colors.red : Colors.green,
                          icon: Icons.warning_amber,
                        ),
                        _StatPanel(
                          title: 'Total Nodes',
                          value: '$totalNodes',
                          color: Colors.purple,
                          icon: Icons.dns,
                        ),
                        _StatPanel(
                          title: 'Avg CPU Load',
                          value: '${avgCpu.toStringAsFixed(1)}%',
                          color: Colors.orange,
                          icon: Icons.speed,
                        ),
                      ]),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Icon(Icons.grid_view, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'CLUSTERS',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClusterCard(
                              cluster: clusters[index],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ClusterDetailsPage(
                                      clusterId: clusters[index].id,
                                      clusterName: clusters[index].name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: clusters.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _StatPanel extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatPanel({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B1F),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF202226)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFCCCCDC),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFFF7F8FA),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
