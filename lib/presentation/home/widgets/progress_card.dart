import 'package:flutter/material.dart';
import 'package:muscleup/data/models/user_model.dart';

class ProgressCard extends StatelessWidget {
  final UserModel? user;
  final DateTime createdAt;

  const ProgressCard({
    super.key,
    required this.user,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate training days
    final now = DateTime.now();
    final trainingDays = now.difference(createdAt).inDays + 1;
    final formattedDate = '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';

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
            Row(
              children: [
                Icon(
                  Icons.track_changes,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ההתקדמות שלך',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth > 600
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth,
                      child: _buildProgressItem(
                        context,
                        icon: Icons.scale,
                        label: 'משקל נוכחי',
                        value: user?.initialWeight != null 
                            ? '${user!.initialWeight!.toStringAsFixed(1)} ק"ג'
                            : 'לא מוגדר',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
                        ),
                        iconColor: const Color(0xFF2563EB),
                        valueColor: const Color(0xFF1E40AF),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 600
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth,
                      child: _buildProgressItem(
                        context,
                        icon: Icons.track_changes,
                        label: 'שינוי במשקל',
                        value: 'טרם נמדד',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF3E8FF), Color(0xFFE9D5FF)],
                        ),
                        iconColor: const Color(0xFF9333EA),
                        valueColor: const Color(0xFF7C3AED),
                        isSmallText: true,
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth > 600
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth,
                      child: _buildProgressItem(
                        context,
                        icon: Icons.calendar_today,
                        label: 'ימי אימון',
                        value: '$trainingDays ימים',
                        subtitle: 'החל מ-$formattedDate',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                        ),
                        iconColor: const Color(0xFF059669),
                        valueColor: const Color(0xFF047857),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Gradient gradient,
    required Color iconColor,
    required Color valueColor,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: iconColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 14 : 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: iconColor.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

