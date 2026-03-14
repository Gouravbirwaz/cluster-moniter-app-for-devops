import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/github_provider.dart';
import '../../domain/entities/github_entities.dart';

class RepoDetailsPage extends StatefulWidget {
  final String repoName;

  const RepoDetailsPage({super.key, required this.repoName});

  @override
  State<RepoDetailsPage> createState() => _RepoDetailsPageState();
}

class _RepoDetailsPageState extends State<RepoDetailsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Fetch real data and subscribe to live updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GitHubProvider>();
      provider.fetchRepoDetails(widget.repoName);
      
      final parts = widget.repoName.split('/');
      if (parts.length == 2) {
        provider.subscribeToRepo(parts[0], parts[1]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GitHubProvider>(
      builder: (context, ghProvider, child) {
        final repo = ghProvider.repos.firstWhere(
          (r) => r.name == widget.repoName,
          orElse: () => GitHubRepo(name: widget.repoName, status: 'Unknown', stars: 0),
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                PreferredSize(
                  preferredSize: const Size.fromHeight(100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.repoName,
                              style: const TextStyle(
                                color: AppColors.textHighlight,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: AppColors.primary,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textDim,
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Commits'),
                          Tab(text: 'Pull Requests'),
                          Tab(text: 'Workflows'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(repo, ghProvider),
                      _buildCommitsTab(ghProvider),
                      _buildPRsTab(ghProvider),
                      _buildWorkflowsTab(ghProvider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(GitHubRepo repo, GitHubProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repo.description != null) ...[
            Text('Description', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 4),
            Text(repo.description!, style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(height: 24),
          ],
          _buildInfoGrid(repo),
          const SizedBox(height: 24),
          const Text('Recent Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActivityTimeline(provider),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(GitHubRepo repo) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, // Changed from 4 for better fit
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2, // Decreased from 3 to give more height
      children: [
        _buildMiniStat('Branch', repo.defaultBranch ?? 'main', Icons.account_tree),
        _buildMiniStat('Stars', repo.stars.toString(), Icons.star_border),
        _buildMiniStat('Forks', repo.forkCount.toString(), Icons.grain),
        _buildMiniStat('Status', repo.status, Icons.check_circle_outline),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 10), overflow: TextOverflow.ellipsis),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitsTab(GitHubProvider provider) {
    final commits = provider.getCommitsForRepo(widget.repoName);
    
    if (provider.isLoading && commits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (commits.isEmpty) {
      return const Center(child: Text('No commits found', style: TextStyle(color: AppColors.textDim)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: commits.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
      itemBuilder: (context, index) {
        final commit = commits[index];
        final timeAgo = _getTimeAgo(commit.timestamp);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: const CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.history, color: Colors.white, size: 16),
          ),
          title: Text(commit.message, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('${commit.author} committed $timeAgo', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          trailing: Text(commit.sha.substring(0, 7), style: const TextStyle(color: AppColors.primary, fontFamily: 'monospace')),
        );
      },
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'just now';
  }

  Widget _buildPRsTab(GitHubProvider provider) {
    final prs = provider.getPRsForRepo(widget.repoName);
    
    if (provider.isLoading && prs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prs.isEmpty) {
      return const Center(child: Text('No pull requests found', style: TextStyle(color: AppColors.textDim)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: prs.length,
      itemBuilder: (context, index) {
        final pr = prs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.merge_type, 
                    color: pr.state == 'OPEN' ? Colors.green : Colors.purpleAccent, 
                    size: 18
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pr.title} #${pr.id}', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (pr.state == 'OPEN' ? Colors.green : Colors.purpleAccent).withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                      pr.state, 
                      style: TextStyle(
                        color: pr.state == 'OPEN' ? Colors.green : Colors.purpleAccent, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'by ${pr.user} • ${_getTimeAgo(pr.createdAt)}', 
                style: const TextStyle(color: AppColors.textDim, fontSize: 12)
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkflowsTab(GitHubProvider provider) {
    final workflows = provider.getWorkflowsForRepo(widget.repoName);
    
    if (provider.isLoading && workflows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workflows.isEmpty) {
      return const Center(child: Text('No workflows found', style: TextStyle(color: AppColors.textDim)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workflows.length,
      itemBuilder: (context, index) {
        final workflow = workflows[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: ListTile(
            leading: Icon(
              Icons.auto_mode, 
              color: workflow.state == 'active' ? Colors.green : AppColors.textDim,
              size: 20,
            ),
            title: Text(workflow.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text('Status: ${workflow.state}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            trailing: workflow.badgeUrl != null 
              ? Image.network(workflow.badgeUrl!, height: 20, errorBuilder: (_, __, ___) => const SizedBox.shrink())
              : const Icon(Icons.chevron_right, color: AppColors.textDim),
          ),
        );
      },
    );
  }

  Widget _buildJobStep(String name, String status, String duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),
          const Spacer(),
          Text(duration, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(GitHubProvider provider) {
    final commits = provider.getCommitsForRepo(widget.repoName).take(5).toList();
    
    if (commits.isEmpty) {
      return const Text('No recent activity found', style: TextStyle(color: AppColors.textDim, fontSize: 12));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: commits.length,
      itemBuilder: (context, index) {
        final commit = commits[index];
        final timeAgo = _getTimeAgo(commit.timestamp);
        return IntrinsicHeight(
          child: Row(
            children: [
              Column(
                children: [
                   Icon(Icons.circle, size: 10, color: index == 0 ? AppColors.primary : AppColors.border),
                   if (index < commits.length - 1)
                     Expanded(child: Container(width: 1, color: AppColors.border)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(commit.message, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('By ${commit.author} • $timeAgo', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
