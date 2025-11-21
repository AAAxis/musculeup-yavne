import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/firestore_service.dart';

// Import isSameDay from table_calendar
bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class CalendarScreen extends StatefulWidget {
  final bool showAppBar;
  
  const CalendarScreen({super.key, this.showAppBar = true});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _firestoreService = FirestoreService();
  
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  Map<DateTime, List<CalendarEntry>> _entriesMap = {};
  List<CalendarEntry> _selectedDayEntries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadEntries();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('he', null);
  }

  Future<void> _loadEntries() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || authState.user.email == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userEmail = authState.user.email!;
      
      // Load all entries in parallel
      final [
        workouts,
        meals,
        waterEntries,
        weightEntries,
      ] = await Future.wait([
        _firestoreService.getWorkouts(userEmail),
        _firestoreService.getMealEntries(userEmail),
        _firestoreService.getWaterEntries(userEmail),
        _firestoreService.getWeightEntries(userEmail),
      ]);

      // Process entries into calendar map
      final Map<DateTime, List<CalendarEntry>> entriesMap = {};
      
      // Process workouts
      for (final workout in workouts) {
        final dateStr = workout['date'] as String?;
        if (dateStr != null) {
          try {
            final date = DateTime.parse(dateStr);
            final day = _normalizeDate(date);
            entriesMap.putIfAbsent(day, () => []).add(
              CalendarEntry(
                type: EntryType.workout,
                title: workout['coach_workout_title'] ?? workout['workout_type'] ?? 'אימון',
                date: day,
                data: workout,
              ),
            );
          } catch (e) {
            print('Error parsing workout date: $e');
          }
        }
      }

      // Process meals
      for (final meal in meals) {
        final dateStr = meal['date'] as String?;
        if (dateStr != null) {
          try {
            final date = DateTime.parse(dateStr);
            final day = _normalizeDate(date);
            entriesMap.putIfAbsent(day, () => []).add(
              CalendarEntry(
                type: EntryType.meal,
                title: meal['meal_type'] ?? 'ארוחה',
                date: day,
                data: meal,
              ),
            );
          } catch (e) {
            print('Error parsing meal date: $e');
          }
        }
      }

      // Process water entries
      for (final water in waterEntries) {
        final dateStr = water['date'] as String?;
        if (dateStr != null) {
          try {
            final date = DateTime.parse(dateStr);
            final day = _normalizeDate(date);
            entriesMap.putIfAbsent(day, () => []).add(
              CalendarEntry(
                type: EntryType.water,
                title: '${water['amount_ml'] ?? 0} מ"ל מים',
                date: day,
                data: water,
              ),
            );
          } catch (e) {
            print('Error parsing water date: $e');
          }
        }
      }

      // Process weight entries
      for (final weight in weightEntries) {
        final dateStr = weight['date'] as String?;
        if (dateStr != null) {
          try {
            final date = DateTime.parse(dateStr);
            final day = _normalizeDate(date);
            entriesMap.putIfAbsent(day, () => []).add(
              CalendarEntry(
                type: EntryType.weight,
                title: '${weight['weight'] ?? 0} ק"ג',
                date: day,
                data: weight,
              ),
            );
          } catch (e) {
            print('Error parsing weight date: $e');
          }
        }
      }

      setState(() {
        _entriesMap = entriesMap;
        _selectedDayEntries = entriesMap[_selectedDay] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בטעינת הנתונים: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<CalendarEntry> _getEntriesForDay(DateTime day) {
    // Normalize to start of day for comparison
    final dayOnly = DateTime(day.year, day.month, day.day);
    // Check if we have entries for this day
    final entries = _entriesMap[dayOnly] ?? [];
    return entries;
  }
  
  // Helper to normalize dates for map keys
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedDayEntries = _getEntriesForDay(selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                // Calendar
                Card(
                  margin: const EdgeInsets.all(16),
                  child: TableCalendar<CalendarEntry>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onDaySelected: _onDaySelected,
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: _getEntriesForDay,
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      markerDecoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 3,
                      markerSize: 6,
                      markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    locale: 'he_IL',
                    startingDayOfWeek: StartingDayOfWeek.sunday,
                    availableCalendarFormats: {
                      CalendarFormat.month: 'חודש',
                      CalendarFormat.twoWeeks: 'שבועיים',
                      CalendarFormat.week: 'שבוע',
                    },
                  ),
                ),
                
                // Selected day entries
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          DateFormat('EEEE, dd.MM.yyyy', 'he').format(_selectedDay),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _selectedDayEntries.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_busy,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'אין רשומות ליום זה',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _selectedDayEntries.length,
                              itemBuilder: (context, index) {
                                final entry = _selectedDayEntries[index];
                                return _buildEntryCard(entry);
                              },
                            ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          );

    if (!widget.showAppBar) {
      return content;
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('לוח שנה'),
        ),
        body: content,
      ),
    );
  }

  Widget _buildEntryCard(CalendarEntry entry) {
    IconData icon;
    Color color;
    String subtitle;

    switch (entry.type) {
      case EntryType.workout:
        icon = Icons.fitness_center;
        color = Colors.purple;
        subtitle = entry.data['workout_type'] ?? 'אימון';
        break;
      case EntryType.meal:
        icon = Icons.restaurant;
        color = Colors.green;
        final calories = entry.data['estimated_calories'];
        subtitle = calories != null ? '$calories קק"ל' : 'ארוחה';
        break;
      case EntryType.water:
        icon = Icons.water_drop;
        color = Colors.blue;
        subtitle = entry.data['container_type'] ?? 'מים';
        break;
      case EntryType.weight:
        icon = Icons.scale;
        color = Colors.orange;
        subtitle = 'עדכון משקל';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_left, color: Colors.grey[400]),
      ),
    );
  }
}

class CalendarEntry {
  final EntryType type;
  final String title;
  final DateTime date;
  final Map<String, dynamic> data;

  CalendarEntry({
    required this.type,
    required this.title,
    required this.date,
    required this.data,
  });
}

enum EntryType {
  workout,
  meal,
  water,
  weight,
}

