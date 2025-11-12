import 'package:flutter/material.dart';

class QuickActionsCard extends StatelessWidget {
  final VoidCallback onWeightUpdateTap;
  final VoidCallback onAddMealTap;
  final VoidCallback onWaterDocTap;
  final VoidCallback onProgressTrackingTap;

  const QuickActionsCard({
    super.key,
    required this.onWeightUpdateTap,
    required this.onAddMealTap,
    required this.onWaterDocTap,
    required this.onProgressTrackingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'פעולות מהירות',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionButton(
                  context,
                  icon: Icons.scale,
                  label: 'עדכון משקל',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  ),
                  iconColor: const Color(0xFFD97706),
                  onTap: onWeightUpdateTap,
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.restaurant,
                  label: 'הוספת ארוחה',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                  ),
                  iconColor: const Color(0xFF059669),
                  onTap: onAddMealTap,
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.water_drop,
                  label: 'תיעוד מים',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
                  ),
                  iconColor: const Color(0xFF2563EB),
                  onTap: onWaterDocTap,
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.track_changes,
                  label: 'מעקב התקדמות',
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
                  ),
                  iconColor: const Color(0xFF9333EA),
                  onTap: onProgressTrackingTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Gradient gradient,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

