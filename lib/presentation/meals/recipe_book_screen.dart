import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';

class RecipeBookScreen extends StatefulWidget {
  const RecipeBookScreen({super.key});

  @override
  State<RecipeBookScreen> createState() => _RecipeBookScreenState();
}

class _RecipeBookScreenState extends State<RecipeBookScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String _selectedFilter = 'all';
  final List<Map<String, dynamic>> _recipes = [];
  final List<Map<String, dynamic>> _filteredRecipes = [];
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _filters = [
    {'key': 'all', 'label': 'הכל', 'icon': Icons.public},
    {'key': 'main_meals', 'label': 'ארוחות עיקריות', 'icon': Icons.restaurant},
    {'key': 'snacks', 'label': 'נשנושים', 'icon': Icons.cookie},
    {'key': 'shakes', 'label': 'שייקים', 'icon': Icons.local_drink},
    {'key': 'salads', 'label': 'סלטים', 'icon': Icons.eco},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      String? userEmail;
      if (authState is AuthAuthenticated) {
        userEmail = authState.user.email;
      }

      final recipes = await _firestoreService.getRecipes(userEmail);
      
      setState(() {
        _recipes.clear();
        _recipes.addAll(recipes);
        _filterRecipes();
      });
    } catch (e) {
      print('Error loading recipes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת המתכונים: $e')),
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

  void _filterRecipes() {
    final searchTerm = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredRecipes.clear();
      _filteredRecipes.addAll(_recipes.where((recipe) {
        // Filter by category
        if (_selectedFilter != 'all') {
          final category = recipe['category'] ?? '';
          if (category != _selectedFilter) {
            return false;
          }
        }
        
        // Filter by search term
        if (searchTerm.isNotEmpty) {
          final name = (recipe['name'] ?? '').toString().toLowerCase();
          final ingredients = (recipe['ingredients'] ?? []).toString().toLowerCase();
          if (!name.contains(searchTerm) && !ingredients.contains(searchTerm)) {
            return false;
          }
        }
        
        return true;
      }).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ספר מתכונים'),
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
                              'ספר מתכונים',
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
                            'גלה מתכונים נבחרים ומנוסים',
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
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'חפש מתכון לפי שם או מרכיב...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            _filterRecipes();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Filter Chips Card
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
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _filters.map((filter) {
                            final isSelected = _selectedFilter == filter['key'];
                            return FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    filter['icon'] as IconData,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.green[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(filter['label'] as String),
                                ],
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter['key'] as String;
                                });
                                _filterRecipes();
                              },
                              backgroundColor: Colors.white,
                              selectedColor: Colors.green[600],
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Recipes List
                    _filteredRecipes.isEmpty
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
                                    Icons.restaurant_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'עדיין אין מתכונים זמינים',
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
                                    'התחל ליצור מתכונים עם AI או הוסף משלך!',
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
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _filteredRecipes.length,
                            itemBuilder: (context, index) {
                              final recipe = _filteredRecipes[index];
                              return _buildRecipeCard(recipe);
                            },
                          ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        _showRecipeDetails(recipe);
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: Container(
                height: 120,
                color: Colors.grey[300],
                child: recipe['image_url'] != null && recipe['image_url'].toString().isNotEmpty
                    ? Image.network(
                        recipe['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.restaurant, size: 48, color: Colors.grey),
                      ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        recipe['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${recipe['prep_time'] ?? 0} דק\'',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recipe['calories_per_serving'] != null) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.local_fire_department, size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${recipe['calories_per_serving']} קל\'',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (recipe['protein_grams'] != null) ...[
                      const SizedBox(height: 4),
                      Flexible(
                        child: Text(
                          'חלבון: ${recipe['protein_grams']}ג',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(Map<String, dynamic> recipe) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: Text(recipe['name'] ?? 'מתכון'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recipe['name_en'] != null)
                  Text(
                    recipe['name_en'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 16),
                if (recipe['ingredients'] != null) ...[
                  const Text(
                    'מרכיבים:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...((recipe['ingredients'] as List?) ?? []).map((ingredient) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $ingredient'),
                  )),
                  const SizedBox(height: 16),
                ],
                if (recipe['instructions'] != null) ...[
                  const Text(
                    'הוראות הכנה:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(recipe['instructions'] ?? ''),
                  const SizedBox(height: 16),
                ],
                if (recipe['prep_time'] != null || recipe['calories_per_serving'] != null) ...[
                  const Text(
                    'מידע תזונתי:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (recipe['prep_time'] != null)
                    Text('זמן הכנה: ${recipe['prep_time']} דקות'),
                  if (recipe['servings'] != null)
                    Text('מנות: ${recipe['servings']}'),
                  if (recipe['calories_per_serving'] != null)
                    Text('קלוריות למנה: ${recipe['calories_per_serving']}'),
                  if (recipe['protein_grams'] != null)
                    Text('חלבון: ${recipe['protein_grams']}ג'),
                  if (recipe['carbs_grams'] != null)
                    Text('פחמימות: ${recipe['carbs_grams']}ג'),
                  if (recipe['fat_grams'] != null)
                    Text('שומן: ${recipe['fat_grams']}ג'),
                ],
                if (recipe['tips'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'טיפים: ${recipe['tips']}',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[700]),
                  ),
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
      ),
    );
  }
}
