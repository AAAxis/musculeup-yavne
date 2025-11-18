import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';

class ManualWorkoutBuilderScreen extends StatefulWidget {
  const ManualWorkoutBuilderScreen({super.key});

  @override
  State<ManualWorkoutBuilderScreen> createState() =>
      _ManualWorkoutBuilderScreenState();
}

class _ManualWorkoutBuilderScreenState
    extends State<ManualWorkoutBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workoutNameController = TextEditingController();
  final _notesController = TextEditingController();

  final _firestoreService = FirestoreService();
  final _firestore = FirebaseFirestore.instance;
  UserModel? _user;

  bool _isLoading = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = await _firestoreService.getUser(authState.user.uid);
        if (mounted) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא הוסף לפחות תרגיל אחד'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('טוען נתוני משתמש...'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final now = DateTime.now();
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Map exercises to workout format
      final allExercises = _selectedExercises.map((ex) {
        final setsCount = ex['sets'] ?? 3;
        return {
          'name': ex['name'] ?? '',
          'category': ex['category'] ?? 'כוח',
          'sets': List.generate(setsCount, (index) => {
            'repetitions': ex['reps'] ?? 0,
            'weight': ex['weight'] ?? 0,
            'duration_seconds': ex['duration_seconds'] ?? 0,
            'completed': false,
          }),
          'completed': false,
          'notes': ex['notes'] ?? '',
          'video_url': '',
        };
      }).toList();

      final workoutData = {
        'date': dateString,
        'workout_type': 'אימון ידני',
        'status': 'פעיל',
        'start_time': now.toIso8601String(),
        'warmup_description': 'חימום כללי - 10 דקות',
        'warmup_duration': 10,
        'warmup_completed': false,
        'exercises': allExercises,
        'notes': _notesController.text.trim(),
        'total_duration': 60, // Default duration
        'created_by': _user!.email,
        'coach_workout_title': _workoutNameController.text.trim(),
        'coach_workout_description': _notesController.text.trim(),
      };

      await _firestore.collection('workouts').add(workoutData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('האימון נשמר בהצלחה! ניתן למצוא אותו בהיסטוריית האימונים'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשמירת האימון: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: _AddExerciseDialog(
          onExerciseAdded: (exercise) {
            setState(() {
              _selectedExercises.add(exercise);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('בניית אימון ידנית'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: _saveWorkout,
                      child: const Text('שמור'),
                    ),
            ),
          ],
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
                                  Color(0xFF059669), // green-600
                                  Color(0xFFEAB308), // yellow-500
                                  Color(0xFF2563EB), // blue-500
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'בנה את האימון שלך',
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
                              'צור אימון מותאם אישית על ידי בחירת תרגילים',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Workout Details Card
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
                                    Icons.edit_note,
                                    color: Colors.green[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'פרטי האימון',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _workoutNameController,
                                decoration: const InputDecoration(
                                  labelText: 'שם האימון',
                                  hintText: 'לדוגמה: כוח גוף עליון',
                                  prefixIcon: Icon(Icons.fitness_center),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'אנא הזן שם אימון';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'הערות (אופציונלי)',
                                  hintText: 'הוסף הערות או הוראות...',
                                  prefixIcon: Icon(Icons.note),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Exercises Card
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
                                    Icons.list,
                                    color: Colors.green[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'תרגילים',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _addExercise,
                                    icon: const Icon(Icons.add_circle),
                                    color: Colors.green[600],
                                    iconSize: 32,
                                    tooltip: 'הוסף תרגיל',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_selectedExercises.isEmpty)
                                Center(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 24),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.fitness_center_outlined,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'עדיין לא נוספו תרגילים',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'לחץ על כפתור + להוספת תרגילים',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark
                                                ? Colors.grey[500]
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _selectedExercises.length,
                                  itemBuilder: (context, index) {
                                    final exercise = _selectedExercises[index];
                                    return Card(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.green[100],
                                          child: Icon(
                                            Icons.fitness_center,
                                            color: Colors.green[600],
                                            size: 20,
                                          ),
                                        ),
                                        title: Text(
                                          exercise['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${exercise['sets'] ?? 0} סטים × ${exercise['reps'] ?? 0} חזרות${exercise['weight'] != null && exercise['weight']! > 0 ? ' × ${exercise['weight']} ק"ג' : ''}',
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          color: Colors.red,
                                          onPressed: () {
                                            setState(() {
                                              _selectedExercises.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info Card
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
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[600],
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'האימון שלך יישמר וניתן יהיה לגשת אליו בכל עת מהיסטוריית האימונים שלך.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
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

class _AddExerciseDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onExerciseAdded;

  const _AddExerciseDialog({required this.onExerciseAdded});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveExercise() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final exercise = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory ?? 'כוח',
      'sets': int.tryParse(_setsController.text.trim()) ?? 3,
      'reps': int.tryParse(_repsController.text.trim()) ?? 10,
      'weight': double.tryParse(_weightController.text.trim()) ?? 0,
      'duration_seconds': 0,
      'notes': _notesController.text.trim(),
    };

    widget.onExerciseAdded(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('הוסף תרגיל'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'שם התרגיל',
                  hintText: 'לדוגמה: סקוואט',
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'אנא הזן שם תרגיל';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'קטגוריה',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'כוח', child: Text('כוח')),
                  DropdownMenuItem(value: 'קרדיו', child: Text('קרדיו')),
                  DropdownMenuItem(value: 'גמישות', child: Text('גמישות')),
                  DropdownMenuItem(value: 'ליבה', child: Text('ליבה')),
                  DropdownMenuItem(value: 'אחר', child: Text('אחר')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'אנא בחר קטגוריה';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      decoration: const InputDecoration(
                        labelText: 'סטים',
                        prefixIcon: Icon(Icons.repeat),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'נדרש';
                        }
                        final sets = int.tryParse(value);
                        if (sets == null || sets < 1) {
                          return 'מספר תקף';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      decoration: const InputDecoration(
                        labelText: 'חזרות',
                        prefixIcon: Icon(Icons.repeat_one),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'נדרש';
                        }
                        final reps = int.tryParse(value);
                        if (reps == null || reps < 1) {
                          return 'מספר תקף';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'משקל (ק"ג)',
                  hintText: '0 אם ללא משקל',
                  prefixIcon: Icon(Icons.scale),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'הערות (אופציונלי)',
                  hintText: 'הוראות או הערות נוספות...',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _saveExercise,
          child: const Text('הוסף'),
        ),
      ],
    );
  }
}
