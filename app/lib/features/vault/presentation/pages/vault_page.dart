import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/vault_provider.dart';
import '../../domain/entities/secret.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedType = 'github_token';

  @override
  Widget build(BuildContext context) {
    return Consumer<VaultProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.secrets.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (provider.error != null)
              _buildErrorBanner(provider.error!),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Securely store and manage your credentials',
                    style: TextStyle(color: AppColors.textDim),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddSecretDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Secret'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.secrets.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: provider.secrets.length,
                      itemBuilder: (context, index) {
                        final secret = provider.secrets[index];
                        return _buildSecretCard(secret, provider);
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
          Icon(Icons.lock_outline, size: 64, color: AppColors.textDim.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text('No secrets found', style: TextStyle(color: AppColors.textDim)),
          const Text('Add your first token to get started', style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSecretCard(Secret secret, VaultProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.key, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  secret.name,
                  style: const TextStyle(
                    color: AppColors.textHighlight,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${secret.type.toUpperCase()} • ${secret.description ?? "No description"}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => provider.deleteSecret(secret.name),
          ),
        ],
      ),
    );
  }

  void _showAddSecretDialog(BuildContext context, VaultProvider provider) {
    _nameController.clear();
    _valueController.clear();
    _descController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add New Secret', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Secret Name', 'e.g. github-pat', _nameController),
              const SizedBox(height: 12),
              _buildDropdown('Type', ['github_token', 'docker_registry', 'kubeconfig', 'cloud_provider', 'api_key']),
              const SizedBox(height: 12),
              _buildTextField('Value', 'Enter sensitive value', _valueController, isPassword: true),
              const SizedBox(height: 12),
              _buildTextField('Description', 'Optional description', _descController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.addSecret(
                  name: _nameController.text,
                  type: _selectedType,
                  value: _valueController.text,
                  description: _descController.text,
                );
                if (mounted) Navigator.pop(context);
              } catch (e) {
                // Error handled by provider
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Secret'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: isPassword,
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

  Widget _buildDropdown(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
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
                value: _selectedType,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => _selectedType = val);
                    setState(() => _selectedType = val);
                  }
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}
