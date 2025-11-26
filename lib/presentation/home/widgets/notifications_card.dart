import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muscleup/presentation/auth/bloc/auth_bloc.dart';
import 'package:muscleup/data/services/notification_popup_service.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsCard extends StatefulWidget {
  const NotificationsCard({super.key});

  @override
  State<NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<NotificationsCard> with WidgetsBindingObserver {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _userEmail;

  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserEmail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications();
    }
  }

  void refresh() {
    _loadNotifications();
  }

  Future<void> _loadUserEmail() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      try {
        final userDoc = await _firestore.collection('users').doc(authState.user.uid).get();
        if (userDoc.exists && mounted) {
          setState(() {
            _userEmail = userDoc.data()?['email'] ?? authState.user.email;
          });
          _loadNotifications();
        }
      } catch (e) {
        print('Error loading user email: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (_userEmail == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cancel existing subscription
      await _notificationsSubscription?.cancel();

      // Set up real-time listener
      _notificationsSubscription = _firestore
          .collection('notifications')
          .where('user_email', isEqualTo: _userEmail)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _notifications = snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList();
            _isLoading = false;
          });
        }
      }, onError: (error) {
        print('Error listening to notifications: $error');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'תאריך לא ידוע';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'תאריך לא ידוע';
      }
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'עכשיו';
          }
          return 'לפני ${difference.inMinutes} דקות';
        }
        return 'לפני ${difference.inHours} שעות';
      } else if (difference.inDays == 1) {
        return 'אתמול';
      } else if (difference.inDays < 7) {
        return 'לפני ${difference.inDays} ימים';
      } else {
        return DateFormat('dd.MM.yyyy', 'he').format(date);
      }
    } catch (e) {
      return 'תאריך לא ידוע';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'workout':
        return Icons.fitness_center;
      case 'weight_reminder':
        return Icons.scale;
      case 'water_reminder':
        return Icons.water_drop;
      case 'meal_reminder':
        return Icons.restaurant;
      case 'message':
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'workout':
        return Colors.blue;
      case 'weight_reminder':
        return Colors.orange;
      case 'water_reminder':
        return Colors.cyan;
      case 'meal_reminder':
        return Colors.green;
      case 'message':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
      });
      await _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
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
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Colors.blue[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'התראות אחרונות',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: _loadNotifications,
                    child: const Text('רענן'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'ההתראות האחרונות שלך מהמאמן.',
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
            else if (_notifications.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'אין התראות להצגה.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _notifications.asMap().entries.map((entry) {
                  final index = entry.key;
                  final notification = entry.value;
                  final notificationId = notification['id'] as String?;
                  final title = notification['title'] as String? ?? 'התראה';
                  final body = notification['body'] as String? ?? notification['name'] as String? ?? '';
                  final type = notification['type'] as String?;
                  final read = notification['read'] as bool? ?? false;
                  final timestamp = notification['createdAt'];

                  return Container(
                    margin: EdgeInsets.only(bottom: index < _notifications.length - 1 ? 12 : 0),
                    decoration: BoxDecoration(
                      color: read
                          ? (isDark ? Colors.grey[900] : Colors.grey[100])
                          : (isDark ? Colors.blue[900]?.withOpacity(0.3) : Colors.blue[50]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: read
                            ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                            : _getNotificationColor(type).withOpacity(0.3),
                        width: read ? 1 : 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _getNotificationColor(type).withOpacity(0.2),
                        child: Icon(
                          _getNotificationIcon(type),
                          color: _getNotificationColor(type),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: read ? FontWeight.normal : FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[500] : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      trailing: !read
                          ? IconButton(
                              icon: const Icon(Icons.check_circle_outline, size: 20),
                              color: Colors.grey[600],
                              onPressed: notificationId != null
                                  ? () => _markAsRead(notificationId)
                                  : null,
                              tooltip: 'סמן כנקרא',
                            )
                          : const Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Colors.grey,
                            ),
                      onTap: notificationId != null && !read
                          ? () => _markAsRead(notificationId)
                          : null,
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

