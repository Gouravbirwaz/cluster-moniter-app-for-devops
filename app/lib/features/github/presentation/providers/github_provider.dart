import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/repositories/remote_github_repository_impl.dart';
import '../../domain/entities/github_entities.dart';

class GitHubProvider with ChangeNotifier {
  final GitHubRepository repository;
  
  List<GitHubRepo> _repos = [];
  Map<String, List<GitHubCommit>> _repoCommits = {};
  Map<String, List<GitHubPR>> _repoPRs = {};
  Map<String, List<GitHubWorkflow>> _repoWorkflows = {};
  bool _isLoading = false;
  String? _error;

  final WebSocketService? webSocketService;
  StreamSubscription? _repoSubscription;

  GitHubProvider({required this.repository, this.webSocketService}) {
    fetchRepos();
  }

  List<GitHubRepo> get repos => _repos;
  Map<String, List<GitHubCommit>> get repoCommits => _repoCommits;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<GitHubCommit> getCommitsForRepo(String repo) => _repoCommits[repo] ?? [];
  List<GitHubPR> getPRsForRepo(String repo) => _repoPRs[repo] ?? [];
  List<GitHubWorkflow> getWorkflowsForRepo(String repo) => _repoWorkflows[repo] ?? [];

  Future<void> fetchRepos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _repos = await repository.getRepositories();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRepoDetails(String repo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getCommits(repo),
        repository.getPullRequests(repo),
        repository.getWorkflows(repo),
      ]);
      
      _repoCommits[repo] = results[0] as List<GitHubCommit>;
      _repoPRs[repo] = results[1] as List<GitHubPR>;
      _repoWorkflows[repo] = results[2] as List<GitHubWorkflow>;
      
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void subscribeToRepo(String owner, String repo) async {
    if (webSocketService == null) return;
    
    await _repoSubscription?.cancel();
    
    final channel = '/ws/repo/$owner/$repo';
    try {
      final stream = await webSocketService!.createStandaloneStream(channel);
      _repoSubscription = stream.listen((event) {
        if (event['type'] == 'GITHUB_EVENT') {
          // Refresh data or handle specific event types
          // fetchCommits(owner, repo);
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('GitHub WS Error: $e');
    }
  }

  @override
  void dispose() {
    _repoSubscription?.cancel();
    super.dispose();
  }

  Future<void> connectRepo(String repo, String tokenSecret) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.connectRepository(repo, tokenSecret);
      await fetchRepos(); // Refresh the list after connection
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRepo(String repo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await repository.deleteRepository(repo);
      await fetchRepos();
      _repoCommits.remove(repo);
      _repoPRs.remove(repo);
      _repoWorkflows.remove(repo);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
