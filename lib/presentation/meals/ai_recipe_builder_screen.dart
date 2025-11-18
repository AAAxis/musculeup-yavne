import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/ai_service.dart';

class AIRecipeBuilderScreen extends StatefulWidget {
  const AIRecipeBuilderScreen({super.key});

  @override
  State<AIRecipeBuilderScreen> createState() => _AIRecipeBuilderScreenState();
}

class _AIRecipeBuilderScreenState extends State<AIRecipeBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ingredientsController = TextEditingController();
  final _aiService = AIService();

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isGeneratingImage = false;
  Map<String, dynamic>? _generatedRecipe;
  String? _errorMessage;

  String? _selectedNutritionalGoal;

  @override
  void dispose() {
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      await _aiService.initialize();
    } catch (e) {
      print('Warning: Failed to initialize AI service: $e');
    }
  }

  Future<void> _generateRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedNutritionalGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר מטרה תזונתית'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _isGeneratingImage = false;
      _errorMessage = null;
      _generatedRecipe = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final ingredients = _ingredientsController.text.trim();
      final nutritionalGoal = _selectedNutritionalGoal!;

      // Map nutritional goal to Hebrew
      final goalMap = {
        'balanced': 'ארוחה מאוזנת',
        'cutting': 'חיטוב/הפחתת שומן',
        'bulking': 'גיבוש/הגדלת שריר',
        'maintain': 'שמירה על משקל',
      };
      final goalHebrew = goalMap[nutritionalGoal] ?? nutritionalGoal;

      final prompt = '''
אתה שף מומחה לתזונה בריאה למפתחי גוף וספורטאים. צור מתכון מפורט ומדויק בעברית על בסיס הנתונים הבאים:

מרכיבים זמינים: $ingredients
מטרה תזונתית: $goalHebrew

דרישות למתכון:
1. השתמש רק במרכיבים שצוינו או במרכיבים בסיסיים נפוצים (מלח, פלפל, שמן זית וכו')
2. ודא שהמתכון תואם למטרה התזונתית שנבחרה:
   - "ארוחה מאוזנת": יחס מאוזן של חלבון, פחמימות ושומנים בריאים
   - "חיטוב/הפחתת שומן": דגש על חלבון גבוה וקלוריות נמוכות יחסית
   - "גיבוש/הגדלת שריר": דגש על קלוריות גבוהות וחלבון
   - "שמירה על משקל": מתכון מאוזן עם כמות קלוריות בינונית
3. תן כמויות מדויקות לכל מרכיב
4. פרט הוראות הכנה צעד אחר צעד, ממוספרות
5. חשב ערכים תזונתיים מדויקים על בסיס המרכיבים והכמויות

חשוב מאוד: החזר את התשובה בפורמט JSON עם המבנה הבא בדיוק. השתמש בשמות השדות באנגלית בלבד:
{
  "name": "שם המתכון בעברית",
  "category": "ארוחות עיקריות" או "נשנושים בריאים" וכו',
  "ingredients": ["מרכיב 1 - כמות", "מרכיב 2 - כמות", ...],
  "instructions": "הוראות הכנה מפורטות",
  "prep_time": מספר_דקות,
  "servings": מספר_מנות,
  "calories_per_serving": מספר_קלוריות,
  "protein_grams": מספר_גרם,
  "carbs_grams": מספר_גרם,
  "fat_grams": מספר_גרם,
  "difficulty": "קל" או "בינוני" או "קשה",
  "equipment": "ציוד נדרש",
  "tips": "טיפים"
}

החזר רק את ה-JSON, ללא טקסט נוסף לפני או אחרי. כל המפתחות (keys) חייבים להיות באנגלית.
''';

      // Generate recipe using AI
      final recipeData = await _aiService.invokeLLM(
        prompt: prompt,
        responseJsonSchema: {
          'name': 'string',
          'category': 'string',
          'ingredients': 'array',
          'instructions': 'string',
          'prep_time': 'number',
          'servings': 'number',
          'calories_per_serving': 'number',
          'protein_grams': 'number',
          'carbs_grams': 'number',
          'fat_grams': 'number',
          'difficulty': 'string',
          'equipment': 'string',
          'tips': 'string',
        },
      );

      // Handle nested structure
      Map<String, dynamic> finalRecipe;
      if (recipeData is Map) {
        if (recipeData['content'] != null && recipeData['name'] == null) {
          finalRecipe = Map<String, dynamic>.from(recipeData['content']);
        } else if (recipeData['recipe'] != null && recipeData['name'] == null) {
          finalRecipe = Map<String, dynamic>.from(recipeData['recipe']);
        } else {
          finalRecipe = Map<String, dynamic>.from(recipeData);
        }
      } else {
        throw Exception('Invalid recipe data format');
      }

      // Handle ingredients array
      if (finalRecipe['ingredients'] != null) {
        final ingredientsList = finalRecipe['ingredients'] as List;
        finalRecipe['ingredients'] = ingredientsList.map((ing) {
          if (ing is String) return ing;
          if (ing is Map) {
            final name = ing['name'] ?? ing['שם'] ?? '';
            final amount = ing['amount'] ?? ing['כמות'] ?? '';
            final unit = ing['unit'] ?? ing['יחידה'] ?? '';
            return amount.isNotEmpty && unit.isNotEmpty
                ? '$name - $amount $unit'
                : name;
          }
          return ing.toString();
        }).toList();
      }

      // Validate required fields
      if (finalRecipe['name'] == null ||
          finalRecipe['ingredients'] == null ||
          finalRecipe['ingredients'] is! List) {
        throw Exception('AI response is missing required fields. Please try again.');
      }

      setState(() {
        _generatedRecipe = finalRecipe;
        _isGenerating = false;
      });

      // Generate image (optional - don't fail if it errors)
      setState(() {
        _isGeneratingImage = true;
      });

      try {
        final imagePrompt =
            'A beautiful, delicious-looking plate of ${finalRecipe['name']}. Professional food photography, high quality, studio lighting, appetizing. The dish is ${finalRecipe['category'] ?? 'healthy meal'}.';
        final imageResult = await _aiService.generateImage(prompt: imagePrompt);
        if (imageResult['url'] != null && mounted) {
          setState(() {
            _generatedRecipe = {
              ...finalRecipe,
              'image_url': imageResult['url'],
            };
          });
        }
      } catch (imageError) {
        print('Image generation failed (optional feature): $imageError');
        // Don't show error to user - image is optional
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
              : 'שגיאה ביצירת המתכון. נסה שוב או שנה את הפרמטרים.';
          _isGenerating = false;
          _isGeneratingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'שגיאה ביצירת המתכון'),
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
        appBar: AppBar(
          title: const Text('צור מתכון עם AI'),
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
                                'צור מתכון עם AI',
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
                              'הזן מרכיבים זמינים וקבל מתכון מותאם אישית',
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

                      // Input Card
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
                                    Icons.restaurant,
                                    color: Colors.purple[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'מרכיבים זמינים',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _ingredientsController,
                                decoration: const InputDecoration(
                                  labelText: 'מרכיבים *',
                                  hintText:
                                      'לדוגמה: חזה עוף, אורז, ברוקולי, שמן זית',
                                  prefixIcon: Icon(Icons.list),
                                ),
                                maxLines: 4,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'אנא הזן מרכיבים זמינים';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedNutritionalGoal,
                                decoration: const InputDecoration(
                                  labelText: 'מטרה תזונתית *',
                                  prefixIcon: Icon(Icons.flag),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'balanced',
                                      child: Text('⚖️ ארוחה מאוזנת')),
                                  DropdownMenuItem(
                                      value: 'cutting',
                                      child: Text('🔥 חיטוב/הפחתת שומן')),
                                  DropdownMenuItem(
                                      value: 'bulking',
                                      child: Text('💪 גיבוש/הגדלת שריר')),
                                  DropdownMenuItem(
                                      value: 'maintain',
                                      child: Text('📊 שמירה על משקל')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedNutritionalGoal = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb_outline,
                                      color: Colors.blue[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'ככל שתרשום יותר מרכיבים, המתכון יהיה יצירתי ומגוון יותר!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                                    (_isGenerating || _isGeneratingImage) ? null : _generateRecipe,
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
                                      ? 'מייצר מתכון חכם...'
                                      : _isGeneratingImage
                                          ? 'מייצר תמונה...'
                                          : 'צור מתכון חכם',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: Colors.purple[600],
                                  foregroundColor: Colors.white,
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
                                      'ה-AI ינתח את המרכיבים שלך ויצור מתכון מותאם אישית',
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

                      // Generated Recipe Display
                      if (_generatedRecipe != null)
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
                                // Recipe Image
                                if (_generatedRecipe!['image_url'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _generatedRecipe!['image_url'],
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
                                if (_generatedRecipe!['image_url'] != null)
                                  const SizedBox(height: 16),
                                
                                // Recipe Name
                                Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant_menu,
                                      color: Colors.green[600],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _generatedRecipe!['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Recipe Info
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    if (_generatedRecipe!['prep_time'] != null)
                                      Chip(
                                        avatar: const Icon(Icons.timer, size: 18),
                                        label: Text('${_generatedRecipe!['prep_time']} דקות'),
                                      ),
                                    if (_generatedRecipe!['servings'] != null)
                                      Chip(
                                        avatar: const Icon(Icons.people, size: 18),
                                        label: Text('${_generatedRecipe!['servings']} מנות'),
                                      ),
                                    if (_generatedRecipe!['difficulty'] != null)
                                      Chip(
                                        avatar: const Icon(Icons.star, size: 18),
                                        label: Text(_generatedRecipe!['difficulty']),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Nutritional Info
                                if (_generatedRecipe!['calories_per_serving'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildNutritionChip('קלוריות', '${_generatedRecipe!['calories_per_serving']}'),
                                        if (_generatedRecipe!['protein_grams'] != null)
                                          _buildNutritionChip('חלבון', '${_generatedRecipe!['protein_grams']}ג'),
                                        if (_generatedRecipe!['carbs_grams'] != null)
                                          _buildNutritionChip('פחמימות', '${_generatedRecipe!['carbs_grams']}ג'),
                                        if (_generatedRecipe!['fat_grams'] != null)
                                          _buildNutritionChip('שומן', '${_generatedRecipe!['fat_grams']}ג'),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 16),

                                // Ingredients
                                if (_generatedRecipe!['ingredients'] != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'מרכיבים:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...((_generatedRecipe!['ingredients'] as List).map((ing) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(ing.toString())),
                                          ],
                                        ),
                                      ))),
                                    ],
                                  ),
                                const SizedBox(height: 16),

                                // Instructions
                                if (_generatedRecipe!['instructions'] != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'הוראות הכנה:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _generatedRecipe!['instructions'],
                                        style: const TextStyle(height: 1.6),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),

                                // Tips
                                if (_generatedRecipe!['tips'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber[200]!),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.lightbulb, color: Colors.amber[700], size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _generatedRecipe!['tips'],
                                            style: TextStyle(color: Colors.amber[900]),
                                          ),
                                        ),
                                      ],
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

  Widget _buildNutritionChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
