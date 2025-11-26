import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPopupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Fetch the latest active notification from Firebase for a specific user
  static Future<Map<String, dynamic>?> getLatestNotification({String? userEmail}) async {
    try {
      print('📱 Fetching latest notification from Firebase for user: $userEmail');
      
      Query query = _firestore
          .collection('notifications')
          .where('isActive', isEqualTo: true);
      
      // Filter by user email if provided
      if (userEmail != null) {
        query = query.where('user_email', isEqualTo: userEmail);
      }
      
      // Query for active notifications, ordered by creation date (newest first)
      final QuerySnapshot snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final notificationData = snapshot.docs.first.data() as Map<String, dynamic>;
        final notificationId = snapshot.docs.first.id;
        
        // Add the document ID to the data
        notificationData['id'] = notificationId;
        
        print('✅ Found latest notification: ${notificationData['title']}');
        return notificationData;
      } else {
        print('📭 No active notifications found');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching latest notification: $e');
      return null;
    }
  }
  
  /// Get all notifications for a user
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userEmail, {int limit = 10}) async {
    try {
      print('📱 Fetching notifications for user: $userEmail');
      
      final QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('user_email', isEqualTo: userEmail)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('❌ Error fetching user notifications: $e');
      return [];
    }
  }
  
  /// Check if user has already seen this notification
  static Future<bool> hasSeenNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenNotifications = prefs.getStringList('seen_notifications') ?? [];
      return seenNotifications.contains(notificationId);
    } catch (e) {
      print('❌ Error checking seen notification: $e');
      return false;
    }
  }
  
  /// Mark notification as seen
  static Future<void> markNotificationAsSeen(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenNotifications = prefs.getStringList('seen_notifications') ?? [];
      
      if (!seenNotifications.contains(notificationId)) {
        seenNotifications.add(notificationId);
        await prefs.setStringList('seen_notifications', seenNotifications);
        print('✅ Marked notification as seen: $notificationId');
      }
    } catch (e) {
      print('❌ Error marking notification as seen: $e');
    }
  }
  
  /// Get notification display data for popup
  static Map<String, dynamic>? formatNotificationForPopup(Map<String, dynamic> notificationData) {
    try {
      return {
        'id': notificationData['id'],
        'title': notificationData['title'] ?? 'Notification',
        'body': notificationData['name'] ?? notificationData['body'] ?? 'You have a new message',
        'imageUrl': notificationData['imageUrl'],
        'createdAt': notificationData['createdAt'],
        'actionUrl': notificationData['actionUrl'], // Optional: if you want to add action URLs
      };
    } catch (e) {
      print('❌ Error formatting notification for popup: $e');
      return null;
    }
  }
}

