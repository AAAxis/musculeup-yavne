import 'package:flutter/material.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Programs',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your workout plan',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Workout Programs
          _buildWorkoutCard(
            context,
            icon: Icons.fitness_center,
            title: 'Strength Training',
            duration: '45-60 min',
            level: 'Intermediate',
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildWorkoutCard(
            context,
            icon: Icons.directions_run,
            title: 'Cardio Blast',
            duration: '30-45 min',
            level: 'All Levels',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildWorkoutCard(
            context,
            icon: Icons.self_improvement,
            title: 'Flexibility & Yoga',
            duration: '20-30 min',
            level: 'Beginner',
            color: Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildWorkoutCard(
            context,
            icon: Icons.sports_martial_arts,
            title: 'HIIT',
            duration: '20-30 min',
            level: 'Advanced',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String duration,
    required String level,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to workout details
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.bar_chart, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          level,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_filled, color: color, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

