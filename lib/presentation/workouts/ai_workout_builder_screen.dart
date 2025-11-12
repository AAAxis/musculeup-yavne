import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';

class AIWorkoutBuilderScreen extends StatefulWidget {
  const AIWorkoutBuilderScreen({super.key});

  @override
  State<AIWorkoutBuilderScreen> createState() => _AIWorkoutBuilderScreenState();
}

class _AIWorkoutBuilderScreenState extends State<AIWorkoutBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _durationController = TextEditingController();

  bool _isLoading = false;
  bool _isGenerating = false;

  String? _selectedFitnessLevel;
  String? _selectedWorkoutType;

  @override
  void dispose() {
    _goalsController.dispose();
    _experienceController.dispose();
    _equipmentController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _generateWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFitnessLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר את רמת הכושר שלך'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWorkoutType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר סוג אימון'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      // TODO: Call AI API to generate workout
      // final workoutData = {
      //   'goals': _goalsController.text.trim(),
      //   'fitness_level': _selectedFitnessLevel,
      //   'workout_type': _selectedWorkoutType,
      //   'equipment': _equipmentController.text.trim(),
      //   'duration': _durationController.text.trim(),
      // };

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('יצירת אימון בקרוב!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת האימון: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('בניית אימון עם AI'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFF8B5CF6), // purple-500
                                  Color(0xFF2563EB), // blue-600
                                  Color(0xFF059669), // green-600
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'בניית אימון עם AI',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'תן ל-AI ליצור אימון מותאם אישית על בסיס המטרות שלך',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Goals Card
                      Container(
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
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.flag,
                                    color: Colors.purple[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'המטרות שלך',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _goalsController,
                                decoration: const InputDecoration(
                                  labelText: 'מטרות כושר',
                                  hintText:
                                      'לדוגמה: בניית שריר, ירידה במשקל, שיפור סיבולת',
                                  prefixIcon: Icon(Icons.track_changes),
                                ),
                                maxLines: 2,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'אנא הזן את מטרות הכושר שלך';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedFitnessLevel,
                                decoration: const InputDecoration(
                                  labelText: 'רמת כושר',
                                  prefixIcon: Icon(Icons.trending_up),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'beginner', child: Text('מתחיל')),
                                  DropdownMenuItem(
                                      value: 'intermediate',
                                      child: Text('בינוני')),
                                  DropdownMenuItem(
                                      value: 'advanced', child: Text('מתקדם')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedFitnessLevel = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedWorkoutType,
                                decoration: const InputDecoration(
                                  labelText: 'סוג אימון',
                                  prefixIcon: Icon(Icons.fitness_center),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'strength',
                                      child: Text('אימון כוח')),
                                  DropdownMenuItem(
                                      value: 'cardio', child: Text('קרדיו')),
                                  DropdownMenuItem(
                                      value: 'hiit', child: Text('HIIT')),
                                  DropdownMenuItem(
                                      value: 'flexibility',
                                      child: Text('גמישות')),
                                  DropdownMenuItem(
                                      value: 'mixed', child: Text('מעורב')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedWorkoutType = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Preferences Card
                      Container(
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
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.settings,
                                    color: Colors.blue[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'העדפות',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _equipmentController,
                                decoration: const InputDecoration(
                                  labelText: 'ציוד זמין',
                                  hintText:
                                      'לדוגמה: משקולות, מוט, רצועות התנגדות',
                                  prefixIcon: Icon(Icons.build),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _durationController,
                                decoration: const InputDecoration(
                                  labelText: 'משך האימון (דקות)',
                                  hintText: 'לדוגמה: 30, 45, 60',
                                  prefixIcon: Icon(Icons.timer),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    final duration = int.tryParse(value);
                                    if (duration == null || duration < 10) {
                                      return 'אנא הזן משך תקף (מינימום 10 דקות)';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Generate Button Card
                      Container(
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
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed:
                                    _isGenerating ? null : _generateWorkout,
                                icon: _isGenerating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome),
                                label: Text(
                                  _isGenerating ? 'מייצר...' : 'צור אימון',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'ה-AI ינתח את הקלט שלך ויצור תוכנית אימון מותאמת אישית',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
