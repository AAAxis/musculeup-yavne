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
          'name': ex['name'] ?? ex['name_he'] ?? ex['name_en'] ?? '',
          'name_he': ex['name_he'],
          'name_en': ex['name_en'],
          'exercise_id': ex['id'], // Store the exercise ID from exerciseDefinitions
          'category': ex['category'] ?? 'Strength',
          'muscle_group': ex['muscle_group'],
          'sets': List.generate(setsCount, (index) => {
            'repetitions': ex['reps'] ?? 0,
            'weight': ex['weight'] ?? 0,
            'duration_seconds': ex['duration_seconds'] ?? 0,
            'completed': false,
          }),
          'completed': false,
          'notes': ex['notes'] ?? '',
          'video_url': ex['video_url'] ?? '',
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

  void _addExercise() async {
    final selectedExercise = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: _ExerciseSelectionScreen(),
        ),
      ),
    );

    if (selectedExercise != null && mounted) {
      // Show configuration dialog for sets, reps, weight
      _showExerciseConfigurationDialog(selectedExercise);
    }
  }

  void _showExerciseConfigurationDialog(Map<String, dynamic> exercise) {
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');
    final weightController = TextEditingController(text: exercise['default_weight']?.toString() ?? '0');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(exercise['name_he'] ?? exercise['name_en'] ?? 'תרגיל'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (exercise['description'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      exercise['description'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: setsController,
                        decoration: const InputDecoration(
                          labelText: 'סטים',
                          prefixIcon: Icon(Icons.repeat),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: repsController,
                        decoration: const InputDecoration(
                          labelText: 'חזרות',
                          prefixIcon: Icon(Icons.repeat_one),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    labelText: 'משקל (ק"ג)',
                    hintText: '0 אם ללא משקל',
                    prefixIcon: Icon(Icons.scale),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
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
          actions: [
            TextButton(
              onPressed: () {
                setsController.dispose();
                repsController.dispose();
                weightController.dispose();
                notesController.dispose();
                Navigator.pop(context);
              },
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                final configuredExercise = {
                  'id': exercise['id'],
                  'name': exercise['name_he'] ?? exercise['name_en'] ?? '',
                  'name_he': exercise['name_he'],
                  'name_en': exercise['name_en'],
                  'category': exercise['category'] ?? 'Strength',
                  'muscle_group': exercise['muscle_group'],
                  'sets': int.tryParse(setsController.text.trim()) ?? 3,
                  'reps': int.tryParse(repsController.text.trim()) ?? 10,
                  'weight': double.tryParse(weightController.text.trim()) ?? 0,
                  'duration_seconds': 0,
                  'notes': notesController.text.trim(),
                };

                setState(() {
                  _selectedExercises.add(configuredExercise);
                });

                setsController.dispose();
                repsController.dispose();
                weightController.dispose();
                notesController.dispose();
                Navigator.pop(context);
              },
              child: const Text('הוסף'),
            ),
          ],
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
                                          exercise['name'] ?? exercise['name_he'] ?? exercise['name_en'] ?? '',
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

class _ExerciseSelectionScreen extends StatefulWidget {
  @override
  State<_ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<_ExerciseSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<Map<String, dynamic>> _exercises = [];
  final List<Map<String, dynamic>> _filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _selectedMuscleGroup;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exercises = await _firestoreService.getExercises(
        muscleGroup: _selectedMuscleGroup,
        category: _selectedCategory,
      );
      
      setState(() {
        _exercises.clear();
        _exercises.addAll(exercises);
        _filterExercises();
      });
    } catch (e) {
      print('Error loading exercises: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת התרגילים: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterExercises() {
    final searchTerm = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredExercises.clear();
      _filteredExercises.addAll(_exercises.where((exercise) {
        final nameHe = (exercise['name_he'] ?? '').toString().toLowerCase();
        final nameEn = (exercise['name_en'] ?? '').toString().toLowerCase();
        final muscleGroup = (exercise['muscle_group'] ?? '').toString().toLowerCase();
        final category = (exercise['category'] ?? '').toString().toLowerCase();
        
        if (searchTerm.isEmpty) {
          return true;
        }
        
        return nameHe.contains(searchTerm) ||
            nameEn.contains(searchTerm) ||
            muscleGroup.contains(searchTerm) ||
            category.contains(searchTerm);
      }).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('בחר תרגיל'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filters
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'חפש תרגיל...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          _filterExercises();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedMuscleGroup,
                              decoration: InputDecoration(
                                labelText: 'קבוצת שרירים',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('הכל')),
                                const DropdownMenuItem(value: 'Chest', child: Text('חזה')),
                                const DropdownMenuItem(value: 'Back', child: Text('גב')),
                                const DropdownMenuItem(value: 'Legs', child: Text('רגליים')),
                                const DropdownMenuItem(value: 'Shoulders', child: Text('כתפיים')),
                                const DropdownMenuItem(value: 'Biceps', child: Text('בייספס')),
                                const DropdownMenuItem(value: 'Triceps', child: Text('טריצפס')),
                                const DropdownMenuItem(value: 'Core', child: Text('ליבה')),
                                const DropdownMenuItem(value: 'Full Body', child: Text('מלא גוף')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedMuscleGroup = value;
                                });
                                _loadExercises();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'קטגוריה',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('הכל')),
                                const DropdownMenuItem(value: 'Strength', child: Text('כוח')),
                                const DropdownMenuItem(value: 'Cardio', child: Text('קרדיו')),
                                const DropdownMenuItem(value: 'Mobility', child: Text('גמישות')),
                                const DropdownMenuItem(value: 'Functional', child: Text('פונקציונלי')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                                _loadExercises();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Exercises list
                Expanded(
                  child: _filteredExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'אין תרגילים זמינים',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                  exercise['name_he'] ?? exercise['name_en'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (exercise['name_en'] != null && exercise['name_he'] != null)
                                      Text(
                                        exercise['name_en'] ?? '',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (exercise['muscle_group'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              exercise['muscle_group'] ?? '',
                                              style: TextStyle(fontSize: 11, color: Colors.green[800]),
                                            ),
                                          ),
                                        if (exercise['category'] != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              exercise['category'] ?? '',
                                              style: TextStyle(fontSize: 11, color: Colors.blue[800]),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.pop(context, exercise);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
