import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/alerts/data/repositories/mock_alert_repository_impl.dart';
import 'features/alerts/data/repositories/remote_alert_repository_impl.dart';
import 'features/alerts/domain/repositories/alert_repository.dart';
import 'features/auth/data/repositories/mock_auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/data/repositories/mock_dashboard_repository_impl.dart';
import 'features/dashboard/data/repositories/remote_dashboard_repository_impl.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/nodes/data/repositories/mock_node_repository_impl.dart';
import 'features/nodes/data/repositories/remote_node_repository_impl.dart';
import 'features/nodes/domain/repositories/node_repository.dart';
import 'features/workloads/data/repositories/mock_workload_repository_impl.dart';
import 'features/workloads/data/repositories/remote_workload_repository_impl.dart';
import 'features/workloads/domain/repositories/workload_repository.dart';

void main() {
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 10.0.2.2 is localhost for Android Emulator. Use localhost for iOS/Web/Windows.
    String baseUrl = 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:8000';
      }
    } catch (e) {
      // Platform check might fail on web, default to localhost
    }
    final apiClient = ApiClient(baseUrl: baseUrl);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => MockAuthRepositoryImpl(),
        ),
        RepositoryProvider<DashboardRepository>(
          create: (context) => RemoteDashboardRepositoryImpl(apiClient: apiClient),
        ),
        RepositoryProvider<NodeRepository>(
          create: (context) => RemoteNodeRepositoryImpl(apiClient: apiClient),
        ),
        RepositoryProvider<WorkloadRepository>(
           create: (context) => RemoteWorkloadRepositoryImpl(apiClient: apiClient),
        ),
        RepositoryProvider<AlertRepository>(
           create: (context) => RemoteAlertRepositoryImpl(apiClient: apiClient),
        ),
      ],
      child: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
        ),
        child: MaterialApp(
          title: 'K8s Monitor',
          theme: AppTheme.darkTheme,
          home: const LoginPage(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}
