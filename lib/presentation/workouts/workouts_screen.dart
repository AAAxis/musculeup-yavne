import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:muscleup/presentation/workouts/manual_workout_builder_screen.dart';
import 'package:muscleup/presentation/workouts/ai_workout_builder_screen.dart';
import 'package:muscleup/presentation/workouts/exercise_library_screen.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('אימונים'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Action Cards
            _buildActionCard(
              context,
              id: 'manual',
              title: 'בניית אימון ידנית',
              description: 'צור אימונים מותאמים אישית על ידי בחירת תרגילים',
              icon: Icons.fitness_center,
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              id: 'ai',
              title: 'בניית אימון עם AI',
              description: 'צור אימונים חכמים המבוססים על המטרות שלך',
              icon: Icons.auto_awesome,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF2563EB)],
              ),
              showDoubleIcon: true,
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              id: 'library',
              title: 'ספריית תרגילים',
              description: 'עיין בתרגילים והגדר את ברירות המחדל שלך',
              icon: Icons.library_books,
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFEF4444)],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String id,
    required String title,
    required String description,
    required IconData icon,
    required Gradient gradient,
    bool showDoubleIcon = false,
  }) {
    // Extract the main color from the gradient for the icon
    Color iconColor;
    if (gradient is LinearGradient) {
      iconColor = gradient.colors.first;
    } else {
      iconColor = Colors.green[600]!;
    }

    return InkWell(
      onTap: () {
        Widget screen;
        switch (id) {
          case 'manual':
            screen = const ManualWorkoutBuilderScreen();
            break;
          case 'ai':
            screen = const AIWorkoutBuilderScreen();
            break;
          case 'library':
            screen = const ExerciseLibraryScreen();
            break;
          default:
            return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  showDoubleIcon
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              size: 28,
                              color: iconColor,
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              icon,
                              size: 28,
                              color: iconColor,
                            ),
                          ],
                        )
                      : Icon(
                          icon,
                          size: 32,
                          color: iconColor,
                        ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 48),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

