import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OnboardingPage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const OnboardingPage({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hub_outlined, size: 80, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Welcome to DevOps Tracker',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textHighlight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'It looks like you haven\'t configured a Kubernetes cluster yet. Connect your first cluster to start monitoring your infrastructure.',
              style: TextStyle(fontSize: 16, color: AppColors.textMain, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildStep(1, 'Obtain your kubeconfig file (usually at ~/.kube/config)'),
            _buildStep(2, 'Navigate to Settings and click "Add Cluster"'),
            _buildStep(3, 'Paste your kubeconfig content and optional Prometheus URL'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Configure Now',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Text('$number', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textMain, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
