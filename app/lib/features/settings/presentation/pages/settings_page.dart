import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:k8s_monitor/features/dashboard/presentation/providers/cluster_provider.dart';
import 'package:k8s_monitor/core/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _kubeconfigController = TextEditingController();
  final _promController = TextEditingController();
  final _descController = TextEditingController();

  void _showAddClusterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add K8s Cluster', style: TextStyle(color: AppColors.textMain)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Cluster Name (e.g. Local, EKS-Prod)',
                  labelStyle: TextStyle(color: AppColors.textDim),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _kubeconfigController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Kubeconfig (YAML content)',
                  labelStyle: TextStyle(color: AppColors.textDim),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Prometheus URL (Optional)',
                  labelStyle: TextStyle(color: AppColors.textDim),
                  hintText: 'http://localhost:9090',
                  hintStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              try {
                await context.read<ClusterProvider>().addCluster(
                  name: _nameController.text,
                  kubeconfig: _kubeconfigController.text,
                  prometheusUrl: _promController.text.isNotEmpty ? _promController.text : null,
                );
                Navigator.pop(context);
                _clearControllers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cluster added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Add Cluster', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _kubeconfigController.clear();
    _promController.clear();
    _descController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final clusterProvider = context.watch<ClusterProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kubernetes Sources',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textHighlight),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Cluster', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: _showAddClusterDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (clusterProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (clusterProvider.clusters.isEmpty)
            _buildEmptyState()
          else
            Expanded(
              child: ListView.builder(
                itemCount: clusterProvider.clusters.length,
                itemBuilder: (context, index) {
                  final cluster = clusterProvider.clusters[index];
                  final isSelected = clusterProvider.selectedCluster?.id == cluster.id;
                  
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        cluster.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      subtitle: Text(
                        cluster.prometheusUrl ?? 'Using default Prometheus',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                      trailing: isSelected 
                        ? const Icon(Icons.check_circle, color: AppColors.healthy)
                        : ElevatedButton(
                            onPressed: () => clusterProvider.selectCluster(cluster),
                            child: const Text('Connect'),
                          ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: AppColors.textDim.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No clusters configured yet.',
            style: TextStyle(color: AppColors.textDim, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first K8s cluster to get started.',
            style: TextStyle(color: AppColors.textDim, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
