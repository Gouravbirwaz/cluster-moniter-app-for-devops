import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sidebar.dart';
import '../theme/app_colors.dart';
import 'package:k8s_monitor/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:k8s_monitor/features/nodes/presentation/pages/nodes_page.dart';
import 'package:k8s_monitor/features/workloads/presentation/pages/namespaces_page.dart';
import 'package:k8s_monitor/features/workloads/presentation/pages/workloads_page.dart';
import 'package:k8s_monitor/features/alerts/presentation/pages/alerts_page.dart';
import 'package:k8s_monitor/features/logs/presentation/pages/logs_page.dart';
import 'package:k8s_monitor/features/vault/presentation/pages/vault_page.dart';
import 'package:k8s_monitor/features/github/presentation/pages/repos_page.dart';
import 'package:k8s_monitor/features/ai_ops/presentation/pages/ai_ops_page.dart';
import 'package:k8s_monitor/features/settings/presentation/pages/settings_page.dart';
import 'package:k8s_monitor/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:k8s_monitor/features/dashboard/presentation/providers/cluster_provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _navigationItems = [
    {'title': 'Cluster Overview', 'page': const DashboardPage()},
    {
      'title': 'Namespaces', 
      'page': const NamespacesPage(clusterId: 'current-cluster', clusterName: 'Production')
    },
    {
      'title': 'Workloads', 
      'page': const WorkloadsPage(clusterId: 'current-cluster', namespace: 'default')
    },
    {
      'title': 'Nodes', 
      'page': const NodesPage(clusterId: 'current-cluster', clusterName: 'Production', isEmbedded: true)
    },
    {'title': 'Logs', 'page': const LogsPage()},
    {'title': 'Alerts', 'page': const AlertsPage()},
    {'title': 'AI Operations', 'page': const AiOpsPage()},
    {'title': 'Repositories', 'page': const ReposPage()},
    {'title': 'Secret Vault', 'page': const VaultPage()},
    {'title': 'Settings', 'page': const SettingsPage()},
  ];


  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;
    final clusterProvider = context.watch<ClusterProvider>();

    // If no clusters configured and not on settings page, show onboarding
    bool showOnboarding = !clusterProvider.hasClusters && 
                        _selectedIndex != 9 && 
                        !clusterProvider.isLoading;

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? Sidebar(
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
                Navigator.pop(context); // Close drawer
              },
            )
          : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile)
              Sidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
              ),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(_navigationItems[_selectedIndex]['title'], isMobile, clusterProvider),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: showOnboarding 
                        ? OnboardingPage(onGetStarted: () => setState(() => _selectedIndex = 9))
                        : _navigationItems[_selectedIndex]['page'],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, bool isMobile, ClusterProvider clusterProvider) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textMain),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          if (isMobile) const SizedBox(width: 8),
          
          // Cluster Selector
          if (clusterProvider.hasClusters)
            _buildClusterSelector(clusterProvider),
          
          if (clusterProvider.hasClusters) const SizedBox(width: 16),
          
          if (!isMobile)
            Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textHighlight,
              ),
            ),
          const Spacer(),
          if (MediaQuery.of(context).size.width > 1100)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: _buildSearchBox(),
            ),
          const SizedBox(width: 20),
          _buildUserMenu(),
        ],
      ),
    );
  }

  Widget _buildClusterSelector(ClusterProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClusterConfig>(
          value: provider.selectedCluster,
          dropdownColor: AppColors.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          onChanged: (ClusterConfig? newValue) {
            if (newValue != null) {
              provider.selectCluster(newValue);
            }
          },
          items: provider.clusters.map<DropdownMenuItem<ClusterConfig>>((ClusterConfig cluster) {
            return DropdownMenuItem<ClusterConfig>(
              value: cluster,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hub_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    cluster.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 300,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: const TextField(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          hintText: 'Search resources...',
          hintStyle: TextStyle(color: AppColors.textDim, fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textDim),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildUserMenu() {
    return Row(
      children: [
        const Icon(Icons.help_outline, size: 20, color: AppColors.textDim),
        const SizedBox(width: 20),
        const Icon(Icons.notifications_none, size: 20, color: AppColors.textDim),
        const SizedBox(width: 20),
        const CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary,
          child: Text('A', style: TextStyle(fontSize: 12, color: Colors.white)),
        ),
      ],
    );
  }
}
