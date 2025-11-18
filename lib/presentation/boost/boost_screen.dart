import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';

class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  final _firestoreService = FirestoreService();
  bool _hasBoosterAccess = false;
  bool _isLoading = true;
  bool _isSendingRequest = false;
  String? _requestStatus;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = await _firestoreService.getUser(authState.user.uid);
        if (mounted) {
          setState(() {
            // Check if user has booster_unlocked field
            // For now, we'll check if booster_unlocked is true
            // This should be added to UserModel if not already present
            _hasBoosterAccess = false; // Will be updated when UserModel includes booster fields
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasBoosterAccess = false;
          _isLoading = false;
        });
      }
    }
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
                    onPressed: _isSendingRequest ? null : _handleBoosterRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isSendingRequest
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mail, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'שלח בקשה למאמן',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Request Status
                  if (_requestStatus != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _requestStatus!.contains('שגיאה') ||
                                _requestStatus!.contains('אירעה')
                            ? Colors.red[100]
                            : Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _requestStatus!.contains('שגיאה') ||
                                  _requestStatus!.contains('אירעה')
                              ? Colors.red[300]!
                              : Colors.green[300]!,
                        ),
                      ),
                      child: Text(
                        _requestStatus!,
                        style: TextStyle(
                          fontSize: 14,
                          color: _requestStatus!.contains('שגיאה') ||
                                  _requestStatus!.contains('אירעה')
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

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

  Future<void> _handleBoosterRequest() async {
    setState(() {
      _isSendingRequest = true;
      _requestStatus = null;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        setState(() {
          _requestStatus = '❌ שגיאה: לא נמצא משתמש מחובר.';
          _isSendingRequest = false;
        });
        return;
      }

      // Get current user info
      final user = await _firestoreService.getUser(authState.user.uid);
      if (user == null) {
        setState(() {
          _requestStatus = '❌ שגיאה: לא נמצא מידע משתמש.';
          _isSendingRequest = false;
        });
        return;
      }

      // Check if a request already exists
      final hasExistingRequest = await _firestoreService.hasExistingBoosterRequest(user.email);
      if (hasExistingRequest) {
        setState(() {
          _requestStatus = 'ℹ️ כבר קיימת בקשה פתוחה. המאמן יראה אותה בקרוב.';
          _isSendingRequest = false;
        });
        return;
      }

      // Use coach email from user profile, or fallback to admin/coach
      String? coachEmail = user.coachEmail;

      if (coachEmail == null || coachEmail.isEmpty) {
        // Find the admin/coach as fallback
        final coaches = await _firestoreService.getCoaches();
        if (coaches.isEmpty) {
          setState(() {
            _requestStatus = '❌ שגיאה: לא נמצא מאמן ליצירת קשר.';
            _isSendingRequest = false;
          });
          return;
        }
        coachEmail = coaches.first.email;
      }

      // Create notification in Firestore
      await _firestoreService.createCoachNotification(
        userEmail: user.email,
        userName: user.name,
        coachEmail: coachEmail,
        notificationType: 'booster_request',
        notificationTitle: '🚀 בקשה להצטרפות לתכנית הבוסטר',
        notificationMessage: 'המתאמן/ת ${user.name} מבקש/ת להצטרף לתכנית הבוסטר.',
        notificationDetails: {
          'user_name': user.name,
          'user_email': user.email,
          'coach_name': user.coachName ?? 'לא צוין',
          'request_date': DateTime.now().toIso8601String(),
        },
      );

      setState(() {
        _requestStatus = '✅ הבקשה נשלחה בהצלחה למאמן! הוא יראה אותה בלוח הבקרה.';
        _isSendingRequest = false;
      });
    } catch (error) {
      setState(() {
        _requestStatus = '❌ אירעה שגיאה בשליחת הבקשה. אנא נסה שוב מאוחר יותר.';
        _isSendingRequest = false;
      });
    }
  }

  Widget _buildBoosterDashboard(BuildContext context) {
    // TODO: Implement the full booster dashboard with cards grid
    // This will be similar to the Progress component in the React code
    return const Center(
      child: Text('לוח בקרת בוסטר - בקרוב'),
    );
  }
}
