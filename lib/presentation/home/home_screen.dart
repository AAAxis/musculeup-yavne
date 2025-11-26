import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:muscleup/presentation/home/widgets/welcome_header.dart';
import 'package:muscleup/presentation/home/widgets/time_display.dart';
import 'package:muscleup/presentation/home/widgets/coach_workouts_card.dart';
import 'package:muscleup/presentation/home/widgets/quick_actions_card.dart';
import 'package:muscleup/presentation/home/widgets/progress_card.dart';
import 'package:muscleup/presentation/home/widgets/recent_workouts_card.dart';
import 'package:muscleup/presentation/boost/boost_screen.dart';
import 'package:muscleup/presentation/weight/weight_update_screen.dart';
import 'package:muscleup/presentation/water/water_tracking_screen.dart';
import 'package:muscleup/presentation/meals/meals_screen.dart';
import 'package:muscleup/presentation/navigation/main_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _firestoreService = FirestoreService();
  final GlobalKey _recentWorkoutsKey = GlobalKey();
  late String _currentTime;
  late String _currentDate;
  UserModel? _userData;
  bool _isLoadingUser = true;

  void refreshWorkouts() {
    final state = _recentWorkoutsKey.currentState;
    if (state != null) {
      // Call refresh method dynamically to avoid type issues
      (state as dynamic).refresh();
    }
  }


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTime();
    _loadUserData();
    // Update time every second
    Future.delayed(const Duration(seconds: 1), _updateTimeLoop);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _loadUserData();
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, dd.MM.yyyy').format(now);
    });
  }

  void _updateTimeLoop() {
    if (mounted) {
      _updateTime();
      Future.delayed(const Duration(seconds: 1), _updateTimeLoop);
    }
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      try {
        final user = await _firestoreService.getUser(authState.user.uid);
        if (mounted) {
          setState(() {
            _userData = user;
            _isLoadingUser = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    }
  }

  void _navigateToWeightUpdate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeightUpdateScreen(),
      ),
    );
  }

  void _navigateToAddMeal() {
    // Switch to meals tab (index 2)
    MainNavigation.switchToTab(2);
  }

  void _navigateToWaterTracking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WaterTrackingScreen(),
      ),
    );
  }

  void _navigateToBoostScreen() {
    // Navigate to Boost screen (index 1 in main navigation)
    // We'll use a simple navigation for now
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('בוסט')),
          body: const BoostScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            final displayName = user.displayName ?? 'משתמש';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Header
                  WelcomeHeader(displayName: displayName),
                  const SizedBox(height: 24),

                  // Time Display
                  TimeDisplay(
                    currentTime: _currentTime,
                    currentDate: _currentDate,
                  ),
                  const SizedBox(height: 24),


                  // Two Column Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  QuickActionsCard(
                                    onWeightUpdateTap: _navigateToWeightUpdate,
                                    onAddMealTap: _navigateToAddMeal,
                                    onWaterDocTap: _navigateToWaterTracking,
                                    onProgressTrackingTap:
                                        _navigateToBoostScreen,
                                  ),
                                  const SizedBox(height: 24),
                                  _isLoadingUser
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ProgressCard(
                                          user: _userData,
                                          createdAt: _userData?.createdAt ??
                                              DateTime.now(),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: RecentWorkoutsCard(key: _recentWorkoutsKey),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            QuickActionsCard(
                              onWeightUpdateTap: _navigateToWeightUpdate,
                              onAddMealTap: _navigateToAddMeal,
                              onWaterDocTap: _navigateToWaterTracking,
                              onProgressTrackingTap: _navigateToBoostScreen,
                            ),
                            const SizedBox(height: 24),
                            _isLoadingUser
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : ProgressCard(
                                    user: _userData,
                                    createdAt:
                                        _userData?.createdAt ?? DateTime.now(),
                                  ),
                            const SizedBox(height: 24),
                            RecentWorkoutsCard(key: _recentWorkoutsKey),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
