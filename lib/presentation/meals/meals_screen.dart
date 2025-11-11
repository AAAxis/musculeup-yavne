import 'package:flutter/material.dart';

class MealsScreen extends StatelessWidget {
  const MealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meal Plans & Recipes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Healthy recipes for your goals',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),

          // Meal Categories
          _buildMealCard(
            context,
            icon: Icons.wb_sunny,
            title: 'Breakfast',
            meals: '12 recipes',
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildMealCard(
            context,
            icon: Icons.lunch_dining,
            title: 'Lunch',
            meals: '18 recipes',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildMealCard(
            context,
            icon: Icons.dinner_dining,
            title: 'Dinner',
            meals: '20 recipes',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildMealCard(
            context,
            icon: Icons.cookie,
            title: 'Snacks',
            meals: '15 recipes',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String meals,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to meal category
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withAlpha(50), color.withAlpha(25)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 48),
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
                    const SizedBox(height: 4),
                    Text(
                      meals,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

