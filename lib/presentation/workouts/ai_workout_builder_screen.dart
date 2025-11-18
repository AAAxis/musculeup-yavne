import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/ai_service.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';

class AIWorkoutBuilderScreen extends StatefulWidget {
  const AIWorkoutBuilderScreen({super.key});

  @override
  State<AIWorkoutBuilderScreen> createState() => _AIWorkoutBuilderScreenState();
}

class _AIWorkoutBuilderScreenState extends State<AIWorkoutBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalsController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _aiService = AIService();
  final _firestoreService = FirestoreService();
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isGeneratingImage = false;
  bool _isSaving = false;
  Map<String, dynamic>? _generatedWorkout;
  String? _errorMessage;
  UserModel? _user;

  String? _selectedFitnessLevel;
  String? _selectedWorkoutType;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _loadUserData();
  }

  @override
  void dispose() {
    _goalsController.dispose();
    _equipmentController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeAI() async {
    try {
      await _aiService.initialize();
    } catch (e) {
      print('Warning: Failed to initialize AI service: $e');
    }
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
      _isGenerating = true;
      _isGeneratingImage = false;
      _errorMessage = null;
      _generatedWorkout = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      // Fetch recent workout history
      final recentWorkoutsQuery = await _firestore
          .collection('workouts')
          .where('created_by', isEqualTo: _user!.email)
          .where('status', isEqualTo: 'הושלם')
          .orderBy('date', descending: true)
          .limit(10)
          .get();

      final recentWorkouts = recentWorkoutsQuery.docs
          .map((doc) => doc.data())
          .toList();

      final recentWorkoutsText = recentWorkouts.isNotEmpty
          ? recentWorkouts
              .take(5)
              .map((w) =>
                  '${w['date']}: ${w['workout_type'] ?? w['coach_workout_title'] ?? 'אימון'} - ${w['completed_exercises_count'] ?? 0} תרגילים הושלמו')
              .join('\n')
          : 'אין אימונים קודמים';

      // Map fitness level and workout type to Hebrew
      final fitnessLevelMap = {
        'beginner': 'מתחיל',
        'intermediate': 'בינוני',
        'advanced': 'מתקדם',
      };

      final workoutTypeMap = {
        'strength': 'אימון כוח',
        'cardio': 'קרדיו',
        'hiit': 'HIIT',
        'flexibility': 'גמישות',
        'mixed': 'מעורב',
      };

      final difficultyLevel = fitnessLevelMap[_selectedFitnessLevel] ?? _selectedFitnessLevel!;
      final workoutType = workoutTypeMap[_selectedWorkoutType] ?? _selectedWorkoutType!;
      final duration = _durationController.text.trim().isNotEmpty
          ? int.tryParse(_durationController.text.trim()) ?? 60
          : 60;
      final userGoal = _goalsController.text.trim();
      final userNotes = _notesController.text.trim();
      final equipment = _equipmentController.text.trim();

      final userContext = '''
פרטי המשתמש:
- שם: ${_user!.name}
- גיל: ${_user!.birthDate != null ? DateTime.now().difference(DateTime.parse(_user!.birthDate!)).inDays ~/ 365 : 'לא ידוע'}
- משקל נוכחי: ${_user!.initialWeight ?? 'לא ידוע'} ק"ג
- תאריך התחלת אימונים: ${_user!.createdAt != null ? '${_user!.createdAt!.day}/${_user!.createdAt!.month}/${_user!.createdAt!.year}' : 'לא ידוע'}

אימונים אחרונים שבוצעו:
$recentWorkoutsText

הערות נוספות מהמשתמש: ${userNotes.isNotEmpty ? userNotes : 'אין'}
      ''';

      final prompt = '''
אתה מאמן כושר מקצועי. צור אימון מותאם לפי הפרטים הבאים:

$userContext

דרישות לאימון:
1. משך האימון: בדיוק $duration דקות (כולל חימום וסיום)
2. מטרת האימון: $userGoal
3. סוג אימון: $workoutType
4. רמת קושי: $difficultyLevel
5. ציוד זמין: ${equipment.isNotEmpty ? equipment : 'כל הציוד זמין'}
6. העדפות נוספות: ${userNotes.isNotEmpty ? userNotes : 'אין'}

הערות חשובות:
- משך האימון חייב להיות בדיוק $duration דקות
- כלול 5-10 דקות חימום ו-5 דקות סיום/מתיחות
- הכן רשימת תרגילים שתתאים למשך זמן זה
- התאם את מספר הסטים והחזרות בהתאם

חשוב מאוד: החזר את התשובה בפורמט JSON עם המבנה הבא בדיוק. השתמש בשמות השדות באנגלית בלבד (workout_title, exercises וכו'), גם אם התוכן בעברית.

דוגמה למבנה הנדרש:
{
  "workout_title": "אימון חיטוב מתקדם",
  "workout_description": "אימון ממוקד לחיטוב ושריפת קלוריות",
  "why_this_workout": "האימון מתאים למטרת החיטוב שלך ומשלב תרגילי כוח וקרדיו",
  "estimated_duration": $duration,
  "difficulty_level": "$difficultyLevel",
  "exercises": [
    {
      "name": "סקוואט",
      "category": "רגליים",
      "sets": 4,
      "reps": 15,
      "weight_suggestion": 0,
      "duration_seconds": 0,
      "rest_seconds": 45,
      "notes": "שמור על גב ישר, ירך עד מקביל לרצפה"
    },
    {
      "name": "פלאנק",
      "category": "ליבה",
      "sets": 3,
      "reps": 0,
      "weight_suggestion": 0,
      "duration_seconds": 60,
      "rest_seconds": 30,
      "notes": "שמור על גוף ישר, נשום עמוק"
    }
  ]
}

החזר רק את ה-JSON, ללא טקסט נוסף לפני או אחרי. כל המפתחות (keys) חייבים להיות באנגלית.
      ''';

      // Generate workout using AI
      final workoutData = await _aiService.invokeLLM(
        prompt: prompt,
        responseJsonSchema: {
          'workout_title': 'string',
          'workout_description': 'string',
          'why_this_workout': 'string',
          'estimated_duration': 'number',
          'difficulty_level': 'string',
          'exercises': 'array',
        },
      );

      // Handle nested structure
      Map<String, dynamic> finalWorkout;
      if (workoutData is Map) {
        if (workoutData['content'] != null && workoutData['workout_title'] == null) {
          finalWorkout = Map<String, dynamic>.from(workoutData['content']);
        } else if (workoutData['workout'] != null && workoutData['workout_title'] == null) {
          finalWorkout = Map<String, dynamic>.from(workoutData['workout']);
        } else {
          finalWorkout = Map<String, dynamic>.from(workoutData);
        }
      } else {
        throw Exception('Invalid workout data format');
      }

      // Validate required fields
      if (finalWorkout['workout_title'] == null ||
          finalWorkout['exercises'] == null ||
          finalWorkout['exercises'] is! List) {
        throw Exception('AI response is missing required fields. Please try again.');
      }

      if ((finalWorkout['exercises'] as List).isEmpty) {
        throw Exception('AI generated a workout with no exercises. Please try again.');
      }

      setState(() {
        _generatedWorkout = finalWorkout;
        _isGenerating = false;
      });

      // Generate image (optional)
      setState(() {
        _isGeneratingImage = true;
      });

      try {
        final imagePrompt =
            'A professional fitness workout scene showing ${finalWorkout['workout_title']}. Modern gym environment, high quality, motivational atmosphere.';
        final imageResult = await _aiService.generateImage(prompt: imagePrompt);
        if (imageResult['url'] != null && mounted) {
          setState(() {
            _generatedWorkout = {
              ...finalWorkout,
              'image_url': imageResult['url'],
            };
          });
        }
      } catch (imageError) {
        print('Image generation failed (optional feature): $imageError');
      } finally {
        if (mounted) {
          setState(() {
            _isGeneratingImage = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('API key')
              ? 'מפתח API חסר. אנא הגדר מפתח OpenAI ב-Firebase Remote Config.'
              : 'שגיאה ביצירת האימון. נסה שוב או שנה את הפרמטרים.';
          _isGenerating = false;
          _isGeneratingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'שגיאה ביצירת האימון'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _notesController,
                                decoration: const InputDecoration(
                                  labelText: 'הערות נוספות (אופציונלי)',
                                  hintText: 'העדפות מיוחדות, פציעות, מגבלות וכו\'',
                                  prefixIcon: Icon(Icons.note),
                                ),
                                maxLines: 3,
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
                                    (_isGenerating || _isGeneratingImage) ? null : _generateWorkout,
                                icon: (_isGenerating || _isGeneratingImage)
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
                                  _isGenerating
                                      ? 'מייצר אימון...'
                                      : _isGeneratingImage
                                          ? 'מייצר תמונה...'
                                          : 'צור אימון',
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

                      // Generated Workout Display
                      if (_generatedWorkout != null)
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
                                // Workout Image
                                if (_generatedWorkout!['image_url'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _generatedWorkout!['image_url'],
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          height: 200,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image_not_supported),
                                        );
                                      },
                                    ),
                                  ),
                                if (_generatedWorkout!['image_url'] != null)
                                  const SizedBox(height: 16),

                                // Workout Title
                                Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      color: Colors.purple[600],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _generatedWorkout!['workout_title'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Workout Description
                                if (_generatedWorkout!['workout_description'] != null)
                                  Text(
                                    _generatedWorkout!['workout_description'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                // Why This Workout
                                if (_generatedWorkout!['why_this_workout'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.purple[200]!),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.info, color: Colors.purple[700], size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _generatedWorkout!['why_this_workout'],
                                            style: TextStyle(color: Colors.purple[900]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                // Workout Info
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    if (_generatedWorkout!['estimated_duration'] != null)
                                      Chip(
                                        avatar: const Icon(Icons.timer, size: 18),
                                        label: Text('${_generatedWorkout!['estimated_duration']} דקות'),
                                      ),
                                    if (_generatedWorkout!['difficulty_level'] != null)
                                      Chip(
                                        avatar: const Icon(Icons.star, size: 18),
                                        label: Text(_generatedWorkout!['difficulty_level']),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Exercises List
                                if (_generatedWorkout!['exercises'] != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'תרגילים:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...((_generatedWorkout!['exercises'] as List).asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final exercise = entry.value as Map<String, dynamic>;
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: Colors.purple[100],
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          '${index + 1}',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.purple[700],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        exercise['name'] ?? '',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    if (exercise['category'] != null)
                                                      Chip(
                                                        label: Text(exercise['category']),
                                                        labelStyle: const TextStyle(fontSize: 12),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 8,
                                                  children: [
                                                    if (exercise['sets'] != null)
                                                      _buildExerciseInfo('סטים', '${exercise['sets']}'),
                                                    if (exercise['reps'] != null && exercise['reps'] != 0)
                                                      _buildExerciseInfo('חזרות', '${exercise['reps']}'),
                                                    if (exercise['duration_seconds'] != null && exercise['duration_seconds'] != 0)
                                                      _buildExerciseInfo('משך', '${exercise['duration_seconds']} שניות'),
                                                    if (exercise['rest_seconds'] != null)
                                                      _buildExerciseInfo('מנוחה', '${exercise['rest_seconds']} שניות'),
                                                    if (exercise['weight_suggestion'] != null && exercise['weight_suggestion'] != 0)
                                                      _buildExerciseInfo('משקל', '${exercise['weight_suggestion']} ק"ג'),
                                                  ],
                                                ),
                                                if (exercise['notes'] != null && exercise['notes'].toString().isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      exercise['notes'],
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontStyle: FontStyle.italic,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      })),
                                    ],
                                  ),
                                const SizedBox(height: 24),

                                // Save Workout Button
                                ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _saveWorkout,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(_isSaving ? 'שומר...' : 'שמור אימון לרשימה שלי'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _saveWorkout() async {
    if (_generatedWorkout == null || _user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אין אימון לשמירה'),
          backgroundColor: Colors.red,
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
      final allExercises = (_generatedWorkout!['exercises'] as List).map((ex) {
        final exercise = ex as Map<String, dynamic>;
        final setsCount = exercise['sets'] ?? 3;
        return {
          'name': exercise['name'] ?? '',
          'category': exercise['category'] ?? 'כוח',
          'sets': List.generate(setsCount, (index) => {
            'repetitions': exercise['reps'] ?? 0,
            'weight': exercise['weight_suggestion'] ?? 0,
            'duration_seconds': exercise['duration_seconds'] ?? 0,
            'completed': false,
          }),
          'completed': false,
          'notes': exercise['notes'] ?? '',
          'video_url': '',
        };
      }).toList();

      final workoutData = {
        'date': dateString,
        'workout_type': 'אימון AI',
        'status': 'פעיל',
        'start_time': now.toIso8601String(),
        'warmup_description': 'חימום אירובי קל 5-10 דקות, מתיחות דינמיות.',
        'warmup_duration': 10,
        'warmup_completed': false,
        'exercises': allExercises,
        'notes': _notesController.text.trim(),
        'total_duration': _generatedWorkout!['estimated_duration'] ?? 60,
        'created_by': _user!.email,
        'coach_workout_title': _generatedWorkout!['workout_title'],
        'coach_workout_description': _generatedWorkout!['workout_description'],
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

  Widget _buildExerciseInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
