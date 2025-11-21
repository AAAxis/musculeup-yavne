import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:intl/intl.dart';

class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen> with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  
  late TabController _tabController;
  
  UserModel? _userData;
  List<Map<String, dynamic>> _waterEntries = [];
  bool _isLoading = false;
  bool _isLoadingEntries = false;
  String? _errorMessage;
  String? _successMessage;

  // Form fields
  String _selectedContainer = 'כוס (250ml)';
  final TextEditingController _customAmountController = TextEditingController();
  
  int _dailyGoal = 2500; // Default goal in ml

  final List<Map<String, String>> _containerTypes = [
    {'value': 'כוס (250ml)', 'ml': '250'},
    {'value': 'בקבוק קטן (500ml)', 'ml': '500'},
    {'value': 'בקבוק גדול (750ml)', 'ml': '750'},
    {'value': 'ליטר', 'ml': '1000'},
    {'value': 'אחר', 'ml': '0'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadWaterEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      try {
        final user = await _firestoreService.getUser(authState.user.uid);
        if (mounted) {
          setState(() {
            _userData = user;
            _calculateDailyGoal(user);
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  void _calculateDailyGoal(UserModel? user) {
    if (user == null) {
      _dailyGoal = 2500;
      return;
    }

    final weight = user.initialWeight ?? 70;
    final height = (user.height ?? 1.70) * 100; // Convert to cm
    final birthDate = user.birthDate;
    
    int age = 30; // Default age
    if (birthDate != null) {
      try {
        final birth = DateTime.parse(birthDate);
        age = DateTime.now().year - birth.year;
      } catch (e) {
        // Use default age
      }
    }

    double baseAmount = weight * 35;
    if (age < 30) baseAmount *= 1.1;
    else if (age > 50) baseAmount *= 0.95;
    if (height > 180) baseAmount *= 1.05;
    else if (height < 160) baseAmount *= 0.95;

    final goal = (baseAmount / 250).round() * 250;
    setState(() {
      _dailyGoal = goal.clamp(2000, 4000);
    });
  }

  Future<void> _loadWaterEntries() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || authState.user.email == null) {
      return;
    }

    setState(() {
      _isLoadingEntries = true;
    });

    try {
      final entries = await _firestoreService.getWaterEntries(authState.user.email!);
      if (mounted) {
        setState(() {
          _waterEntries = entries;
          _isLoadingEntries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEntries = false;
          _errorMessage = 'שגיאה בטעינת נתוני מים: $e';
        });
      }
    }
  }

  int _getTodayTotal() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _waterEntries
        .where((entry) => entry['date'] == today)
        .fold<int>(0, (sum, entry) => sum + (entry['amount_ml'] as int? ?? 0));
  }

  Future<void> _logWater() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || authState.user.email == null) {
      setState(() {
        _errorMessage = 'משתמש לא מחובר';
      });
      return;
    }

    final container = _containerTypes.firstWhere(
      (c) => c['value'] == _selectedContainer,
      orElse: () => _containerTypes[0],
    );

    int amount;
    if (_selectedContainer == 'אחר') {
      amount = int.tryParse(_customAmountController.text) ?? 0;
      if (amount <= 0) {
        setState(() {
          _errorMessage = 'יש להזין כמות תקינה וחיובית';
        });
        return;
      }
    } else {
      amount = int.parse(container['ml']!);
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);
      final timeString = DateFormat('HH:mm').format(now);

      // Save water entry
      await _firestoreService.addWaterEntry(
        userEmail: authState.user.email!,
        amountMl: amount,
        date: dateString,
        time: timeString,
        containerType: _selectedContainer,
        dailyGoalMl: _dailyGoal,
      );

      setState(() {
        _successMessage = 'נרשמו ${amount} מ"ל מים בהצלחה!';
        _selectedContainer = 'כוס (250ml)';
        _customAmountController.clear();
      });

      // Reload entries
      await _loadWaterEntries();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'אירעה שגיאה ברישום המים: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayTotal = _getTodayTotal();
    final todayPercentage = _dailyGoal > 0 ? ((todayTotal / _dailyGoal) * 100).round() : 0;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('תיעוד מים'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'רישום מים'),
              Tab(text: 'היסטוריה'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLogTab(context, todayTotal, todayPercentage),
            _buildHistoryTab(context, todayTotal, todayPercentage),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTab(BuildContext context, int todayTotal, int todayPercentage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Today's Progress Summary
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Color(0xFF2563EB), size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      'מעקב שתיית מים - יום זה',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(todayTotal / 1000).toStringAsFixed(1)}L / ${(_dailyGoal / 1000).toStringAsFixed(1)}L',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: todayPercentage >= 100
                            ? Colors.green[100]
                            : todayPercentage >= 75
                                ? Colors.blue[100]
                                : Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$todayPercentage% מהיעד',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: todayPercentage >= 100
                              ? Colors.green[800]
                              : todayPercentage >= 75
                                  ? Colors.blue[800]
                                  : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (todayPercentage / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.blue[100],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    todayPercentage >= 100
                        ? Colors.green
                        : todayPercentage >= 75
                            ? Colors.blue
                            : Colors.orange,
                  ),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  todayPercentage >= 100
                      ? '🎉 הגעת ליעד היומי!'
                      : todayPercentage >= 75
                          ? '💪 כמעט שם!'
                          : 'נותרו ${((_dailyGoal - todayTotal) / 1000).toStringAsFixed(1)} ליטר ליעד',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Log Water Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'רישום שתיית מים',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Container Type
                  DropdownButtonFormField<String>(
                    value: _selectedContainer,
                    decoration: const InputDecoration(
                      labelText: 'סוג כלי',
                      prefixIcon: Icon(Icons.local_drink),
                    ),
                    items: _containerTypes.map((container) {
                      return DropdownMenuItem<String>(
                        value: container['value'],
                        child: Text(container['value']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedContainer = value;
                        });
                      }
                    },
                  ),
                  
                  // Custom Amount (if "אחר" selected)
                  if (_selectedContainer == 'אחר') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customAmountController,
                      decoration: const InputDecoration(
                        labelText: 'כמות במ"ל',
                        hintText: 'הזן כמות במ״ל',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Error/Success Messages
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _logWater,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'שמור מים',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(BuildContext context, int todayTotal, int todayPercentage) {
    // Calculate weekly stats
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weeklyEntries = _waterEntries.where((entry) {
      final entryDate = entry['date'] as String?;
      if (entryDate == null) return false;
      try {
        final date = DateTime.parse(entryDate);
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    final weeklyTotal = weeklyEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry['amount_ml'] as int? ?? 0),
    );
    final weeklyAverage = weeklyEntries.isNotEmpty
        ? (weeklyTotal / weeklyEntries.length).round()
        : 0;
    final daysWithEntries = weeklyEntries.map((e) => e['date'] as String).toSet().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'סטטיסטיקות שבועיות',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'סה"כ השבוע',
                        '${(weeklyTotal / 1000).toStringAsFixed(1)}L',
                        Icons.water_drop,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'ממוצע יומי',
                        '${(weeklyAverage / 1000).toStringAsFixed(1)}L',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'ימים עם רישום',
                        '$daysWithEntries/7',
                        Icons.calendar_today,
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'היום',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(todayTotal / 1000).toStringAsFixed(1)}L',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$todayPercentage%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: todayPercentage >= 100
                              ? Colors.green
                              : todayPercentage >= 75
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (todayPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      todayPercentage >= 100
                          ? Colors.green
                          : todayPercentage >= 75
                              ? Colors.blue
                              : Colors.orange,
                    ),
                    minHeight: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistoryTab(BuildContext context, int todayTotal, int todayPercentage) {
    if (_isLoadingEntries) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate weekly stats
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weeklyEntries = _waterEntries.where((entry) {
      final entryDate = entry['date'] as String?;
      if (entryDate == null) return false;
      try {
        final date = DateTime.parse(entryDate);
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    final weeklyTotal = weeklyEntries.fold<int>(
      0,
      (sum, entry) => sum + (entry['amount_ml'] as int? ?? 0),
    );
    final weeklyAverage = weeklyEntries.isNotEmpty
        ? (weeklyTotal / weeklyEntries.length).round()
        : 0;
    final daysWithEntries = weeklyEntries.map((e) => e['date'] as String).toSet().length;

    // Group entries by date
    final Map<String, List<Map<String, dynamic>>> groupedEntries = {};
    for (final entry in _waterEntries) {
      final date = entry['date'] as String? ?? '';
      if (!groupedEntries.containsKey(date)) {
        groupedEntries[date] = [];
      }
      groupedEntries[date]!.add(entry);
    }

    final sortedDates = groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadWaterEntries,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Statistics Banner
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'סטטיסטיקות שבועיות',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'סה"כ השבוע',
                        '${(weeklyTotal / 1000).toStringAsFixed(1)}L',
                        Icons.water_drop,
                        Colors.blue,
                      ),
                      _buildStatItem(
                        'ממוצע יומי',
                        '${(weeklyAverage / 1000).toStringAsFixed(1)}L',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _buildStatItem(
                        'ימים עם רישום',
                        '$daysWithEntries/7',
                        Icons.calendar_today,
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'היום',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(todayTotal / 1000).toStringAsFixed(1)}L',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$todayPercentage%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: todayPercentage >= 100
                              ? Colors.green
                              : todayPercentage >= 75
                                  ? Colors.blue
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (todayPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.blue[100],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      todayPercentage >= 100
                          ? Colors.green
                          : todayPercentage >= 75
                              ? Colors.blue
                              : Colors.orange,
                    ),
                    minHeight: 8,
                  ),
                ],
              ),
            ),
          ),
          
          // History List
          if (_waterEntries.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.water_drop_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'עדיין לא נרשמו מים',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'התחל לעקוב אחר שתיית המים שלך',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ...sortedDates.map((date) {
              final entries = groupedEntries[date]!;
              final dayTotal = entries.fold<int>(
                0,
                (sum, entry) => sum + (entry['amount_ml'] as int? ?? 0),
              );

              // Format date
              String formattedDate;
              try {
                final dateTime = DateTime.parse(date);
                formattedDate = DateFormat('EEEE, dd.MM.yyyy', 'he').format(dateTime);
              } catch (e) {
                formattedDate = date;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('סה"כ: ${(dayTotal / 1000).toStringAsFixed(1)}L'),
                  leading: const Icon(Icons.water_drop, color: Colors.blue),
                  children: entries.map((entry) {
                    final time = entry['time_logged'] as String? ?? '';
                    final amount = entry['amount_ml'] as int? ?? 0;
                    final container = entry['container_type'] as String? ?? '';
                    return ListTile(
                      leading: const Icon(Icons.access_time, size: 20),
                      title: Text('$amount מ"ל - $container'),
                      subtitle: Text(time),
                      trailing: entry['photo_url'] != null
                          ? const Icon(Icons.camera_alt, size: 20, color: Colors.blue)
                          : null,
                    );
                  }).toList(),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

