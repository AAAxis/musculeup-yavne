import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/home/home_screen.dart';
import 'package:muscleup/presentation/meals/meals_screen.dart';
import 'package:muscleup/presentation/workouts/workouts_screen.dart';
import 'package:muscleup/presentation/log/log_screen.dart';
import 'package:muscleup/presentation/settings/settings_screen.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:muscleup/presentation/profile/profile_screen.dart';
import 'package:muscleup/presentation/settings/notifications_screen.dart';
import 'package:muscleup/presentation/export/export_screen.dart';
import 'package:muscleup/presentation/language/bloc/language_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();

  static void switchToTab(int index) {
    _MainNavigationState.navigateToTab(index);
  }
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey _homeKey = GlobalKey();
  static _MainNavigationState? _instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _instance = this;
    _screens.addAll([
      HomeScreen(key: _homeKey),
      const MealsScreen(),
      const WorkoutsScreen(),
      const LogScreen(),
      const SettingsScreen(),
    ]);
  }

  @override
  void dispose() {
    _instance = null;
    super.dispose();
  }

  static void navigateToTab(int index) {
    _instance?.setState(() {
      _instance!._currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: Text(_getTitle()),
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                ),
              ],
            ),
            endDrawer: _buildUserDrawer(context, state),
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex > 3 ? 0 : _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                  // Refresh home screen when navigating to it
                  if (index == 0) {
                    final homeState = _homeKey.currentState;
                    if (homeState != null) {
                      // Call refreshWorkouts method dynamically
                      try {
                        (homeState as dynamic).refreshWorkouts();
                      } catch (e) {
                        // Method might not exist, ignore
                      }
                    }
                  }
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'בית',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_outlined),
                  selectedIcon: Icon(Icons.restaurant),
                  label: 'ארוחות',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center),
                  label: 'אימון',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'יומן',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'MuscleUp';
      case 1:
        return 'מתכונים';
      case 2:
        return 'אימונים';
      case 3:
        return 'יומן';
      case 4:
        return 'הגדרות';
      default:
        return 'MuscleUp';
    }
  }

  Widget _buildUserDrawer(BuildContext context, AuthState state) {
    String? userEmail;
    String? coachEmail;
    
    if (state is AuthAuthenticated) {
      userEmail = state.user.email;
      // Get coach email from user's Firestore data
      // We'll fetch it in the FutureBuilder
    }

    // Fetch trainer data
    Future<UserModel?> _fetchTrainer() async {
      if (state is! AuthAuthenticated) return null;
      
      final firestoreService = FirestoreService();
      String? trainerEmail;
      
      // Try to get coach email from user's document
      try {
        final userDoc = await firestoreService.getUser(state.user.uid);
        trainerEmail = userDoc?.coachEmail;
        
        // Get all coaches
        final coaches = await firestoreService.getCoaches();
        
        // If no coach email in user doc, use first available coach
        if (trainerEmail == null || trainerEmail.isEmpty) {
          if (coaches.isNotEmpty) {
            return coaches.first;
          }
          return null;
        }
        
        // Find trainer by email
        try {
          return coaches.firstWhere(
            (coach) => coach.email == trainerEmail,
          );
        } catch (e) {
          // If trainer not found, return first coach as fallback
          if (coaches.isNotEmpty) {
            return coaches.first;
          }
        }
      } catch (e) {
        print('Error fetching trainer: $e');
      }
      
      return null;
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Trainer header with large image
            FutureBuilder<UserModel?>(
              future: _fetchTrainer(),
              builder: (context, snapshot) {
                final trainer = snapshot.data;
                final trainerPhotoUrl = trainer?.photoUrl;
                final trainerName = trainer?.name ?? 'מאמן';
                final trainerEmail = trainer?.email;
                
                return Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Trainer image as background
                      if (trainerPhotoUrl != null && trainerPhotoUrl.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            trainerPhotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Trainer info
                      Positioned(
                        bottom: 24,
                        right: 24,
                        left: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trainerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Settings menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Profile
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('ערוך פרופיל'),
                    subtitle: const Text('עדכן את המידע האישי שלך'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  
                  // Notifications
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('הגדרות התראות'),
                    subtitle: const Text('נהל את העדפות ההתראות שלך'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  
                  // Export Reports
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: const Text('ייצוא דוחות'),
                    subtitle: const Text('צור דוחות מקצועיים ושלח למאמן'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ExportScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  
                  // Terms of Service
                  ListTile(
                    leading: const Icon(Icons.article),
                    title: const Text('תנאי שירות'),
                    onTap: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse('https://muscle-up-main-green.vercel.app/termsofservice');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Divider(),
                  
                  // Privacy Policy
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text('מדיניות פרטיות'),
                    onTap: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse('https://muscle-up-main-green.vercel.app/privacy');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Divider(),
                  
                  // Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('התנתק', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final languageBloc = context.read<LanguageBloc>();
    final currentLanguage = languageBloc.state.language;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: currentLanguage == 'he' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: AlertDialog(
          title: const Text('יציאה מהחשבון'),
          content: const Text('האם אתה בטוח שברצונך להתנתק מהחשבון?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('התנתק'),
            ),
          ],
        ),
      ),
    );
  }
}
