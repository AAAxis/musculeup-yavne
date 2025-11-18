import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/presentation/profile/profile_screen.dart';
import 'package:muscleup/presentation/settings/notifications_screen.dart';
import 'package:muscleup/presentation/export/export_screen.dart';
import 'package:muscleup/data/services/account_deletion_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _accountDeletionService = AccountDeletionService();
  bool _isDeletingAccount = false;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא ניתן לפתוח את הקישור'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('יציאה מהחשבון'),
          content: const Text('האם אתה בטוח שברצונך להתנתק?'),
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

  void _showAccountDeletionDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'מחיקת חשבון',
            style: TextStyle(color: Colors.red),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'האם אתה בטוח שברצונך למחוק את החשבון שלך?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'פעולה זו תמחק לצמיתות:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• כל המידע האישי שלך'),
              Text('• כל הנתונים וההיסטוריה'),
              Text('• כל הקבצים והחתימות'),
              SizedBox(height: 16),
              Text(
                'פעולה זו אינה ניתנת לביטול!',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showAccountDeletionConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('המשך למחיקה'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountDeletionConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'אישור סופי למחיקה',
            style: TextStyle(color: Colors.red),
          ),
          content: const Text(
            'זהו האישור האחרון. האם אתה בטוח לחלוטין שברצונך למחוק את החשבון שלך? פעולה זו אינה ניתנת לביטול.',
          ),
          actions: [
            TextButton(
              onPressed: _isDeletingAccount
                  ? null
                  : () => Navigator.pop(context),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: _isDeletingAccount ? null : _deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: _isDeletingAccount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('מחק חשבון לצמיתות'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא נמצא משתמש מחובר'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await _accountDeletionService.deleteAccount(user.uid);

      if (mounted) {
        // Close any open dialogs
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Sign out and navigate to login
        context.read<AuthBloc>().add(const AuthSignOutRequested());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('החשבון נמחק בהצלחה'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeletingAccount = false;
        });
        
        Navigator.of(context).pop(); // Close confirmation dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה במחיקת החשבון: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Section
            _buildSectionCard(
              context,
              title: 'פרופיל',
              icon: Icons.person,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('ערוך פרופיל'),
                  subtitle: const Text('עדכן את המידע האישי שלך'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notifications Section
            _buildSectionCard(
              context,
              title: 'התראות',
              icon: Icons.notifications,
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('הגדרות התראות'),
                  subtitle: const Text('נהל את העדפות ההתראות שלך'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Export/Reports Section
            _buildSectionCard(
              context,
              title: 'דוחות וייצוא',
              icon: Icons.description,
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('ייצוא דוחות'),
                  subtitle: const Text('הפק דוחות מקצועיים ושלח למאמן'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // About Section
            _buildSectionCard(
              context,
              title: 'אודות',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('אודות MuscleUp'),
                  subtitle: const Text('גרסה 1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'MuscleUp',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      children: [
                        const Text(
                          'בן הלוויה האישי שלך לכושר למעקב אחר אימונים, ארוחות והתקדמות.',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('תנאי שימוש'),
                  onTap: () {
                    _launchURL('https://muscleup.com/terms');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('מדיניות פרטיות'),
                  onTap: () {
                    _launchURL('https://muscleup.com/privacy');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('עזרה ותמיכה'),
                  onTap: () {
                    _launchURL('https://muscleup.com/support');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Account Deletion Section
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: Colors.red[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'מחיקת חשבון',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'מחיקת החשבון תמחק לצמיתות את כל המידע והנתונים שלך. פעולה זו אינה ניתנת לביטול.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isDeletingAccount ? null : _showAccountDeletionDialog,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('מחק חשבון'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sign Out Section
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.exit_to_app,
                          color: Colors.red[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'יציאה מהחשבון',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'האם אתה בטוח שברצונך להתנתק מהחשבון?',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text('התנתק'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'MUSCLE UP YAVNE',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Better Than Yesterday',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color:
                                  isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '© 2025 MuscleUp. כל הזכויות שמורות.',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.green[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
