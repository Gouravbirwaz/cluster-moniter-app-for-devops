import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/github_provider.dart';
import '../../domain/entities/github_entities.dart';
import '../../../vault/presentation/providers/vault_provider.dart';
import 'repo_details_page.dart';

class ReposPage extends StatefulWidget {
  const ReposPage({super.key});

  @override
  State<ReposPage> createState() => _ReposPageState();
}

class _ReposPageState extends State<ReposPage> {
  final _repoController = TextEditingController();
  String? _selectedTokenSecret;

  @override
  Widget build(BuildContext context) {
    return Consumer2<GitHubProvider, VaultProvider>(
      builder: (context, ghProvider, vaultProvider, child) {
        return Column(
          children: [
            _buildOverviewCards(ghProvider),
            const SizedBox(height: 24),
            if (ghProvider.error != null)
              _buildErrorBanner(ghProvider.error!),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Connected Repositories',
                    style: TextStyle(
                      color: AppColors.textHighlight,
                      fontSize: 16, // Smaller font
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showConnectRepoDialog(context, ghProvider, vaultProvider),
                  icon: const Icon(Icons.link),
                  label: const Text('Connect Repository'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ghProvider.isLoading && ghProvider.repos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ghProvider.repos.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: ghProvider.repos.length,
                          itemBuilder: (context, index) {
                            final repo = ghProvider.repos[index];
                            return _buildRepoCard(repo, ghProvider);
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.source_outlined, size: 64, color: AppColors.textDim.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No repositories connected', style: TextStyle(color: AppColors.textDim)),
          const Text('Connect your first repository to start monitoring commits and CI/CD', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(GitHubProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: _buildStatCard('Total Repos', provider.repos.length.toString().padLeft(2, '0'), Icons.source, Colors.blue),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: _buildStatCard('Active Workflows', '00', Icons.auto_mode, Colors.green),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 160,
            child: _buildStatCard('Pipeline Failures', '00', Icons.error_outline, Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
        padding: const EdgeInsets.all(12), // Reduced from 20
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20), // Smaller icon
            ),
            const SizedBox(width: 8), // Reduced from 16
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 13), overflow: TextOverflow.ellipsis),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textHighlight,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildRepoCard(GitHubRepo repo, GitHubProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.folder_outlined, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  repo.name,
                  style: const TextStyle(
                    color: AppColors.textHighlight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.link_off, color: Colors.redAccent, size: 20),
                tooltip: 'Disconnect Repository',
                onPressed: () => _showDeleteRepoConfirmation(context, provider, repo.name),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('HEALTHY', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildRepoMetric(Icons.history, 'Activity'),
              _buildRepoMetric(Icons.merge_type, 'PRs'),
              _buildRepoMetric(Icons.star_border, '${repo.stars} Stars'),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RepoDetailsPage(repoName: repo.name)),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('View Details →', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteRepoConfirmation(BuildContext context, GitHubProvider provider, String repoName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Disconnect Repository', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to disconnect $repoName? This will stop real-time monitoring.', 
          style: const TextStyle(color: AppColors.textDim)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteRepo(repoName);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepoMetric(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textDim),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
      ],
    );
  }

  void _showConnectRepoDialog(BuildContext context, GitHubProvider ghProvider, VaultProvider vaultProvider) {
    _repoController.clear();
    _selectedTokenSecret = vaultProvider.secrets.isNotEmpty ? vaultProvider.secrets.first.name : null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Connect New Repository', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Connect a GitHub repository to monitor activity, workflows, and CI/CD events in real-time.',
                style: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
              const SizedBox(height: 20),
              _buildTextField('Repository Name', 'owner/repo', _repoController),
              const SizedBox(height: 16),
              _buildVaultTokenDropdown(vaultProvider),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_selectedTokenSecret != null) {
                await ghProvider.connectRepo(_repoController.text, _selectedTokenSecret!);
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Connect Repo'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildVaultTokenDropdown(VaultProvider vaultProvider) {
    final tokens = vaultProvider.secrets.where((s) => s.type == 'github_token').toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Auth Token (from Vault)', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: StatefulBuilder(builder: (context, setDialogState) {
              return DropdownButton<String>(
                value: _selectedTokenSecret,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                hint: const Text('Select a token', style: TextStyle(color: Colors.white24)),
                items: tokens.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => _selectedTokenSecret = val);
                    setState(() => _selectedTokenSecret = val);
                  }
                },
              );
            }),
          ),
        ),
        if (tokens.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('No GitHub tokens found in vault.', style: TextStyle(color: Colors.orange, fontSize: 11)),
          ),
      ],
    );
  }
}
