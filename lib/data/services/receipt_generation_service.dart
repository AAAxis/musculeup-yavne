import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'he');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

  /// Generate a professional receipt/report as HTML
  Future<String> generateReceipt({
    required UserModel user,
    required DateTime startDate,
    required DateTime endDate,
    required String reportType,
    required String reportTitle,
  }) async {
    try {
      // Fetch all data for the period
      final userEmail = user.email;
      final data = await _fetchReportData(userEmail, startDate, endDate);

      // Generate HTML content
      final htmlContent = _generateHTML(
        user: user,
        data: data,
        startDate: startDate,
        endDate: endDate,
        reportTitle: reportTitle,
        reportType: reportType,
      );

      return htmlContent;
    } catch (e) {
      throw Exception('Failed to generate receipt: $e');
    }
  }

  /// Save and share the receipt
  Future<void> saveAndShareReceipt({
    required String htmlContent,
    required String fileName,
  }) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.html');

      // Write HTML to file
      await file.writeAsString(htmlContent);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'דוח התקדמות - MuscleUp',
        subject: fileName,
      );
    } catch (e) {
      throw Exception('Failed to save and share receipt: $e');
    }
  }

  /// Fetch all data needed for the report
  Future<Map<String, dynamic>> _fetchReportData(
    String userEmail,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Query all collections in parallel
      // Note: Firestore queries need to filter client-side for date ranges with string dates
      final queries = await Future.wait([
        // Weight entries - fetch all and filter client-side
        _firestore
            .collection('weight_entries')
            .where('user_email', isEqualTo: userEmail)
            .get(),
        // Calorie tracking
        _firestore
            .collection('calorie_tracking')
            .where('created_by', isEqualTo: userEmail)
            .get(),
        // Workouts
        _firestore
            .collection('workouts')
            .where('created_by', isEqualTo: userEmail)
            .get(),
      ]);

      // Filter by date range client-side
      final allWeightEntries = queries[0].docs.map((doc) => doc.data()).toList();
      final allCalorieTracking = queries[1].docs.map((doc) => doc.data()).toList();
      final allWorkouts = queries[2].docs.map((doc) => doc.data()).toList();

      final filteredWeightEntries = allWeightEntries.where((entry) {
        final date = _parseDate(entry['date']);
        if (date == null) return false;
        return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      final filteredCalorieTracking = allCalorieTracking.where((entry) {
        final date = _parseDate(entry['date']);
        if (date == null) return false;
        return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      final filteredWorkouts = allWorkouts.where((entry) {
        final date = _parseDate(entry['date']);
        if (date == null) return false;
        final status = entry['status'];
        return (status == 'הושלם' || status == 'completed') &&
            date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      return {
        'weightEntries': filteredWeightEntries,
        'calorieTracking': filteredCalorieTracking,
        'workouts': filteredWorkouts,
      };
    } catch (e) {
      // If queries fail, return empty data
      print('Error fetching report data: $e');
      return {
        'weightEntries': [],
        'calorieTracking': [],
        'workouts': [],
      };
    }
  }

  /// Generate HTML content for the receipt
  String _generateHTML({
    required UserModel user,
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
    required String reportTitle,
    required String reportType,
  }) {
    final weightEntries = data['weightEntries'] as List;
    final calorieTracking = data['calorieTracking'] as List;
    final workouts = data['workouts'] as List;

    final cssStyles = '''
      body { 
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', Arial, sans-serif; 
        direction: rtl; 
        text-align: right; 
        background-color: #f9f9f9; 
        color: #333; 
        margin: 0; 
        padding: 20px; 
      }
      .container { 
        max-width: 800px; 
        margin: auto; 
        background: white; 
        border: 1px solid #eee; 
        box-shadow: 0 0 10px rgba(0,0,0,0.05); 
        padding: 40px; 
      }
      .header { 
        text-align: center; 
        border-bottom: 2px solid #7F9253; 
        padding-bottom: 20px; 
        margin-bottom: 30px; 
      }
      h1 { 
        color: #7F9253; 
        font-size: 28px; 
        margin: 0;
      }
      .subtitle { 
        font-size: 14px; 
        color: #555; 
        margin-top: 10px;
      }
      .section { 
        margin-bottom: 30px; 
      }
      h2 { 
        font-size: 22px; 
        color: #5E737B; 
        border-bottom: 1px solid #ddd; 
        padding: 10px; 
        margin-bottom: 15px; 
      }
      table { 
        width: 100%; 
        border-collapse: collapse; 
        margin-top: 15px;
      }
      th, td { 
        border: 1px solid #ddd; 
        padding: 10px; 
        text-align: right; 
      }
      th { 
        background-color: #f2f2f2; 
        font-weight: bold; 
      }
      .insight-box { 
        background-color: #f0f8ff; 
        border: 1px solid #d1e7fd; 
        padding: 15px; 
        margin-top: 20px; 
        border-radius: 5px; 
      }
      .insight-box h3 { 
        margin-top: 0; 
        color: #0c5464; 
      }
      .footer { 
        text-align: center; 
        margin-top: 40px; 
        font-size: 12px; 
        color: #999; 
      }
    ''';

    final userInfoSection = '''
      <div class="section">
        <h2>👤 פרטים אישיים</h2>
        <p><strong>שם מתאמן:</strong> ${user.name}</p>
        <p><strong>כתובת מייל:</strong> ${user.email}</p>
        ${user.createdAt != null ? '<p><strong>תאריך תחילת מעקב:</strong> ${_dateFormat.format(user.createdAt!)}</p>' : ''}
        ${user.coachName != null ? '<p><strong>מאמן מלווה:</strong> ${user.coachName}</p>' : ''}
      </div>
    ''';

    final weightSection = weightEntries.isNotEmpty ? '''
      <div class="section">
        <h2>⚖️ מעקב משקל</h2>
        <table>
          <tr>
            <th>תאריך</th>
            <th>משקל (ק"ג)</th>
          </tr>
          ${weightEntries.map((w) {
            final date = _parseDate(w['date']);
            final weight = w['weight_kg'] ?? w['weight'] ?? '-';
            return '''
              <tr>
                <td>${date != null ? _dateFormat.format(date) : '-'}</td>
                <td>$weight</td>
              </tr>
            ''';
          }).join('')}
        </table>
        <div class="insight-box">
          <h3>📌 תובנות משקל</h3>
          ${_generateWeightInsights(weightEntries)}
        </div>
      </div>
    ''' : '';

    final calorieSection = calorieTracking.isNotEmpty ? '''
      <div class="section">
        <h2>🥗 מעקב קלוריות</h2>
        <table>
          <tr>
            <th>תאריך</th>
            <th>קלוריות</th>
            <th>חלבון (גרם)</th>
            <th>פחמימה (גרם)</th>
            <th>שומן (גרם)</th>
          </tr>
          ${calorieTracking.map((c) {
            final date = _parseDate(c['date']);
            return '''
              <tr>
                <td>${date != null ? _dateFormat.format(date) : '-'}</td>
                <td>${c['total_calories'] ?? '-'}</td>
                <td>${c['total_protein'] ?? '-'}</td>
                <td>${c['total_carbs'] ?? '-'}</td>
                <td>${c['total_fat'] ?? '-'}</td>
              </tr>
            ''';
          }).join('')}
        </table>
        <div class="insight-box">
          <h3>📌 תובנות קלוריות</h3>
          ${_generateCalorieInsights(calorieTracking)}
        </div>
      </div>
    ''' : '';

    final workoutSection = workouts.isNotEmpty ? '''
      <div class="section">
        <h2>🏋️ מעקב אימונים</h2>
        <table>
          <tr>
            <th>תאריך</th>
            <th>סוג אימון</th>
            <th>פירוט</th>
          </tr>
          ${workouts.map((w) {
            final date = _parseDate(w['date']);
            return '''
              <tr>
                <td>${date != null ? _dateFormat.format(date) : '-'}</td>
                <td>${w['workout_type'] ?? '-'}</td>
                <td>${w['notes'] ?? '-'}</td>
              </tr>
            ''';
          }).join('')}
        </table>
        <div class="insight-box">
          <h3>📌 סיכום אימונים בתקופה</h3>
          <p><strong>סה"כ אימונים:</strong> ${workouts.length}</p>
        </div>
      </div>
    ''' : '';

    return '''
      <!DOCTYPE html>
      <html dir="rtl" lang="he">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>$reportTitle</title>
        <style>
          $cssStyles
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>$reportTitle</h1>
            <div class="subtitle">
              מאמן מלווה: ${user.coachName ?? 'לא צוין'}<br>
              טווח דיווח: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}<br>
              תאריך הפקת הדוח: ${_dateFormat.format(DateTime.now())}
            </div>
          </div>
          
          $userInfoSection
          $weightSection
          $workoutSection
          $calorieSection

          <div class="footer">
            <p>דוח זה הופק באמצעות מערכת MUSCLE UP YAVNE.</p>
          </div>
        </div>
      </body>
      </html>
    ''';
  }

  String _generateWeightInsights(List weightEntries) {
    if (weightEntries.isEmpty) {
      return '<p>אין נתוני משקל בתקופה זו.</p>';
    }

    final sortedWeights = List.from(weightEntries)
      ..sort((a, b) {
        final dateA = _parseDate(a['date']);
        final dateB = _parseDate(b['date']);
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });

    final initialWeight = sortedWeights.first['weight_kg'] ?? sortedWeights.first['weight'];
    final finalWeight = sortedWeights.last['weight_kg'] ?? sortedWeights.last['weight'];

    if (initialWeight == null || finalWeight == null) {
      return '<p>נתוני משקל לא שלמים.</p>';
    }

    final weights = sortedWeights
        .map((w) => w['weight_kg'] ?? w['weight'])
        .where((w) => w != null)
        .map((w) => double.tryParse(w.toString()) ?? 0.0)
        .toList();

    final minWeight = weights.isNotEmpty ? weights.reduce((a, b) => a < b ? a : b) : 0.0;
    final maxWeight = weights.isNotEmpty ? weights.reduce((a, b) => a > b ? a : b) : 0.0;
    final diff = (finalWeight - initialWeight).toStringAsFixed(1);
    final change = double.parse(diff) > 0
        ? 'עליה של $diff ק"ג'
        : double.parse(diff) < 0
            ? 'ירידה של ${diff.replaceFirst('-', '')} ק"ג'
            : 'ללא שינוי';

    return '''
      <p><strong>משקל התחלתי:</strong> $initialWeight ק"ג</p>
      <p><strong>משקל נוכחי:</strong> $finalWeight ק"ג</p>
      <p><strong>שינוי כולל:</strong> $change</p>
      <p><strong>משקל מינימלי:</strong> $minWeight ק"ג</p>
      <p><strong>משקל מקסימלי:</strong> $maxWeight ק"ג</p>
    ''';
  }

  String _generateCalorieInsights(List calorieTracking) {
    if (calorieTracking.isEmpty) {
      return '<p>אין נתוני קלוריות בתקופה זו.</p>';
    }

    final calories = calorieTracking
        .map((c) => c['total_calories'])
        .where((c) => c != null)
        .map((c) => double.tryParse(c.toString()) ?? 0.0)
        .toList();

    final proteins = calorieTracking
        .map((c) => c['total_protein'])
        .where((p) => p != null)
        .map((p) => double.tryParse(p.toString()) ?? 0.0)
        .toList();

    final carbs = calorieTracking
        .map((c) => c['total_carbs'])
        .where((c) => c != null)
        .map((c) => double.tryParse(c.toString()) ?? 0.0)
        .toList();

    final fats = calorieTracking
        .map((c) => c['total_fat'])
        .where((f) => f != null)
        .map((f) => double.tryParse(f.toString()) ?? 0.0)
        .toList();

    final avgCalories = calories.isNotEmpty
        ? (calories.reduce((a, b) => a + b) / calories.length).toStringAsFixed(0)
        : '0';
    final avgProtein = proteins.isNotEmpty
        ? (proteins.reduce((a, b) => a + b) / proteins.length).toStringAsFixed(0)
        : '0';
    final avgCarbs = carbs.isNotEmpty
        ? (carbs.reduce((a, b) => a + b) / carbs.length).toStringAsFixed(0)
        : '0';
    final avgFat = fats.isNotEmpty
        ? (fats.reduce((a, b) => a + b) / fats.length).toStringAsFixed(0)
        : '0';

    return '''
      <p><strong>ממוצע יומי קלוריות:</strong> $avgCalories קק"ל</p>
      <p><strong>ממוצע יומי חלבון:</strong> $avgProtein גרם</p>
      <p><strong>ממוצע יומי פחמימה:</strong> $avgCarbs גרם</p>
      <p><strong>ממוצע יומי שומן:</strong> $avgFat גרם</p>
    ''';
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is Timestamp) return dateValue.toDate();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}


