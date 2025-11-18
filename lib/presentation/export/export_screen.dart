import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:muscleup/data/models/user_model.dart';
import 'package:muscleup/data/services/firestore_service.dart';
import 'package:muscleup/data/services/receipt_generation_service.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _firestoreService = FirestoreService();
  final _receiptService = ReceiptGenerationService();
  
  UserModel? _user;
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      try {
        final user = await _firestoreService.getUser(authState.user.uid);
        if (mounted) {
          setState(() {
            _user = user;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה בטעינת נתונים: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _generateReport(String reportType) async {
    if (_user == null) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      final now = DateTime.now();
      DateTime startDate;
      String reportTitle;
      String fileName;

      switch (reportType) {
        case 'weekly':
          startDate = now.subtract(const Duration(days: 7));
          reportTitle = 'דוח שבועי - ${_user!.name}';
          fileName = 'weekly-report-${_user!.name}-${DateFormat('dd-MM-yyyy').format(now)}';
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month - 1, now.day);
          reportTitle = 'דוח חודשי - ${_user!.name}';
          fileName = 'monthly-report-${_user!.name}-${DateFormat('dd-MM-yyyy').format(now)}';
          break;
        case 'all':
          startDate = _user!.createdAt ?? now.subtract(const Duration(days: 365));
          reportTitle = 'דוח סיכום - ${_user!.name}';
          fileName = 'summary-report-${_user!.name}-${DateFormat('dd-MM-yyyy').format(now)}';
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
          reportTitle = 'דוח - ${_user!.name}';
          fileName = 'report-${_user!.name}-${DateFormat('dd-MM-yyyy').format(now)}';
      }

      // Generate HTML receipt
      final htmlContent = await _receiptService.generateReceipt(
        user: _user!,
        startDate: startDate,
        endDate: now,
        reportType: reportType,
        reportTitle: reportTitle,
      );

      // Save and share
      await _receiptService.saveAndShareReceipt(
        htmlContent: htmlContent,
        fileName: fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הדוח הופק בהצלחה!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת הדוח: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('ייצוא דוחות'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ייצוא ושליחת דוחות'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.blue[500]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.description,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ייצוא ושליחת דוחות',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'הפק דוחות מקצועיים ושלח אותם למאמן המלווה',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Weekly Report Card
              _buildReportCard(
                context,
                icon: Icons.calendar_today,
                title: 'דוח שבועי',
                description: 'סיכום פעילות שבועית',
                color: Colors.green,
                onTap: () => _generateReport('weekly'),
              ),
              const SizedBox(height: 16),

              // Monthly Report Card
              _buildReportCard(
                context,
                icon: Icons.calendar_month,
                title: 'דוח חודשי',
                description: 'סיכום מקיף של 30 הימים האחרונים',
                color: Colors.blue,
                onTap: () => _generateReport('monthly'),
              ),
              const SizedBox(height: 16),

              // Summary Report Card
              _buildReportCard(
                context,
                icon: Icons.summarize,
                title: 'דוח סיכום',
                description: 'דוח מקיף לכל התקופה',
                color: Colors.orange,
                onTap: () => _generateReport('all'),
              ),
              const SizedBox(height: 24),

              // Info Card
              if (_user?.coachEmail != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'הדוחות יישלחו אוטומטית למאמן: ${_user!.coachEmail}',
                          style: TextStyle(color: Colors.blue[900]),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: _isGenerating ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_isGenerating)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

