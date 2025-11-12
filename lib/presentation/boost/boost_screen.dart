import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';

class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  bool _hasBoosterAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    // TODO: Check user's booster access from Firestore
    // For now, we'll set it to false to show the application form
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _hasBoosterAccess = false;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if user has booster access
          if (!_hasBoosterAccess) {
            return _buildApplicationForm(context);
          }

          // If they have access, show the booster dashboard
          return _buildBoosterDashboard(context);
        },
      ),
    );
  }

  Widget _buildApplicationForm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Application Form Card
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.rocket_launch,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'הצטרף לתוכנית הבוסטר',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'תוכנית הבוסטר היא תוכנית אימונים אינטנסיבית שנועדה לעזור לך להגיע ליעדי הכושר שלך מהר יותר. הגש בקשה עכשיו כדי להצטרף למחזור הבא!',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Benefits List
                  _buildBenefitItem(
                    context,
                    icon: Icons.fitness_center,
                    title: 'תוכניות אימון מותאמות אישית',
                    description:
                        'אימונים מותאמים שתוכננו על ידי מאמנים מקצועיים',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    context,
                    icon: Icons.restaurant,
                    title: 'הדרכה תזונתית',
                    description: 'תוכניות ארוחות ומעקב קלוריות',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    context,
                    icon: Icons.people,
                    title: 'תמיכה קבוצתית',
                    description: 'הצטרף לקהילה של אנשים מוטיבציה',
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    context,
                    icon: Icons.trending_up,
                    title: 'מעקב התקדמות',
                    description: 'ניתוח מפורט ובדיקות שבועיות',
                  ),
                  const SizedBox(height: 32),

                  // Apply Button
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to application form
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('טופס הבקשה בקרוב!'),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'הגש בקשה עכשיו',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Text
                  Text(
                    'בקשות נבדקות תוך 2-3 ימי עסקים',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.green[600],
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBoosterDashboard(BuildContext context) {
    // TODO: Implement the full booster dashboard with cards grid
    // This will be similar to the Progress component in the React code
    return const Center(
      child: Text('לוח בקרת בוסטר - בקרוב'),
    );
  }
}
