import 'package:equatable/equatable.dart';

class GitHubRepo extends Equatable {
  final String name;
  final String? description;
  final String status;
  final int stars;
  final int forkCount;
  final String? defaultBranch;

  const GitHubRepo({
    required this.name,
    this.description,
    required this.status,
    required this.stars,
    this.forkCount = 0,
    this.defaultBranch,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    return GitHubRepo(
      name: json['full_name'] ?? json['name'],
      description: json['description'],
      status: 'Healthy', // Derived
      stars: json['stargazers_count'] ?? 0,
      forkCount: json['forks_count'] ?? 0,
      defaultBranch: json['default_branch'],
    );
  }

  @override
  List<Object?> get props => [name, status, stars];
}

class GitHubCommit extends Equatable {
  final String sha;
  final String message;
  final String author;
  final DateTime timestamp;

  const GitHubCommit({
    required this.sha,
    required this.message,
    required this.author,
    required this.timestamp,
  });

  factory GitHubCommit.fromJson(Map<String, dynamic> json) {
    final commitData = json['commit'];
    return GitHubCommit(
      sha: json['sha'],
      message: commitData['message'],
      author: commitData['author']['name'],
      timestamp: DateTime.parse(commitData['author']['date']),
    );
  }

  @override
  List<Object?> get props => [sha, message];
}
class GitHubPR extends Equatable {
  final int id;
  final String title;
  final String state;
  final String user;
  final DateTime createdAt;

  const GitHubPR({
    required this.id,
    required this.title,
    required this.state,
    required this.user,
    required this.createdAt,
  });

  factory GitHubPR.fromJson(Map<String, dynamic> json) {
    return GitHubPR(
      id: json['number'],
      title: json['title'],
      state: json['state'].toString().toUpperCase(),
      user: json['user']['login'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, title, state];
}

class GitHubWorkflow extends Equatable {
  final int id;
  final String name;
  final String state;
  final String? badgeUrl;

  const GitHubWorkflow({
    required this.id,
    required this.name,
    required this.state,
    this.badgeUrl,
  });

  factory GitHubWorkflow.fromJson(Map<String, dynamic> json) {
    return GitHubWorkflow(
      id: json['id'],
      name: json['name'],
      state: json['state'],
      badgeUrl: json['badge_url'],
    );
  }

  @override
  List<Object?> get props => [id, name, state];
}
