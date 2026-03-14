import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.sidebarWidth,
      color: AppColors.sidebar,
      child: Column(
        children: [
          _buildLogo(),
          const Divider(),
          _buildNavItem(0, Icons.dashboard_outlined, 'Dashboard'),
          _buildNavItem(1, Icons.layers_outlined, 'Namespaces'),
          _buildNavItem(2, Icons.widgets_outlined, 'Workloads'),
          _buildNavItem(3, Icons.dns_outlined, 'Nodes'),
          _buildNavItem(4, Icons.description_outlined, 'Logs'),
          _buildNavItem(5, Icons.notifications_none_outlined, 'Alerts'),
          const Divider(),
          _buildNavItem(6, Icons.source_outlined, 'Repositories'),
          _buildNavItem(7, Icons.enhanced_encryption_outlined, 'Secret Vault'),
          const Spacer(),
          _buildNavItem(8, Icons.settings_outlined, 'Settings'),
          const SizedBox(height: AppSizes.paddingM),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.paddingL,
        horizontal: AppSizes.paddingM,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: AppColors.primary, size: 28),
          const SizedBox(width: AppSizes.paddingM),
          Text(
            'K8S MONITOR',
            style: TextStyle(
              color: AppColors.textHighlight,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isSelected 
                  ? const Border(left: BorderSide(color: AppColors.primary, width: 4))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.primary : AppColors.textDim,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.textHighlight : AppColors.textDim,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
