import '../../../../core/network/api_client.dart';
import '../../domain/entities/github_entities.dart';

abstract class GitHubRepository {
  Future<Map<String, dynamic>> connectRepository(String repo, String tokenSecret);
  Future<List<GitHubCommit>> getCommits(String repo);
  Future<List<GitHubPR>> getPullRequests(String repo);
  Future<List<GitHubWorkflow>> getWorkflows(String repo);
  Future<List<GitHubRepo>> getRepositories();
  Future<void> deleteRepository(String repo);
}

class RemoteGitHubRepositoryImpl implements GitHubRepository {
  final ApiClient apiClient;

  RemoteGitHubRepositoryImpl({required this.apiClient});

  @override
  Future<Map<String, dynamic>> connectRepository(String repo, String tokenSecret) async {
    return await apiClient.post('/api/v1/github/connect', data: {
      'repository': repo,
      'token_secret_name': tokenSecret,
    });
  }

  @override
  Future<List<GitHubCommit>> getCommits(String repo) async {
    final List<dynamic> data = await apiClient.get('/api/v1/github/repos/$repo/commits');
    return data.map((json) => GitHubCommit.fromJson(json)).toList();
  }

  @override
  Future<List<GitHubPR>> getPullRequests(String repo) async {
    final List<dynamic> data = await apiClient.get('/api/v1/github/repos/$repo/pulls');
    return data.map((json) => GitHubPR.fromJson(json)).toList();
  }

  @override
  Future<List<GitHubWorkflow>> getWorkflows(String repo) async {
    final Map<String, dynamic> data = await apiClient.get('/api/v1/github/repos/$repo/workflows');
    final List<dynamic> workflows = data['workflows'] ?? data; // Try both
    return workflows.map((json) => GitHubWorkflow.fromJson(json)).toList();
  }

  @override
  Future<List<GitHubRepo>> getRepositories() async {
    final List<dynamic> data = await apiClient.get('/api/v1/github/repos');
    return data.map((json) => GitHubRepo.fromJson(json)).toList();
  }

  @override
  Future<void> deleteRepository(String repo) async {
    await apiClient.delete('/api/v1/github/repos/$repo');
  }
}
