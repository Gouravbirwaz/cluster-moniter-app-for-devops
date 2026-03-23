import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:provider/provider.dart';
import 'package:k8s_monitor/core/network/api_client.dart';
import 'package:k8s_monitor/core/services/websocket_service.dart';
import 'package:k8s_monitor/core/theme/app_theme.dart';
import 'package:k8s_monitor/core/widgets/main_layout.dart';
import 'package:k8s_monitor/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:k8s_monitor/features/nodes/data/repositories/remote_node_repository_impl.dart';
import 'package:k8s_monitor/features/nodes/domain/repositories/node_repository.dart';
import 'package:k8s_monitor/features/dashboard/presentation/providers/cluster_provider.dart';
import 'package:k8s_monitor/features/workloads/data/repositories/remote_workload_repository_impl.dart';
import 'package:k8s_monitor/features/workloads/domain/repositories/workload_repository.dart';
import 'package:k8s_monitor/features/alerts/data/repositories/remote_alert_repository_impl.dart';
import 'package:k8s_monitor/features/alerts/domain/repositories/alert_repository.dart';
import 'package:k8s_monitor/features/vault/domain/repositories/vault_repository.dart';
import 'package:k8s_monitor/features/vault/data/repositories/remote_vault_repository_impl.dart';
import 'package:k8s_monitor/features/vault/presentation/providers/vault_provider.dart';
import 'package:k8s_monitor/features/github/data/repositories/remote_github_repository_impl.dart';
import 'package:k8s_monitor/features/github/presentation/providers/github_provider.dart';
import 'package:k8s_monitor/features/github/presentation/pages/repos_page.dart';
import 'package:k8s_monitor/features/vault/presentation/pages/vault_page.dart';
import 'package:k8s_monitor/features/github/domain/entities/github_entities.dart';
import 'package:k8s_monitor/features/vault/domain/entities/secret.dart';
import 'package:k8s_monitor/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:k8s_monitor/features/auth/presentation/pages/login_page.dart';
import 'package:k8s_monitor/features/auth/data/repositories/remote_auth_repository_impl.dart';
import 'package:k8s_monitor/features/ai_ops/presentation/providers/ai_chat_provider.dart';



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
          create: (context) => AiChatProvider(
            apiClient: apiClient,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ClusterProvider(
            apiClient: apiClient,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(
            apiClient: apiClient,
            webSocketService: webSocketService,
          ),
        ),

      ],
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository: RemoteAuthRepositoryImpl(apiClient: apiClient)),
        child: MaterialApp(
          title: 'K8s Monitor Platform',
          theme: AppTheme.darkTheme,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return const MainLayout();
              }
              return const LoginPage();
            },
          ),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

