import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/services/exercisedb_service.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Firebase exercises state
  bool _isLoadingFirebase = false;
  final FirestoreService _firestoreService = FirestoreService();
  final List<Map<String, dynamic>> _exercises = [];
  final List<Map<String, dynamic>> _filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedMuscleGroup;
  String? _selectedCategory;

  // ExerciseDB state
  final ExerciseDBService _exerciseDBService = ExerciseDBService();
  bool _isLoadingExerciseDB = false;
  final List<Map<String, dynamic>> _exerciseDBExercises = [];
  final TextEditingController _exerciseDBSearchController = TextEditingController();
  String _exerciseDBSearchType = 'name'; // 'name', 'bodyPart', 'equipment'
  String? _selectedBodyPart;
  String? _selectedEquipment;
  final List<String> _bodyParts = [
    'CHEST', 'BACK', 'LEGS', 'SHOULDERS', 'ARMS', 'BICEPS', 'TRICEPS',
    'FOREARMS', 'CORE', 'ABS', 'GLUTES', 'CALVES', 'QUADRICEPS',
    'HAMSTRINGS', 'LATS', 'TRAPS', 'CARDIO', 'FULL BODY', 'NECK'
  ];
  final List<String> _equipment = [
    'BODYWEIGHT', 'DUMBBELL', 'BARBELL', 'KETTLEBELL', 'MACHINE',
    'CABLE', 'RESISTANCE BAND', 'MEDICINE BALL', 'TRX', 'BOX',
    'PULL-UP BAR', 'ROWER', 'BIKE', 'TREADMILL'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExercises();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _exerciseDBSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoadingFirebase = true;
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
          _isLoadingFirebase = false;
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

  Future<void> _searchExerciseDB() async {
    if (_exerciseDBSearchType == 'name' && _exerciseDBSearchController.text.trim().isEmpty) {
      return;
    }
    if (_exerciseDBSearchType == 'bodyPart' && _selectedBodyPart == null) {
      return;
    }
    if (_exerciseDBSearchType == 'equipment' && _selectedEquipment == null) {
      return;
    }

    setState(() {
      _isLoadingExerciseDB = true;
    });

    try {
      List<Map<String, dynamic>> results = [];
      
      if (_exerciseDBSearchType == 'name') {
        results = await _exerciseDBService.searchExercises(_exerciseDBSearchController.text.trim());
      } else if (_exerciseDBSearchType == 'bodyPart') {
        results = await _exerciseDBService.getExercisesByBodyPart(_selectedBodyPart!);
      } else if (_exerciseDBSearchType == 'equipment') {
        results = await _exerciseDBService.getExercisesByEquipment(_selectedEquipment!);
      }

      setState(() {
        _exerciseDBExercises.clear();
        _exerciseDBExercises.addAll(results);
      });
    } catch (e) {
      print('Error searching ExerciseDB: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בחיפוש ב-ExerciseDB: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingExerciseDB = false;
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          title: const Text('ספריית תרגילים'),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.green[600],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green[600],
            tabs: const [
              Tab(
                icon: Icon(Icons.local_fire_department),
                text: 'Firebase',
              ),
              Tab(
                icon: Icon(Icons.cloud),
                text: 'ExerciseDB',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFirebaseTab(isDark),
            _buildExerciseDBTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFirebaseTab(bool isDark) {
    return _isLoadingFirebase
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
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                _buildFirebaseExercisesList(isDark),
              ],
            ),
          );
  }

  Widget _buildFirebaseExercisesList(bool isDark) {
    if (_filteredExercises.isEmpty) {
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
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = _filteredExercises[index];
        return _buildExerciseCard(exercise, isDark, isFirebase: true);
      },
    );
  }

  Widget _buildExerciseDBTab(bool isDark) {
    return SingleChildScrollView(
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
                    'ExerciseDB',
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
                  'חפש תרגילים מ-ExerciseDB עם תמונות וסרטונים',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        Icons.cloud,
                        color: Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'חיפוש ב-ExerciseDB',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Search Type Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('שם'),
                          selected: _exerciseDBSearchType == 'name',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _exerciseDBSearchType = 'name';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('קבוצת שרירים'),
                          selected: _exerciseDBSearchType == 'bodyPart',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _exerciseDBSearchType = 'bodyPart';
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('ציוד'),
                          selected: _exerciseDBSearchType == 'equipment',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _exerciseDBSearchType = 'equipment';
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Input based on type
                  if (_exerciseDBSearchType == 'name')
                    TextField(
                      controller: _exerciseDBSearchController,
                      decoration: InputDecoration(
                        hintText: 'חפש תרגיל ב-ExerciseDB...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _searchExerciseDB(),
                    )
                  else if (_exerciseDBSearchType == 'bodyPart')
                    DropdownButtonFormField<String>(
                      value: _selectedBodyPart,
                      decoration: InputDecoration(
                        labelText: 'בחר קבוצת שרירים',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('בחר...')),
                        ..._bodyParts.map((bp) => DropdownMenuItem(
                          value: bp,
                          child: Text(bp),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedBodyPart = value;
                        });
                      },
                    )
                  else if (_exerciseDBSearchType == 'equipment')
                    DropdownButtonFormField<String>(
                      value: _selectedEquipment,
                      decoration: InputDecoration(
                        labelText: 'בחר ציוד',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('בחר...')),
                        ..._equipment.map((eq) => DropdownMenuItem(
                          value: eq,
                          child: Text(eq),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedEquipment = value;
                        });
                      },
                    ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingExerciseDB ? null : _searchExerciseDB,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoadingExerciseDB
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'חפש ב-ExerciseDB',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ExerciseDB Results
          if (_isLoadingExerciseDB)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_exerciseDBExercises.isEmpty && !_isLoadingExerciseDB)
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
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'חפש תרגילים מ-ExerciseDB',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                      'השתמש בחיפוש למעלה כדי למצוא תרגילים',
                                    style: TextStyle(
                                      fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Text(
                    'נמצאו ${_exerciseDBExercises.length} תרגילים',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
                ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                  itemCount: _exerciseDBExercises.length,
                            itemBuilder: (context, index) {
                    final exercise = _exerciseDBExercises[index];
                    return _buildExerciseCard(exercise, isDark, isFirebase: false);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, bool isDark, {required bool isFirebase}) {
    String? imageUrl;
    
    if (isFirebase) {
      // For Firebase exercises, try to get image from exercisedb_image_url
      if (exercise['exercisedb_image_url'] != null) {
        final url = exercise['exercisedb_image_url'].toString();
        imageUrl = url.startsWith('http') ? url : 'https://v2.exercisedb.dev/images/$url';
      }
    } else {
      // For ExerciseDB exercises, get image directly from API response
      imageUrl = ExerciseDBService.getImageUrl(exercise);
    }

    final exerciseName = isFirebase
        ? (exercise['name_he'] ?? exercise['name_en'] ?? '')
        : (exercise['name'] ?? '');
    final exerciseNameEn = isFirebase
        ? (exercise['name_en'] ?? '')
        : '';
    final muscleGroup = isFirebase
        ? (exercise['muscle_group'] ?? '')
        : (exercise['bodyParts'] != null && (exercise['bodyParts'] as List).isNotEmpty
            ? (exercise['bodyParts'] as List).first.toString()
            : '');
    final category = isFirebase
        ? (exercise['category'] ?? '')
        : '';
    final description = isFirebase
        ? (exercise['description'] ?? '')
        : (exercise['instructions'] != null && (exercise['instructions'] as List).isNotEmpty
            ? (exercise['instructions'] as List).join('\n')
            : '');

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Image
            if (imageUrl != null)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exerciseName,
                                    style: const TextStyle(
                            fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          _showExerciseDetails(exercise, isFirebase);
                        },
                      ),
                    ],
                  ),
                  if (exerciseNameEn.isNotEmpty) ...[
                    const SizedBox(height: 4),
                                        Text(
                      exerciseNameEn,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                                        children: [
                      if (muscleGroup.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                            muscleGroup,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green[800],
                                                ),
                                              ),
                                            ),
                      if (category.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue[100],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                            category,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue[800],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                                        Text(
                      description,
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
                          ),
                  ],
              ),
      ),
    );
  }

  void _showExerciseDetails(Map<String, dynamic> exercise, bool isFirebase) {
    String? imageUrl;
    String? videoUrl;
    
    if (isFirebase) {
      if (exercise['exercisedb_image_url'] != null) {
        final url = exercise['exercisedb_image_url'].toString();
        imageUrl = url.startsWith('http') ? url : 'https://v2.exercisedb.dev/images/$url';
      }
      videoUrl = exercise['video_url'];
    } else {
      imageUrl = ExerciseDBService.getImageUrl(exercise);
      videoUrl = ExerciseDBService.getVideoUrl(exercise);
    }

    final exerciseName = isFirebase
        ? (exercise['name_he'] ?? exercise['name_en'] ?? 'תרגיל')
        : (exercise['name'] ?? 'תרגיל');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exerciseName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              if (imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (isFirebase) ...[
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
              ] else ...[
                if (exercise['bodyParts'] != null && (exercise['bodyParts'] as List).isNotEmpty)
                  Text('קבוצת שרירים: ${(exercise['bodyParts'] as List).join(', ')}'),
                if (exercise['equipment'] != null && (exercise['equipment'] as List).isNotEmpty)
                  Text('ציוד: ${(exercise['equipment'] as List).join(', ')}'),
                if (exercise['target'] != null)
                  Text('מטרה: ${exercise['target']}'),
                if (exercise['instructions'] != null && (exercise['instructions'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('הוראות:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...(exercise['instructions'] as List).asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('${entry.key + 1}. ${entry.value}'),
                    );
                  }),
                ],
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
