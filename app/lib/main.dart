import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/api_client.dart';
import 'core/services/websocket_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/main_layout.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/nodes/data/repositories/remote_node_repository_impl.dart';
import 'features/nodes/domain/repositories/node_repository.dart';
import 'features/workloads/data/repositories/remote_workload_repository_impl.dart';
import 'features/workloads/domain/repositories/workload_repository.dart';
import 'features/alerts/data/repositories/remote_alert_repository_impl.dart';
import 'features/alerts/domain/repositories/alert_repository.dart';
import 'features/vault/domain/repositories/vault_repository.dart';
import 'features/vault/data/repositories/remote_vault_repository_impl.dart';
import 'features/vault/presentation/providers/vault_provider.dart';
import 'features/github/data/repositories/remote_github_repository_impl.dart';
import 'features/github/presentation/providers/github_provider.dart';
import 'features/github/presentation/pages/repos_page.dart';
import 'features/vault/presentation/pages/vault_page.dart';
import 'features/github/domain/entities/github_entities.dart';
import 'features/vault/domain/entities/secret.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Production Graded Base URL
    const String baseUrl = 'https://unengaged-slatier-anibal.ngrok-free.dev';
    final apiClient = ApiClient(baseUrl: baseUrl);
    final webSocketService = WebSocketService(url: baseUrl)..connect('/api/v1/ws/monitor');

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<WebSocketService>.value(value: webSocketService),
        Provider<NodeRepository>(
          create: (_) => RemoteNodeRepositoryImpl(apiClient: apiClient),
        ),
        Provider<WorkloadRepository>(
          create: (_) => RemoteWorkloadRepositoryImpl(apiClient: apiClient),
        ),
        Provider<AlertRepository>(
          create: (_) => RemoteAlertRepositoryImpl(apiClient: apiClient),
        ),
        // GitHub Service Integration
        ProxyProvider<ApiClient, GitHubRepository>(
          update: (_, client, __) => RemoteGitHubRepositoryImpl(apiClient: client),
        ),
        ProxyProvider<ApiClient, VaultRepository>(
          update: (_, client, __) => RemoteVaultRepositoryImpl(apiClient: client),
        ),
        ChangeNotifierProvider(
          create: (context) => VaultProvider(
            repository: context.read<VaultRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => GitHubProvider(
            repository: context.read<GitHubRepository>(),
            webSocketService: context.read<WebSocketService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(
            apiClient: apiClient,
            webSocketService: webSocketService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'K8s Monitor Platform',
        theme: AppTheme.darkTheme,
        home: const MainLayout(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

