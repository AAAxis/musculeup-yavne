import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/presentation/meals/recipe_book_screen.dart';
import 'package:muscleup/presentation/meals/ai_recipe_builder_screen.dart';
import 'package:muscleup/presentation/meals/favorite_recipes_screen.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  String _activeView = 'overview'; // 'overview', 'ai', 'recipes', 'favorites'
  bool _hasNutritionAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    // TODO: Check user's nutrition access from Firestore
    // For now, we'll set it to true
    setState(() {
      _hasNutritionAccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if user has nutrition access
          if (!_hasNutritionAccess) {
            return _buildLockedScreen(context);
          }

          if (_activeView == 'overview') {
            return _buildOverview(context);
          }

          return _buildDetailView(context);
        },
      ),
    );
  }

  Widget _buildLockedScreen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.construction,
                  size: 40,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'שדרוג מערכת המתכונים',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'בקרוב...',
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
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Action Cards
          _buildActionCard(
            context,
            id: 'recipes',
            title: 'ספר מתכונים',
            description: 'גלה מתכונים נבחרים ומנוסים',
            icon: Icons.menu_book,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            id: 'ai',
            title: 'צור מתכון עם AI',
            description: 'הזן מרכיבים זמינים וקבל מתכון מותאם אישית',
            icon: Icons.auto_awesome,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF2563EB)],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context,
            id: 'favorites',
            title: 'מתכונים מועדפים',
            description: 'המתכונים השמורים שלך',
            icon: Icons.favorite,
            gradient: const LinearGradient(
              colors: [Color(0xFFEC4899), Color(0xFFEF4444)],
            ),
          ),
        ],
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
        setState(() {
          _activeView = id;
        });
      },
      borderRadius: BorderRadius.circular(24),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: iconColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context) {
    // Navigate to the appropriate screen instead of showing inline content
    Widget screen;
    switch (_activeView) {
      case 'recipes':
        screen = const RecipeBookScreen();
        break;
      case 'ai':
        screen = const AIRecipeBuilderScreen();
        break;
      case 'favorites':
        screen = const FavoriteRecipesScreen();
        break;
      default:
        return const Center(child: Text('Unknown view'));
    }

    // Navigate and reset view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ).then((_) {
        // Reset to overview when returning
        if (mounted) {
          setState(() {
            _activeView = 'overview';
          });
        }
      });
    });

    // Return empty container while navigating
    return const SizedBox.shrink();
  }
}

