import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:intl/intl.dart';

class RecentWorkoutsCard extends StatefulWidget {
  const RecentWorkoutsCard({super.key});

  @override
  State<RecentWorkoutsCard> createState() => _RecentWorkoutsCardState();
}

class _RecentWorkoutsCardState extends State<RecentWorkoutsCard> with WidgetsBindingObserver {
  final _firestoreService = FirestoreService();
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _recentWorkouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadRecentWorkouts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh workouts when app comes back to foreground
      _loadRecentWorkouts();
    }
  }

  void refresh() {
    _loadRecentWorkouts();
  }

  Future<void> _loadRecentWorkouts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final user = await _firestoreService.getUser(authState.user.uid);
        if (user != null && mounted) {
          // Fetch recent workouts (both active and completed)
          final workoutsQuery = await _firestore
              .collection('workouts')
              .where('created_by', isEqualTo: user.email)
              .orderBy('date', descending: true)
              .orderBy('start_time', descending: true)
              .limit(3)
              .get();

          final workouts = workoutsQuery.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();

          if (mounted) {
            setState(() {
              _recentWorkouts = workouts;
              _isLoading = false;
            });
          }
        } else if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // If orderBy fails (no index), try without orderBy on start_time
      try {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          final user = await _firestoreService.getUser(authState.user.uid);
          if (user != null && mounted) {
            final workoutsQuery = await _firestore
                .collection('workouts')
                .where('created_by', isEqualTo: user.email)
                .orderBy('date', descending: true)
                .limit(3)
                .get();

            final workouts = workoutsQuery.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data(),
                    })
                .toList();

            if (mounted) {
              setState(() {
                _recentWorkouts = workouts;
                _isLoading = false;
              });
            }
          }
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'תאריך לא ידוע';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy', 'he').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _getWorkoutTitle(Map<String, dynamic> workout) {
    return workout['coach_workout_title'] ?? 
           workout['workout_type'] ?? 
           'אימון';
  }

  String _getWorkoutStatus(Map<String, dynamic> workout) {
    final status = workout['status'];
    if (status == 'הושלם') {
      return 'הושלם';
    } else if (status == 'פעיל') {
      return 'פעיל';
    }
    return status ?? 'לא ידוע';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'אימונים אחרונים',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'סיכום 3 האימונים האחרונים שלך.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_recentWorkouts.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'אין אימונים אחרונים להצגה.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'צור אימון כדי לראות אותו כאן!',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _recentWorkouts.map((workout) {
                  final status = _getWorkoutStatus(workout);
                  final isCompleted = status == 'הושלם';
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.green[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted ? Colors.green[200]! : Colors.blue[200]!,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isCompleted ? Colors.green[100] : Colors.blue[100],
                        child: Icon(
                          Icons.fitness_center,
                          color: isCompleted ? Colors.green[700] : Colors.blue[700],
                          size: 20,
                        ),
                      ),
                      title: Text(
                        _getWorkoutTitle(workout),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(workout['date']),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted ? Colors.green[200] : Colors.blue[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isCompleted ? Colors.green[900] : Colors.blue[900],
                                  ),
                                ),
                              ),
                              if (workout['exercises'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    ' • ${(workout['exercises'] as List).length} תרגילים',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // TODO: Navigate to workout history
                },
                child: const Text('צפה בכל היסטוריית האימונים'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

