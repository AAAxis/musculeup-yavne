import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:muscleup/data/services/firestore_service.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  final List<Map<String, dynamic>> _exercises = [];
  final List<Map<String, dynamic>> _filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('ספריית תרגילים'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
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
                              'ספריית תרגילים',
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
                            'עיין בתרגילים והגדר את ברירות המחדל האישיות שלך',
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

                    // Search Card
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
                                  Icons.search,
                                  color: Colors.green[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'חיפוש תרגילים',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
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
                            const SizedBox(height: 16),
                            // Filter dropdowns
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
                    ),
                    const SizedBox(height: 16),

                    // Exercises List
                    _filteredExercises.isEmpty
                        ? Container(
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
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.fitness_center_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'אין תרגילים זמינים',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ספריית תרגילים בקרוב!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = _filteredExercises[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  title: Text(
                                    exercise['name_he'] ?? exercise['name_en'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (exercise['name_en'] != null && exercise['name_he'] != null)
                                        Text(
                                          exercise['name_en'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
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
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green[800],
                                                ),
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
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (exercise['description'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          exercise['description'] ?? '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.info_outline),
                                    onPressed: () {
                                      _showExerciseDetails(exercise);
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
    );
  }

  void _showExerciseDetails(Map<String, dynamic> exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise['name_he'] ?? exercise['name_en'] ?? 'תרגיל'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exercise['name_en'] != null)
                Text(
                  'English: ${exercise['name_en']}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              const SizedBox(height: 8),
              if (exercise['muscle_group'] != null)
                Text('קבוצת שרירים: ${exercise['muscle_group']}'),
              if (exercise['category'] != null)
                Text('קטגוריה: ${exercise['category']}'),
              if (exercise['equipment'] != null)
                Text('ציוד: ${exercise['equipment']}'),
              if (exercise['description'] != null) ...[
                const SizedBox(height: 8),
                Text('תיאור: ${exercise['description']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('סגור'),
          ),
        ],
      ),
    );
  }
}
