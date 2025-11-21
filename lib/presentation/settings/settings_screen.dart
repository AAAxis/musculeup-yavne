import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/presentation/language/bloc/language_bloc.dart';
import 'package:muscleup/presentation/profile/profile_screen.dart';
import 'package:muscleup/presentation/settings/notifications_screen.dart';
import 'package:muscleup/presentation/export/export_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('לא ניתן לפתוח קישור'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

      void _showLogoutDialog() {
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
                  subtitle: const Text('צור דוחות מקצועיים ושלח למאמן'),
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
                  subtitle: const Text('גרסה 1.4.0+3'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('תנאי שירות'),
                  onTap: () {
                    _launchURL('https://muscle-up-main-green.vercel.app/termsofservice');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('מדיניות פרטיות'),
                  onTap: () {
                    _launchURL('https://muscle-up-main-green.vercel.app/privacy');
                  },
                ),
              ],
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
                          'התנתקות',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'האם אתה בטוח שברצונך להתנתק?',
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
