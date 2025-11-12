import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/home/home_screen.dart';
import 'package:muscleup/presentation/boost/boost_screen.dart';
import 'package:muscleup/presentation/meals/meals_screen.dart';
import 'package:muscleup/presentation/workouts/workouts_screen.dart';
import 'package:muscleup/presentation/log/log_screen.dart';
import 'package:muscleup/presentation/settings/settings_screen.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    BoostScreen(),
    MealsScreen(),
    WorkoutsScreen(),
    LogScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String? userPhotoUrl;
          if (state is AuthAuthenticated) {
            userPhotoUrl = state.user.photoURL;
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(_getTitle()),
              automaticallyImplyLeading: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: IconButton(
                    icon: userPhotoUrl != null
                        ? CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(userPhotoUrl),
                            backgroundColor: Colors.transparent,
                          )
                        : CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(25),
                            child: Icon(
                              Icons.person,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                    onPressed: () {
                      setState(() {
                        _currentIndex = 5; // Navigate to Settings
                      });
                    },
                  ),
                ),
              ],
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'בית',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bolt_outlined),
                  selectedIcon: Icon(Icons.bolt),
                  label: 'בוסט',
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
        return 'בוסט';
      case 2:
        return 'מתכונים';
      case 3:
        return 'אימונים';
      case 4:
        return 'יומן';
      case 5:
        return 'הגדרות';
      default:
        return 'MuscleUp';
    }
  }
}
