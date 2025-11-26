import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:intl/intl.dart';

class WeightUpdateScreen extends StatefulWidget {
  const WeightUpdateScreen({super.key});

  @override
  State<WeightUpdateScreen> createState() => _WeightUpdateScreenState();
}

class _WeightUpdateScreenState extends State<WeightUpdateScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _firestoreService = FirestoreService();
  
  late TabController _tabController;
  
  UserModel? _userData;
  List<Map<String, dynamic>> _weightEntries = [];
  bool _isLoading = false;
  bool _isLoadingEntries = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadWeightEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _weightController.dispose();
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
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadWeightEntries() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || authState.user.email == null) {
      return;
    }

    setState(() {
      _isLoadingEntries = true;
    });

    try {
      final entries = await _firestoreService.getWeightEntries(authState.user.email!);
      if (mounted) {
        setState(() {
          _weightEntries = entries;
          _isLoadingEntries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEntries = false;
          _errorMessage = 'שגיאה בטעינת נתוני משקל: $e';
        });
      }
    }
  }

  Future<void> _deleteWeightEntry(String entryId) async {
    try {
      await _firestoreService.deleteWeightEntry(entryId);
      
      // Remove from local list
      setState(() {
        _weightEntries.removeWhere((entry) => entry['id'] == entryId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('רישום המשקל נמחק בהצלחה'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting weight entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה במחיקת רישום המשקל: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Reload entries on error
        _loadWeightEntries();
      }
    }
  }

  Future<void> _saveWeight() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight < 30 || weight > 300) {
      setState(() {
        _errorMessage = 'אנא הזן משקל תקין (30-300 ק"ג)';
      });
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() {
        _errorMessage = 'משתמש לא מחובר';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final userEmail = authState.user.email;
      if (userEmail == null) {
        throw Exception('אימייל משתמש לא נמצא');
      }

      // Get current date in YYYY-MM-DD format
      final now = DateTime.now();
      final dateString = DateFormat('yyyy-MM-dd').format(now);
      final timeString = DateFormat('HH:mm').format(now);

      // Save weight entry to Firestore
      await _firestoreService.addWeightEntry(
        userEmail: userEmail,
        weight: weight,
        date: dateString,
        time: timeString,
      );

      // Update user's current weight
      await _firestoreService.updateUser(authState.user.uid, {
        'current_weight': weight,
      });

      setState(() {
        _successMessage = 'המשקל עודכן בהצלחה!';
        _weightController.clear();
      });

      // Reload entries
      await _loadWeightEntries();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('המשקל עודכן בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'שגיאה בשמירת המשקל: $e';
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
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('עדכון משקל'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'רישום משקל'),
              Tab(text: 'היסטוריה'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLogTab(context),
            _buildHistoryTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.scale,
                        size: 48,
                        color: const Color(0xFFD97706),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'עדכון משקל',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'עקוב אחר ההתקדמות שלך',
                        style: TextStyle(
                          fontSize: 16,
                          color: const Color(0xFFD97706).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 24),

            // Weight Input
            TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'משקל (ק"ג)',
                    hintText: 'הזן משקל',
                    prefixIcon: Icon(Icons.monitor_weight),
                    suffixText: 'ק"ג',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'אנא הזן משקל';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null) {
                      return 'אנא הזן מספר תקין';
                    }
                    if (weight < 30 || weight > 300) {
                      return 'המשקל חייב להיות בין 30 ל-300 ק"ג';
                    }
                    return null;
                  },
                ),
            const SizedBox(height: 24),

            // Error Message
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

            // Success Message
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
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
                  onPressed: _isLoading ? null : _saveWeight,
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
                          'שמור משקל',
                          style: TextStyle(fontSize: 16),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    if (_isLoadingEntries) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate statistics
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weeklyEntries = _weightEntries.where((entry) {
      final entryDate = entry['date'] as String?;
      if (entryDate == null) return false;
      try {
        final date = DateTime.parse(entryDate);
        return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();

    // Calculate weight change
    double? currentWeight;
    double? previousWeight;
    double weightChange = 0.0;
    String trend = 'stable';
    
    if (_weightEntries.isNotEmpty) {
      currentWeight = _weightEntries[0]['weight']?.toDouble();
      if (_weightEntries.length > 1) {
        previousWeight = _weightEntries[1]['weight']?.toDouble();
        if (currentWeight != null && previousWeight != null) {
          weightChange = currentWeight - previousWeight;
          if (weightChange.abs() < 0.1) {
            trend = 'stable';
          } else if (weightChange > 0) {
            trend = 'up';
          } else {
            trend = 'down';
          }
        }
      }
    }

    // Calculate weekly average
    double weeklyAverage = 0.0;
    if (weeklyEntries.isNotEmpty) {
      final totalWeight = weeklyEntries.fold<double>(
        0.0,
        (sum, entry) => sum + (entry['weight']?.toDouble() ?? 0.0),
      );
      weeklyAverage = totalWeight / weeklyEntries.length;
    }

    // Group entries by date
    final Map<String, List<Map<String, dynamic>>> groupedEntries = {};
    for (final entry in _weightEntries) {
      final date = entry['date'] as String? ?? '';
      if (!groupedEntries.containsKey(date)) {
        groupedEntries[date] = [];
      }
      groupedEntries[date]!.add(entry);
    }

    final sortedDates = groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: _loadWeightEntries,
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
                    'סטטיסטיקות',
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
                        'משקל נוכחי',
                        currentWeight != null ? '${currentWeight.toStringAsFixed(1)} ק"ג' : '—',
                        Icons.scale,
                        Colors.orange,
                      ),
                      _buildStatItem(
                        'שינוי אחרון',
                        weightChange != 0
                            ? '${weightChange > 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} ק"ג'
                            : '0.0 ק"ג',
                        trend == 'down'
                            ? Icons.trending_down
                            : trend == 'up'
                                ? Icons.trending_up
                                : Icons.remove,
                        trend == 'down'
                            ? Colors.green
                            : trend == 'up'
                                ? Colors.red
                                : Colors.grey,
                      ),
                      _buildStatItem(
                        'ממוצע שבועי',
                        weeklyAverage > 0 ? '${weeklyAverage.toStringAsFixed(1)} ק"ג' : '—',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'סה"כ מדידות',
                        '${_weightEntries.length}',
                        Icons.assessment,
                        Colors.purple,
                      ),
                      _buildStatItem(
                        'מדידות השבוע',
                        '${weeklyEntries.length}',
                        Icons.today,
                        Colors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // History List
          if (_weightEntries.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.scale_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'עדיין לא נרשמו מדידות משקל',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'התחל לעקוב אחר המשקל שלך',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          else
            ...sortedDates.map((date) {
              final entries = groupedEntries[date]!;
              final latestWeight = entries[0]['weight']?.toDouble();

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
                  subtitle: latestWeight != null
                      ? Text('${latestWeight.toStringAsFixed(1)} ק"ג')
                      : null,
                  leading: const Icon(Icons.scale, color: Colors.orange),
                  children: entries.asMap().entries.map((entryMap) {
                    final index = entryMap.key;
                    final entry = entryMap.value;
                    final entryId = entry['id'] as String?;
                    final time = entry['time'] as String? ?? '';
                    final weight = entry['weight']?.toDouble();
                    
                    return Dismissible(
                      key: Key(entryId ?? 'weight_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('מחיקת רישום משקל'),
                            content: const Text('האם אתה בטוח שברצונך למחוק את הרישום הזה?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('ביטול'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('מחק'),
                              ),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (direction) {
                        if (entryId != null) {
                          _deleteWeightEntry(entryId);
                        }
                      },
                      child: ListTile(
                        leading: const Icon(Icons.access_time, size: 20),
                        title: Text(
                          weight != null ? '${weight.toStringAsFixed(1)} ק"ג' : '—',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(time),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
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
}

