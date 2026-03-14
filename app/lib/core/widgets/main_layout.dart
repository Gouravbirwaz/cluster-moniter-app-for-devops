import 'package:flutter/material.dart';
import 'sidebar.dart';
import '../theme/app_colors.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/nodes/presentation/pages/nodes_page.dart';
import '../../features/workloads/presentation/pages/namespaces_page.dart';
import '../../features/workloads/presentation/pages/workloads_page.dart';
import '../../features/alerts/presentation/pages/alerts_page.dart';
import '../../features/logs/presentation/pages/logs_page.dart';
import '../../features/vault/presentation/pages/vault_page.dart';
import '../../features/github/presentation/pages/repos_page.dart';

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
    {'title': 'Repositories', 'page': const ReposPage()},
    {'title': 'Secret Vault', 'page': const VaultPage()},
    {'title': 'Settings', 'page': const Center(child: Text('Settings Page', style: TextStyle(color: Colors.white)))},
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

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
                  _buildHeader(_navigationItems[_selectedIndex]['title'], isMobile),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: _navigationItems[_selectedIndex]['page'],
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

  Widget _buildHeader(String title, bool isMobile) {
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
          Expanded(
            flex: 2,
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textHighlight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (MediaQuery.of(context).size.width > 600)
            Flexible(
              flex: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildSearchBox(),
              ),
            ),
          const Spacer(),
          _buildUserMenu(),
        ],
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
